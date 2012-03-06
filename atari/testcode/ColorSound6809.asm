 org $FF00
reset
 orcc #$50
 lds #$2000
 clrb
cleario
 ldx   #$D000
 clr   b,x
 ldx   #$D200
 clr   b,x
 ldx   #$D300
 clr   b,x
 ldx   #$D400
 clr   b,x
 decb
 bne   cleario
 lda   #3
 sta   $D20F ; set Pokey to active

delay
 lda   #$55
 sta   $D01A  ; set screen color
 lda   #$A0
 sta   $D200
 lda   #$A1
 sta   $D202  ; set audf1 and audf2
 lda   #$A8
 sta   $D201
 sta   $D203  ; set audc1 and audc2
wait
 jmp   wait

 fill  $FF,$FFF0-*
 fdb   reset
 fdb   reset
 fdb   reset
 fdb   reset
 fdb   reset
 fdb   reset
 fdb   reset
 fdb   reset
