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
	lda		#$A6
	sta		$D203
	rts

counter equ $1000

	fill	$FF,$E000-*
SWI3Vct
	rti
SWI2Vct
	rti
FIRQVct
	rti
IRQVct
	lda		#0
	sta		$D20E
	lda		#1
	sta		$D20E		clear then re-enable Timer1 IRQ
	inc		counter
	lda		counter
	sta		$D202
	rti
	
SWIVct
*	rti
NMIVct
	rti
	
RESETVct
	orcc	#$50
	lds		#$2000
	clr		counter

	lbsr	ClearIO
	lbsr	DelayQuick
	lbsr	SetupSound
	lbsr	SetupPOKEY
	lda     #$40

	lda		#131		262/2 = 131, half the screen height NTSC
	sta		$D200		Set Timer1 value
	lda		#1
	sta		$D208		Set main audio divider to 16 KHz (TV line frequency)
	lda		#1
	sta		$D20E		Enable Timer 1 IRQ
	andcc   #^$50		enable interrupts


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
