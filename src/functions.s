;>>> empty_vram(): empty the vram buffer, replacing everything with " ".
;
; preconditions:  - none
; execution:      - none
; postconditions: - A (overwritten)
;                 - X (overwritten)
;                 - Y (preserved)
;<<<
empty_vram:
  lda #" "              ; empty vram.
  ldx #vram_size
empty_vram_loop:
  sta vram,x
  dex
  bpl empty_vram_loop
vram_empty:
  rts

;>>> fill_bg_vram(): fill the vRAM with a string. The string is treated as a background and
;                    and allows future blits on the vRAM.
;
; preconditions:  - word pointer to the background string in ptr16.
; execution:      - none
; postconditions: - A (overwritten)
;                 - X (preserved)
;                 - Y (overwritten)
;<<<
fill_bg_vram:
  ldy #0
fill_bg_vram_loop
  lda (ptr16),y
  beq fill_bg_vram_done
  sta vram,y
  iny
  jmp fill_bg_vram_loop
fill_bg_vram_done
  rts

;>>>flip_vram(): flip the vRAM onto the LCD screen. Allows the CPU to do computations in the
;                vRAM buffer, without changing the LCD state until flip time (avoid flickering).
;
; preconditions:  - none
; execution:      - 5 bytes pushed onto the stack ((2 +) 3 in lcd_instruction or print_char).
;                 - 5 bytes pulled onto the stack ((2 +) 3 in lcd_instruction or print_char).
; postconditions: - A (overwritten)
;                 - X (overwritten)
;                 - Y (preserved)
;<<<
flip_vram:
  lda #%00000010              ; go home.
  jsr lcd_instruction
  ldx #0                      ; flip vRAM.
flip_vram_loop:
  lda vram,x
  jsr print_char
  inx
  txa
  cmp #vram_size
  bne flip_vram_loop
  rts

;>>> irand(): initialize the pRNG with arbitrary values.
;
; preconditions:  - none
; execution:      - none
; postconditions: - pRNG initialized.
;                 - A (overwritten)
;                 - X (preserved)
;                 - Y (preserved)
;                 - RAM: writes at prng_mod, prng_mult and prng_inc.
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
;
; preconditions:  - 8-bit seed in A.
; execution:      - none
; postconditions: - pRNG's seed initialized.
;                 - A (preserved)
;                 - X (preserved)
;                 - Y (preserved)
;                 - RAM: writes at prng_seed and prng_num.
;<<<
srand:
  sta prng_seed
  sta prng_num
  rts

;>>> rand(): use the pRNG to generate the next pseudo-random number of the series.
;
; preconditions:  - none
; execution:      - 3 bytes pushed onto the stack ((2 +) 1 in divide8).
;                 - 3 bytes pulled onto the stack ((2 +) 1 in divide8).
; postconditions: - A (overwritten)
;                 - X (overwritten)
;                 - Y (overwritten)
;                 - RAM: - prng_num (new pseudo-random number)
;                        - writes at prng_mod, prng_mult and prng_inc.
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
;
; preconditions:  - a in X.
;                 - b in Y.
;                 - a >= b
;                 - a and b are bytes.
; execution:      - loop invariant: a = bq + r (a = b*Y + X)
;                 - 1 byte pushed onto the stack (1 in body).
;                 - 1 byte pulled onto the stack (1 in body).
; postconditions: - A (overwritten)
;                 - X (holds rest)
;                 - Y (holds quotient)
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

;>>> print8_decimal(): print a byte in decimal format.
;
; preconditions:  - byte pointer in ptr16.
; execution:      - 8 bytes pushed onto the stack (1 in body + (2 +) 5 in print_string or (2 +) + 1 in divide8).
;                 - 8 bytes pushed onto the stack (1 in body + (2 +) 5 in print_string or (2 +) + 1 in divide8).
; postconditions: - A (overwritten)
;                 - X (overwritten)
;                 - Y (overwritten)
;<<<
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

;>>> print16_decimal(): print a word in decimal format.
;
; preconditions:  - word in div10 in RAM
; execution:      - 7 bytes pushed onto the stack ((2 +) 5 in print_string or (2 +) 1 in  push_char_to_message).
;                 - 7 bytes pushed onto the stack ((2 +) 5 in print_string or (2 +) 1 in  push_char_to_message).
; postconditions: - A (overwritten)
;                 - X (overwritten)
;                 - Y (overwritten)
;<<<
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

;  ; complete with spaces.     WORK IN PROGRESS.
;  ldx #0
;  ldy #5
;prt16countchrs:
;  lda message,x
;  beq prt16completestr
;  inx
;  dey
;  jmp prt16countchrs
;prt16completestr:
;  tya
;  beq prt16strcomplete
;prt16completechr:
;  lda #"_"
;  phy
;  jsr push_char_to_message
;  ply
;  dey
;  bne prt16completechr
;
;prt16strcomplete:
  lda #<message
  sta ptr16
  lda #>message
  sta ptr16 + 1
  jsr print_string
  rts


;>>> push_char_to_message(): push a character onto 'message'.
;
; preconditions:  - 8-bit character in A.
; execution:      - 1 byte pushed onto the stack (1 in body).
;                 - 1 byte pulled onto the stack (1 in body).
; postconditions: - A (overwritten)
;                 - X (overwritten)
;                 - Y (overwritten).
;<<<
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


;>>> print_string(): print a string.
;
; preconditions:  - 16-bit string pointer in ptr16.
; execution:      - 5 bytes pushed onto the stack ((2 +) 3 in print_char).
;                 - 5 bytes pushed onto the stack ((2 +) 3 in print_char).
; postconditions: - A (overwritten)
;                 - X (preserved)
;                 - Y (overwritten)
;                 - ptr16 (overwritten if string is more than 256 chars).
;<<<
print_string:
  ldy #0           ; start at index 0.

prt_str_loop:
  lda (ptr16),y   ; load character.
  beq prt_str_end ; end if null character.

  jsr print_char

  iny             ; inc the low byte index.
  bne prt_str_loop
  inc ptr16+ 1    ; inc the high byte index.
  jmp prt_str_loop

prt_str_end:
  rts

;>>> print8(): print a byte in hex format.
;
; preconditions:  - byte in A.
; execution:      - 7 bytes pushed onto the stack (2 in body + (2 +) 3 in print_char).
;                 - 7 bytes pulled onto the stack (2 in body + (2 +) 3 in print_char).
; postconditions: - A (preserved)
;                 - X (preserved)
;                 - Y (preserved)
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

;>>> blit8(): blit a byte onto vram.
;
; preconditions:  - byte in A.
;                 - vram address in Y.
; execution:      - 1 byte pushed onto the stack (1 in body).
;                 - 1 byte pulled onto the stack (1 in body).
; postconditions: - A (preserved)
;                 - X (overwritten)
;                 - Y (+2)
;<<<
blit8:
  pha
  ror             ; roll to get the 4 MS bits.
  ror
  ror
  ror
  and #%00001111  ; mask the other bits.
  tax             ; transfer the index in X.
  lda digits,x    ; print the character.
  sta vram,y
  iny
  pla             ; get back the argument.
  pha
  and #%00001111  ; mask the MS bits.
  tax             ; transfer index and print.
  lda digits,x
  sta vram,y
  pla             ; pull back A and X and return.
  iny             ; increment y to use the function in a row.
  rts

digits: .asciiz "0123456789abcdef"  ; the list of all possible hexadecimal digits.



;>>> lcd_cgram_write(): write a character to the CGRAM of the LCD.
;
; preconditions:  - address in A, format ~ **210***
;                 - character bytes are put at character label.
;                   there must be exactly 8 bytes.
;                   each top 3 bits do not matter.
; execution:      - 5 bytes pushed onto the stack ((2 +) 3 in lcd_instruction or print_char).
;                 - 5 bytes pulled onto the stack ((2 +) 3 in lcd_instruction or print_char).
; postconditions: - A (overwritten)
;                 - X (overwritten)
;                 - Y (overwritten)
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
; execution:      - 1 byte pushed onto the stack (1 in body).
;                 - 1 byte pulled onto the stack (1 in body).
; postconditions: - A (preserved)
;                 - X (preserved)
;                 - Y (preserved)
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
;                       see https://eater.net/datasheets/HD44780.pdf at Instructions (p.24) and Instruction and Display Correspondence (p.39) for more information about the instructions and how to use them.
;
; preconditions:  - 8-bit instruction in A.
; execution:      - 3 bytes pushed onto the stack ((2 +) 1 in lcd_wait).
;                 - 3 bytes pulled onto the stack ((2 +) 1 in lcd_wait).
; postconditions: - A (overwritten)
;                 - X (preserved)
;                 - Y (preserved)
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
;                  see https://eater.net/datasheets/HD44780.pdf at Function Description (p.17-18) formore information about the LCD and available characters.
;
; preconditions:  - 8-bit character in A.
; execution:      - 3 bytes pushed onto the stack ((2 +) 1 in lcd_wait).
;                 - 3 bytes pulled onto the stack ((2 +) 1 in lcd_wait).
; postconditions: - A (overwritten)
;                 - X (preserved)
;                 - Y (preserved)
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
