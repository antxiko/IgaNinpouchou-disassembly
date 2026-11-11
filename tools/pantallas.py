"""Las pantallas de Iga Ninpouchou.

  - el titulo: EJECUTANDO la ROM (tools/bios.py: el Z80 con la BIOS que usa) desde INIT (0x8010) hasta la espera
    del boton (0x80D6), sin la presentacion de CASIO (0x8094, que espera a la interrupcion). Las letras las copia
    el juego de la fuente de la BIOS (0x1D3F): aqui salen de la VRAM que grabo openMSX con C-BIOS. SETGRP es
    SCREEN 2;
  - logotipo.png, la cabecera de la web: los kanji y CASIO del titulo;
  - pantallas de los cuadros que grabo openMSX.

El titulo se coteja con la VRAM grabada (work/atraccion.bin): el primer cuadro con la misma tabla de nombres,
antes de que el juego cambie los colores del tercer tercio (cada 3 cuadros, con bytes de la pagina 1).

Uso: pantallas.py <dir> [cotejo]
"""
import os
import sys

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)
import vdp                  # noqa: E402
from bios import Msx, SCREEN2        # noqa: E402

RAIZ = os.path.dirname(AQUI)
PANTALLAS = {}


def cuadro(grab, n):
    for i, c in enumerate(vdp.cuadros(os.path.join(RAIZ, "work", grab + ".bin"))):
        if i == n:
            return c


class Iga(Msx):
    def _bios(self):
        if self.pc == 0x007E:                             # SETGRP: SCREEN 2
            self.vdp.regs[:] = SCREEN2
            self.pc = self._pop()
            return
        super()._bios()


def sin_presentacion(m):
    m.pc = 0x8097


def titulo(fuente):
    rom = open(os.path.join(RAIZ, "iganinpouchou.rom"), "rb").read()
    m = Iga(rom, 0x8000)
    m.mem[0x1D3F:0x1D3F + 0x180] = fuente                # la fuente, desde el caracter 0x30
    m.hasta(0x8010, 0x80D6, ganchos={0x8094: sin_presentacion})
    return bytes(m.vdp.vram), bytes(m.vdp.regs)


def cotejo(v, regs):
    for n, c in enumerate(vdp.cuadros(os.path.join(RAIZ, "work", "atraccion.bin"))):
        if c["vram"][0x1800:0x1B00] == v[0x1800:0x1B00] and c["regs"][1] & 0x40:
            break
    t1, t2 = vdp.tela(v, regs, False), vdp.tela(c["vram"], c["regs"], False)
    puntos = sum(1 for y in range(192) for x in range(256) if t1[y][x] != t2[y][x])
    print("titulo contra atraccion/%d: puntos distintos %d de 49152; registros %s"
          % (n, puntos, "iguales" if regs == bytes(c["regs"]) else "%s / %s" % (regs.hex(), bytes(c["regs"]).hex())))
    return n, puntos


def main(argv):
    fuente = bytes(cuadro("atraccion", 300)["vram"][0:0x180])
    v, regs = titulo(fuente)
    vdp.imagen(v, regs, 2, con_sprites=False).save(os.path.join(argv[0], "titulo.png"))
    vdp.imagen(v, regs, 4, con_sprites=False).crop((176, 240, 848, 520)).save(os.path.join(argv[0], "logotipo.png"))
    for f, (g, n) in PANTALLAS.items():
        c = cuadro(g, n)
        vdp.imagen(c["vram"], c["regs"], 2).save(os.path.join(argv[0], f))
    if len(argv) > 1:
        cotejo(v, regs)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
