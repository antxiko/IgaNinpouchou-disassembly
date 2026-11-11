#!/usr/bin/env python3
"""Los mapas enteros de las cinco fases, como los tiene el juego en la RAM (0xE700, 0x840 bytes): 22 filas de
0x60 casillas en las fases 2 a 4 (la pantalla corre de lado) y 66 filas de 32 en la 1 y la 5 (de arriba abajo; la
1 solo usa las 22 primeras). Salen de la grabacion work/fases.bin (tools/guiones/fases.tcl): el primer cuadro de
cada fase en que suena la musica 2, cuando el mapa ya esta hecho y nadie lo ha tocado; las casillas se pintan con
los dibujos y colores que hay en ese momento en la VRAM (el primer tercio).

Uso: mapas.py docs/imagenes
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import vdp          # noqa: E402
from PIL import Image  # noqa: E402

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def pinta(ram, vram, ancho, filas):
    im = Image.new("RGB", (ancho * 8, filas * 8))
    px = im.load()
    for f in range(filas):
        for c in range(ancho):
            t = ram[0x700 + f * ancho + c]
            for y in range(8):
                p, col = vram[t * 8 + y], vram[0x2000 + t * 8 + y]
                for x in range(8):
                    px[c * 8 + x, f * 8 + y] = vdp.PALETA[(col >> 4) if p & (0x80 >> x) else (col & 15)]
    return im


def main(salida):
    hechas = set()
    for c in vdp.cuadros(os.path.join(RAIZ, "work", "fases.bin")):
        r = c["ram"]
        f = r[0x00A]
        if r[0x000] != 1 or f in hechas or r[0x2BD] != 2:
            continue
        hechas.add(f)
        ancho, filas = (0x60, 22) if 2 <= f <= 4 else (0x20, 66 if f == 5 else 22)
        im = pinta(r, c["vram"], ancho, filas)
        ruta = os.path.join(salida, "mapa_fase%d.png" % f)
        im.save(ruta)
        print("%-16s %dx%d casillas" % (os.path.basename(ruta), ancho, filas))
        if len(hechas) == 5:
            break


if __name__ == "__main__":
    main(sys.argv[1])
