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
  lda #%00001110          ; display on; cursor on; blink off
  jsr lcd_instruction
  lda #%00000110          ; increment and shift cursor; don't shift display
  jsr lcd_instruction
  lda #%00000001          ; clear display
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
message: .asciiz ">1st line here <....unused.characters...>2nd line there<"

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
