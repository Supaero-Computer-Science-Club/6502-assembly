  .org $8000

reset:
  ldx #$ff
  txs                     ; set the stack to being #ff.

; init the LCD.
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

