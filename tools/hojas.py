#!/usr/bin/env python3
"""Los sprites de Iga Ninpouchou MONTADOS DESDE LA ROM (ninguna imagen es una captura).

Los dibujos son los 0x800 bytes de 0xB800 que `sprites_dibujos` (0x8EC9) pone tal cual en 0x3800. Los sprites son de
16 x 16 (el registro 1, 0xA2).

  protagonista.png  el ninja: dos sprites a la misma Y, el dibujo en azul (color 5) y el dibujo + 4 encima en amarillo
                    claro (11) (`fase` 0x816F, `prota_dibujo_dos` 0x96A5); andando a la derecha (0x28, 0x30) y a la
                    izquierda (0x00, 0x08) (`prota_dibujo`, 0x966E), saltando en el sitio (0x40, 0x18) y de lado (0x38,
                    0x10) (`salto_dibujo`, 0x9A00), agachado (0x48, 0x20; `agacha` 0xA8F0) y tocado (0x88 y 0x90,
                    `tocado_cuadro` 0x8BA6); con el objeto del santuario desde la fase 4, un solo sprite: el dibujo + 4
                    en azul; y la estrella (0xA4 y 0xA8, color 5; la grande de la fase 2, 0xB0 y 0xB4, color 15;
                    `estrella` 0x96B6, `tira` 0x92CC)
  otros.png         los otros, un sprite cada uno (0xE300, 16 bytes): los ninja de los tipos 3, 5 y 8 (`tipo3_dibujo`,
                    0x8831: +6 = 0x50, + el lado (0 a la izquierda, 0x10 a la derecha) + el paso (0 u 8) + 4 en los
                    impares de +8, que van en color 11; los pares en 13, 14 o 3), cayendo (+6 = 0x88, color 15), el de
                    las bolas (el tipo 8) parpadeando (0x70 en color 2 y 0x74 en 11) y saltando (0xB8 en 3 y 0xBC en 6); los que
                    cruzan (el tipo 1, la flecha: 0x78 y 0x7C, color 15; el 2: 0x80 y 0x84 en 9 y 10), lo que tiran (las
                    estrellas, el tipo 4: 0xA4 y 0xA8 en 7; las bolas, el 7: 0x9C y 0xA0 en 15) y lo que cae en la
                    fase 1 (el tipo 6: 0x98 en 11 y despues 0x9C y 0xA0 en 9)
  andar_cuadros.gif el ninja andando, el paso cada 8 cuadros (la cuenta 0xE01F), y tocado
  otros_cuadros.gif los ninja andando a los dos lados (el paso cada 8 cuadros y + 4 en color 11 un cuadro si y otro
                    no), el tipo 8 parpadeando y saltando, el tipo 2 (dibujo cada 4 cuadros, color cada 2) y
                    las estrellas y las bolas girando (cada 4)

Uso: hojas.py docs/imagenes | hojas.py cotejo
"""
import os
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(RAIZ, "tools"))
import vdp          # noqa: E402

ORG = 0x8000
ROM = open(os.path.join(RAIZ, "iganinpouchou.rom"), "rb").read()
FONDO = (40, 40, 48)
PROTA = [0x28, 0x30, 0x00, 0x08, 0x40, 0x18, 0x38, 0x10, 0x48, 0x20, 0x88, 0x90]
COLOR_TIPO = {3: 13, 5: 14, 8: 3}               # tipo3_color_tipo, 0x886C


def b(a):
    return ROM[a - ORG]


def patrones():
    return ROM[0xB800 - ORG:0xB800 - ORG + 0x800]


def pinta(im, pat, n, x, y, color, escala=1):
    if color == 0:
        return
    n &= 0xFC
    d = pat[n * 8:n * 8 + 32]
    c = vdp.PALETA[color]
    for fila in range(16):
        for col in range(16):
            if (d[fila + (16 if col >= 8 else 0)] >> (7 - (col & 7))) & 1:
                for ey in range(escala):
                    for ex in range(escala):
                        px, py = (x + col) * escala + ex, (y + fila) * escala + ey
                        if 0 <= px < im.width and 0 <= py < im.height:
                            im.putpixel((px, py), c)


def ninja(d, objeto=False):
    """Los sprites (dibujo, color) del protagonista: d en 5 y d + 4 en 11; con el objeto, solo d + 4 en 5."""
    return [(d + 4, 5)] if objeto else [(d, 5), (d + 4, 11)]


def otro_ninja(base, lado, paso, impar, tipo, estado=1):
    """tipo3_dibujo (0x8831): (dibujo, color) de un ninja de los tipos 3, 5 y 8."""
    d = base + lado + paso + (4 if impar else 0)
    if impar:
        return d, 11
    return d, (15 if estado == 2 else COLOR_TIPO[tipo])


def grupo(im, pat, sprites, x, y, E):
    """Los sprites (dibujo, color), el primero encima (el VDP pinta delante el de numero mas bajo)."""
    for n, c in reversed(sprites):
        pinta(im, pat, n, x, y, c, E)


def hoja(Image):
    pat, E = patrones(), 4
    im = Image.new("RGB", (8 * 20 * E, 3 * 20 * E), FONDO)
    for k, d in enumerate(PROTA[:8]):
        grupo(im, pat, ninja(d), 2 + 20 * k, 2, E)
    for k, d in enumerate(PROTA[8:]):
        grupo(im, pat, ninja(d), 2 + 20 * k, 22, E)
    for k, d in enumerate((0x28, 0x00)):
        grupo(im, pat, ninja(d, True), 2 + 20 * (4 + k), 22, E)
    for k, (d, c) in enumerate(((0xA4, 5), (0xA8, 5), (0xB0, 15), (0xB4, 15))):
        pinta(im, pat, d, 2 + 20 * k, 42, c, E)
    return im


def hoja_otros(Image):
    pat, E = patrones(), 4
    im = Image.new("RGB", (8 * 20 * E, 5 * 20 * E), FONDO)
    for fila, tipo in enumerate((3, 5, 8)):
        k = 0
        for lado in (0, 0x10):
            for paso in (0, 8):
                sprites = [otro_ninja(0x50, lado, paso, impar, tipo) for impar in (1, 0)]
                grupo(im, pat, sprites, 2 + 20 * k, 2 + 20 * fila, E)
                k += 1
        if tipo == 5:
            for paso in (0, 8):
                grupo(im, pat, [otro_ninja(0x88, 0, paso, impar, tipo, 2) for impar in (1, 0)], 2 + 20 * k, 22, E)
                k += 1
        if tipo == 8:
            grupo(im, pat, [(0x74, 11), (0x70, 2)], 2 + 20 * k, 42, E)
            grupo(im, pat, [(0xBC, 6), (0xB8, 3)], 2 + 20 * (k + 1), 42, E)
            pinta(im, pat, 0xB8, 2 + 20 * (k + 2), 42, 3, E)
            pinta(im, pat, 0xBC, 2 + 20 * (k + 3), 42, 6, E)
    cosas = [(0x78, 15), (0x7C, 15), (0x80, 9), (0x84, 10)]
    for k, (d, c) in enumerate(cosas):
        pinta(im, pat, d, 2 + 20 * k, 62, c, E)
    cosas = [(0xA4, 7), (0xA8, 7), (0x9C, 15), (0xA0, 15), (0x98, 11), (0x9C, 9), (0xA0, 9)]
    for k, (d, c) in enumerate(cosas):
        pinta(im, pat, d, 2 + 20 * k, 82, c, E)
    return im


def anima(Image):
    pat, E, cuadros = patrones(), 4, []
    for base in (0x28, 0x00):
        for n in range(64):
            im = Image.new("RGB", (20 * E, 20 * E), FONDO)
            grupo(im, pat, ninja(base + (n & 8)), 2, 2, E)
            cuadros.append(im)
    for n in range(48):
        im = Image.new("RGB", (20 * E, 20 * E), FONDO)
        grupo(im, pat, ninja(0x88 + (n & 8)), 2, 2, E)
        cuadros.append(im)
    return cuadros


def anima_otros(Image):
    """Cuadro a cuadro: cada ninja un cuadro con su dibujo y otro con el + 4 (en el juego, segun +8), como se ven."""
    pat, E, cuadros = patrones(), 3, []
    for n in range(128):
        im = Image.new("RGB", (6 * 20 * E, 2 * 20 * E), FONDO)
        paso, impar = n & 8, n & 1
        for k, (tipo, lado) in enumerate(((3, 0), (5, 0x10), (8, 0))):
            d, c = otro_ninja(0x50, lado, paso, impar, tipo)
            pinta(im, pat, d, 2 + 20 * k, 2, c, E)
        d, c = ((0x74, 11) if impar else (0x70, 2)) if n < 64 else ((0xBC, 6) if impar else (0xB8, 3))
        pinta(im, pat, d, 2 + 20 * 3, 2, c, E)
        pinta(im, pat, 0x80 + (n & 4), 2 + 20 * 4, 2, 9 + ((n & 2) >> 1), E)
        pinta(im, pat, 0x78, 2 + 20 * 5, 2, 15, E)
        for k, (d, c) in enumerate(((0xA4, 7), (0x9C, 15), (0x9C, 9), (0xA4, 5))):
            pinta(im, pat, d + (n & 4), 2 + 20 * k, 22, c, E)
        cuadros.append(im)
    return cuadros


def guarda_gif(cuadros, ruta, ms=1000 / 60):
    imgs, durs = [], []
    for im in cuadros:
        if imgs and list(im.getdata()) == list(imgs[-1].getdata()):
            durs[-1] += ms
        else:
            imgs.append(im)
            durs.append(ms)
    imgs[0].save(ruta, save_all=True, append_images=imgs[1:], duration=[max(20, int(round(d))) for d in durs],
                 loop=0, disposal=1)


def esperado(e, ram):
    """(dibujos posibles, colores posibles) de un otro (16 bytes de 0xE300) con la RAM del cuadro; None si no se
    comprueba."""
    tipo, estado = e[4], e[5]
    paso = ram[0x01F] & 8
    if tipo in (3, 5, 8) and estado in (1, 2):
        impar = e[8] & 1
        d, c = otro_ninja(e[6], e[9], paso, impar, tipo, estado)
        colores = {c} | ({10} if not impar and estado == 1 else set())      # fase 3 con el objeto: 10
        return {d, otro_ninja(e[6], e[9], paso ^ 8, impar, tipo, estado)[0]}, colores
    if tipo == 8 and estado == 3:
        return ({0x74}, {11}) if e[0x0D] & 1 else ({0x70}, {2})
    if tipo == 8 and estado == 4:
        return ({0xBC}, {6}) if e[0x0D] & 1 else ({0xB8}, {3})
    if tipo == 1:
        return {0x78, 0x7C}, {15}
    if tipo == 2:
        return {0x80, 0x84}, {9, 10}
    if tipo == 4:
        return {0xA4, 0xA8}, {7}
    if tipo == 7:
        return {0x9C, 0xA0}, {15}
    if tipo == 6:
        return ({0x98}, {11}) if estado == 1 else ({0x9C, 0xA0, 0xA4}, {9})
    return None


def cambiado(e, a, ram, antes):
    """Si el dibujo y el color de e casan con su estado (+5), su espera (+8), su lado (+9) o su cuenta (+0x0D) del
    cuadro anterior (a), o con la paridad de la espera o el lado cambiados, con el paso de este cuadro o del anterior:
    el juego lo dibujo antes de cambiarlos."""
    for m in range(64):
        f = bytearray(e)
        for bit, i in enumerate((5, 8, 9, 0x0D)):
            if m >> bit & 1:
                f[i] = a[i]
        f[8] ^= m >> 4 & 1                          # la espera o el lado ya cambiados en este cuadro
        f[9] ^= (m >> 5 & 1) * 0x10
        for r in (ram, antes):
            q = esperado(f, r)
            if q and e[2] in q[0] and e[3] in q[1]:
                return True
    return False


def cotejo():
    """Contra las grabaciones de openMSX (work/*.bin, la RAM 0xE000-0xF0FF):
    1) la tabla de dibujos de los sprites (VRAM 0x3800-0x3FFF) contra los 0x800 bytes de 0xB800;
    2) los dos sprites del protagonista en la tabla de la RAM (0xE100 y 0xE104): uno de sus dibujos en color 5 y el
       + 4 en 11 a la misma Y, o el + 4 solo en color 5 (con el objeto);
    3) cada otro (0xE300, 16 bytes) en marcha: su dibujo y su color contra lo que pone su rutina con su tipo (+4), su
       estado (+5), su base (+6), su espera (+8), su lado (+9), su cuenta (+0x0D) y el paso del cuadro (0xE01F);
    4) la copia de la tabla (0xE110, 4 bytes por sprite) contra los cuatro primeros bytes de cada uno de 0xE300."""
    pat = patrones()
    dibujos_prota = set(PROTA)
    tot = dict(patrones=0, pat_carga=0, pat_mal=0, prota=0, prota_objeto=0, prota_sin_poner=0, prota_resto=0,
               prota_mal=0, otros=0, otros_salen=0, otros_cambio=0, otros_mal=0,
               copia=0, copia_antes=0, copia_2=0, copia_mal=0)
    for grab in ("atraccion", "partida", "fases"):
        ruta = os.path.join(RAIZ, "work", grab + ".bin")
        if not os.path.exists(ruta):
            continue
        antes, antes2, pendiente, dos = None, None, 0, {}
        for c in vdp.cuadros(ruta):
            v, ram = c["vram"], c["ram"]
            t = v[0x3800:0x4000]
            if any(t):
                if t == pat:
                    tot["patrones"] += 1
                    tot["pat_carga"] += pendiente
                else:
                    tot["pat_mal"] += pendiente
                pendiente = int(t != pat)                # mal, salvo si el cuadro siguiente ya esta (carga a medias)
            if not ram[0x000] and not ram[0x048]:
                antes = ram
                continue
            p = ram[0x100:0x108]
            if p[0] < 0xC0:
                if p[2] in dibujos_prota and p[3] == 5 and p[6] == p[2] + 4 and p[7] == 11 and p[4] == p[0]:
                    tot["prota"] += 1
                elif p[2] - 4 in dibujos_prota and p[3] == 5 and p[4] >= 0xC0:
                    tot["prota_objeto"] += 1
                elif p[:4] == bytes(4) or list(p[:4]) == [0, 0, 0, 0]:
                    tot["prota_sin_poner"] += 1             # aun sin poner, al empezar la fase
                elif p[2] - 4 in dibujos_prota and p[3] == 5 and p[4] == p[0] and p[6] - 4 in dibujos_prota:
                    tot["prota_resto"] += 1     # con el objeto: el segundo sprite vuelve a su Y con el dibujo de antes
                else:
                    tot["prota_mal"] += 1
            for k in range(14):
                e = ram[0x300 + 16 * k:0x310 + 16 * k]
                if e[4] in (0, 0xFF) or e[0] >= 0xC0:
                    continue
                q = esperado(e, ram)
                if q is None:
                    continue
                if e[2] in q[0] and e[3] in q[1]:
                    tot["otros"] += 1
                elif antes is not None and cambiado(e, antes[0x300 + 16 * k:0x310 + 16 * k], ram, antes):
                    tot["otros_cambio"] += 1    # el estado, la espera, el lado o la cuenta cambiados despues de dibujarlo
                elif e[2] == 0 or (e[4] in (3, 5, 8) and e[3] == 9 and e[2] in (0x50, 0x60)):
                    tot["otros_salen"] += 1             # recien salido: aun sin dibujo o con el de tipo3_lado
                else:
                    tot["otros_mal"] += 1
            hay = [bytes(ram[0x110 + 4 * k:0x114 + 4 * k]) for k in range(14)]
            quiero = [bytes(ram[0x300 + 16 * k:0x304 + 16 * k]) for k in range(14)]
            fuera = [k for k in range(14) if (hay[k][0] >= 0xC0 or hay[k] == bytes(4)) and quiero[k][0] >= 0xC0]
            for k in fuera:                             # los que no se ven no cuentan
                hay[k] = quiero[k]
            if antes2 is not None:                      # copiada dos cuadros antes (los que van de dos en dos)
                for k in range(14):
                    if hay[k] == bytes(antes2[0x300 + 16 * k:0x304 + 16 * k]) and hay[k] != quiero[k]:
                        dos[k] = True
            if hay == quiero:
                tot["copia"] += 1
            elif antes is not None and all(h == q or h == bytes(antes[0x300 + 16 * k:0x304 + 16 * k])
                                           for k, (h, q) in enumerate(zip(hay, quiero))):
                tot["copia_antes"] += 1                 # copiada antes de que se movieran (`fase_cuadro`, 0x8250)
            elif antes is not None and all(h == q or h == bytes(antes[0x300 + 16 * k:0x304 + 16 * k]) or dos.get(k)
                                           for k, (h, q) in enumerate(zip(hay, quiero))):
                tot["copia_2"] += 1
            else:
                tot["copia_mal"] += 1
            antes2, antes, dos = antes, ram, {}
    return tot


def main(argv):
    if argv and argv[0] == "cotejo":
        print(cotejo())
        return 0
    from PIL import Image
    salida = argv[0]
    os.makedirs(salida, exist_ok=True)
    hoja(Image).save(os.path.join(salida, "protagonista.png"))
    hoja_otros(Image).save(os.path.join(salida, "otros.png"))
    guarda_gif(anima(Image), os.path.join(salida, "andar_cuadros.gif"))
    guarda_gif(anima_otros(Image), os.path.join(salida, "otros_cuadros.gif"))
    for f in ("protagonista.png", "otros.png", "andar_cuadros.gif", "otros_cuadros.gif"):
        print(f, os.path.getsize(os.path.join(salida, f)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
