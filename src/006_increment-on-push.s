; the following code will increment a counter and print it over
; and over, when any of the 5 buttons is pressed.

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

a         = $0200 ; 1 byte.
b         = $0201 ; 1 byte.
buffer8   = $0202 ; 1 byte.
buffer16  = $0203 ; 1 word.
message   = $0205 ; 6 bytes.
value     = $020b ; 1 word.
mod10     = $020d ; 1 word.
counter   = $020f ; 1 word.

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
  lda #%00001110          ; display on; cursor on; blink off.
  jsr lcd_instruction
  lda #%00000110          ; increment and shift cursor; don't shift display.
  jsr lcd_instruction
  lda #%00000001          ; clear display.
  jsr lcd_instruction

  ; initialize the W65C22 interface.
  lda #$82  ; activate CA1.
  sta IER
  lda #$00  ; CA1 ~ negative edge.
  sta PCR

  ; initialize the counter to 0.
  lda #0
  sta counter
  sta counter + 1

loop:
  lda #%00000010          ; go home.
  jsr lcd_instruction
  ; print the counter.
  lda counter
  sta value
  lda counter + 1
  sta value + 1
  jsr print16_decimal

  jmp loop


;;; computes the true division a / b.
; preconditions:  - a in X.
;                 - b in Y.
;                 - a >= b
;                 - a and b are bytes.
; execution:      - loop invariant: a = bq + r (a = b*Y + X)
;                 - 1 byte pushed.
;                 - 1 byte pulled.
; postconditions: - Y = q, X = r.
divide8:
  phy             ; store b onto stack.
  ldy #0          ; r=a in X and q=0 in Y

div8loop:
  pla             ; pull b from stack.
  stx buffer8     ; put r in buffer8.
  cmp buffer8     ; compare r and b.
  bcs div8end
  pha             ; push b back onto stack.

  iny             ; increment q.

  sta buffer8     ; put b in buffer8.
  txa             ; put r in A.
  sec
  sbc buffer8     ; A <- r - b
  tax             ; put r back in X.

  jmp div8loop    ; go back to loop.

div8end:
  rts

;;; print a byte in decimal format.
;
; preconditions:  - byte pointer in ptr16.
; execution:      - none.
; postconditions: - overwrites A.
;                 - overwrites X.
;                 - overwrites Y.
print8_decimal:
  lda (ptr16)     ; load byte in X.
  tax

  lda #20          ; clear the message.
  sta message
  sta message + 1
  sta message + 2
  ldy #2           ; end of message onto stack.
  phy

prt8decloop:
  ldy #10
  jsr divide8  ; divide by 10.

  lda digits,x
  plx              ; pull index, store.
  sta message,x
  dex              ; update and stack index.
  phx

  tya              ; r is the new a.
  tax
  beq prt8decend
  jmp prt8decloop

prt8decend:
  lda #<message    ; print the message.
  sta ptr16
  lda #>message
  sta ptr16 + 1
  jsr print_string

  rts

;;; print a word in decimal format.
;
; preconditions:  - word in value in RAM
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
  rol value       ; rol the 4 bytes.
  rol value + 1
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

  rol value         ; shift last bit from carry into value.
  rol value + 1

  ; print the character on LCD.
  lda mod10
  clc
  adc #"0"
  jsr push_char_to_message

  ; continue algorithm until dividend is 0.
  lda value
  ora value + 1
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

;;; print a byte in hex format.
;
; preconditions:  - byte in A.
; execution:      - 2 bytes pushed.
;                 - 2 bytes pulled.
; postconditions: - preserves all registers.
;
print8:
  phx             ; save X and argument onto stack.
  pha

  ror             ; roll to get the 4 MS bits.
  ror
  ror
  ror
  and #%00001111  ; mask the other bits.
  tax             ; transfer the index in X.
  lda digits,x    ; print the character.
  jsr print_char

  pla             ; get back the argument.
  pha
  and #%00001111  ; mask the MS bits.
  tax             ; transfer index and print.
  lda digits,x
  jsr print_char

  pla             ; pull back A and X and return.
  plx
  rts

digits: .asciiz "0123456789abcdef"  ; the list of all possible hexadecimal digits.





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
  rti

; counter is incremented when an interrupt is triggered.
irq:
  pha              ; stash everything onto the stack.
  phx
  phy

  inc counter      ; increment the 16-bit counter.
  bne exit_irq
  inc counter + 1

exit_irq:

  ldx #$01         ; wait some time to debounce
  ldy #$ff         ; the buttons in software.
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
