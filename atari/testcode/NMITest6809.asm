	org $2000

counter equ $1000

DelayQuick
	clra
d@
	deca
	bne		d@
	rts 
 
DelayLong
	ldd		#$4000
d@
	subd	#$0001
	bne 	d@
	rts 
 
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
	rts

SetupPOKEY
	lda		#3
	sta		$D20F		; set POKEY to active
	rts

SetupSound
	lda		#$A6
	sta		$D203
	rts

	fill	$FF,$E000-*
SWI3Vct
	rti
SWI2Vct
	rti
FIRQVct
	rti
IRQVct
	rti
SWIVct
	rti
NMIVct
	inc		counter
	lda		counter
	sta		$D202
	rti
	
RESETVct
	orcc	#$50
	lds		#$00FF
	clr		counter

	lbsr	ClearIO
	lbsr	DelayQuick
	lbsr	SetupSound
	lbsr	SetupPOKEY
	lda     #$40
	sta     $D40E		enable VBlank NMI

loop@
	lda 	$D40B
	adda    counter
	sta		$D01A
	bra		loop@

* 6809 Vectors
	fill	$FF,$FFF0-*
	fdb		$0000		Reserved
	fdb		SWI3Vct		SWI3
	fdb		SWI2Vct		SWI2
	fdb		FIRQVct		/FIRQ
	fdb		IRQVct		/IRQ
	fdb		SWIVct		SWI
	fdb		NMIVct		/NMI
	fdb		RESETVct	/RESET
