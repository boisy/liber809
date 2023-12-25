*******************************************************
*
* DWWrite
*    Send a packet to the DriveWire server.
*    Serial data format:  1-8-N-1
*    4/12/2009 by Darren Atkinson
*
* Entry:
*    X  = starting address of data to send
*    Y  = number of bytes to send
*
* Exit:
*    X  = address of last byte sent + 1
*    Y  = 0
*    All others preserved
*

* Atari SIO Version
* Based on the hipatch source for the Atari and translated
* into 6809 assembly language by Boisy G. Pitre.
*
SENDDELAY equ       20

DWWrite
          andcc     #^Carry               ; clear carry to assume no error
          pshs      cc,dp,d
          clra
          tfr       a,dp
          setdp     $00
; setup pokey
*          lda       #$28
*          sta       AUDCTL
*          lda       #$A0
*          lda       #$A8
*          sta       AUDC4
* delay before send
          bsr       somedelay
          orcc      #IntMasks                ; mask interrupts
; set pokey to transmit data mode
          lda       #SKCTL.SERMODEOUT|SKCTL.KEYBRDSCAN|SKCTL.KEYDEBOUNCE
          sta	    SKCTL
          sta	    SKRES
          lda       D.IRQENSHDW
          ora       #IRQEN.SEROUTNEEDED
          sta       D.IRQENSHDW
          sta       IRQEN
*          bsr       somedelay
          lda       ,x+
          sta       SEROUT
          leay      -1,y
          beq       ex@
byteloop@
          lda       ,x+
          ldb       #IRQST.SEROUTNEEDED
* NOTE: Potential infinite loop here!
waitloop@
          bitb      IRQST
          bne       waitloop@
          ldb       D.IRQENSHDW
          andb      #^IRQEN.SEROUTNEEDED
          stb       IRQEN
          ldb       D.IRQENSHDW
          stb       IRQEN
          sta       SEROUT
          leay      -1,y
          bne       byteloop@
ex@
          lda       #IRQST.SEROUTDONE
wt        bita      IRQST	; wait until transmit complete
          bne       wt
          puls      cc
          bsr       somedelay
          puls      dp,d,pc


somedelay
          pshs      y
          ldy       #20
delay@
          leay      -1,y
          bne       delay@
          puls      y,pc
