PORTB = $6000    ; port B of the versatile interface.
PORTA = $6001    ; port A of the versatile interface.
DDRB = $6002     ; port B is controlled by DDRB at 6002.
DDRA = $6003     ; port A is controlled by DDRA at 6003.

; hardware uses top 3 bits of PORTA to control the LDC display. PORTA ~ EWS*****.
E  = %10000000   ; enables the LCD display for control.
RW = %01000000   ; 0 to write, 1 to read.
RS = %00100000   ; 0 to access Instruction Register (IR), 1 for Data Register (DR).

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
