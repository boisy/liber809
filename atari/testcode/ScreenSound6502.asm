*=$8000
	.byte 0
;
	*= $FFFC
	.word reset
	.word 0
	*= $F000
reset
  sei
  jmp wait
  cld
  ldx #$FF
  txs  ; initialize 6502 mode and stack ptr
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
  ldx #$10
delay
  dex
  bne delay ; short delay for Pokey to start, probably not needed
  ldx #<dlist
  ldy #>dlist
  stx $d402
  sty $d403	; setup DList pointer
  lda #$22
  sta $d400	; DMA mode normal
  lda #$f0
  sta $d409	; CHBase at $F000
  lda #$a0
  sta $d200
  lda #$a1
  sta $d202  ; set audf1 and audf2
  lda #0
  sta $d01a  ; Colour border/background
  lda #$82
  sta $d018	; Colour background
  lda #$ca
  sta $d017	; PF1 colour

  lda #$a8
  sta $d201
  sta $d203 ; set audc1 and audc2
wait
  jmp wait  ; loop forever
dlist
	.byte $70,$70,$70,$70
	.byte $42
	.word screen1
	.byte $42
	.word screen1
	.byte $41
	.word dlist
screen1
	.byte 0,1,2,3,4,5,6,7,8,9
	.byte 10,11,12,13,14,15,16,17,18,19
	.byte 0,1,2,3,4,5,6,7,8,9
	.byte 10,11,12,13,14,15,16,17,18,19

