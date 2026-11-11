# Iga Ninpouchou - commented disassembly

*(También [en castellano](README.es.md).)*

The commented disassembly of **Iga Ninpouchou** (伊賀忍法帖, Casio, 1985) for the MSX: a 16 KB cartridge at 0x8000.

- **100%** of the binary explained: 9,296 bytes of code and 7,088 of named data, not one byte unassigned.
- **40.6%** of the listing commented, 644 routines and labels, none below 10% of comments.
- The listing reassembles into the original ROM **byte for byte**.
- The title comes from running the ROM, checked against openMSX; the maps of the five stages from RAM; the gate, the kakejiku and the secret scroll, the doors and the tower, played in GIF; the five tunes, from its own sound engine and identical to openMSX frame by frame.

The site: <https://antxiko.github.io/IgaNinpouchou-disassembly/>
(in Spanish: <https://antxiko.github.io/IgaNinpouchou-disassembly/es/>).

## Rebuilding it

The ROM image is not distributed. Put yours in the root as `iganinpouchou.rom` (sha256 `5d02bfe0...`) and run `make`. The details, in [UNDER THE HOOD](docs/UNDER-THE-HOOD.md).

## Legal

The game belongs to Casio and its rights holders. The `LICENSE` covers only the tools, comments, analysis and documentation here. See [LEGAL-NOTICE.md](LEGAL-NOTICE.md).
