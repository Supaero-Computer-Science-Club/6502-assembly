; the following code demonstrate the use and the inner working of a simple
; pseudo-random number generator.
;
; the generator is a Linear Congruential Generator and uses the following
; rules to generate new numbers in the series:
; Xn+1 = (aXn + c) mod m
;  where X is the sequence of pseudo-random values
;  m, 0 < m  - modulus 
;  a, 0 < a < m  - multiplier
;  c, 0 ≤ c < m  - increment
;  x0, 0 ≤ x0 < m  - the seed or start value
; source (https://www.geeksforgeeks.org/pseudo-random-number-generator-prng/)
;
; the code displays information on the LCD in following format:
; +----------------+
; |nn              |
; |ss ** ++ %% nn  | where ss is the seed, ** the multiplier
; +----------------+ ++ the increment, %% the modulus and nn the number.

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

; program variables addresses.
buffer8  = $0200 ; 1 byte, 8-bit buffer.
buffer16 = $0201 ; 1 word, 16-bit buffer.
div10    = $0203 ; 1 word, used as dividend in print16.
mod10    = $0205 ; 1 word, used as remainder in print16.

; pseudo-random number generator variables.
prng_seed = $3ffb
prng_mod  = $3ffc
prng_mult = $3ffd
prng_inc  = $3ffe
prng_num  = $3fff

  .org $8000

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

  jsr irand ; initialize the pRNG.
  lda $01
  jsr srand

loop:
  lda #%00000010      ; print number in top left corner.
  jsr lcd_instruction
  lda prng_num
  jsr print8

  lda #%11000000      ; print pRNG status on second line.
  jsr lcd_instruction ; "ss ** ++ %% nn" where "ss" is the seed and "nn" the number.
  lda prng_seed
  jsr print8
  lda #" "
  jsr print_char
  lda prng_mult
  jsr print8
  lda #" "
  jsr print_char
  lda prng_inc
  jsr print8
  lda #" "
  jsr print_char
  lda prng_mod
  jsr print8
  lda #" "
  jsr print_char
  lda prng_num
  jsr print8
  lda #" "
  jsr print_char

  jmp loop


;>>> irand(): initialize the pRNG with arbitrary values.
; preconditions:  - none
; execution:      - none
; postconditions: - pRNG initialized.
;                 - overwrites A.
;                 - preserves all other registers.
;                 - writes at prng_mod, prng_mult and prng_inc.
;<<<
irand:
  lda #223
  sta prng_mod
  lda #111
  sta prng_mult
  lda #17
  sta prng_inc
  rts

;>>> srand(): initialize the pRNG's seed, i.e. the first number of the series.
; preconditions:  - 8-bit seed in A.
; execution:      - none
; postconditions: - pRNG's seed initialized.
;                 - preserves all registers.
;                 - writes at prng_seed and prng_num.
;<<<
srand:
  sta prng_seed
  sta prng_num
  rts

;>>> rand(): use the pRNG to generate the next pseudo-random number of the series.
; preconditions:  - none
; execution:      - none
; postconditions: - new pseudo-random number generated in prng_num.
;                 - overwrites A.
;                 - overwrites X.
;                 - writes at prng_mod, prng_mult, prng_inc and prng_num.
;<<<
rand:
  lda prng_num       ; get previous number.

  ldx prng_mult      ; multiply it.
  dex ; one is superfluous.
  clc
rand_mult_loop:
  adc prng_num
  dex
  bne rand_mult_loop

  adc prng_inc       ; increment the number.

  tax                ; apply the modulo.
  ldy prng_mod
  jsr divide8

  stx prng_num       ; store new number.

  inc prng_mult      ; trick to change
  bne mess_with_inc  ; the parameters of
  lda #223           ; the pRNG.
  sta prng_mult
mess_with_inc:       ; simply increment them.
  inc prng_inc       ; make sure prng_mult and
  inc prng_mod       ; prng_mod are not zero.
  bne rand_end
  lda #111
  sta prng_mod
rand_end:

  rts

;>>> divide8(): computes the true division a / b.
; preconditions:  - a in X.
;                 - b in Y.
;                 - a >= b
;                 - a and b are bytes.
; execution:      - loop invariant: a = bq + r (a = b*Y + X)
;                 - 1 byte pushed.
;                 - 1 byte pulled.
; postconditions: - Y = q, X = r.
;<<<
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

;>>> print8(): print a byte in hex format.
;
; preconditions:  - byte in A.
; execution:      - 2 bytes pushed.
;                 - 2 bytes pulled.
; postconditions: - preserves all registers.
;<<<
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


nmi:
irq:
  pha
  phx
  phy

  jsr rand

exit_irq:
  bit PORTA

  ply
  plx
  pla
  rti

  .org $fffa
  .word nmi
  .word reset
  .word irq
