; the following 65C02 assembly code prints "Hello world!" on the
; LCD, character by character, without any stack and thus with no
; subroutine calls.

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
  ; initialize the LCD.
  lda #%11111111 ; Set all pins on port B to output
  sta DDRB

  lda #%11100000 ; Set top 3 pins on port A to output
  sta DDRA

  lda #%00111000 ; Set 8-bit mode; 2-line display; 5x8 font
  sta PORTB
  lda #0         ; Clear RS/RW/E bits
  sta PORTA
  lda #E         ; Set the E bit. to send instruction
  sta PORTA
  lda #0         ; Clear RS/RW/E bits
  sta PORTA

  lda #%00001110 ; Display on; cursor on; blink off
  sta PORTB
  lda #0         ; Clear RS/RW/E bits
  sta PORTA
  lda #E         ; Set the E bit. to send instruction
  sta PORTA
  lda #0         ; Clear RS/RW/E bits
  sta PORTA

  lda #%00000110 ; Increment and shift cursor; don't shift display
  sta PORTB
  lda #0         ; Clear RS/RW/E bits
  sta PORTA
  lda #E         ; Set the E bit. to send instruction
  sta PORTA
  lda #0         ; Clear RS/RW/E bits
  sta PORTA

  ; print "Hello world!" character by character.
  lda #"H"
  sta PORTB
  lda #RS         ; Set RS; Clear RW/E bits
  sta PORTA
  lda #(RS | E)   ; Set the E bit. to send instruction
  sta PORTA
  lda #RS         ; Clear the E bit.
  sta PORTA

  lda #"e"
  sta PORTB
  lda #RS         ; Set RS; Clear RW/E bits
  sta PORTA
  lda #(RS | E)   ; Set the E bit. to send instruction
  sta PORTA
  lda #RS         ; Clear the E bit.
  sta PORTA

  lda #"l"
  sta PORTB
  lda #RS         ; Set RS; Clear RW/E bits
  sta PORTA
  lda #(RS | E)   ; Set the E bit. to send instruction
  sta PORTA
  lda #RS         ; Clear the E bit.
  sta PORTA

  lda #"l"
  sta PORTB
  lda #RS         ; Set RS; Clear RW/E bits
  sta PORTA
  lda #(RS | E)   ; Set the E bit. to send instruction
  sta PORTA
  lda #RS         ; Clear the E bit.
  sta PORTA

  lda #"o"
  sta PORTB
  lda #RS         ; Set RS; Clear RW/E bits
  sta PORTA
  lda #(RS | E)   ; Set the E bit. to send instruction
  sta PORTA
  lda #RS         ; Clear the E bit.
  sta PORTA

  lda #","
  sta PORTB
  lda #RS         ; Set RS; Clear RW/E bits
  sta PORTA
  lda #(RS | E)   ; Set the E bit. to send instruction
  sta PORTA
  lda #RS         ; Clear the E bit.
  sta PORTA

  lda #" "
  sta PORTB
  lda #RS         ; Set RS; Clear RW/E bits
  sta PORTA
  lda #(RS | E)   ; Set the E bit. to send instruction
  sta PORTA
  lda #RS         ; Clear the E bit.
  sta PORTA

  lda #"w"
  sta PORTB
  lda #RS         ; Set RS; Clear RW/E bits
  sta PORTA
  lda #(RS | E)   ; Set the E bit. to send instruction
  sta PORTA
  lda #RS         ; Clear the E bit.
  sta PORTA

  lda #"o"
  sta PORTB
  lda #RS         ; Set RS; Clear RW/E bits
  sta PORTA
  lda #(RS | E)   ; Set the E bit. to send instruction
  sta PORTA
  lda #RS         ; Clear the E bit.
  sta PORTA

  lda #"r"
  sta PORTB
  lda #RS         ; Set RS; Clear RW/E bits
  sta PORTA
  lda #(RS | E)   ; Set the E bit. to send instruction
  sta PORTA
  lda #RS         ; Clear the E bit.
  sta PORTA

  lda #"l"
  sta PORTB
  lda #RS         ; Set RS; Clear RW/E bits
  sta PORTA
  lda #(RS | E)   ; Set the E bit. to send instruction
  sta PORTA
  lda #RS         ; Clear the E bit.
  sta PORTA

  lda #"d"
  sta PORTB
  lda #RS         ; Set RS; Clear RW/E bits
  sta PORTA
  lda #(RS | E)   ; Set the E bit. to send instruction
  sta PORTA
  lda #RS         ; Clear the E bit.
  sta PORTA

  lda #"!"
  sta PORTB
  lda #RS         ; Set RS; Clear RW/E bits
  sta PORTA
  lda #(RS | E)   ; Set the E bit. to send instruction
  sta PORTA
  lda #RS         ; Clear the E bit.
  sta PORTA

; end of program.
loop:
  jmp loop

  .org $fffc
  .word reset
  .word $0000
