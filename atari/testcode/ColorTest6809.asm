	org $C000

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
	lda		#$A0
	sta		$D200
	lda		#$A1
	sta		$D202  ; set audf1 and audf2
	lda		#$A8
	sta		$D201
	sta		$D203  ; set audc1 and audc2
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
	rti
RESETVct
	orcc	#$50
	lds		#$2000

	lbsr	ClearIO
	lbsr	DelayQuick
	lbsr	SetupPOKEY
	lbsr	SetupSound

	clra
xxx
	sta		$D01A
	inca
	pshs	a
	lbsr	DelayLong
	puls	a
	bra		xxx

wait
	jmp		wait

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
