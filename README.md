# The Liber809

This repository contains code for the Liber809 Project. The Liber809 is a daughterboard that fits inside of Atari 8-bit computers such as that 600XL, 130XE, XEGS, etc. It replaces the 6502 and internal ROM with a 6809 and its own ROM.

## Prerequisites
All 6809 sources are built with the 'mamou' assembler, available from the ToolShed project on SourceForge:
    http://sourceforge.net/projects/toolshed/develop


## Atari XL/XE
The Atari version of the Liber809 is designed to replace the 6502C microprocessor and has been verified to work on the following systems:
- Atari 65XE
- Atari 130XE
- Atari 800XL
- Atari 1200XL
- Atari XEGS

The Liber809 ROM file replaces the OS ROM found in the Atari.  It resides in $F400-$FFFF of the ROM memory area and is composed of the following source files:
- liber809.asm: the main source file that initializes hardware, etc.
- dwread.asm: the DriveWire read routine for the Atari SIO
- dwwrite.asm: the DriveWire write routine for the Atari SIO
- atari.d: definitions file for the Atari XL/XE

The Liber809 boot ROM expects the Atari to be connected to a computer via the SIO port running a DriveWire server. There are a number to choose from:

- DriveWire Mac Server (https://github.com/boisy/drivewire-mac) - A DriveWire server for macOS.
- DriveWire Win Server (https://github.com/boisy/drivewire-win) - A DriveWire server for Windows.
- DriveWire Unix Server (https://github.com/boisy/drivewire-unix) - A DriveWire server for Unix-based systems.
- pyDriveWire (https://github.com/n6il/pyDriveWire) - A Python-based DriveWire server that is being maintained.
- DriveWire 4 Java Server (http://sites.google.com/site/drivewire4/) - This is no longer being maintained; suitable for older computers.

The Liber809 ROM sets up hardware, then requests a file called **kick** from the DriveWire server. This file is a 32K binary file with 6809 code. The ROM loads the contents of the file starting at address $8000 in the Atari's RAM, then begins executing at that address.

