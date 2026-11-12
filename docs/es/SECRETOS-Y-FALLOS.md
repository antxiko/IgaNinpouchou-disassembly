# Secretos y fallos

Lo que se ha buscado en el código y lo que se ha encontrado. Un fallo solo entra aquí si está comprobado:
ejecutando la propia rutina del juego (`tools/bios.py`) o contra las grabaciones de openMSX.

## Secretos: ninguno escondido

- **Ninguna tecla escondida.** Los mandos se leen en la interrupción (0x8FBA-0x9064): la palanca del mando 1 y los
  cursores (GTSTCK 1 y 0), los botones A y B del mando 1 (GTTRIG 1 y 3), y la barra y GRAPH, leídas con SNSMAT en las
  filas 8 y 6. El mando 2 no se lee, y no hay ninguna otra lectura del teclado: ninguna tecla al encender ni en el
  título.
- **Ni contraseñas ni fases escondidas**: lo único que el juego no enseña es el rollo secreto, que sale siempre en el
  último kakejiku de la sala, como se cuenta en [Curiosidades](CURIOSIDADES.html).

## Fallo: pasado 999.999, 990.000

Contado en [Curiosidades](CURIOSIDADES.html) y ejecutado con la rutina del juego: el tope de los puntos pone los tres
0x99 en el mismo byte (`puntos_tope`, 0x90E8), y 999.999 + 1 da **990.000**, con una vida más.

## Fallo: los cursores y el mando a la vez

`palanca` (0x8FD9) junta los cursores y el mando 1 con un `or` (0x8FE9), pero GTSTCK da números de dirección del 1 al
8, no bits. Con los dos a la vez sale otra dirección. Ejecutando aquí la rutina con cada puerto en una dirección:

| cursores | mando | sale | en un piso, el ninja va |
|---|---|---|---|
| derecha | — | 3 | a la derecha |
| derecha | abajo | **7** | **a la izquierda** |
| arriba-derecha | abajo-derecha | **6** | **a la izquierda** |
| arriba | abajo | 5 | abajo (se agacha) |

En los pisos, `anda_palanca` (0x933B) manda a la izquierda todo lo que sea 6 o más (0x9371).

## Comparaciones que no sirven, contadas en [Curiosidades](CURIOSIDADES.html)

- Arriba del salto, cuatro caminos que acaban en la misma instrucción (0x9843), y al caer un `inc hl` y un `dec hl`
  que se pierden (0x98E9).
- Al acabarse TIME, el juego mira 0xE185, que nadie escribe en la ROM (0x8DD5).
- En la fase 1, abajo a la derecha hace un `cp 4` que no decide nada: salta igual (0x964C).
- La demostración no tiene vidas: al primer toque, GAME OVER.
