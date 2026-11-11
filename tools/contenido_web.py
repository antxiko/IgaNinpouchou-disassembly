#!/usr/bin/env python3
"""EL CONTENIDO de la web de esta ROM: lo unico que es de este juego.

jekyll.py y make_web.py son la maquinaria y no llevan dentro el nombre de
ningun juego: lo leen de aqui.

Todas las cifras de aqui estan medidas sobre esta ROM, con las herramientas
de tools/: CODIGO y DATOS los imprime tools/presupuesto.py (make sanity),
INSTRUCCIONES, COMENTARIOS y RUTINAS los da tools/densidad.py (make densidad:
"de N" rutinas, "N instrucciones, M comentarios").
"""

NOMBRE = "Iga Ninpouchou"
EDITOR = "Casio"
ANIO = 1985
REPOSITORIO = "https://github.com/antxiko/IgaNinpouchou-disassembly"
SHA1 = "f629b8f7133c3442d0371a4d84275fb2e0974854"

CODIGO = 9296
DATOS = 7088
RUTINAS = 644
INSTRUCCIONES = 4274
COMENTARIOS = 1736


def densidad(idioma):
    """El porcentaje comentado, con la coma o el punto de cada idioma."""
    d = "%.1f" % (100.0 * COMENTARIOS / INSTRUCCIONES)
    return d.replace(".", ",") if idioma == "es" else d


PIE_LEGAL = {
    "es": "<em>Iga Ninpouchou</em> es un juego de Casio para MSX, de 1985, en un cartucho de 16 KB. "
          "Todos los derechos sobre el juego siguen siendo de sus titulares. Este trabajo es de "
          "preservaci&oacute;n, estudio y documentaci&oacute;n, y la imagen de la ROM no se distribuye.",
    "en": "<em>Iga Ninpouchou</em> is a 1985 Casio game for the MSX, on a 16 KB cartridge. All rights in "
          "the game remain with their holders. This is preservation, study and documentation work, and the "
          "ROM image is not distributed.",
}

PORTADA = {
    "es": dict(
        titulo="Iga Ninpouchou - desensamblado comentado",
        claim="Un ninja entra en un castillo: delante de la muralla tumba a diez para que se abra la puerta; dentro, "
              "tira del cord&oacute;n de cada kakejiku buscando el rollo secreto, que solo est&aacute; en el "
              "&uacute;ltimo, y sube por la torre. Los mapas de las cinco fases desde la RAM; el t&iacute;tulo desde "
              "los bytes de la ROM, cotejado con openMSX; la partida en GIF y las cinco m&uacute;sicas de su propio "
              "motor, id&eacute;nticas a openMSX cuadro a cuadro.",
        ficha=["Casio - <b>(c) 1985</b>",
               "Cartucho de <b>16 KB</b> en 0x8000",
               "<b>MSX</b>", "Volcado <b>f629b8f7...</b>"],
        aviso="<b>Aqu&iacute; no hay capturas del juego.</b> El logotipo y el t&iacute;tulo salen de "
              "ejecutar la ROM (cotejados con openMSX), y los mapas y los GIF son la ROM <b>funcionando en "
              "openMSX</b>: en cada cuadro se apuntan la VRAM, la RAM y los registros del VDP, y <b>c&oacute;digo "
              "nuestro los pinta</b>.",
    ),
    "en": dict(
        titulo="Iga Ninpouchou - commented disassembly",
        claim="A ninja breaks into a castle: in front of the wall he knocks down ten so the gate opens; inside, he "
              "pulls the cord of every kakejiku looking for the secret scroll, which is only in the last one, and "
              "climbs the tower. The maps of the five stages from RAM; the title from the ROM's bytes, checked "
              "against openMSX; the game in GIF and the five tunes from its own engine, identical to openMSX frame "
              "by frame.",
        ficha=["Casio - <b>(c) 1985</b>",
               "<b>16 KB</b> cartridge at 0x8000",
               "<b>MSX</b>", "Dump <b>f629b8f7...</b>"],
        aviso="<b>There are no screenshots of the game here.</b> The logo and the title come from running "
              "the ROM (checked against openMSX), and the maps and the GIFs are the ROM <b>running in openMSX</b>: "
              "on every frame the VRAM, the RAM and the VDP registers are logged, and <b>our own code paints "
              "them</b>.",
    ),
}

PAGINAS = [
    [("THE-GAME.html", "LA-PARTIDA.html", "The game", "La partida",
      "the intro, the title, the controls, the star and the jump, TIME, the lives and the points",
      "la presentaci&oacute;n, el t&iacute;tulo, los mandos, la estrella y el salto, TIME, las vidas y los puntos"),
     ("THE-STAGES.html", "LAS-FASES.html", "The stages", "Las fases",
      "the five maps, the gate, the kakejiku and the scroll, the shrines, the tower and the enemies, in GIF",
      "los cinco mapas, la puerta, los kakejiku y el rollo, los altarcitos, la torre y los enemigos, en GIF"),
     ("THE-TEXTS.html", "LOS-TEXTOS.html", "The texts", "Los textos",
      "every text in the ROM, with its translation",
      "todos los textos de la ROM, con su traducci&oacute;n"),
     ("THE-MUSIC.html", "LA-MUSICA.html", "The music", "La m&uacute;sica",
      "the five tunes, from its own sound engine and checked against openMSX",
      "las cinco m&uacute;sicas, de su propio motor de sonido y cotejadas con openMSX")],
    [("CURIOSITIES.html", "CURIOSIDADES.html", "Curiosities", "Curiosidades",
      "SCORE inside HISCORE, 999,999 that becomes 990,000, the title colour, the scroll in the last kakejiku "
      "and tiles made of code",
      "SCORE dentro de HISCORE, 999.999 que se vuelve 990.000, el color del t&iacute;tulo, el rollo en el "
      "&uacute;ltimo kakejiku y casillas hechas de c&oacute;digo")],
    [("UNDER-THE-HOOD.html", "POR-DENTRO.html", "Under the hood", "Por dentro",
      "rebuilding the ROM, the BIOS it uses, the interrupt and the loop, the map in RAM, the RAM and the tools",
      "rehacer la ROM, la BIOS que usa, la interrupci&oacute;n y el bucle, el mapa en la RAM, la RAM y las "
      "herramientas")],
]

# Repositorio nuevo: no hay paginas viejas que redirigir.
VIEJAS = {}

LOGOTIPO = "logotipo.png"
