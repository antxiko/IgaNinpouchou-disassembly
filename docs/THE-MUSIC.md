# The music

Five tunes, all short, on the three PSG channels. They are not hand-made recordings: `tools/musica.py` **runs the
ROM's own sound engine** with `tools/z80run.py` -`musica_pide` (0xA283) with the tune's number and, on every
frame, `sonido` (0xA288)- and logs what it writes to the PSG through the BIOS (WRTPSG).

**Checked against openMSX**: the tone and volume registers match the recorded ones, **0 different** in all five,
while each one plays. They come from three recordings (`tools/guiones/`): untouched, a game and the forced
stages. Each recorded frame is paired with the engine frame that has the same RAM in the three channels. The
stage-cleared tune plays twice in a row on stage 1 (when the gate opens and again while TIME is counted): the
second time the check does not pair it, because it starts over.

The sound effects are not here: the steps, the star, the jump, the stairs, the TIME warning and the rest.

## The engine

It runs in the interrupt, once per frame (`interrupcion`, 0x8F81). The request goes to 0xE2BE and, on the next
frame, the engine starts the three channels of the tune from the table at 0xA210, three pieces per tune
(`musica_empieza`, 0xA55F). The channels are at 0xE280, 0xE292 and 0xE2A4, 18 bytes each; on every frame they are
copied in turn to a work block at 0xE2C3, move one step and go back. A note is a byte with the duration (from the
table at 0xA539, from 128 frames down to 1) and the volume, followed by the tone period; from 0xF0 on they are
commands: noise, three repeat marks with their counts, back to the start, silence and the end. There are eight
effects for channel A (table at 0xA234) and eight for channels B and C (0xA244); if another is requested while one
plays, the lower number wins.

| | Who asks for it | Length |
|---|---|---:|
| the intro | CASIO, when the logos meet (0x9D6D) | 1.1 s |
| the stage | the start of every stage (0x81DC) | 4.3 s |
| stage cleared | the door opened and TIME into points (0x8C56, 0x8CE8) | 2.4 s |
| hit | the ninja touched or fallen into a pit (0x8B9F) | 0.6 s |
| GAME OVER | no lives left (0x8C17) | 3.1 s |

## The intro

<audio controls src="audio/musica_casio.mp3"></audio>

## The stage

<audio controls src="audio/musica_fase.mp3"></audio>

## Stage cleared

<audio controls src="audio/musica_fase_acabada.mp3"></audio>

## Hit

<audio controls src="audio/musica_tocado.mp3"></audio>

## GAME OVER

<audio controls src="audio/musica_game_over.mp3"></audio>
