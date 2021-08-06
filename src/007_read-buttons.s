; the following code demonstrates the interrupts and button reads
; through the W65C22 interface adapter.
;
; count the number of times the buttons are pressed
; and prints the counter.
; show the button reads at any time:
;   code        : button = 0 <-> button is pressed.
;   button order: left - up - right - down - enter
; 

; ports of the 65C22 versatile interface adapter.
PORTB = $6000    ; port B of the versatile interface.
PORTA = $6001    ; port A of the versatile interface.
DDRB  = $6002    ; port B is controlled by DDRB at 6002.
DDRA  = $6003    ; port A is controlled by DDRA at 6003.
SR    = $600a    ; shift register.
ACR   = $600b    ; auxiliary control register.
PCR   = $600c    ; preipheral control register.
IFR   = $600d    ; interrupt flag register.
IER   = $600e    ; interrupt enable register.

; hardware uses 3 top bits of PORTA to control the LDC display. PORTA ~ EWS*****.
E  = %10000000   ; enables the LCD display for control.
RW = %01000000   ; 0 to write, 1 to read.
RS = %00100000   ; 0 to access Instruction Register (IR), 1 for Data Register (DR).

; program variables.
ptr16    = $0000 ; 1 word.

buffer8  = $0200 ; 1 byte.
buffer16 = $0201 ; 1 word.
div10    = $0203 ; 1 word.
mod10    = $0205 ; 1 word.
counter  = $0207 ; 1 word.
message  = $0209 ; 6 bytes (including the null-terminating character).
buttons  = $020f ; 1 byte.
changes  = $0210 ; 1 byte.

  .org $8000

;; resets the internals of the CPU and interface for proper use.
reset:
  ; initialize the processor.
  ldx #$ff
  txs                     ; set the stack to being #ff.
  cli

  ; initialize the LCD.
  lda #%11111111          ; set all pins on port B to output.
  sta DDRB
  lda #%11100000          ; set top 3 pins on port A to output.
  sta DDRA

  lda #%00111000          ; set 8-bit mode; 2-line display; 5x8 font.
  jsr lcd_instruction
  lda #%00001100          ; display on; cursor off; blink off.
  jsr lcd_instruction
  lda #%00000110          ; increment and shift cursor; don't shift display.
  jsr lcd_instruction
  lda #%00000001          ; clear display.
  jsr lcd_instruction

  ; initialize the W65C22 interface.
  lda #$82  ; activate CA1.
  sta IER
  lda #$02  ; CA1 ~ positive active edge.
  sta PCR

  ; initialize the counter to 0.
  lda #0
  sta counter
  sta counter + 1

  ; initialize button status.
  lda #$ff
  sta buttons
  lda #0
  sta changes

loop:
  lda #%10000000          ; 1st line ~ counter.
  jsr lcd_instruction
  lda #%00000010          ; go home.
  jsr lcd_instruction
  ; print the counter.
  lda counter
  sta div10
  lda counter + 1
  sta div10 + 1
  jsr print16_decimal

  lda #%11000000          ; 2nd line ~ buttons.
  jsr lcd_instruction
  lda PORTA               ; read buttons.
  tay
  eor buttons             ; look at changes only when pressed.
  and buttons
  sta changes             ; save new buttons and current changes.
  sty buttons

  lda buttons             ; print the buttons status byte.
  ldy #5                  ; there are 5 buttons.
buttons_loop:
  tax
  and #$01
  clc                     ; print the bit.
  adc #"0"
  jsr print_char
  txa
  ror
  dey
  bne buttons_loop

  lda changes             ; increment the counter if changes.
  ldy #5                  ; there are 5 buttons.
changes_loop:
  tax
  and #$01
  beq skip
  inc counter
  bne skip
  inc counter + 1
skip:
  txa
  ror
  dey
  bne changes_loop

  jmp loop




;;; print a word in decimal format.
;
; preconditions:  - word in div10 in RAM
; execution:      - none.
; postconditions: - overwrites A.
;                 - overwrites X.
;                 - overwrites Y.
print16_decimal:
  lda #0       ; empty message.
  sta message
prt16divinit
  ; initialize the remainder modulo 10.
  lda #0
  sta mod10
  sta mod10 + 1
  clc

  ldx #16
prt16divloop:
  rol div10       ; rol the 4 bytes.
  rol div10 + 1
  rol mod10
  rol mod10 + 1

  sec             ; subtract 10 from remainder.
  lda mod10
  sbc #10
  tay
  lda mod10 + 1
  sbc #0          ; a,y = dividend - divisor.

  bcc prt16divskip
  sty mod10
  sta mod10 + 1

prt16divskip:
  dex
  bne prt16divloop

  rol div10         ; shift last bit from carry into div10.
  rol div10 + 1

  ; print the character on LCD.
  lda mod10
  clc
  adc #"0"
  jsr push_char_to_message

  ; continue algorithm until dividend is 0.
  lda div10
  ora div10 + 1
  bne prt16divinit

  lda #<message
  sta ptr16
  lda #>message
  sta ptr16 + 1
  jsr print_string
  rts


;;; push a character onto 'message'.
;
; preconditions:  - character in A.
; execution:      - none.
; postconditions: - overwrites A.
;                 - overwrites X.
;                 - overwrites Y.
push_char_to_message:
  pha             ; new character onto stack.

  ldy #0
phcharloop:
  lda message,y   ; pull head of message into X.
  tax
  pla
  sta message,y   ; change current character.
  iny
  txa
  pha             ; push new character onto stack.
  bne phcharloop

  pla             ; put back the null terminating character.
  sta message,y
  rts


;;; print a string.
;
; preconditions:  - string pointer in ptr16.
; execution:      - none.
; postconditions: - overwrites A.
;                 - overwrites Y.
;                 - may overwrite ptr16.
print_string:
  ldy #0           ; start at index 0.

prt_str_loop:
  lda (ptr16),y   ; load character.
  beq prt_str_end  ; end if null character.

  jsr print_char

  iny              ; inc the low byte index.
  bne prt_str_loop
  inc ptr16+ 1    ; inc the high byte index.
  jmp prt_str_loop

prt_str_end:
  rts


;;; wait for the LCD's busy flag to go low, indicating that the LCD is done.
;
; preconditions:  - none.
; execution:      - 1 byte pushed.
;                 - 1 byte pulled.
; postconditions: - preserves all registers.
lcd_wait:
  pha               ; push A to retrieve it later.
  lda #%00000000    ; set port B as input.
  sta DDRB
lcd_busy_loop:
  lda #RW           ; set RW pin to read the LCD.
  sta PORTA
  lda #(RW | E)
  sta PORTA
  lda PORTB         ; read the LCD's status.
  and #%10000000    ; isolate busy flag, i.e. the MSB.
  bne lcd_busy_loop ; busy if flag is set.

  lda #RW           ; disable the LCD.
  sta PORTA
  lda #%11111111    ; set port B as output.
  sta DDRB
  pla               ; pull A and return.
  rts

;;; send an instruction to the LCD. wait for the device to be ready.
;
; preconditions:  - none.
; execution:      - none.
; postconditions: - overwrites A.
;                 - preserves all other registers.
lcd_instruction:
  jsr lcd_wait    ; wait...
  sta PORTB
  lda #0          ; clear control bits.
  sta PORTA
  lda #E          ; set E bit to send instruction.
  sta PORTA
  lda #0          ; clear control bits.
  sta PORTA
  rts

;;; print a character on the LCD. wait for the device to be ready.
;
; preconditions:  - none.
; execution:      - none.
; postconditions: - overwrites A.
print_char:
  jsr lcd_wait    ; wait...
  sta PORTB
  lda #RS         ; select data register.
  sta PORTA
  lda #(RS | E)   ; set E bit to send instruction
  sta PORTA
  lda #RS         ; disable LCD.
  sta PORTA
  rts

; the non-maskable interrupt pin is not connected here.
nmi:
; counter is incremented when an interrupt is triggered.
irq:
  pha              ; stash everything onto the stack.
  phx
  phy

exit_irq:

  ldx #$01         ; wait some time to debounce
  ldy #$01         ; the buttons in software.
delay:
  dex
  bne delay
  dey
  bne delay

  bit PORTA        ; clear the interrupt.

  ply              ; restore CPU's internal state.
  plx
  pla
  rti

  .org $fffa
  .word nmi
  .word reset
  .word irq
