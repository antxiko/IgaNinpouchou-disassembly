# Iga Ninpouchou - desensamblado comentado

*(Also [in English](README.md).)*

El desensamblado comentado de **Iga Ninpouchou** (伊賀忍法帖, Casio, 1985) para MSX: un cartucho de 16 KB en 0x8000.

- **100 %** del binario explicado: 9.296 bytes de código y 7.088 de datos con nombre, ni un byte sin asignar.
- **40,6 %** del listado comentado, 644 rutinas y etiquetas, ninguna por debajo del 10 % de comentarios.
- El listado se reensambla en la ROM original **byte a byte**.
- El título sale de ejecutar la ROM, cotejado con openMSX; los mapas de las cinco fases, desde la RAM; la puerta, los kakejiku y el rollo secreto, las puertas y la torre, jugados en GIF; las cinco músicas, de su propio motor de sonido e idénticas a openMSX cuadro a cuadro.

La web: <https://antxiko.github.io/IgaNinpouchou-disassembly/es/>
(en inglés: <https://antxiko.github.io/IgaNinpouchou-disassembly/>).

## Reproducirlo

La imagen de la ROM no se distribuye. Pon la tuya en la raíz como `iganinpouchou.rom` (sha256 `5d02bfe0...`) y ejecuta `make`. El detalle, en [POR DENTRO](docs/es/POR-DENTRO.md).

## Legal

El juego es de Casio y de sus titulares. La licencia de `LICENSE` cubre solo las herramientas, los comentarios, el análisis y la documentación de aquí. Mira [AVISO-LEGAL.md](AVISO-LEGAL.md).
