# The texts

Every text in the ROM. The letters are not the BIOS ones as they are: the game copies the characters from "0" to
"_" out of the BIOS font into its own tiles (0x00-0x2F) and writes with tile numbers: 0x00-0x09 the digits, 0x0A
the colon, 0x10 the space, 0x11 A ... 0x2A Z.

| address | original | translation | where it appears |
|---|---|---|---|
| 0x8EDB | 伊賀忍法帖 (Iga Ninpōchō) | The book of the ninja arts of Iga | the title, in big letters: five kanji of 3 x 3 tiles |
| 0x8F14 | CASIO | CASIO | the title, in six tiles of its own |
| 0x8F1A | PUSH TRIG:1 OR SPACE | Press button 1 or the space bar | the title |
| 0x8F2E | COPYRIGHT 1985 © CASIO | Copyright 1985 © Casio | the title |
| 0x8F44 | TIME:01 | Time | the status line; the digits are overwritten with TIME |
| 0x8F4B | HISCORE:000000 | High score | the status line |
| 0x8F50 | SCORE:000000 | Score | the status line: it is the same text as the high score, without the HI |
| 0x8F5D | (ninja):00 | knocked down | the status line: the count of enemies knocked down on the stage; from 10 on it always shows 10 |
| 0x8F61 | OVER | It is over | instead of TIME, when it reaches zero |
| 0x8F6B | GAME OVER | Game over | in the middle, with no lives |

Iga is the province of the ninja (today part of Mie); *ninpō* are the ninja arts and *-chō* a book or record.

The status line also has the stage number drawn as **scrolls** (tiles 0x64 and 0x68, as many as the stage,
`fase_pinta`, 0x907D), and the spare lives as small ninja (0xE8, up to five).
