; the following code will print a number on the screen, in base 16.
; one can easily change both the message and the number on lines
; 60 and 61 respectively.

; ports of the 65C22 versatile interface adapter.
PORTB = $6000    ; port B of the versatile interface.
PORTA = $6001    ; port A of the versatile interface.
DDRB = $6002     ; port B is controlled by DDRB at 6002.
DDRA = $6003     ; port A is controlled by DDRA at 6003.

; hardware uses top 3 bits of PORTA to control the LDC display. PORTA ~ EWS*****.
E  = %10000000   ; enables the LCD display for control.
RW = %01000000   ; 0 to write, 1 to read.
RS = %00100000   ; 0 to access Instruction Register (IR), 1 for Data Register (DR).

  .org $8000

;; starting point of the program, resets the internals of the CPU and interface for proper use.
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
  lda #%00001110          ; display on; cursor on; blink off
  jsr lcd_instruction
  lda #%00000110          ; increment and shift cursor; don't shift display
  jsr lcd_instruction
  lda #$00000001          ; clear display
  jsr lcd_instruction

; print "num = 0x" on the LCD.
  ldx #0
print_head:
  lda head_of_msg,x
  beq print_number
  jsr print_char
  inx
  jmp print_head

; print the number.
print_number:
  lda number + 1          ; print MS bits in little endian.
  jsr print_byte

  lda number              ; print LS bits.
  jsr print_byte

; end of program.
loop:
  jmp loop

head_of_msg: .asciiz "num = 0x"  ; head of the message.
number: .word $9876              ; the number to print on the LCD.





;; print in hex the byte in A.
print_byte:
  pha             ; save the argument in S.

  ror             ; roll to get the 4 MS bits.
  ror
  ror
  ror
  and #%00001111  ; mask the other bits.
  tax             ; transfer the index in X.
  lda digits,x    ; print the character.
  jsr print_char

  pla             ; get back the argument.
  and #%00001111  ; mask the MS bits.
  tax             ; transfer index and print.
  lda digits,x
  jsr print_char

  rts

digits: .asciiz "0123456789abcdef"  ; the list of all possible hexadecimal digits.





;; wait for the LCD display's busy flag to go low.
lcd_wait:
  pha
  lda #%00000000  ; Port B is input.
  sta DDRB
lcdbusy:
  lda #RW
  sta PORTA
  lda #(RW | E)
  sta PORTA
  lda PORTB
  and #%10000000
  bne lcdbusy

  lda #RW
  sta PORTA
  lda #%11111111  ; Port B is output.
  sta DDRB
  pla
  rts

;; send an instruction to the LCD monitor.
lcd_instruction:
  jsr lcd_wait
  sta PORTB
  lda #0         ; clear RS/RW/E bits.
  sta PORTA
  lda #E         ; set E bit to send instruction.
  sta PORTA
  lda #0         ; clear RS/RW/E bits.
  sta PORTA
  rts

;; print a character to the LCD monitor.
print_char:
  jsr lcd_wait
  sta PORTB
  lda #RS         ; Set RS; Clear RW/E bits
  sta PORTA
  lda #(RS | E)   ; Set E bit to send instruction
  sta PORTA
  lda #RS         ; Clear E bits
  sta PORTA
  rts





  .org $fffc
  .word reset
  .word $0000
