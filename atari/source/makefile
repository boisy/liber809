%.bin: %.asm
	mamou -q -mr -I.. $< -o$@
     
%.rom: %.asm
	mamou -q -mr -I.. $< -o$@
     
BOOTROMS	= liber809_rommode.rom liber809_rammode.rom

ALLROMS		= $(BOOTROMS)
ALLPROGS	= Hello6809.bin fuji.bin

all:	$(ALLROMS) $(ALLPROGS)

liber809_rommode.rom: liber809.asm
	mamou -q -mr -aALLRAM_MODE=0 -aATARI $< -o$@
	os9 padrom -b 16384 $@

liber809_rammode.rom: liber809.asm
	mamou -q -mr -aALLRAM_MODE=1 -aATARI $< -o$@
	os9 padrom -b 16384 $@

clean:
	-rm $(ALLROMS) $(ALLPROGS)
