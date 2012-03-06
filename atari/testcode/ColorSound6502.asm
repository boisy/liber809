*= $FFFE
  .word reset
  *= $FF00
reset
  sei
  cld
  ldx #$FF
;  txs  ; initialize 6502 mode and stack ptr
  inx
  txa
cleario
  sta $d000,x
  sta $d200,x
  sta $d300,x
  sta $d400,x
  dex
  bne cleario
  lda #3
  sta $d20f ; set Pokey to active
;  ldx #$10
delay
;  dex
;  bne delay ; short delay for Pokey to start, probably not needed
  lda #$46
  sta $d01a  ; set screen color
  lda #$a0
  sta $d200
  lda #$a1
  sta $d202  ; set audf1 and audf2
  lda #$a8
  sta $d201
  sta $d203 ; set audc1 and audc2
wait
  jmp wait  ; loop forever
