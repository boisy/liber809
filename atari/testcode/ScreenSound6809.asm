 org $F000
reset
 orcc #$50		mask interrupts
 lds  #$00FF		stack pointer

* clear I/O
ClearIO
	clrb
loop
	ldx		#$D000
	clr		b,x
	ldx		#$D200
	clr		b,x
	ldx		#$D300
	clr		b,x
	ldx		#$D400
	clr		b,x
	decb
	bne		loop

* set POKEY active
 lda  #3
 sta  $D20F

* setup DList pointer
 leax dlist,pcr
 tfr x,d
 exg a,b
 std  $D402

 lda #$22
 sta $D400	DMA mode normal
 lda #$F0
 sta $D409      CHBase at $F000
 lda #$A0
 sta $D200
 lda #$A1
 sta $D202	set audf1 and audf2
 clra
 sta  $D10A	; color border/background
 lda  #$82
 sta  $D018	; color background
 lda  #$CA
 sta  $D017	;PF1 color

 lda #$A8
 sta  $D201
 sta $D203      ; set audc1 and audc2

wait jmp wait

    fill $FF,$FF00-*
    
dlist
	fcb $70,$70,$70,$70
	fcb $42
	fdbs screen1
	fcb $42
	fdbs screen1
	fcb $41
	fdbs dlist
screen1
	fcb 0,1,2,3,4,5,6,7,8,9
	fcb 10,11,12,13,14,15,16,17,18,19
	fcb 0,1,2,3,4,5,6,7,8,9
	fcb 10,11,12,13,14,15,16,17,18,19

 fill  $FF,$FFF0-*
 fdb   reset
 fdb   reset
 fdb   reset
 fdb   reset
 fdb   reset
 fdb   reset
 fdb   reset
 fdb   reset


