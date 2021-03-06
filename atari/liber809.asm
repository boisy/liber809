*****************************************************
* Liber809 Boot ROM for the 6809-based Atari XL/XE
* Currently DriveWire based
*
* Assembled with the 'mamou' assembler from the
* ToolShed Project:  http://sourceforge.net/projects/toolshed/
*
* Assemble with this command line:
* mamou -mr liber809.asm -oliber809.rom
*
* (C) 2012 Boisy G. Pitre
*
* This ROM code copies itself into RAM then puts the machine
* into All-RAM mode.  Then it proceeds to initialize the hardware
* and obtain the 'kick' code from the DriveWire server.
*
* This is how the memory map looks for the bootstrap ROM:
*
*     $0000----> ================================== 
*               |               Stack              |
*     $0500---->|==================================|
*               |                                  |
*  $0500-$08BF  |        40*24 Screen Buffer       |
*  $08C0-$08FF  |    Screen management variables   |
*               |                                  |
*     $0900---->|==================================|
*               |                                  |
*               |      . . . . . . . . . . . .     |
*               |                                  |
*     $F400---->|==================================|
*               |                                  |
*               |       Character Set Bitmap       |
*               |                                  |
*     $F800---->|==================================|
*               |                                  |
*               |        Init and Load Code        |
*               |                                  |
*     $FFE0---->|==================================|
*               |    Screen/SIO Vector Addresses   |
*     $FFF0---->|==================================|
*               |            6809 Vectors          |
*               |==================================|
*
               use       atari.d
               use       drivewire.d

* Version
REVMAJOR       equ  0
REVMINOR       equ  5


ROMTOP         equ       $F400
KICKSTART      equ       $8000               address to load 'kick'
KICKEND        equ       $F400
SCRMEM         equ       $0500
SCRMEMEND      equ       $0500+(G.Rows*G.Cols)
STACK          equ       SCRMEM

* Organization of Screen Managemnt variables
V.CurRow       equ       SCRMEMEND+0
V.CurCol       equ       SCRMEMEND+1
V.CurChr       equ       SCRMEMEND+2
V.EscVect      equ       SCRMEMEND+3
V.EscCh1       equ       SCRMEMEND+5
V.NODrive      equ       SCRMEMEND+7

BAUD192K  	EQU		$2800
BAUD384K  	EQU		$1000
BAUD576K  	EQU		$0800
BAUD1152K 	EQU		$0400
BAUDRATE       EQU       BAUD576K

RAMLOC         equ       $1000

Entire         EQU       %10000000           Full Register Stack flag
FIRQMask       EQU       %01000000           Fast-Interrupt Mask bit
HalfCrry       EQU       %00100000           Half Carry flag
IRQMask        EQU       %00010000           Interrupt Mask bit
Negative       EQU       %00001000           Negative flag
Zero           EQU       %00000100           Zero flag
TwosOvfl       EQU       %00000010           Two's Comp Overflow flag
Carry          EQU       %00000001           Carry bit
IntMasks       EQU       IRQMask+FIRQMask
Sign           EQU       %10000000           sign bit

               org       ROMTOP

* Character Set -- must be aligned on a 1K boundary!
CharSet
               fcb	$00,$00,$00,$00,$00,$00,$00,$00	;$00 - space
               fcb	$00,$18,$18,$18,$18,$00,$18,$00	;$01 - !
               fcb	$00,$66,$66,$66,$00,$00,$00,$00	;$02 - "
               fcb	$00,$66,$FF,$66,$66,$FF,$66,$00	;$03 - #
               fcb	$18,$3E,$60,$3C,$06,$7C,$18,$00	;$04 - $
               fcb	$00,$66,$6C,$18,$30,$66,$46,$00	;$05 - %
               fcb	$1C,$36,$1C,$38,$6F,$66,$3B,$00	;$06 - &
               fcb	$00,$18,$18,$18,$00,$00,$00,$00	;$07 - '
               fcb	$00,$0E,$1C,$18,$18,$1C,$0E,$00	;$08 - (
               fcb	$00,$70,$38,$18,$18,$38,$70,$00	;$09 - )
               fcb	$00,$66,$3C,$FF,$3C,$66,$00,$00	;$0A - asterisk
               fcb	$00,$18,$18,$7E,$18,$18,$00,$00	;$0B - plus
               fcb	$00,$00,$00,$00,$00,$18,$18,$30	;$0C - comma
               fcb	$00,$00,$00,$7E,$00,$00,$00,$00	;$0D - minus
               fcb	$00,$00,$00,$00,$00,$18,$18,$00	;$0E - period
               fcb	$00,$06,$0C,$18,$30,$60,$40,$00	;$0F - /
               
               fcb	$00,$3C,$66,$6E,$76,$66,$3C,$00	;$10 - 0
               fcb	$00,$18,$38,$18,$18,$18,$7E,$00	;$11 - 1
               fcb	$00,$3C,$66,$0C,$18,$30,$7E,$00	;$12 - 2
               fcb	$00,$7E,$0C,$18,$0C,$66,$3C,$00	;$13 - 3
               fcb	$00,$0C,$1C,$3C,$6C,$7E,$0C,$00	;$14 - 4
               fcb	$00,$7E,$60,$7C,$06,$66,$3C,$00	;$15 - 5
               fcb	$00,$3C,$60,$7C,$66,$66,$3C,$00	;$16 - 6
               fcb	$00,$7E,$06,$0C,$18,$30,$30,$00	;$17 - 7
               fcb	$00,$3C,$66,$3C,$66,$66,$3C,$00	;$18 - 8
               fcb	$00,$3C,$66,$3E,$06,$0C,$38,$00	;$19 - 9
               fcb	$00,$00,$18,$18,$00,$18,$18,$00	;$1A - colon
               fcb	$00,$00,$18,$18,$00,$18,$18,$30	;$1B - semicolon
               fcb	$06,$0C,$18,$30,$18,$0C,$06,$00	;$1C - <
               fcb	$00,$00,$7E,$00,$00,$7E,$00,$00	;$1D - =
               fcb	$60,$30,$18,$0C,$18,$30,$60,$00	;$1E - >
               fcb	$00,$3C,$66,$0C,$18,$00,$18,$00	;$1F - ?
               
               fcb	$00,$3C,$66,$6E,$6E,$60,$3E,$00	;$20 - @
               fcb	$00,$18,$3C,$66,$66,$7E,$66,$00	;$21 - A
               fcb	$00,$7C,$66,$7C,$66,$66,$7C,$00	;$22 - B
               fcb	$00,$3C,$66,$60,$60,$66,$3C,$00	;$23 - C
               fcb	$00,$78,$6C,$66,$66,$6C,$78,$00	;$24 - D
               fcb	$00,$7E,$60,$7C,$60,$60,$7E,$00	;$25 - E
               fcb	$00,$7E,$60,$7C,$60,$60,$60,$00	;$26 - F
               fcb	$00,$3E,$60,$60,$6E,$66,$3E,$00	;$27 - G
               fcb	$00,$66,$66,$7E,$66,$66,$66,$00	;$28 - H
               fcb	$00,$7E,$18,$18,$18,$18,$7E,$00	;$29 - I
               fcb	$00,$06,$06,$06,$06,$66,$3C,$00	;$2A - J
               fcb	$00,$66,$6C,$78,$78,$6C,$66,$00	;$2B - K
               fcb	$00,$60,$60,$60,$60,$60,$7E,$00	;$2C - L
               fcb	$00,$63,$77,$7F,$6B,$63,$63,$00	;$2D - M
               fcb	$00,$66,$76,$7E,$7E,$6E,$66,$00	;$2E - N
               fcb	$00,$3C,$66,$66,$66,$66,$3C,$00	;$2F - O
               
               fcb	$00,$7C,$66,$66,$7C,$60,$60,$00	;$30 - P
               fcb	$00,$3C,$66,$66,$66,$6C,$36,$00	;$31 - Q
               fcb	$00,$7C,$66,$66,$7C,$6C,$66,$00	;$32 - R
               fcb	$00,$3C,$60,$3C,$06,$06,$3C,$00	;$33 - S
               fcb	$00,$7E,$18,$18,$18,$18,$18,$00	;$34 - T
               fcb	$00,$66,$66,$66,$66,$66,$7E,$00	;$35 - U
               fcb	$00,$66,$66,$66,$66,$3C,$18,$00	;$36 - V
               fcb	$00,$63,$63,$6B,$7F,$77,$63,$00	;$37 - W
               fcb	$00,$66,$66,$3C,$3C,$66,$66,$00	;$38 - X
               fcb	$00,$66,$66,$3C,$18,$18,$18,$00	;$39 - Y
               fcb	$00,$7E,$0C,$18,$30,$60,$7E,$00	;$3A - Z
               fcb	$00,$1E,$18,$18,$18,$18,$1E,$00	;$3B - [
               fcb	$00,$40,$60,$30,$18,$0C,$06,$00	;$3C - \
               fcb	$00,$78,$18,$18,$18,$18,$78,$00	;$3D - ]
               fcb	$00,$08,$1C,$36,$63,$00,$00,$00	;$3E - ^
               fcb	$00,$00,$00,$00,$00,$00,$FF,$00	;$3F - underline
               
               fcb	$00,$18,$3C,$7E,$7E,$3C,$18,$00	;$60 - diamond card
               fcb	$00,$00,$3C,$06,$3E,$66,$3E,$00	;$61 - a
               fcb	$00,$60,$60,$7C,$66,$66,$7C,$00	;$62 - b
               fcb	$00,$00,$3C,$60,$60,$60,$3C,$00	;$63 - c
               fcb	$00,$06,$06,$3E,$66,$66,$3E,$00	;$64 - d
               fcb	$00,$00,$3C,$66,$7E,$60,$3C,$00	;$65 - e
               fcb	$00,$0E,$18,$3E,$18,$18,$18,$00	;$66 - f
               fcb	$00,$00,$3E,$66,$66,$3E,$06,$7C	;$67 - g
               fcb	$00,$60,$60,$7C,$66,$66,$66,$00	;$68 - h
               fcb	$00,$18,$00,$38,$18,$18,$3C,$00	;$69 - i
               fcb	$00,$06,$00,$06,$06,$06,$06,$3C	;$6A - j
               fcb	$00,$60,$60,$6C,$78,$6C,$66,$00	;$6B - k
               fcb	$00,$38,$18,$18,$18,$18,$3C,$00	;$6C - l
               fcb	$00,$00,$66,$7F,$7F,$6B,$63,$00	;$6D - m
               fcb	$00,$00,$7C,$66,$66,$66,$66,$00	;$6E - n
               fcb	$00,$00,$3C,$66,$66,$66,$3C,$00	;$6F - o
               
               fcb	$00,$00,$7C,$66,$66,$7C,$60,$60	;$70 - p
               fcb	$00,$00,$3E,$66,$66,$3E,$06,$06	;$71 - q
               fcb	$00,$00,$7C,$66,$60,$60,$60,$00	;$72 - r
               fcb	$00,$00,$3E,$60,$3C,$06,$7C,$00	;$73 - s
               fcb	$00,$18,$7E,$18,$18,$18,$0E,$00	;$74 - t
               fcb	$00,$00,$66,$66,$66,$66,$3E,$00	;$75 - u
               fcb	$00,$00,$66,$66,$66,$3C,$18,$00	;$76 - v
               fcb	$00,$00,$63,$6B,$7F,$3E,$36,$00	;$77 - w
               fcb	$00,$00,$66,$3C,$18,$3C,$66,$00	;$78 - x
               fcb	$00,$00,$66,$66,$66,$3E,$0C,$78	;$79 - y
               fcb	$00,$00,$7E,$0C,$18,$30,$7E,$00	;$7A - z
               fcb	$00,$18,$3C,$7E,$7E,$18,$3C,$00	;$7B - spade card
               fcb	$18,$18,$18,$18,$18,$18,$18,$18	;$7C - |
               fcb	$00,$7E,$78,$7C,$6E,$66,$06,$00	;$7D - display clear
               fcb	$08,$18,$38,$78,$38,$18,$08,$00	;$7E - display backspace
               fcb	$10,$18,$1C,$1E,$1C,$18,$10,$00	;$7F - display tab
               
               fcb	$00,$36,$7F,$7F,$3E,$1C,$08,$00	;$40 - heart card
               fcb	$18,$18,$18,$1F,$1F,$18,$18,$18	;$41 - mid left window
               fcb	$03,$03,$03,$03,$03,$03,$03,$03	;$42 - right box
               fcb	$18,$18,$18,$F8,$F8,$00,$00,$00	;$43 - low right window
               fcb	$18,$18,$18,$F8,$F8,$18,$18,$18	;$44 - mid right window
               fcb	$00,$00,$00,$F8,$F8,$18,$18,$18	;$45 - up right window
               fcb	$03,$07,$0E,$1C,$38,$70,$E0,$C0	;$46 - right slant box
               fcb	$C0,$E0,$70,$38,$1C,$0E,$07,$03	;$47 - left slant box
               fcb	$01,$03,$07,$0F,$1F,$3F,$7F,$FF	;$48 - right slant solid
               fcb	$00,$00,$00,$00,$0F,$0F,$0F,$0F	;$49 - low right solid
               fcb	$80,$C0,$E0,$F0,$F8,$FC,$FE,$FF	;$4A - left slant solid
               fcb	$0F,$0F,$0F,$0F,$00,$00,$00,$00	;$4B - up right solid
               fcb	$F0,$F0,$F0,$F0,$00,$00,$00,$00	;$4C - up left solid
               fcb	$FF,$FF,$00,$00,$00,$00,$00,$00	;$4D - top box
               fcb	$00,$00,$00,$00,$00,$00,$FF,$FF	;$4E - bottom box
               fcb	$00,$00,$00,$00,$F0,$F0,$F0,$F0	;$4F - low left solid
               
               fcb	$00,$1C,$1C,$77,$77,$08,$1C,$00	;$50 - club card
               fcb	$00,$00,$00,$1F,$1F,$18,$18,$18	;$51 - up left window
               fcb	$00,$00,$00,$FF,$FF,$00,$00,$00	;$52 - mid box
               fcb	$18,$18,$18,$FF,$FF,$18,$18,$18	;$53 - mid window
               fcb	$00,$00,$3C,$7E,$7E,$7E,$3C,$00	;$54 - solid circle
               fcb	$00,$00,$00,$00,$FF,$FF,$FF,$FF	;$55 - bottom solid
               fcb	$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0	;$56 - left box
               fcb	$00,$00,$00,$FF,$FF,$18,$18,$18	;$57 - up mid window
               fcb	$18,$18,$18,$FF,$FF,$00,$00,$00	;$58 - low mid window
               fcb	$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0	;$59 - left solid
               fcb	$18,$18,$18,$1F,$1F,$00,$00,$00	;$5A - low left window
               fcb	$78,$60,$78,$60,$7E,$18,$1E,$00	;$5B - display escape
               fcb	$00,$18,$3C,$7E,$18,$18,$18,$00	;$5C - up arrow
               fcb	$00,$18,$18,$18,$7E,$3C,$18,$00	;$5D - down arrow
               fcb	$00,$18,$30,$7E,$30,$18,$00,$00	;$5E - left arrow
               fcb	$00,$18,$0C,$7E,$0C,$18,$00,$00	;$5F - right arrow

* The display list sets up the ANTIC chip to display the main screen. 
DList
               fcb	$70,$70,$70	3 * 8 blank scanlines
               fcb	$42			Mode 2 with LMS (Load Memory Scan).  Mode 2 = 40 column hires text, next 2 bytes L/H determine screen origin
               fdbs	SCRMEM   		origin
               fcb	2,2,2,2,2,2,2,2,2,2
               fcb	2,2,2,2,2,2,2,2,2,2
               fcb	2,2,2
* 23 extra mode 2 lines for total of 24.  240 scanlines can be used for display area, but a hires line cannot be on scanline 240 due to an Antic bug
               fcb	$41			this is the end of Display List command JVB (Jump and wait for Vertical Blank)
               fdbs DList


SignOnMsg      fcc  "Liber809 ROM v"
               fcb  $30+REVMAJOR
               fcc  "."
               fcb  $30+REVMINOR
               fcc  " - Atari XL/XE"
               fcb  $0D,$0A
               fcc  "(C) 2012 Boisy G. Pitre"
               fcb  $0D,$0A
               fcb  $0D,$0A
               fcb  0
MemModeMsg
               IFNE ALLRAM_MODE
               fcc  "Running in RAM"
               ELSE
               fcc  "Running in ROM"
               ENDC
               fcb  $0D,$0A
               fcb  0
SIOMsg         fcc  "SIO speed at "
               IFNE      BAUDRATE-57600
               fcc  "57.6"
               ELSE
               IFNE      BAUDRATE-38400
               fcc  "38.4"
               ENDC
               ENDC
               fcc  "Kbps"
               fcb  $0D,$0A
MountMsg       fcc  "Mounting '"
MountName      fcc  "kick"
MountNameLen   equ  *-MountName
               fcc  "'... "
               fcb  00

OKMsg          fcc       "OK"
CRLF           fcb       $0D,$0A
               fcb       00

LoadingMsg     fcc       "Loading $"
               fcb       00
Loading2Msg    fcc       " bytes at $"
               fcb       00

FailedMsg      fcc       "FAIL"
               fcb       $0D,$0A
               fcb       00

JumpMsg
               fcb       $0D,$0A
               fcc       "Jumping to $"
               fcb       00

ResetMsg       fcc       "Press RESET to try again"
               fcb       00

*******************************************************
* ENTRY POINT!
RESETVct
* mask interrupts and setup the stack
               orcc	     #$50
               lds	     #STACK

* clear the I/O space between $D000-$D3FF
ClearIO
               clr       D.IRQENSHDW
               
               clr       PBCTL          set for direction register first
               clrb
loop
               ldx		#CTIA
               clr		b,x
               ldx		#ANTIC
               clr		b,x
               ldx		#POKEY
               clr		b,x
               cmpb      #PORTB&$0F
               beq       loopbot@
               ldx		#PIA
               clr		b,x
loopbot@
               incb
               bne		loop
               
* setup the PIA
SetupPIA
	          lda	     #$3C
          	STA	     PBCTL	;precondition port B outputs
          	LDA	     #$CF
               STA	     PORTB	;initialize port B
               LDA	     #$38
               STA	     PACTL	;select data direction register
               STA	     PBCTL	;select data direction register
               LDA	     #$00
               STA	     PORTA	;all inputs
               LDA	     #$FF
               STA	     PORTB	;all outputs
               LDA	     #$3C
               STA	     PACTL	;back to port
               STA	     PBCTL	;back to port
               LDA	     PORTB	;clear interrupts
               LDA	     PORTA	;clear interrupts
	
* setup POKEY here
SetupPOKEY
          	lda		#$22           get POKEY out of initialization mode and set ch.4
          	sta		SKCTL		; set POKEY to active

               lda       #$A0
               sta       AUDC3
               sta       AUDC4
               
               lda       #$28
               sta       AUDCTL
               
               lda       #$FF
               sta       SEROUT
               
               ldd		#BAUDRATE 	get POKEY baud rate
               std		AUDF3		and store it in HW reg

               IFNE      ALLRAM_MODE
* Copy RAMCODE to RAMLOC then execute it
               leax      RAMCODE,pcr
               ldy       #RAMLOC
               ldb       #RAMCODELEN
loop@          lda       ,x+
               sta       ,y+
               decb
               bne       loop@
               jmp       >RAMLOC
               
RAMCODE
* The following is run from RAM
* Copy ROMTOP-$FFFF from ROM to RAM
*               lda       PORTB
*               tfr       a,b
*               ora       #%00000001     ROM mode
*               andb      #%11111110     RAM mode
               lda       #%11111111
               ldb       #%11111110
* put in ROM mode
               sta       PORTB          ROM mode
* copy from ROM to RAM
               ldx       #ROMTOP
               ldy       #RAMLOC+$1000
copyloop1@
               ldu       ,x++
               stu       ,y++
               cmpx      #$0000
               bne       copyloop1@

* put in RAM mode
               stb       PORTB          RAM mode
* copy from low RAM to high RAM
               ldx       #ROMTOP
               ldy       #RAMLOC+$1000
copyloop2@
               ldu       ,y++
               stu       ,x++
               cmpx      #$0000
               bne       copyloop2@


               jmp       >Continue

**** A check to see the address at X is ROM (carry set) or RAM (carry clear)
RAMROMCheck
               pshs      d
               ldd       ,x             get two bytes at X
               coma                     complement
               comb
               std       ,x             write back
               cmpd      ,x             compare to what we wrote
               bne       itsrom@        if not same, it is ROM
               coma                     else its RAM... re complement
               comb
               std       ,x             save back
               clrb                     clear carry
               puls      d,pc
itsrom@
               comb                     set carry
               puls      d,pc

* Test snippet used to debug code
* just sets the background to a color and cycles through forever
GoCrazy
               clra
gl@            inca
               sta       COLBK
               lbrn      $0000
               cmpx      ,s
               bra       gl@
          
RAMCODELEN     equ       *-RAMCODE
               ENDC

Continue          
               ldu       #SCRMEMEND
               lbsr	     VTIOInit
               
               leax      SignOnMsg,pcr
               lbsr      WriteString

               leax      MemModeMsg,pcr
               lbsr      WriteString
               
               leax      SIOMsg,pcr
               lbsr      WriteString

* clear memory
               ldx       #$8000
               ldd       #$0000
loop@
               std       ,x++
               cmpx      #$D000
               bne       next@
               leax      $800,x
               bra       loop@
next@          cmpx      #KICKEND
               bne       loop@

* Tell DW Server we want to mount the named object
               lda       #OP_NAMEOBJ_MOUNT
               ldb       #MountNameLen
               pshs      d
               leax      ,s
               ldy       #$0002
               lbsr      DWWrite
               leax      MountName,pcr
               ldy       #MountNameLen
               lbsr      DWWrite
               
               leax      ,s
               ldy       #$0001
               lbsr      DWRead
               puls      d
               lbcs      MountFailed
               lbne      MountFailed
               tsta
               lbeq      MountFailed
               sta       V.NODrive,u
               leax      OKMsg,pcr
               lbsr      WriteString
               
* Object is mounted... now load bytes sarting at KICKSTART
               leax      LoadingMsg,pcr
               lbsr      WriteString

               ldd       #KICKEND
               subd      #KICKSTART
               lbsr      WriteHexWord
               
               leax      Loading2Msg,pcr
               lbsr      WriteString

               ldd       #KICKSTART
               lbsr      WriteHexWord

               leax      CRLF,pcr
               lbsr      WriteString

               ldx       #KICKSTART
               ldy       #$0000
               lda       #OP_READEX

ReadLoop
* Send Read Command
               cmpx      #$D000
               bne       keepon
               leax      $800,x
               leay      8,y            skip sectors $50-$57 ($D000-$D7FF)
keepon
               pshs      a,x,y
               pshs      d,x
               lda       #'$
               lbsr      WriteChar
               tfr       x,d
               lbsr      WriteHexWord
               puls      d,x
               pshs      y              put LSN bits 15-0 on stack
               clr       ,-s            put LSN bits 23-16 on stack ($00)
               ldy       #$0000
               ldb       V.NODrive,u
               pshs      d              put OP code and drive # on stack
               leax      ,s
               ldy       #$0005
               lbsr      DWWrite
               leas      5,s

* Get Sector Data
               ldy       #$100
               ldx       1,s
               clra
               lbsr      DWRead
* Note: we ignore any error in reading and send whatever CRC we have.
               bcs       uhoh
               bne       uhoh
          
* Send CRC
sendcrc
               pshs      y
               leax      ,s
               ldy       #$0002
               lbsr      DWWrite
               leas      2,s
          
* Get Error Code
               pshs      a
               leax      ,s
               ldy       #$0001
               clra
               lbsr      DWRead          
               puls      d,x,y
               bcs       ReRead
               bne       ReRead
               tsta
               beq       ReadOk
ReRead
               lbsr      WaitABit
               lda       #'?
               lbsr      WriteChar
               lda       #OP_REREADEX *v0.5 - Fixed
               bra       ReadLoop
ReadOk          
               lda       #$0D
               pshs      b,x,y
               lbsr      WriteChar
               puls      a,x,y
               leax      $100,x
               leay      1,y
               cmpx      #KICKEND
               lbne      ReadLoop
               ldx       -2,x

               leax      JumpMsg,pcr
               lbsr      WriteString

               ldd       KICKEND-2
*               ldd       #KICKSTART
               lbsr      WriteHexWord

               leax      CRLF,pcr
               lbsr      WriteString

*               jmp       >KICKSTART
               jmp       [>KICKEND-2]

uhoh
               puls     a,x,y
               bra      ReRead

MountFailed
               leax      FailedMsg,pcr
               lbsr      WriteString

               leax      ResetMsg,pcr
               lbsr      WriteString
               
Loop4Ever      bra       Loop4Ever


WaitABit       pshs      x
               ldx       #$0000
loop@               
               leax      -1,x
               bne       loop@
               puls      x,pc

VTIOInit      
		     pshs 	u

     		leax 	ChkSpc,pcr
	     	stx  	V.EscVect,u
		
* setup static vars
               clra
               clrb
               std	     V.CurRow,u

* Clear screen memory
               ldx       #SCRMEM
               ldy       #40*24
               ldd       #$0000
clearLoop@
          	std	     ,x++
               leay      -2,y
     	     bne	     clearLoop@
     	
* tell the ANTIC where the dlist is
               ldd       #DList
               exg       a,b
		     std	     DLISTL

* tell the ANTIC where the character set is (page aligned, currently in Krn)		
     		lda	     #ROMTOP>>8
	     	sta	     CHBASE
		
* set background color
     		clra
 	     	sta	     COLBK

* set text color
     		ldd	     #$0F*256+$94
 		     sta	     COLPF1
 		     stb	     COLPF2
 		
* tell ANTIC to start DMA and enable character set 2

     		ldd	     #$22*256+$02
 	     	sta	     DMACTL
 	     	stb	     CHACTL

initex	     puls	     u,pc


HexTable       fcc       "0123456789ABCDEF"
          
* D = hex value to write
WriteHexWord
               pshs      d,x,y
               leax      HexTable,pcr
               lsra
               lsra
               lsra
               lsra
               lda       a,x
               bsr       WriteChar
               lda       ,s
               anda      #$0F
               lda       a,x
               bsr       WriteChar
               ldb       1,s
               lsrb
               lsrb
               lsrb
               lsrb
               lda       b,x
               bsr       WriteChar
               ldb       1,s
               andb      #$0F
               lda       b,x
               bsr       WriteChar
               puls      d,x,y,pc
          
* X = hi-byte-terminated string to write
WriteHiString
               pshs a,x
loop@
               lda  ,x+
               bmi  hi@
               bsr  WriteChar
               bra  loop@
hi@            anda #%01111111
               bsr  WriteChar
done           puls a,x,pc

* X = nul-terminated string to write
WriteString
               pshs a,x
loop@
               lda  ,x+
               beq  done
               bsr  WriteChar
               bra  loop@

WriteChar
               pshs      d,x,y,u
               ldu       #SCRMEMEND
     		bsr		hidecursor		
	     	ldx		V.EscVect,u
		     jsr		,x
		     bsr       drawcursor
		     puls      d,x,y,u,pc


ChkSpc
     		cmpa		#$20 			space or greater?
	     	bcs		ChkESC			branch if not
		
wchar	     suba		#$20
               pshs		a
               lda		V.CurRow,u
               ldb		#G.Cols
               mul
               addb		V.CurCol,u
               adca		#0
               ldx		#SCRMEM
               leax		d,x
               puls		a
               sta		,x
               ldd		V.CurRow,u
               incb
               cmpb		#G.Cols
               blt		ok
               clrb
incrow
     		inca
	     	cmpa		#G.Rows
     		blt		clrline
SCROLL    	EQU		1
               IFNE		SCROLL
               deca						set A to G.Rows - 1
               pshs		d				save off Row/Col
               ldx		#SCRMEM   		get start of screen memory
               ldy		#G.Cols*(G.Rows-1)	set Y to size of screen minus last row
scroll_loop
               ldd		G.Cols,x			get two bytes on next row
               std		,x++				store on this row
               leay		-2,y				decrement Y
               bne		scroll_loop		branch if not 0
               puls		d				recover Row/Col
               ELSE
               clra
               ENDC
* clear line
clrline   	std		V.CurRow,u
               bsr		DelLine
               rts
ok   		std		V.CurRow,u
ret            rts
		
* calculates the cursor location in screen memory
* Exit: X = address of cursor
*       All other regs preserved
calcloc
               pshs		d
               lda		V.CurRow,u
               ldb		#G.Cols
               mul
               addb		V.CurCol,u
               adca		#0
               ldx		#G.ScrStart
               leax		d,x
               puls		d,pc

drawcursor
		bsr		calcloc
		lda		,x
		sta		V.CurChr,u
		lda		#$80
		sta		,x
		rts

hidecursor
    		pshs		a
		bsr		calcloc
		lda		V.CurChr,u
		sta		,x
		puls		a,pc

ChkESC
               cmpa	     #$1B			ESC?
               lbeq	     EscHandler
               cmpa      #$0D		$0D?
               bhi       ret	branch if higher than
               leax      <DCodeTbl,pcr	deal with screen codes
               lsla  			adjust for table entry size
               ldd       a,x		get address in D
               jmp       d,x		and jump to routine

* display functions dispatch table
DCodeTbl  	fdb       NoOp-DCodeTbl			$00:no-op (null)
               fdb       CurHome-DCodeTbl		$01:HOME cursor
               fdb       CurXY-DCodeTbl		$02:CURSOR XY
               fdb       DelLine-DCodeTbl		$03:ERASE LINE
               fdb       ErEOLine-DCodeTbl		$04:CLEAR TO EOL
               fdb       Do05-DCodeTbl			$05:CURSOR ON/OFF
               fdb       CurRght-DCodeTbl		$005e  $06:CURSOR RIGHT
               fdb       NoOp-DCodeTbl			$07:no-op (bel:handled in VTIO)
               fdb       CurLeft-DCodeTbl		$08:CURSOR LEFT
               fdb       CurUp-DCodeTbl		$09:CURSOR UP
               fdb       CurDown-DCodeTbl		$0A:CURSOR DOWN
               fdb       ErEOScrn-DCodeTbl		$0B:ERASE TO EOS
               fdb       ClrScrn-DCodeTbl		$0C:CLEAR SCREEN
               fdb       Retrn-DCodeTbl		$0D:RETURN
         
DelLine
     		lda		V.CurRow,u
	     	ldb		#G.Cols
		     mul
     		ldx		#SCRMEM
	     	leax		d,x
		     lda		#G.Cols
clrloop@	     clr		,x+
     		deca
	     	bne		clrloop@
     		rts
		
ClrScrn
ErEOScrn
CurUp
NoOp
CurHome
CurXY
ErEOLine
Do05
CurRght
	     	rts

CurLeft
               ldd		V.CurRow,u
               beq		leave
               decb
               bpl		erasechar
               ldb		#G.Cols-1
               deca
               bpl		erasechar
               clra
erasechar
               std		V.CurRow,u
               ldb		#G.Cols
               mul
               addb		V.CurCol,u
               adca		#0
               ldx		#SCRMEM
               leax		d,x
               clr		1,x
leave	     rts

CurDown
               ldd		V.CurRow,u
     		lbra		incrow

Retrn
               clr		V.CurCol,u
               rts

EscHandler
     		leax		EscHandler2,pcr
eschandlerout
     		stx		V.EscVect,u
	     	rts

EscHandler2
               sta		V.EscCh1,u
               leax		EscHandler3,pcr
               bra		eschandlerout

EscHandler3
               ldb		V.EscCh1,u
               cmpb		#$32
               beq		DoFore
               cmpb		#$33
               beq		DoBack
               cmpb		#$34
               beq		DoBord
eschandler3out
               leax		ChkSpc,pcr
               bra		eschandlerout

DoFore
*    		sta		COLPF0
	     	sta		COLPF1
*	     	sta		COLPF3
     		bra		eschandler3out
DoBack
               sta		COLPF2
               bra		eschandler3out
DoBord
               sta		COLBK
               bra		eschandler3out
		

* Unused vectors routed here
SWI3Vct
SWI2Vct
FIRQVct
IRQVct
SWIVct
NMIVct
	          rti

* DriveWire read/write routines for SIO are here
               use       dwread.asm
          
               use       dwwrite.asm
          
               fill      $FF,$FFE0-*
* I/O Entry points
DWIORENT       fdb       DWRead
DWIOWENT       fdb       DWWrite
WRCHARENT      fdb       WriteChar
WRSTRENT       fdb       WriteString
WRHISTRENT     fdb       WriteHiString
WRHEXENT       fdb       WriteHexWord

* 6809 Vectors - these go at the very last 16 bytes of ROM
     	     fill      $FF,$FFF0-*
	          fdb		$0000		Reserved
               fdb       $0100
               fdb       $0103
               fdb       $010F
               fdb       $010C
               fdb       $0106
               fdb       $0109
	          fdb		RESETVct	     /RESET
