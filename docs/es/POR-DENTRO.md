# Por dentro

## Rehacer la ROM

`make verify` ensambla `src/iganinpouchou.asm` con pasmo y sale la ROM de 16 KB **byte a byte**. `make sanity`
comprueba lo que el reensamblado no cubre: que ningún byte declarado como dato se lea como código, que ningún
punto de entrada caiga en datos y que los 16.384 bytes estén explicados. `make test` pasa las pruebas. La ROM no
está en el repositorio: hay que ponerla en la raíz como `iganinpouchou.rom` (el volcado de GoodMSX, `[!]`, sha1
`f629b8f7...`).

| | bytes |
|---|---|
| código trazado | 9.296 |
| datos con nombre | 7.088 |
| sin explicar | 0 |

El listado tiene 1.736 comentarios en 4.274 instrucciones (40,6 %), 644 rutinas y etiquetas, ninguna por debajo
del 10 % comentado, y ninguna rutina llamada sin nombre.

## El cartucho

16 KB en la **página 2** (0x8000-0xBFFF), con INIT en 0x8010. Casi la mitad son datos: los dibujos de las
casillas y sus colores (0xA800-0xB5FF, copiados a partir de la casilla 0x30 de cada tercio), las casillas del
título (0xAE00), los sprites (0xB800), los mapas comprimidos de la fase 1 y del tejado de la torre, las listas de
piezas de las salas, los dibujos de las puertas y de los kakejiku al enrollarse, los textos y la música.

## La BIOS que usa

SETGRP, CHGCLR, DISSCR, ENASCR y WRTVDP para poner la pantalla; FILVRM, LDIRVM y WRTVRM para llenarla (el mapa
entero va de la RAM a la pantalla con LDIRVM en cada cuadro, 22 filas de 32); GTSTCK, GTTRIG y SNSMAT para los
mandos, y WRTPSG para el sonido. Lee la fuente de la BIOS en su dirección fija (0x1D3F, el "0" de la fuente de
0x1BBF).

## La interrupción y el bucle

INIT pone un salto a 0x8F81 en el gancho H.TIMI (0xFD9F). La interrupción lleva el **motor de sonido**, avanza
dieciséis cuentas de cuadros (0xE010-0xE01F) y lee los mandos; en la demostración, los pone al azar
(`interrupcion`, 0x8F81). El bucle de la fase da un paso por cuadro contado (`fase_cuadro`, 0x8245): los sprites
a la VRAM, el ninja, el mapa a la pantalla, los enemigos que salen y los que se mueven, el marcador y TIME.

## El mapa

El mapa vive en la RAM, en 0xE700 (0x840 bytes), y el juego lo lee para todo: el suelo de los enemigos, los
muros, las escaleras (las casillas 0x32, 0x35, 0x39 y 0x3A son sus extremos), los cordones de los kakejiku, el
rollo, los fosos y las puertas. Lo que cambia (un kakejiku enrollado, un foso, una puerta abierta) se escribe en
ese mapa y sale en la pantalla en el cuadro siguiente. El ninja está en el mapa por la casilla de suelo que pisa
(0xE18A); su sprite va aparte, y cuando la pantalla corre se mueven los otros en lugar de él.

## Cómo se ha hecho

El trazado sigue el código desde INIT y la interrupción, declarados en `src/iganinpouchou.entries`. No hay saltos
indirectos. Lo demás se ha **medido en openMSX** (`tools/omsx_cobertura.tcl`: una condición en cada instrucción
apunta cada dirección nueva de la ROM), jugando y esperando la demostración en un Philips VG 8020: nada de lo que
corrió quedó fuera del trazado. El motor de sonido es el de otros Casio de 1985, y sus notas se han llevado de
uno a otro donde los bytes coinciden.

## La RAM

| | |
|---|---|
| 0xE000 | la partida en marcha (0 en la demostración) |
| 0xE001-0xE006, 0xE00C-0xE00E | los puntos: seis cifras y en BCD |
| 0xE009 / 0xE00A | la vuelta y la fase |
| 0xE00B | las vidas de reserva |
| 0xE010-0xE01F | dieciséis cuentas de cuadros |
| 0xE040-0xE046 | los botones: saltar, tirar y empezar |
| 0xE048 | la demostración |
| 0xE080-0xE087 | TIME, cifra a cifra, y su copia para la pantalla |
| 0xE08E-0xE096 | el récord |
| 0xE100 | la tabla de sprites, que va a 0x1B00: el ninja (dos sprites) y su estrella |
| 0xE180 | la palanca |
| 0xE183 / 0xE186 | el ninja tocado / la fase acabada |
| 0xE18A | la casilla del mapa que pisa el ninja |
| 0xE190 | el piso del ninja |
| 0xE193 / 0xE19A | la pantalla corrida de lado / de arriba abajo |
| 0xE194-0xE199 | el salto y las escaleras |
| 0xE1B2 | los tumbados |
| 0xE1B4 | el objeto del altarcito y su tiempo |
| 0xE1C3-0xE1CA | el kakejiku que se enrolla y los abiertos |
| 0xE1C8 | la puerta: el rollo cogido y la salida |
| 0xE1CE | el ancho del mapa: 0x60 o 0x20 |
| 0xE280-0xE2D5 | el motor de sonido |
| 0xE300 | los enemigos y lo que tiran (16 bytes cada uno) |
| 0xE700-0xEF3F | el mapa |
