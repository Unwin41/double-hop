# Credits

Double Hop's code is MIT licensed (see [LICENSE](LICENSE)).
Every asset below is **CC0 1.0 (public domain)**. Credit isn't required, but these creators deserve it.

| What | Files in this repo | Author | Source | License |
|---|---|---|---|---|
| Pixel Platformer (v1.2): tiles, characters, backgrounds | `assets/sprites/tiles.png`, `assets/sprites/characters.png`, `assets/sprites/backgrounds.png` | [Kenney](https://kenney.nl) | [kenney.nl](https://kenney.nl/assets/pixel-platformer) · [itch.io](https://kenney-assets.itch.io/pixel-platformer) · [OpenGameArt](https://opengameart.org/content/pixel-platformer-0) (the copy downloaded) | [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) |
| Kenney Fonts: Kenney Pixel | `assets/fonts/kenpixel.ttf` | [Kenney](https://kenney.nl) | [OpenGameArt](https://opengameart.org/content/kenney-fonts) | [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) |
| The Essential Retro Video Game Sound Effects Collection [512 sounds] | `audio/sfx/*.wav` | Juhani Junkala (SubspaceAudio) | [OpenGameArt](https://opengameart.org/content/512-sound-effects-8-bit-style) | [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) |
| Retro Game Music Pack ("5 Chiptunes (Action)"): "Level 1" and "Ending" | `audio/music/level.wav`, `audio/music/ending.wav` | Juhani Junkala (SubspaceAudio) | [OpenGameArt](https://opengameart.org/content/5-chiptunes-action) | [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) |

## Changes made to the assets

- Sprite sheets were copied from the pack's `Tilemap/*_packed.png` files and renamed.
- Sound effects were renamed for readability:

  | Game file | Original file |
  |---|---|
  | `jump.wav` | `Movement/Jumping and Landing/sfx_movement_jump1.wav` |
  | `land.wav` | `Movement/Jumping and Landing/sfx_movement_jump9_landing.wav` |
  | `coin.wav` | `General Sounds/Coins/sfx_coin_single1.wav` |
  | `hurt.wav` | `General Sounds/Negative Sounds/sfx_sounds_damage1.wav` |
  | `gem.wav` | `General Sounds/Positive Sounds/sfx_sounds_powerup2.wav` |
  | `win.wav` | `General Sounds/Fanfares/sfx_sounds_fanfare1.wav` |
  | `menu_move.wav` | `General Sounds/Menu Sounds/sfx_menu_move1.wav` |
  | `menu_select.wav` | `General Sounds/Menu Sounds/sfx_menu_select1.wav` |

- The two music tracks were converted to mono, 22,050 Hz to keep the web build small.

## Tools

- [Godot Engine](https://godotengine.org) 4.7 (MIT)
