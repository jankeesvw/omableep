# Where the recordings came from

Two of the six boards are recordings and the rest is synthesised. The rule is that anything which was once a chip gets synthesised, because a coin sound on a home computer really was a square wave and generating one is the same act rather than an imitation of it. Anything which was once a physical object, or a signal carried down a phone line, is a recording, because no envelope on a noise generator convincingly imitates a stepper motor or a modem negotiating a rate.

Everything here is Creative Commons Zero or Creative Commons Attribution. CC0 carries no attribution requirement and is credited anyway, so that anyone reviewing this repository can check the provenance rather than take it on faith.

## MODEM

| pads | source | author | licence |
|---|---|---|---|
| `DIAL TONE`, `DIALING`, `HANDSHAKE`, `NEGOTIATE`, `CONNECT` | [56kmodem take04 edit clean m44.wav](https://freesound.org/people/theTone/sounds/209687/) on Freesound | theTone | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) |
| `1200 BAUD` | [modem1200.wav](https://freesound.org/people/guitarguy1985/sounds/78657/) on Freesound | guitarguy1985 | [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) |

`RING` and `BUSY` are synthesised, and that is not a shortcut. A ringing tone is 440 and 480 Hz together, and a busy signal is 480 and 620 Hz at half a second on and half a second off. Those are specifications, so generating them produces the signal itself rather than a likeness of it.

## DRIVE

| pads | source | licence |
|---|---|---|
| `SPIN UP`, `SEEK`, `STEP`, `GRIND` | [Floppy drive sounds.ogg](https://commons.wikimedia.org/wiki/File:Floppy_drive_sounds.ogg) on Wikimedia Commons | [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) |
| `SCREECH`, `SQUEAL`, `CHATTER` | [5.25 inch Floppy Disk making screeching sounds while being read by drive.wav](https://commons.wikimedia.org/wiki/File:5.25_inch_Floppy_Disk_making_screeching_sounds_while_being_read_by_drive.wav) on Wikimedia Commons | [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) |
| `SCRATCH` | [5.25 inch Floppy Disk making scratching sounds while being read by drive.wav](https://commons.wikimedia.org/wiki/File:5.25_inch_Floppy_Disk_making_scratching_sounds_while_being_read_by_drive.wav) on Wikimedia Commons | [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) |

## What was done to them

Every source runs for half a minute or more. A segment of one and a half to three seconds was cut out of each, converted to the same 22 kHz 8 bit mono the synthesiser produces, levelled with `loudnorm`, and given a short fade at each end so a pad stops without a click of its own. The Freesound material was taken from the site's own preview encodes. Nothing was added, and no part of any recording appears here other than the segment named above.

The whole set is 696 KB.

## Why these and not others

Recordings of dial-up modems are everywhere and most of them cannot be shipped. The copies in general circulation are re-uploads whose provenance nobody can establish, and a plugin cannot carry audio on the strength of a hopeful guess about who owns it. The two used here are by people who appear to have recorded their own hardware, under licences that permit redistribution, and the licence was confirmed on each sound's own page rather than taken from a search filter.

If you have recordings you are entitled to use, put them in `~/.config/omableep/sounds/` and they appear on a board of their own. That directory is yours and this repository never touches it.
