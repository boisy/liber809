*******************************************************
*
* DWRead
*    Receive a response from the DriveWire server.
*    Times out if serial port goes idle for more than 1.4 (0.7) seconds.
*    Serial data format:  1-8-N-1
*    4/12/2009 by Darren Atkinson
*
* Entry:
*    X  = starting address where data is to be stored
*    Y  = number of bytes expected
*
* Exit:
*    CC = carry set on framing error, Z set if all bytes received
*    X  = starting address of data received
*    Y  = checksum
*    U is preserved.  All accumulators are clobbered
*


* ATARI SIO Version
TIMEOUT   equ       $1000
DWRead                    
          clrb                     clear Carry & Zero CC flags
          pshs      cc,dp,a,x,y,u
          tfr       b,dp
          setdp     $00
          tfr       x,u
          ldx       #$0000
          orcc      #IntMasks
*          lda       D.IRQENShdw
*          sta       IRQEN
*          ora       #%00100000
* enable the serial input interrupt
          
          ldb       SERIN               read what is in the buffer
          lda	    #SKCTL.SERMODEIN|SKCTL.KEYBRDSCAN|SKCTL.KEYDEBOUNCE
          sta	    SKCTL
          sta	    SKRES
inloop@
          lda       D.IRQENShdw
          ora       #IRQEN.SERINRDY
          sta       D.IRQENShdw
          sta       IRQEN
* timing loop to read a character from the serial chip
          ldd       #TIMEOUT
loop@     subd      #$0001
          beq       overrun_error@
          pshs      b
          ldb       IRQST
          bitb      #IRQST.SERINRDY
          puls      b
          bne       loop@
          ldb       SERIN
          lda       D.IRQENShdw
          anda      #^IRQEN.SERINRDY
          sta       D.IRQENShdw
          sta       IRQEN
* check for framing error
          lda       SKSTAT
          bpl       framing_error@	framing error
          lsla
          bcc       overrun_error@	data input overrun
          stb       ,u+
          abx
          leay      -1,y
          bne       inloop@
bye@      sta	    SKRES          clear framing or data input overrun bits
          stx       5,s
          puls      cc,dp,a,x,y,u,pc
framing_error@
          lda       ,s
          ora       #Carry
          sta       ,s
          bra       outtahere@
overrun_error@
          lda       ,s
          anda      #^Zero
          sta       ,s 
outtahere@
          lda       D.IRQENShdw
          anda      #^IRQEN.SERINRDY
          sta       D.IRQENShdw
          sta       IRQEN
          bra       bye@
