%.bin: %.asm
	mamou -q -mr -I.. $< -o$@
     
%.rom: %.asm
	mamou -q -mr -I.. $< -o$@
     
BOOTROMS	= liber809.rom

ALLROMS		= $(BOOTROMS)
ALLPROGS       = Hello6809.bin

all:	$(ALLROMS) $(ALLPROGS)

clean:
	-rm $(ALLROMS) $(ALLPROGS)
