# Curiosidades

## SCORE es HISCORE sin el HI

En la ROM solo está escrito `HISCORE:000000` (0x8F4B). La línea de los puntos copia ese mismo texto desde dos
letras más allá, 0x8F50: `SCORE:000000` (`marcador`, 0x8D54).

## Pasado 999.999, 990.000

Cuando los puntos pasan de 999.999, el juego quiere dejarlos en 999.999: pone 0x99 en los tres bytes de los
puntos... pero el bucle no avanza el puntero, y los tres 0x99 caen en el mismo byte, el de arriba (`puntos_tope`,
0x90E8). Ejecutando la rutina con `tools/bios.py`, 999.999 + 1 da **990.000** (y una vida más, la de cada 10.000).

## El color del título lo pone el ordenador

Mientras espera en el título, el juego cambia cada 3 cuadros los colores de los kanji grandes con 512 bytes
leídos de la **página 1** (0x4000 en adelante, un byte más allá cada vez): la mitad alta de cada byte es el color,
y si sale menos de 2, rojo (`titulo_espera`, 0x80D6). En la página 1 no está el cartucho sino lo que tenga el
ordenador ahí, así que el color depende del MSX. Ejecutando la ROM (sin esos bytes) los kanji salen blancos, como
en el [título](../imagenes/titulo.png); en openMSX con C-BIOS, rojos.

## El rollo está en el último

Los kakejiku de cada sala se pueden abrir en cualquier orden, pero el rollo secreto sale siempre en el último:
el juego cuenta los abiertos (0xE1CA) y lo da cuando la cuenta llega a 10, 18, 20 o 9, que son justo los que tiene
cada sala (0x9FF4). Para salir de una sala hay que abrirlos todos.

## Casillas hechas de código

Los dibujos de las casillas del juego se copian a la VRAM en un bloque de 0x600 bytes desde 0xA800
(`vram_casillas_a800`, 0x8E8D), pero ese bloque empieza antes de que acaben el código y los datos: las casillas
0x4E-0x57 son los bytes de la rutina de agacharse (`agacha`, 0xA8F0) y las siguientes, las filas del logotipo
de CASIO. Ningún mapa usa esas casillas. Lo mismo con los sprites: se copian 0x800 bytes desde 0xB800
(`sprites_dibujos`, 0x8EC9), y los últimos son las piezas de los mapas y la rutina que pinta el mapa.

## Comparaciones que no cambian nada

Arriba del salto, el juego mira hacia dónde salta y hacia dónde mira el ninja... y los cuatro caminos acaban en
la misma instrucción con el mismo HL (0x9843). Al caer hace lo mismo con un `inc hl` y un `dec hl` que se pierden
porque HL se carga otra vez (0x98E9). Y antes de dar la fase por perdida al acabarse TIME mira 0xE185, que nadie
escribe en la ROM (0x8DD5).

## La demostración no tiene vidas

La demostración no pasa por la partida nueva, así que empieza sin vidas de reserva: al primer toque sale GAME
OVER y vuelve al título.

## Lo que nadie llama

69 bytes de código que no llama nadie en 0x9C8C, dos variantes de la rutina que mira si algo toca al ninja en
0x842D, un `jr` detrás de un `ret` (0x9787) y un `ret` detrás de otro (0x9BC5). Ninguno corre en las medidas de
openMSX.
