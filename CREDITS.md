# Where the recordings came from

Most of this plugin is synthesised and has no source to credit. The `DRIVE` board is the exception: those eight pads are cut from real recordings of a real 5.25 inch floppy drive, because a stepper motor and a head dragging across oxide are physical events and a square wave does not imitate them convincingly.

Both source files are Creative Commons Zero, which is a dedication to the public domain and carries no attribution requirement. They are credited here anyway, so that anyone reviewing this repository can check the provenance rather than take it on faith.

| pads | source | licence |
|---|---|---|
| `SPIN UP`, `SEEK`, `STEP`, `GRIND` | [Floppy drive sounds.ogg](https://commons.wikimedia.org/wiki/File:Floppy_drive_sounds.ogg) on Wikimedia Commons | [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) |
| `SCREECH`, `SQUEAL`, `CHATTER` | [5.25 inch Floppy Disk making screeching sounds while being read by drive.wav](https://commons.wikimedia.org/wiki/File:5.25_inch_Floppy_Disk_making_screeching_sounds_while_being_read_by_drive.wav) on Wikimedia Commons | [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) |
| `SCRATCH` | [5.25 inch Floppy Disk making scratching sounds while being read by drive.wav](https://commons.wikimedia.org/wiki/File:5.25_inch_Floppy_Disk_making_scratching_sounds_while_being_read_by_drive.wav) on Wikimedia Commons | [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) |

## What was done to them

Each source runs for half a minute or more. A segment of one to two and a half seconds was cut out, converted to the same 22 kHz 8 bit mono the synthesiser produces, levelled with `loudnorm`, and given a short fade at each end so a pad stops without a click of its own. Nothing else was added or removed. The result is 324 KB for the whole board.

## What is not in here

There is no recording of a dial-up modem handshake, and the `MODEM` board is synthesised in full. Real recordings of one are easy to find and hard to license: the copies in circulation are re-uploads whose provenance nobody can establish, and the only Creative Commons Zero result on Freesound turned out to be a generated sound rather than a recording. A plugin cannot ship audio on the strength of a hopeful guess about who owns it.

If you have a recording you are entitled to use, put it in `~/.config/omableep/sounds/` and it appears on its own board. That directory is yours and this repository never touches it.
