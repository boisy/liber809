* Simple example of a 'kick' program in 6809 assembly
* To assemble: mamou kick.asm -mr -okick

     	org $1000

* Our entry point is here
Entry
          leax      HelloMsg,pcr        point to Hello message
          jsr       [>$FFE6]            Call WriteString subroutine

Forever   bra       Forever             branch forever

HelloMsg  fcb       $0D,$0A
          fcc       "Hi there, Liber809!"
          fcb       $00