%.bin: %.asm
	mamou -q -mr -I.. $< -o$@
     
%.rom: %.asm
	mamou -q -mr -I.. $< -o$@
     
BOOTROMS	= liber809.rom

ALLROMS		= $(BOOTROMS)
ALLPROGS       = Hello6809.bin TimerTest6809.bin NMITest6809.bin ColorTest6809.bin \
               ColorSound6809.bin ScreenSound6809.bin

all:	$(ALLROMS) $(ALLPROGS)

clean:
	-rm $(ALLROMS) $(ALLPROGS)
