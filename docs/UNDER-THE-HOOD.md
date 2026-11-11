# Under the hood

## Rebuilding the ROM

`make verify` assembles `src/iganinpouchou.asm` with pasmo and the 16 KB ROM comes out **byte for byte**. `make
sanity` checks what reassembly does not cover: that no byte declared as data is read as code, that no entry point
falls into data and that all 16,384 bytes are explained. `make test` runs the tests. The ROM is not in the
repository: put it in the root as `iganinpouchou.rom` (the GoodMSX dump, `[!]`, sha1 `f629b8f7...`).

| | bytes |
|---|---|
| traced code | 9,296 |
| named data | 7,088 |
| unexplained | 0 |

The listing has 1,736 comments on 4,274 instructions (40.6%), 644 routines and labels, none below 10% commented,
and no called routine without a name.

## The cartridge

16 KB in **page 2** (0x8000-0xBFFF), with INIT at 0x8010. Almost half of it is data: the drawings of the tiles
and their colours (0xA800-0xB5FF, copied from tile 0x30 on in each third), the title tiles (0xAE00), the sprites
(0xB800), the compressed maps of stage 1 and of the tower roof, the piece lists of the halls, the drawings of the
doors and of the kakejiku rolling up, the texts and the music.

## The BIOS it uses

SETGRP, CHGCLR, DISSCR, ENASCR and WRTVDP to set up the screen; FILVRM, LDIRVM and WRTVRM to fill it (the whole
map goes from RAM to the screen with LDIRVM on every frame, 22 rows of 32); GTSTCK, GTTRIG and SNSMAT for the
controls, and WRTPSG for the sound. It reads the BIOS font at its fixed address (0x1D3F, the "0" of the font at
0x1BBF).

## The interrupt and the loop

INIT puts a jump to 0x8F81 on the H.TIMI hook (0xFD9F). The interrupt runs the **sound engine**, moves sixteen
frame counters on (0xE010-0xE01F) and reads the controls; in the demo it sets them at random (`interrupcion`,
0x8F81). The stage loop takes one step per counted frame (`fase_cuadro`, 0x8245): the sprites to the VRAM, the
ninja, the map to the screen, the enemies that come out and the ones that move, the status line and TIME.

## The map

The map lives in RAM, at 0xE700 (0x840 bytes), and the game reads it for everything: the enemies' ground, the
walls, the stairs (tiles 0x32, 0x35, 0x39 and 0x3A are their ends), the kakejiku cords, the scroll, the pits and
the doors. Whatever changes (a rolled-up kakejiku, a pit, an open door) is written into that map and shows on the
screen on the next frame. The ninja is in the map by the floor tile he stands on (0xE18A); his sprite is apart,
and when the screen scrolls the others move instead of him.

## How it was done

The trace follows the code from INIT and the interrupt, declared in `src/iganinpouchou.entries`. There are no
indirect jumps. The rest was **measured in openMSX** (`tools/omsx_cobertura.tcl`: a condition on every
instruction logs each new ROM address), playing and waiting for the demo on a Philips VG 8020: nothing that ran
was left out of the trace. The sound engine is the one in other 1985 Casio games, and its notes were carried over
from one to the other where the bytes match.

## The RAM

| | |
|---|---|
| 0xE000 | the game running (0 in the demo) |
| 0xE001-0xE006, 0xE00C-0xE00E | the score: six digits and in BCD |
| 0xE009 / 0xE00A | the round and the stage |
| 0xE00B | the spare lives |
| 0xE010-0xE01F | sixteen frame counters |
| 0xE040-0xE046 | the buttons: jump, throw and start |
| 0xE048 | the demo |
| 0xE080-0xE087 | TIME, digit by digit, and its copy for the screen |
| 0xE08E-0xE096 | the high score |
| 0xE100 | the sprite table, which goes to 0x1B00: the ninja (two sprites) and his star |
| 0xE180 | the stick |
| 0xE183 / 0xE186 | the ninja hit / the stage cleared |
| 0xE18A | the map tile the ninja stands on |
| 0xE190 | the ninja's floor |
| 0xE193 / 0xE19A | the screen scrolled sideways / up and down |
| 0xE194-0xE199 | the jump and the stairs |
| 0xE1B2 | the ones knocked down |
| 0xE1B4 | the shrine's object and its time |
| 0xE1C3-0xE1CA | the kakejiku rolling up and the opened ones |
| 0xE1C8 | the door: the scroll taken and the exit |
| 0xE1CE | the map width: 0x60 or 0x20 |
| 0xE280-0xE2D5 | the sound engine |
| 0xE300 | the enemies and what they throw (16 bytes each) |
| 0xE700-0xEF3F | the map |
