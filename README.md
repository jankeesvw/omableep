# Omableep

A soundboard for the Omarchy bar. The chip sounds are synthesised on the spot, the machine sounds are real recordings.

Five boards of eight: `MODEM` (dial tone, handshake, CONNECT, NO CARRIER), `DRIVE` (a real 5.25 inch floppy spinning up, seeking, grinding), `SYSTEM` (power-on, keyclick, tape load, error), `ARCADE` (coin, laser, extra life, game over) and `ALERT` (klaxon, siren, red alert). Press a letter for a board, a number for a pad.

## Where the sounds come from

Anything that was once a chip is synthesised, and anything that was once a physical object is a recording. That line is not a compromise, it is the whole design: a coin sound on a home computer really was a square wave with a pitch step in it, so synthesising one is not an imitation but the same act. A stepper motor dragging a head across oxide is not, and no envelope on a noise generator will convince you otherwise.

So four boards are numbers. A waveform, a pulse width, an envelope, a pitch slide, turned into 8-bit 22 kHz audio at the moment you press the pad and piped straight into the system player. The longest takes 69 milliseconds to make and most take three or four, which is why there is no cache, no first-run generation step, and no state directory to clean up.

The `DRIVE` board is 324 KB of real floppy drive, cut from two CC0 recordings on Wikimedia Commons. `CREDITS.md` names them, says what was done to them, and explains why there is no recording of a modem in here.

Sampled game audio is a different matter and is not in this plugin at any point. It is still under copyright everywhere and will be for another fifty years, so a board built from it could not be published. If you have recordings you are entitled to use, the `YOURS` board below is for exactly that.

## Installing

```bash
omarchy plugin add https://github.com/jankeesvw/omableep --enable
omarchy bar move jankeesvw.omableep --section right
```

Needs `python3` and one of `pw-play`, `paplay` or `aplay`. Omarchy ships all of these, so there is nothing to install.

A key to open it directly, if you want one:

```lua
o.bind("SUPER SHIFT, B", "Omableep", "omarchy-shell shell toggle jankeesvw.omableep")
```

## Using it

| | |
|---|---|
| `A` to `F` | pick a board, in the order they are listed on the card |
| `1` to `8` | fire that pad |
| arrow keys | move the cursor |
| `enter` or `space` | fire the pad under the cursor |
| `tab` | next board, `shift+tab` for the previous one |
| `+` and `-` | volume |
| `backspace` | stop everything that is sounding |
| `esc` | close |

Six pads can sound at once. A seventh takes over the oldest, the way a hardware board does.

## Making your own pads

Copy a board out of `pads.json` into `~/.config/omableep/pads.json` and edit it. A board whose `id` matches a shipped one replaces it; a board with a new `id` is added after the others. The panel re-reads the file the next time the shell starts.

A pad is either a `"wav"` naming a file in `sounds/`, or a list of notes played one after another with an optional second list mixed on top:

```json
{
  "label": "COIN",
  "seq": [
    { "w": "pulse", "f": 988,  "ms": 65,  "duty": 0.5, "r": 15,  "vol": 0.36 },
    { "w": "pulse", "f": 1319, "ms": 300, "duty": 0.5, "r": 230, "vol": 0.36 }
  ]
}
```

| field | meaning |
|---|---|
| `w` | `pulse`, `tri`, `saw` or `noise` |
| `f` | frequency in Hz |
| `ms` | length in milliseconds |
| `duty` | pulse width, `0.5` is a square |
| `pwm`, `pwmhz` | how far and how fast the pulse width wobbles |
| `a`, `d`, `s`, `r` | attack, decay, sustain level, release |
| `slide` | semitones per second, negative for down |
| `vib`, `vibhz` | vibrato depth and rate |
| `arp`, `arphz` | semitone steps cycled at that rate |
| `vol` | `0` to `1`; a note at `0` is a rest |

A top-level `"gain"` sets the starting volume. The panel does not remember where you left the slider, because remembering would mean writing a file.

## Using your own recordings

Put `.wav` files in `~/.config/omableep/sounds/` and they appear as a board of their own called `YOURS`, named after the filenames, sixteen at most. The directory is not created for you; make it yourself when you want it.

This is the place for audio this plugin will not carry. What you put there stays on your machine, is never copied anywhere, and is not part of this repository.

Files are refused if they are not ordinary files you own, are larger than 2 MB, or do not start with a RIFF/WAVE header. Refused files do not appear on the board.

## What it touches

**Reads:** `pads.json` and the eight recordings in `sounds/` beside the plugin, plus `~/.config/omableep/pads.json` and any `.wav` files in `~/.config/omableep/sounds/`. Nothing else.

**Writes:** nothing, anywhere, ever. No cache, no state file, no configuration written on your behalf.

**Network:** none. There is no endpoint to name because there is no request.

**Runs:** `/usr/bin/python3` on the bundled script, and one of `/usr/bin/pw-play`, `/usr/bin/paplay` or `/usr/bin/aplay` per pad, with a minimal environment and the audio arriving on its stdin rather than as a filename. At most six such processes exist at a time and each has a thirty second deadline.

## Removing

```bash
omarchy plugin remove jankeesvw.omableep
```

That is all of it, because the plugin never wrote anything. If you made `~/.config/omableep/` yourself it stays where it is, along with your own pads and recordings; delete that directory if you want it gone.

## Credits

The `DRIVE` recordings and their licences are listed in `CREDITS.md`.

## Licence

MIT. See `LICENSE`.
