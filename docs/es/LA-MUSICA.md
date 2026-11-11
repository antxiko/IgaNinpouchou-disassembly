# La música

Cinco músicas, todas cortas, en los tres canales del PSG. No están grabadas a mano: `tools/musica.py` **ejecuta
el propio motor de sonido de la ROM** con `tools/z80run.py` -`musica_pide` (0xA283) con el número de la música
y, en cada cuadro, `sonido` (0xA288)- y apunta lo que escribe en el PSG por la BIOS (WRTPSG).

**Cotejadas con openMSX**: los registros de tono y de volumen coinciden con los grabados, **0 distintos** en las
cinco, mientras suena cada una. Salen de tres grabaciones (`tools/guiones/`): sin tocar nada, una partida y las
fases forzadas. Cada cuadro grabado se empareja con el cuadro del motor que tiene la misma RAM en los tres
canales. La de la fase acabada suena dos veces seguidas en la fase 1 (al abrirse la puerta y otra vez al contar
TIME): la segunda vez el cotejo no la empareja, porque empieza de nuevo.

Los efectos de sonido no están aquí: los pasos, la estrella, el salto, las escaleras, el aviso de TIME y los
demás.

## El motor

Va en la interrupción, una vez por cuadro (`interrupcion`, 0x8F81). La petición queda en 0xE2BE y, en el cuadro
siguiente, el motor empieza los tres canales de la música de la tabla 0xA210, tres piezas por música
(`musica_empieza`, 0xA55F). Los canales están en 0xE280, 0xE292 y 0xE2A4, 18 bytes cada uno; en cada cuadro se
copian por turno a un bloque de trabajo en 0xE2C3, avanzan un paso y vuelven a su sitio. Una nota es un byte con
la duración (de la tabla 0xA539, de 128 cuadros a 1) y el volumen, y detrás el periodo del tono; desde 0xF0 son
órdenes: ruido, tres marcas de repetición con sus cuentas, vuelta al principio, silencio y el final. Hay ocho
efectos para el canal A (tabla 0xA234) y ocho para los canales B y C (0xA244); si se pide otro mientras suena uno,
se queda el de número más bajo.

| | Quién la pide | Duración |
|---|---|---:|
| la presentación | CASIO, al juntarse (0x9D6D) | 1,1 s |
| la fase | el principio de cada fase (0x81DC) | 4,3 s |
| la fase acabada | la puerta abierta y TIME a puntos (0x8C56, 0x8CE8) | 2,4 s |
| tocado | el ninja tocado o caído en un foso (0x8B9F) | 0,6 s |
| GAME OVER | sin vidas (0x8C17) | 3,1 s |

## La presentación

<audio controls src="../audio/musica_casio.mp3"></audio>

## La fase

<audio controls src="../audio/musica_fase.mp3"></audio>

## La fase acabada

<audio controls src="../audio/musica_fase_acabada.mp3"></audio>

## Tocado

<audio controls src="../audio/musica_tocado.mp3"></audio>

## GAME OVER

<audio controls src="../audio/musica_game_over.mp3"></audio>
