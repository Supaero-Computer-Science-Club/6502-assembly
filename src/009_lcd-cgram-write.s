; the following code prints any string on the LCD.
; to do so, the stack has to been connected in hardware and
; subroutines have to be called.
; message can be changed on line 54.

; ports of the 65C22 versatile interface adapter.
PORTB = $6000    ; port B of the versatile interface.
PORTA = $6001    ; port A of the versatile interface.
DDRB = $6002     ; port B is controlled by DDRB at 6002.
DDRA = $6003     ; port A is controlled by DDRA at 6003.

; hardware uses 3 top bits of PORTA to control the LDC display. PORTA ~ EWS*****.
E  = %10000000   ; enables the LCD display for control.
RW = %01000000   ; 0 to write, 1 to read.
RS = %00100000   ; 0 to access Instruction Register (IR), 1 for Data Register (DR).

  .org $8000

;; resets the internals of the CPU and interface for proper use.
reset:
  ; initialize the processor.
  ldx #$ff
  txs                     ; set the stack to being #ff.

  ; initialize the LCD.
  lda #%11111111          ; set all pins on port B to output.
  sta DDRB
  lda #%11100000          ; set top 3 pins on port A to output.
  sta DDRA

  lda #%00111000          ; set 8-bit mode; 2-line display; 5x8 font
  jsr lcd_instruction
  lda #%00001100          ; display on; cursor off; blink off
  jsr lcd_instruction
  lda #%00000110          ; increment and shift cursor; don't shift display
  jsr lcd_instruction
  lda #%00000001          ; clear display
  jsr lcd_instruction

  ; write character at 001.
  lda #%00001000
  jsr lcd_cgram_write

  
  ; go home and print CGRAM.
  lda #%00000010
  jsr lcd_instruction
  ldx #8
print_cgram_loop:
  txa
  jsr print_char
  dex
  bne print_cgram_loop

  ; go on second line for the probe.
  lda #%11000000
  jsr lcd_instruction

;; print a string of character on the LCD monitor.
  ldx #0                  ; begin with character 0.
print:
  lda message,x           ; put char in A register.
  beq loop                ; if end of message, A will have null byte.
  jsr print_char          ; print a character and increment the x pointer.
  inx
  jmp print               ; starts over until end of message.

; end of program.
loop:
  jmp loop

; change what you want to print here.
message: .asciiz "probe"

character:
  .byte %00100000
  .byte %00111111
  .byte %00100000
  .byte %00111111
  .byte %00100000
  .byte %00111111
  .byte %00100000
  .byte %00111111


;>>> lcd_cgram_write(): write a character to the CGRAM of the LCD.
;
; preconditions:  - address in A, format ~ **210***
;                 - character bytes are put at character label.
;                   there must be exactly 8 bytes.
;                   each top 3 bits do not matter.
; execution:      - 1 byte pushed.
;                 - 1 byte pulled.
; postconditions: - overwrites all registers.
;<<<
lcd_cgram_write:
  and #%00111000          ; isolate high-bits address.
  ora #%01000111          ; add the instruction 01 and
  tax                     ; begin with last character.
  ldy #7

write_cgram_loop:
  txa                     ; load instruction.
  jsr lcd_instruction
  lda character,y         ; load next character.
  jsr print_char

  dex                     ; decrement the instruction.
  dey                     ; and the index.
  bne write_cgram_loop

  ; first row.
  txa                     ; load instruction.
  jsr lcd_instruction
  lda character,y         ; load next character.
  jsr print_char

  rts

;>>> lcd_wait(): wait for the LCD's busy flag to go low, indicating that the LCD is done.
;
; preconditions:  - none.
; execution:      - 1 byte pushed.
;                 - 1 byte pulled.
; postconditions: - preserves all registers.
;<<<
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

;>>> lcd_instruction(): send an instruction to the LCD. wait for the device to be ready.
;
; preconditions:  - none.
; execution:      - none.
; postconditions: - overwrites A.
;                 - preserves all other registers.
;<<<
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

;>>> print_char(): print a character on the LCD. wait for the device to be ready.
;
; preconditions:  - none.
; execution:      - none.
; postconditions: - overwrites A.
;<<<
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

  .org $fffc
  .word reset
  .word $0000
