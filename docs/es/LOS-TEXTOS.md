# Los textos

Todos los textos de la ROM. Las letras no son las de la BIOS tal cual: el juego copia de la fuente de la BIOS los
caracteres del "0" al "_" a sus propias casillas (0x00-0x2F) y escribe con números de casilla: 0x00-0x09 las
cifras, 0x0A los dos puntos, 0x10 el espacio, 0x11 la A ... 0x2A la Z.

| dirección | original | traducción | dónde sale |
|---|---|---|---|
| 0x8EDB | 伊賀忍法帖 (Iga Ninpōchō) | El libro de las artes ninja de Iga | el título, en letras grandes: cinco kanji de 3 x 3 casillas |
| 0x8F14 | CASIO | CASIO | el título, en seis casillas propias |
| 0x8F1A | PUSH TRIG:1 OR SPACE | Pulsa el botón 1 o la barra | el título |
| 0x8F2E | COPYRIGHT 1985 © CASIO | Copyright 1985 © Casio | el título |
| 0x8F44 | TIME:01 | Tiempo | el marcador; las cifras se pisan con TIME |
| 0x8F4B | HISCORE:000000 | Récord | el marcador |
| 0x8F50 | SCORE:000000 | Puntos | el marcador: es el mismo texto del récord, sin el HI |
| 0x8F5D | (ninja):00 | los tumbados | el marcador: la cuenta de los enemigos tumbados en la fase; de 10 en adelante pone siempre 10 |
| 0x8F61 | OVER | Se acabó | en lugar de TIME, cuando llega a cero |
| 0x8F6B | GAME OVER | Fin de la partida | en el centro, sin vidas |

Iga es la provincia de los ninja (hoy parte de Mie); *ninpō* son las artes ninja y *-chō* un libro o registro.

El marcador tiene además el número de la fase en dibujos de **rollos** (las casillas 0x64 y 0x68, tantos como la
fase, `fase_pinta`, 0x907D), y las vidas de reserva como ninjas pequeños (0xE8, hasta cinco).
