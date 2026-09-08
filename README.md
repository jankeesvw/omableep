# Omableep

A soundboard for the Omarchy bar. The chip sounds are synthesised on the spot, the machine sounds are real recordings.

Five boards of eight: `MODEM` (a real 56k session: dial tone, dialing, handshake, connect), `DRIVE` (a real 5.25 inch floppy spinning up, seeking, grinding), `SYSTEM` (power-on, keyclick, tape load, error), `ARCADE` (coin, laser, extra life, game over) and `ALERT` (klaxon, siren, red alert). Press a letter for a board, a number for a pad.

## Where the sounds come from

Anything that was once a chip is synthesised, and anything that was once a physical object is a recording. That line is not a compromise, it is the whole design: a coin sound on a home computer really was a square wave with a pitch step in it, so synthesising one is not an imitation but the same act. A stepper motor dragging a head across oxide is not, and no envelope on a noise generator will convince you otherwise.

So four boards are numbers. A waveform, a pulse width, an envelope, a pitch slide, turned into 8-bit 22 kHz audio at the moment you press the pad and piped straight into the system player. The longest takes 69 milliseconds to make and most take three or four, which is why there is no cache, no first-run generation step, and no state directory to clean up.

The `MODEM` and `DRIVE` boards are 696 KB of real hardware: a 56k modem dialling out and connecting, and a 5.25 inch floppy drive spinning up and grinding. `CREDITS.md` names every source, its author and its licence, and says what was cut out of it.

Two pads on the `MODEM` board stay synthesised, and that is not a shortcut either. A ringing tone is 440 and 480 Hz together and a busy signal is 480 and 620 Hz at half a second on and off. Those are specifications, so generating them produces the signal rather than a likeness of it.

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

This is the place for audio this plugin will not carry, and it is deliberately the only place. Nothing in this repository reaches the network, so a pack is something you assemble rather than something the plugin fetches on your behalf. What you put there stays on your machine and is never copied anywhere.

Files are refused if they are not ordinary files you own, are larger than 2 MB, or do not start with a RIFF/WAVE header. Refused files do not appear on the board, and the extension is not taken at its word: the header is what decides.

### An example pack

A worked example, because the shape of a pack is easier to see than to describe. This one is a car: a Tesla reversing, its tailgate, a seatbelt reminder and an autopilot disconnect warning. Every sound is CC0, checked on its own page rather than on a search filter, and the whole thing is five files and about 400 KB.

Paste it into a terminal. It needs `curl` and `ffmpeg`, both of which Omarchy already has.

```bash
mkdir -p ~/.config/omableep/sounds && cd ~/.config/omableep/sounds

while read -r name url start secs; do
  fade=$(awk -v s="$secs" 'BEGIN{printf "%.2f", s-0.08}')
  curl -q -sS --fail --proto '=https' --max-time 60 --max-filesize 8000000 \
    -o /tmp/omableep-src -- "$url" &&
  ffmpeg -nostdin -v error -y -ss "$start" -t "$secs" -i /tmp/omableep-src \
    -ac 1 -ar 22050 -acodec pcm_u8 \
    -af "afade=t=in:d=0.03,afade=t=out:st=$fade:d=0.08,loudnorm=I=-16:TP=-1.5" \
    "$name.wav" && echo "  $name.wav"
done <<'SOUNDS'
tesla-backup   https://cdn.freesound.org/previews/745/745146_2397507-lq.ogg   0.15  3.4
tesla-accel    https://cdn.freesound.org/previews/761/761685_13088347-lq.ogg  0.15  4.8
tesla-trunk    https://cdn.freesound.org/previews/585/585830_7439175-lq.ogg  11.0   5.0
car-seatbelt   https://cdn.freesound.org/previews/218/218315_1480854-lq.ogg   0.2   4.0
autopilot-off  https://cdn.freesound.org/previews/203/203539_1028972-lq.ogg   0.0   1.4
SOUNDS

rm -f /tmp/omableep-src
```

Then `omarchy restart shell` and press `F`.

The `-nostdin` on `ffmpeg` is not decoration. Without it ffmpeg eats the list this loop is reading from and you get one file instead of five.

Two of those sources are worth a word. `tesla-backup` is the pedestrian warning a Tesla plays when it reverses, recorded by [itinerantmonk108](https://freesound.org/people/itinerantmonk108/sounds/745146/); `autopilot-off` is an aircraft autopilot disconnect warning by [KIZILSUNGUR](https://freesound.org/people/KIZILSUNGUR/sounds/203539/), not a car one. Tesla's own interface sounds, the autopilot chime and the takeover alert as the car plays them, are not in this list and could not be: they are Tesla's assets and are not published under any licence, anywhere. If you want those and you have the car, record them yourself. A recording you made is yours, and it drops straight into the same directory.

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
