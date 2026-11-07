<div align="center">

# Double Hop

**A tiny, cozy pixel-art platformer where Pip the alien can jump twice. That's the whole trick.**

![Double Hop gameplay](docs/gameplay.gif)

### [▶ Play in your browser on itch.io](https://unwin.itch.io/double-hop)

Made with Godot 4 · 7 short levels · about 5–10 minutes · keyboard or gamepad

</div>

---

## About

Pip has exactly one special move: a second jump in mid-air. Every level is built around it:
tall ledges, wide gaps, spike ceilings that punish an unneeded double jump, cloud platforms,
and blue gems that give the air jump back so you can chain hops over a bottomless sky.

Run, hop, grab the coins, touch the flag.

## Controls

| Action | Keyboard | Gamepad |
|---|---|---|
| Move | ← → or A D | D-pad / left stick |
| Jump (press again in the air to double jump) | Space, ↑, W or Z | A / B |
| Pause | Esc or P | Start |
| Restart level | R | Back / Select |

Hold jump for a higher jump, tap it for a small hop.

## Game feel

The movement code is short and readable: [`scripts/player.gd`](scripts/player.gd).

- **Coyote time** (0.1 s): you can still jump just after running off a ledge.
- **Jump buffer** (0.12 s): pressing jump just before landing still jumps.
- **Variable jump height**: release early for a short hop.
- **Floaty apex**: gravity is lighter at the top of a jump while you hold the button.
- Faster falling than rising, squash and stretch, dust and a little cloud puff on the double jump.

## Run it

1. Install [Godot 4.7](https://godotengine.org/download) (standard build, no .NET needed).
2. Clone this repo and open `project.godot` in Godot, or run it straight from a terminal:

```bash
git clone https://github.com/Unwin41/double-hop.git
cd double-hop
godot --path .
```

## Export for the web (itch.io)

The project ships with a `Web` export preset that has **thread support turned off**,
so it runs on itch.io without SharedArrayBuffer or special headers.

1. In Godot: **Editor → Manage Export Templates → Download and Install** (once).
2. Export from the command line:

```bash
mkdir -p build/web
godot --headless --path . --export-release "Web" build/web/index.html
cd build/web && zip -r ../double-hop-web.zip . && cd -
```

3. Upload `build/double-hop-web.zip` to itch.io as an HTML game and tick
   **"This file will be played in the browser"**.

## Make your own level

Levels are drawn as plain text in [`tools/levels/`](tools/levels/) and turned into
Godot scenes by a small builder. One character is one 18×18 tile:

```text
name: My First Level
theme: 0
hint 1: Jump twice!
---
            c c
     1     #####
  P        #####        F
######   ##########  #######
```

| Char | Meaning | Char | Meaning |
|---|---|---|---|
| `#` | ground (auto-tiled) | `=` | cloud you can jump up through |
| `^` | floor spikes | `v` | ceiling spikes |
| `c` | coin | `g` | gem that refills the air jump |
| `P` | Pip's start | `F` | goal flag |
| `e` | walking blob | `b` | flying bat |
| `*` | random plant | `1`–`9` | hint text from the header |

`theme` picks the sky: `0` pale clouds, `1` warm sunset, `2` green forest.
Rebuild every level (and the TileSet) with:

```bash
godot --headless --path . res://tools/build_levels.tscn
```

Then add the new scene path to `LEVELS` in [`scripts/game_manager.gd`](scripts/game_manager.gd).

## Tests

Movement tests check jump height, the double jump, short hops, coyote time,
the jump buffer and the gem refill:

```bash
godot --headless --path . res://tests/test_movement.tscn
```

## Project layout

```text
assets/    sprites, font, generated TileSet
audio/     sound effects and music
scenes/    player, objects, levels, UI
scripts/   all GDScript (GameManager and Audio are autoloads)
tests/     headless movement tests
tools/     level builder, ASCII level maps, screenshot helper
```

## Credits

All art, sound and music are **CC0** (public domain). Thank you!

- **Art and font:** [Kenney](https://kenney.nl): [Pixel Platformer](https://kenney.nl/assets/pixel-platformer), [Kenney Fonts](https://opengameart.org/content/kenney-fonts)
- **Sound effects:** Juhani Junkala: [512 Sound Effects (8-bit style)](https://opengameart.org/content/512-sound-effects-8-bit-style)
- **Music:** Juhani Junkala: [5 Chiptunes (Action)](https://opengameart.org/content/5-chiptunes-action)

File-by-file details are in [CREDITS.md](CREDITS.md).

## License

Code: [MIT](LICENSE). Assets: CC0 by their authors (see [CREDITS.md](CREDITS.md)).

If Pip made you smile, a ⭐ on the repo means a lot.
