# Curiosities

## SCORE is HISCORE without the HI

Only `HISCORE:000000` is written in the ROM (0x8F4B). The score line copies that same text from two letters
further on, 0x8F50: `SCORE:000000` (`marcador`, 0x8D54).

## Past 999,999, 990,000

When the score goes past 999,999 the game wants to hold it at 999,999: it writes 0x99 into the three bytes of
the score... but the loop does not move the pointer on, and the three 0x99 land on the same byte, the top one
(`puntos_tope`, 0x90E8). Running the routine with `tools/bios.py`, 999,999 + 1 gives **990,000** (and one more
life, the one every 10,000).

## The computer picks the title's colour

While it waits on the title, every 3 frames the game changes the colours of the big kanji with 512 bytes read
from **page 1** (0x4000 onwards, one byte further each time): the high half of each byte is the colour, and if it
is below 2, red (`titulo_espera`, 0x80D6). Page 1 does not hold the cartridge but whatever the computer has
there, so the colour depends on the MSX. Running the ROM (without those bytes) the kanji come out white, as in the
[title](imagenes/titulo.png); in openMSX with C-BIOS, red.

## The scroll is in the last one

The kakejiku of each hall can be opened in any order, but the secret scroll always comes out of the last one:
the game counts the opened ones (0xE1CA) and gives it when the count reaches 10, 18, 20 or 9, which are exactly
the ones each hall has (0x9FF4). To leave a hall you have to open them all.

## Tiles made of code

The drawings of the game's tiles are copied to the VRAM in a 0x600-byte block from 0xA800
(`vram_casillas_a800`, 0x8E8D), but that block starts before the code and the data end: tiles 0x4E-0x57 are the
bytes of the crouching routine (`agacha`, 0xA8F0) and the next ones, the rows of the CASIO logo. No map uses
those tiles. The same with the sprites: 0x800 bytes are copied from 0xB800 (`sprites_dibujos`, 0x8EC9), and the
last ones are the map pieces and the routine that draws the map.

## Comparisons that change nothing

At the top of the jump the game checks which way it jumps and which way the ninja faces... and the four paths end
at the same instruction with the same HL (0x9843). On landing it does the same with an `inc hl` and a `dec hl`
that are lost because HL is loaded again (0x98E9). And before losing the stage when TIME runs out it checks
0xE185, which nothing in the ROM writes (0x8DD5).

## The demo has no lives

The demo does not go through the new-game setup, so it starts with no spare lives: on the first hit GAME OVER
comes up and it goes back to the title.

## What nothing calls

69 bytes of code that nothing calls at 0x9C8C, two variants of the routine that checks whether something touches
the ninja at 0x842D, a `jr` after a `ret` (0x9787) and a `ret` after another one (0x9BC5). None of them runs in the
openMSX measurements.
