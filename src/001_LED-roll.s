; the following code is only designed to work on early stages of the 
; 65C02 computer project, or if wiring some LEDs at any point of the
; project. LEDs should be connected to port B of the W65C22 versatile
; interface adapter of the microprocessor.
;
; loads %01010000 into port B of the interface and makes it roll to
; the right, looping forever.
  .org $8000

reset:
  lda #$ff   ; sets port B as output.
  sta $6002

  lda #$50   ; load %01010000 into port B.
  sta $6000

loop:
  ror        ; roll right and store value.
  sta $6000

  jmp loop

  .org $fffc
  .word reset
  .word $0000
