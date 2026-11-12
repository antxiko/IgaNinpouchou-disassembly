# Secrets and bugs

What was searched for in the code and what was found. A bug only goes here if it has been checked: by running the
game's own routine (`tools/bios.py`) or against the openMSX recordings.

## Secrets: none hidden

- **No hidden keys.** The controls are read in the interrupt (0x8FBA-0x9064): the stick of joystick 1 and the cursor
  keys (GTSTCK 1 and 0), buttons A and B of joystick 1 (GTTRIG 1 and 3), and the space bar and GRAPH, read with SNSMAT
  on rows 8 and 6. Joystick 2 is not read, and there is no other keyboard read: no key at power-on or on the title
  screen.
- **No passwords or hidden stages**: the only thing the game does not show is the secret scroll, which always comes out
  of the last kakejiku in the room, as told in [Curiosities](CURIOSITIES.html).

## Bug: past 999,999, 990,000

Told in [Curiosities](CURIOSITIES.html) and run with the game's routine: the score cap puts the three 0x99 into the
same byte (`puntos_tope`, 0x90E8), and 999,999 + 1 gives **990,000**, with an extra life.

## Bug: the cursor keys and the joystick at once

`palanca` (0x8FD9) joins the cursor keys and joystick 1 with an `or` (0x8FE9), but GTSTCK gives direction numbers from
1 to 8, not bits. With both at once another direction comes out. Running the routine here with each port in one
direction:

| cursor keys | joystick | result | on a floor, the ninja goes |
|---|---|---|---|
| right | — | 3 | right |
| right | down | **7** | **left** |
| up-right | down-right | **6** | **left** |
| up | down | 5 | down (crouches) |

On the floors, `anda_palanca` (0x933B) sends anything from 6 up to the left (0x9371).

## Comparisons that do nothing, told in [Curiosities](CURIOSITIES.html)

- Above the jump, four paths that end at the same instruction (0x9843), and when falling an `inc hl` and a `dec hl`
  that are lost (0x98E9).
- When TIME runs out, the game checks 0xE185, which nothing in the ROM writes (0x8DD5).
- On stage 1, down-right does a `cp 4` that decides nothing: it jumps anyway (0x964C).
- The demo has no lives: at the first hit, GAME OVER.
