# Liber809 ReadMe

This repository contains code for the Liber809 Project.

## Prerequisites
All 6809 sources are built with the 'mamou' assembler, available from the ToolShed project on SourceForge:
    http://sourceforge.net/projects/toolshed/develop


## Atari XL/XE
The Atari version of the Liber809 is designed to replace the 6502C microprocessor and has been verified to work on the following systems:
- Atari 130XE
- Atari 800XL
- Atari 1200XL

The Liber809 ROM file replaces the OS ROM found in the Atari.  It resides in $F400-$FFFF of the ROM memory area and is composed of the following source files:
- liber809.asm: the main source file that initializes hardware, etc.
- dwread.asm: the DriveWire read routine for the Atari SIO
- dwwrite.asm: the DriveWire write routine for the Atari SIO
- atari.d: definitions file for the Atari XL/XE

The Liber809 boot ROM expects the Atari to be connected to the DriveWire 4 server (http://sites.google.com/site/drivewire4/) via the SIO port.  After setting up hardware, it asks the DriveWire 4 server for a file called 'kick', expected to be up to a 32K binary file with 6809 code.  The contents of kick are loaded, and execution jumps to address $8000.

