"""Lo que se afirma de la ROM, comprobado contra sus bytes.

Corre con la ROM delante y sin ella: cuando no esta, la imagen se rehace desde
las filas defb/defw del listado, que si viaja con el repositorio. Sin la ROM
solo se comprueba lo que cae en datos.
"""

import os
import re
import subprocess
import sys
import unittest

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(RAIZ, "tools"))

ROM = os.path.join(RAIZ, "iganinpouchou.rom")
ASM = os.path.join(RAIZ, "src", "iganinpouchou.asm")
NOTAS = os.path.join(RAIZ, "src", "iganinpouchou.notes")
ORG = 0x8000
TAM = 16384

FILA = re.compile(r"^\s+def(b|w)\s+([0-9a-fA-F,h ]+)\s*;\s*([0-9a-f]{4})")


def imagen_desde_el_listado():
    img = bytearray(TAM)
    with open(ASM, encoding="utf-8") as f:
        for ln in f:
            m = FILA.match(ln)
            if not m:
                continue
            ancho, cuerpo, dirr = m.group(1), m.group(2), int(m.group(3), 16)
            p = dirr - ORG
            for tok in cuerpo.split(","):
                tok = tok.strip().rstrip("h")
                if not tok:
                    continue
                v = int(tok, 16)
                if ancho == "b":
                    img[p] = v
                    p += 1
                else:
                    img[p] = v & 0xFF
                    img[p + 1] = v >> 8
                    p += 2
    return bytes(img)


def lee():
    if os.path.exists(ROM):
        with open(ROM, "rb") as f:
            return f.read()
    return imagen_desde_el_listado()


def b(a):
    return lee()[a - ORG]


def w(a):
    rom = lee()
    return rom[a - ORG] | (rom[a - ORG + 1] << 8)


def instruccion(dirr):
    """La instruccion del listado en esa direccion (sin el comentario)."""
    with open(ASM, encoding="utf-8") as f:
        for ln in f:
            m = re.match(r"^\t(\S.*?)\s*;([0-9a-f]{4})", ln)
            if m and int(m.group(2), 16) == dirr:
                return m.group(1).replace("\t", " ").strip()
    return None


class Cabecera(unittest.TestCase):
    def test_ab_e_init_en_0x8010(self):
        rom = lee()
        self.assertEqual(rom[:2], b"AB")
        self.assertEqual(w(0x8002), 0x8010)
        self.assertEqual(rom[4:16], bytes(12))

    def test_son_16_kb(self):
        self.assertEqual(len(lee()), TAM)


class LaInterrupcion(unittest.TestCase):
    def test_va_por_h_timi(self):
        self.assertEqual([instruccion(a) for a in (0x8025, 0x8028, 0x802B, 0x802D)],
                         ["ld hl,08f81h", "ld (0fda0h),hl", "ld a,0c3h", "ld (0fd9fh),a"])


def texto(a, n):
    s = ""
    for c in lee()[a - ORG:a - ORG + n]:
        s += str(c) if c < 10 else (" " if c == 0x10 else (":" if c == 0x0A else
             (chr(0x40 + c - 0x10) if 0x11 <= c <= 0x2A else "?")))
    return s


class LosTextos(unittest.TestCase):
    def test_las_letras_son_casillas_propias(self):
        self.assertEqual(texto(0x8F1A, 20), "PUSH TRIG:1 OR SPACE")
        self.assertEqual(texto(0x8F44, 7), "TIME:01")
        self.assertEqual(texto(0x8F61, 4), "OVER")
        self.assertEqual(texto(0x8F6B, 9), "GAME OVER")

    def test_score_es_el_hiscore_sin_el_hi(self):
        self.assertEqual(texto(0x8F4E, 7), "HISCORE")
        self.assertEqual(instruccion(0x8D63), "ld hl,08f50h")
        self.assertEqual(texto(0x8F50, 5), "SCORE")

    def test_las_letras_de_la_bios_por_su_direccion(self):
        """0x1D3F = 0x1BBF + 0x30 x 8: las letras de la BIOS japonesa desde el "0"."""
        self.assertEqual(instruccion(0x8E7D), "ld hl,01d3fh")


class LosPuntos(unittest.TestCase):
    def test_el_tope_de_999999_no_avanza(self):
        """El bucle que pone 0x99 en los tres bytes no incrementa HL."""
        self.assertEqual([instruccion(a) for a in (0x90E3, 0x90E6, 0x90E8, 0x90EA)],
                         ["ld hl,0e00ch", "ld b,003h", "ld (hl),099h", "djnz puntos_tope"])

    def test_vida_a_los_3000(self):
        self.assertEqual(instruccion(0x90F5), "cp 030h")


class ElMapa(unittest.TestCase):
    def test_las_piezas_de_las_fases_2_a_5(self):
        for k in range(4):
            self.assertTrue(0xBE47 <= w(0xBE3F + 2 * k) < 0xBF53, hex(w(0xBE3F + 2 * k)))

    def test_la_puerta(self):
        """Medio abierta, abierta y cerrada: la cerrada son las casillas 0x80-0x8D."""
        self.assertEqual(list(lee()[0xB750 - ORG:0xB758 - ORG]), [0x80, 0x81, 0x84, 0x85, 0x8A, 0x8B, 0x8C, 0x8D])

    def test_los_mapas_comprimidos_acaban_en_ff(self):
        self.assertEqual(b(0x9FD4), 0xFF)
        self.assertEqual(b(0xB7CB), 0xFF)


class Sonido(unittest.TestCase):
    def test_duraciones(self):
        self.assertEqual(list(lee()[0xA539 - ORG:0xA547 - ORG]),
                         [0x80, 0x60, 0x40, 0x30, 0x20, 0x18, 0x10, 0x0C, 0x08, 0x06, 0x04, 0x03, 0x02, 0x01])

    def test_las_tablas_apuntan_a_los_datos(self):
        for a in range(0xA210, 0xA264, 2):
            self.assertTrue(0xA642 <= w(a) < 0xA7F2, hex(a))


class LoQueNadieUsa(unittest.TestCase):
    def test_un_jr_y_un_ret_sueltos(self):
        self.assertEqual(list(lee()[0x9787 - ORG:0x9789 - ORG]), [0x18, 0x4D])
        self.assertEqual(b(0x9BC5), 0xC9)
        self.assertEqual(instruccion(0x9786), "ret")


class ElListado(unittest.TestCase):
    def test_densidad_y_flojas(self):
        salida = subprocess.run(
            [sys.executable, os.path.join(RAIZ, "tools", "densidad.py"), ASM],
            capture_output=True, text=True, check=True).stdout
        m = re.search(r"(\d+) instrucciones, (\d+) comentarios", salida)
        self.assertGreaterEqual(int(m.group(2)) * 100, 40 * int(m.group(1)))
        self.assertIn("---- 0 rutinas por debajo del 10 %", salida)

    def test_ningun_call_sin_nombre(self):
        salida = subprocess.run(
            [sys.executable, os.path.join(RAIZ, "tools", "sin_bautizar.py"), ASM],
            capture_output=True, text=True, check=True).stdout
        self.assertTrue(salida.startswith("0 rutinas sin bautizar"), salida[:200])

    def test_cada_comentario_en_su_instruccion(self):
        salida = subprocess.run(
            [sys.executable, os.path.join(RAIZ, "tools", "valida_c.py"), ASM, NOTAS],
            capture_output=True, text=True, check=True).stdout
        self.assertIn("0 fuera de sitio, 0 repetidos", salida)


if __name__ == "__main__":
    unittest.main()
