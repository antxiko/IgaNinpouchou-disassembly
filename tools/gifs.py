#!/usr/bin/env python3
"""Los GIF de la web: tramos de las grabaciones de openMSX (tools/guiones/*.tcl, grabados con
tools/lanza_graba.ps1 en C-BIOS_MSX1_JP, -ram "0xE000 0x1100"), pintados con tools/vdp.py.

Los tramos salen de la RAM grabada: 0xE00A la fase, 0xE00B las vidas, 0xE183 el protagonista tocado, 0xE186 la
fase acabada, 0xE1B2 los tumbados, 0xE1D1 la puerta del castillo, 0xE1C8 la puerta de las otras fases, 0xE1C3 el
kakejiku que se enrolla (0xE1BF lo que sale) y 0xE1B4 el objeto del altarcito.

  atraccion  sin tocar nada: la presentacion de CASIO, el titulo y las demostraciones
  partida    una partida con un piloto en Tcl (partida.tcl) en la fase 1: tumbados, vidas perdidas y GAME OVER
  fases      FORZADA (fases.tcl): la cuenta de tumbados puesta en 9 en la fase 1, y en las otras el protagonista
             llevado al ultimo kakejiku, al rollo y a la puerta de salida

Uso: gifs.py docs/imagenes
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import vdp          # noqa: E402

# (fichero, grabacion, desde, hasta, cada)
TRAMOS = [
    ("casio.gif", "atraccion", 60, 200, 2),             # la presentacion: CASIO crece desde el centro
    ("fase1.gif", "partida", 1540, 1900, 2),            # la fase 1: el piloto tumba a cuatro con la estrella
    ("tocado.gif", "partida", 1950, 2060, 2),           # le dan: parpadea, cae y una vida menos
    ("game_over.gif", "partida", 3490, 3790, 2),        # la ultima vida: GAME OVER
    ("puerta_castillo.gif", "fases", 900, 1300, 2),     # el decimo tumbado: la puerta se abre, entra, TIME a puntos
    ("entrada.gif", "fases", 1287, 1640, 2),            # la fase 2: la puerta por la que entra
    ("kakejiku.gif", "fases", 1686, 1765, 1),           # el ultimo kakejiku: el cordon, se enrolla y el rollo
    ("salida.gif", "fases", 1745, 1990, 2),             # con el rollo, la puerta de salida
    ("foso.gif", "atraccion", 4780, 5060, 2),           # la demostracion de la fase 4: un kakejiku abre el foso y cae
    ("objeto.gif", "fases", 3420, 3560, 2),             # la fase 4: el objeto del altarcito
    ("fase5.gif", "fases", 4200, 4420, 2),              # la fase 5: la torre, la puerta de abajo
]


def main(salida):
    raiz = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    for fichero, grab, desde, hasta, cada in TRAMOS:
        n, s = vdp.gif(os.path.join(raiz, "work", grab + ".bin"),
                       os.path.join(salida, fichero), desde, hasta, cada=cada, tope_ms=4000)
        print("%-20s %4d imagenes, %5.1f s, %8d bytes" % (
            fichero, n, s, os.path.getsize(os.path.join(salida, fichero))))


if __name__ == "__main__":
    main(sys.argv[1])
