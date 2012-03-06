counter = $2000
*=$F000
startup   ldx #$FF
  txs
  cld
  sei
  inx
  txa
cleario   sta $D000,x
  sta $D200,x
  sta $D300,x
  sta $D400,x
  dex
  bne cleario
  LDA #$A6
  STA $D203
  lda #3
  sta $D20F
  lda #$40
  sta $D40E
loop   lda $D40B
  clc
  adc counter
  sta $D01A
  jmp loop
nmi
   pha
   inc counter
	LDA COUNTER
  STA $D202
  pla
irq   rti
  *=$FFFA
 .word nmi
 .word startup
 .word irq