; ==========================================================================
; IGA NINPOUCHOU - ROM de 16 KB en 0x8000
; ==========================================================================
; Generado por tools/mkasm.py a partir del trazado de flujo real.
; Los comentarios provienen de tools/../src/*.notes y estan anclados a
; direccion, de modo que sobreviven a un retrazado.
; ==========================================================================

	org 0x08000


; ----------------------------------------------------------------------
; DATOS cabecera: "AB", INIT (0x8010) y el resto de la cabecera a cero
;   0x8000..0x8010  (16 bytes)
DATA_cabecera:
	defb 041h,042h	; 8000
	defw 08010h,00000h,00000h,00000h,00000h,00000h,00000h	; 8002

; ======================================================================
; CODIGO 0x8010..0x842d  (1053 bytes)
; ======================================================================


init:		; El arranque: la pila, la interrupcion en H.TIMI, SCREEN 2, las letras de la BIOS en los tres tercios, los colores, los sprites y el titulo
	di			;8010   ; sin interrupciones
	call 00041h		;8011   ; DISSCR
	ld hl,0e000h		;8014   ; 0xE000-0xF0FF...
	ld bc,01100h		;8017   ; ...0x1100 bytes...
init_borra:		; ...a cero
	ld (hl),000h		;801a   ; un byte a 0
	inc hl			;801c
	dec c			;801d   ; 256 bytes...
	jr nz,init_borra		;801e
	djnz init_borra		;8020   ; ...17 veces
	ld sp,0f100h		;8022   ; la pila
	ld hl,08f81h		;8025   ; la interrupcion (0x8F81)...
	ld (0fda0h),hl		;8028   ; ...en H.TIMI...
	ld a,0c3h		;802b   ; ...con su "jp"
	ld (0fd9fh),a		;802d   ; ...0xFD9F
	call 0007eh		;8030   ; SETGRP: SCREEN 2
	xor a			;8033   ; fondo y borde negros...
	ld (0f3eah),a		;8034   ; BAKCLR = 0
	ld (0f3ebh),a		;8037   ; BDRCLR = 0
	dec a			;803a   ; ...letras blancas (0xFF)
	ld (0f3e9h),a		;803b   ; FORCLR = 0xFF
	call 00062h		;803e   ; CHGCLR
	ld de,00000h		;8041   ; las letras de la BIOS ("0" a "_", 0x30-0x5F: 0x1D3F = 0x1BBF + 0x30 x 8, la direccion fija de la BIOS japonesa) a las casillas 0-0x2F, en los tres tercios
	ld b,003h		;8044
init_letras:
	call vram_copia_pon		;8046
	djnz init_letras		;8049
	xor a			;804b   ; el color 0 a la casilla 0x10 (el espacio), en los tres tercios
	ld hl,00080h		;804c
	ld b,003h		;804f
init_espacio:
	call vram_llena8		;8051
	djnz init_espacio		;8054
	ld hl,02000h		;8056   ; los colores de todo a 0xF0
	ld bc,01800h		;8059   ; 0x1800 bytes
	ld a,0f0h		;805c   ; 0xF0: blanco sobre transparente
	call 00056h		;805e   ; FILVRM
	call sprites_dibujos		;8061   ; los dibujos de los sprites
	ld a,0a2h		;8064   ; el registro 1 a 0xA2: la pantalla apagada, sprites de 16 x 16
	ld b,a			;8066
	ld c,001h		;8067
	call 00047h		;8069   ; WRTVDP
	ld a,003h		;806c   ; 0xE090 = 3
	ld (0e090h),a		;806e
	ld a,030h		;8071   ; 0xE095 = 0x30
	ld (0e095h),a		;8073
	ei			;8076   ; con interrupciones
titulo:		; El titulo: la presentacion de CASIO, 伊賀忍法帖, CASIO, PUSH TRIG:1 OR SPACE y el copyright; los colores del titulo cambian con bytes de la pagina 1 (desde 0x4000); al rato, la demostracion
	call sonido_pide_calla		;8077   ; la pantalla en blanco
	call pantalla_juego		;807a
	ld de,00200h		;807d   ; las casillas del titulo en los tres tercios
	ld b,003h		;8080
titulo_casillas:
	call vram_casillas_ae00		;8082
	djnz titulo_casillas		;8085
	ld hl,02200h		;8087   ; y sus colores
	ld b,003h		;808a
titulo_colores:
	call vram_color_f0		;808c
	djnz titulo_colores		;808f
	call 00044h		;8091   ; ENASCR
	call presentacion		;8094   ; la presentacion de CASIO
	ld hl,08edbh		;8097   ; el nombre en letras grandes (0x8EDB)...
	ld de,01906h		;809a   ; ...desde la fila 8, columna 6: tres filas
	ld b,003h		;809d
titulo_nombre:
	call vram_fila		;809f
	djnz titulo_nombre		;80a2
	ld hl,08f14h		;80a4   ; CASIO (6 casillas)...
	ld de,019edh		;80a7   ; ...en la fila 15, columna 13
	ld bc,00006h		;80aa
	call 0005ch		;80ad   ; LDIRVM
	ld hl,08f1ah		;80b0   ; PUSH TRIG:1 OR SPACE (20 casillas)...
	ld de,01a46h		;80b3   ; ...en la fila 18, columna 6
	ld bc,00014h		;80b6
	call 0005ch		;80b9   ; LDIRVM
	ld hl,08f2eh		;80bc   ; el copyright...
	ld de,01a85h		;80bf   ; ...en la fila 20, columna 5
	ld bc,00016h		;80c2
	call 0005ch		;80c5   ; LDIRVM
	call 00044h		;80c8   ; ENASCR
	ld de,04000h		;80cb   ; los colores salen de 0x4000 en adelante
	ld (0e049h),de		;80ce
	xor a			;80d2   ; la cuenta a 0
	ld (0e018h),a		;80d3
titulo_espera:		; Espera: a los 240 cuadros (0xE018), la demostracion; cada 3 cuadros, 512 colores nuevos
	ld a,(0e018h)		;80d6
	cp 0f0h		;80d9   ; 240?
	jp nc,demostracion		;80db
	ld a,(0e011h)		;80de   ; cada 3 cuadros
	cp 003h		;80e1
	jr c,titulo_boton		;80e3
	xor a			;80e5
	ld (0e011h),a		;80e6
	ld hl,0e800h		;80e9   ; a 0xE800...
	ld bc,00200h		;80ec   ; ...512 bytes...
	ld de,(0e049h)		;80ef   ; ...de la pagina 1
titulo_color:		; Un byte: su mitad alta es el color (0x20 o mas); si no, 0x60
	ld a,(de)			;80f3
	and 0f0h		;80f4
	cp 020h		;80f6   ; 0x20 o mas?
	jr nc,titulo_color_pon		;80f8
	ld a,060h		;80fa   ; si no, 0x60
titulo_color_pon:
	ld (hl),a			;80fc
	inc hl			;80fd
	inc de			;80fe
	dec c			;80ff
	jr nz,titulo_color		;8100
	djnz titulo_color		;8102
	ld hl,0e800h		;8104   ; los 512 colores...
	ld de,02a00h		;8107   ; ...en el tercer tercio (0x2A00)
	ld bc,00200h		;810a
	call 0005ch		;810d   ; LDIRVM
	ld de,(0e049h)		;8110   ; la proxima vez, un byte mas alla
	inc de			;8114
	ld (0e049h),de		;8115
titulo_boton:		; El boton de empezar?
	ld a,(0e046h)		;8119
	and a			;811c
	jr z,titulo_espera		;811d
	xor a			;811f   ; gastado
	ld (0e046h),a		;8120
	jr partida		;8123
demostracion:		; La demostracion: una fase al azar de la 1 a la 4
	xor a			;8125
	ld (0e009h),a		;8126   ; las decenas a 0
	ld a,r		;8129   ; al azar...
	and 003h		;812b
	inc a			;812d   ; ...de 1 a 4
	ld (0e00ah),a		;812e
	ld a,001h		;8131   ; 0xE048 = 1: la demostracion
	ld (0e048h),a		;8133
	jr fase		;8136
partida:		; Una partida nueva: la fase 1, tres vidas, los puntos a cero
	xor a			;8138
	ld (0e047h),a		;8139   ; sin demostracion
	ld (0e048h),a		;813c
	ld (0e009h),a		;813f   ; la vuelta 0
	ld (0e0d3h),a		;8142   ; la vida de los 3000, sin dar
	ld a,001h		;8145   ; la fase 1...
	ld (0e00ah),a		;8147
	ld (0e000h),a		;814a   ; ...y en partida
	ld a,003h		;814d   ; tres vidas
	ld (0e00bh),a		;814f   ; en 0xE00B
	ld hl,0e001h		;8152   ; los puntos (0xE001-0xE006) a cero
	ld b,006h		;8155   ; seis cifras
partida_borra:
	ld (hl),000h		;8157   ; una cifra a 0
	inc hl			;8159
	djnz partida_borra		;815a
	xor a			;815c   ; y los tres bytes BCD
	ld (0e00eh),a		;815d
	ld (0e00dh),a		;8160
	ld (0e00ch),a		;8163
fase:		; Una fase: la pantalla, los sprites; el protagonista en su sitio segun la fase; la musica 2 y el bucle
	call pantalla_juego		;8166   ; la pantalla en blanco
	call mapa_fase		;8169   ; la fase en la pantalla
	call marcador		;816c
	ld ix,0e100h		;816f   ; el protagonista (0xE100)
	ld a,001h		;8173   ; 0xE19C = 1
	ld (0e19ch),a		;8175
	ld (ix+000h),0eeh		;8178   ; sus dos sprites, fuera (Y 0xEE)...
	ld (ix+004h),0eeh		;817c
	ld (ix+002h),028h		;8180   ; ...el dibujo 0x28, color 5...
	ld (ix+003h),005h		;8184
	ld (ix+006h),02ch		;8188   ; ...y el 0x2C, color 11
	ld (ix+007h),00bh		;818c
	ld a,(0e00ah)		;8190   ; la fase 1?
	cp 001h		;8193
	jr z,fase1		;8195
	cp 005h		;8197   ; la 5?
	jr z,fase5		;8199
	ld hl,0eeb0h		;819b   ; el protagonista en 0xEEB0 del mapa
	ld (0e18ah),hl		;819e
	ld a,020h		;81a1   ; la pantalla corrida 32 columnas
	ld (0e193h),a		;81a3
	ld hl,00060h		;81a6   ; el ancho del mapa, 0x60
	ld (0e1ceh),hl		;81a9
	jr fase_empieza		;81ac
fase5:		; La 5: 0xEE30, 0x2B y 0x20
	ld hl,0ee30h		;81ae   ; el protagonista en 0xEE30 del mapa
	ld (0e18ah),hl		;81b1
	ld a,02bh		;81b4   ; la pantalla corrida 43 filas (0x2B)
	ld (0e19ah),a		;81b6
	ld hl,00020h		;81b9   ; el ancho del mapa, 32
	ld (0e1ceh),hl		;81bc
	jr fase_empieza		;81bf
fase1:		; La 1: el protagonista en Y 0x90, X 0x7C
	ld (ix+000h),090h		;81c1
	ld (ix+004h),090h		;81c5
	ld (ix+001h),07ch		;81c9
	ld (ix+005h),07ch		;81cd
fase_empieza:
	call mapa_pantalla		;81d1
	call sprites_vram		;81d4   ; los sprites a la VRAM
	call 00044h		;81d7   ; ENASCR
	ld a,002h		;81da   ; la musica 2
	call musica_pide		;81dc
	call espera_musica		;81df
	xor a			;81e2   ; las cuentas y los botones a 0
	ld (0e010h),a		;81e3
	ld (0e017h),a		;81e6
	ld (0e040h),a		;81e9
	ld (0e042h),a		;81ec
	ld (0e046h),a		;81ef
	ld a,080h		;81f2   ; 0xE1B1 = 0x80
	ld (0e1b1h),a		;81f4
	ld a,(0e00ah)		;81f7   ; la fase 1?
	cp 001h		;81fa
	jr z,fase_bucle		;81fc
	call puerta_entra		;81fe
	ld a,(0e00ah)		;8201   ; la 5?
	cp 005h		;8204
	jr z,fase5_sitio		;8206
	ld (ix+000h),09fh		;8208   ; las otras: Y 0x9F, X 0x7C
	ld (ix+004h),09fh		;820c
	ld (ix+001h),07ch		;8210
	ld (ix+005h),07ch		;8214
	jr fase_cero		;8218
fase5_sitio:		; La 5: Y 0x6F, X 0x7C
	ld (ix+000h),06fh		;821a
	ld (ix+004h),06fh		;821e
	ld (ix+001h),07ch		;8222
	ld (ix+005h),07ch		;8226
fase_cero:
	xor a			;822a
	ld (0e010h),a		;822b
	ld (0e040h),a		;822e
	ld (0e042h),a		;8231
	ld (0e180h),a		;8234
fase_bucle:		; El bucle de la fase: un paso por cuadro (0xE011); se acaba con 0xE183 (0x8B7B) o 0xE186 (0x8C49)
	ld a,(0e183h)		;8237   ; 0xE183?
	and a			;823a
	jp nz,tocado		;823b
	ld a,(0e186h)		;823e   ; 0xE186?
	and a			;8241
	jp nz,fase_fin		;8242
fase_cuadro:		; Un cuadro: los sprites, el protagonista, los otros, la salida de los otros, el sonido y lo demas
	ld a,(0e011h)		;8245   ; un cuadro?
	cp 001h		;8248
	jr c,fase_sigue		;824a
	xor a			;824c   ; gastado
	ld (0e011h),a		;824d
	call sprites_vram		;8250   ; la tabla de sprites a la VRAM
	call sprites_tabla		;8253   ; los otros a la tabla
	call protagonista		;8256   ; el protagonista
	call mapa_pantalla		;8259   ; el mapa a la pantalla
	call salen		;825c   ; salen otros?
	call otros		;825f   ; los otros se mueven
	call marcador_cifras		;8262   ; las cifras del marcador
	call tiempo		;8265   ; TIME
	call sonido_e1b4		;8268   ; el sonido del objeto 0x6A
	call fase1_salida		;826b   ; la salida de la fase 1
fase_sigue:		; En la demostracion, el boton vuelve al titulo
	ld a,(0e000h)		;826e   ; en partida, sigue
	and a			;8271
	jr nz,fase_bucle		;8272
	ld a,(0e046h)		;8274   ; el boton de empezar?
	and a			;8277
	jr z,fase_bucle		;8278
	jp titulo		;827a   ; al titulo
fase1_salida:		; En la fase 1: con 0xE1D1 y el protagonista arriba (Y menos de 0x52) en la columna 0x79-0x7D, la fase se acaba (0xE186)
	ld a,(0e00ah)		;827d   ; la fase 1?
	cp 001h		;8280
	ret nz			;8282
	ld a,(0e1d1h)		;8283   ; la puerta abierta (0xE1D1)?
	and a			;8286
	ret z			;8287
	ld a,(ix+000h)		;8288   ; arriba?
	cp 052h		;828b   ; por encima de 0x52?
	ret nc			;828d
	ld a,(ix+001h)		;828e   ; en la columna?
	cp 079h		;8291   ; X 0x79-0x7D?
	ret c			;8293
	cp 07eh		;8294
	ret nc			;8296
	ld a,001h		;8297   ; la fase se acaba
	ld (0e186h),a		;8299
	ret			;829c
sonido_e1b4:		; Con 0xE1B4, el efecto 2
	ld a,(0e1b4h)		;829d   ; el objeto 0x6A en marcha?
	and a			;82a0
	ret z			;82a1
	ld a,002h		;82a2   ; el efecto 2 (mientras dura)
	call efecto_pide		;82a4
	ret			;82a7
salen:		; Cuando la cuenta de 0xE1B1 llega a 0, salen otros; a 0x28 en la fase 1, seis mas (0xE304)
	ld a,(0e1b1h)		;82a8   ; la cuenta
	and a			;82ab
	jr z,salen_otro		;82ac   ; a 0: salen
	cp 028h		;82ae   ; 0x28?
	jr z,salen_28		;82b0
salen_cuenta:		; La cuenta, uno menos
	dec a			;82b2
	cp 0c0h		;82b3   ; pasada de 0xC0: a 0
	jr c,salen_cuenta_pon		;82b5
	xor a			;82b7
salen_cuenta_pon:
	ld (0e1b1h),a		;82b8   ; la cuenta nueva
	ret			;82bb
salen_28:
	ld c,a			;82bc   ; la cuenta guardada
	ld a,(0e00ah)		;82bd   ; la fase 1?
	cp 001h		;82c0
	jr z,salen_seis		;82c2
	ld a,c			;82c4   ; no: sigue la cuenta
	jr salen_cuenta		;82c5
salen_seis:
	ld hl,0e304h		;82c7   ; desde el segundo (0xE314)...
	ld de,00010h		;82ca   ; ...de 16 en 16...
	ld b,006h		;82cd   ; ...seis huecos
salen_seis_uno:
	ld a,(hl)			;82cf   ; libre?
	and a			;82d0
	jr nz,salen_seis_sig		;82d1
	ld (hl),006h		;82d3   ; el tipo 6
	ld a,c			;82d5   ; la cuenta
	jr salen_cuenta		;82d6
salen_seis_sig:
	add hl,de			;82d8   ; el siguiente
	djnz salen_seis_uno		;82d9
	ld a,c			;82db   ; ninguno libre
	jr salen_cuenta		;82dc
salen_otro:		; La cuenta nueva (al azar) y otro que sale segun la fase
	ld a,r		;82de   ; al azar 0-63
	and 03fh		;82e0
	ld b,a			;82e2   ; la fase
	ld a,(0e00ah)		;82e3
	cp 001h		;82e6   ; la fase 1?
	jr nz,salen_fase		;82e8   ; la fase 1: 16 + eso
	ld a,010h		;82ea   ; 16 + el azar
	add a,b			;82ec
	jr salen_pon		;82ed
salen_fase:		; Las otras: 0x60 - (fase + 1) x 8 + eso
	ld c,a			;82ef   ; la fase...
	ld a,008h		;82f0   ; ...8...
salen_fase_x8:
	add a,008h		;82f2   ; ...+ 8 por fase
	dec c			;82f4
	jr nz,salen_fase_x8		;82f5
	ld c,a			;82f7
	ld a,060h		;82f8   ; 0x60 menos eso...
	sub c			;82fa
	add a,b			;82fb   ; ...+ el azar
salen_pon:
	ld (0e1b1h),a		;82fc   ; la cuenta nueva
	ld a,(0e1b3h)		;82ff   ; uno mas salido (0xE1B3)
	inc a			;8302
	ld (0e1b3h),a		;8303
	ld a,(0e198h)		;8306   ; en una escalera: el tipo 1
	and a			;8309
	jr nz,sale5		;830a
	ld a,(0e00ah)		;830c   ; la fase 1?
	cp 001h		;830f
	jp z,sale_fase1		;8311
	ld a,(0e1b8h)		;8314   ; por turnos (0xE1B8, 1-5)
	inc a			;8317   ; el turno siguiente
	ld (0e1b8h),a		;8318
	cp 001h		;831b   ; 1?
	jr z,sale1		;831d
	cp 002h		;831f
	jr z,sale2		;8321
	cp 003h		;8323
	jr z,sale3		;8325
	cp 004h		;8327
	jr z,sale4		;8329
	cp 005h		;832b
	jr z,sale5		;832d
	xor a			;832f   ; pasado el 5: otra vez
	ld (0e1b8h),a		;8330
	jr salen_otro		;8333
sale1:		; El turno 1: el hueco de 0xE364 (tipo 3); desde la fase 3, a veces el tipo 8
	ld hl,0e364h		;8335   ; el hueco 0xE364
	ld a,(hl)			;8338   ; libre?
	and a			;8339
	jr nz,sale2		;833a   ; no: el turno 2
	ld (hl),003h		;833c   ; el tipo 3...
	ld a,001h		;833e   ; ...con +0x0E = 1 (el piso de abajo)
	ld (0e36eh),a		;8340
sale_tipo8:		; Desde la fase 3, la mitad de las veces y si no hay otro (0xE1D0), el tipo 8 en vez del 3
	ld a,(0e00ah)		;8343   ; la fase 3 o mas?
	cp 003h		;8346
	ret c			;8348
	ld a,r		;8349   ; al azar, la mitad
	bit 0,a		;834b
	ret nz			;834d
	ld a,(0e1d0h)		;834e   ; ya hay un tipo 8?
	and a			;8351
	ret nz			;8352
	inc a			;8353   ; ahora si
	ld (0e1d0h),a		;8354
	ld (hl),008h		;8357   ; el tipo 8
	ret			;8359
sale2:		; El turno 2: 0xE384
	ld hl,0e384h		;835a   ; el hueco 0xE384
	ld a,(hl)			;835d
	and a			;835e
	jr nz,sale3		;835f   ; no: el turno 3
	ld (hl),003h		;8361   ; el tipo 3...
	ld a,002h		;8363   ; ...en el piso de en medio (2)
	ld (0e38eh),a		;8365
	jr sale_tipo8		;8368
sale3:		; El turno 3: 0xE3A4
	ld hl,0e3a4h		;836a   ; el hueco 0xE3A4
	ld a,(hl)			;836d
	and a			;836e
	jr nz,sale4		;836f   ; no: el turno 4
	ld a,003h		;8371   ; el tipo 3...
	ld (hl),a			;8373
	ld (0e3aeh),a		;8374   ; ...en el piso de arriba (3)
	jr sale_tipo8		;8377
sale4:		; El turno 4: 0xE3B4 (tipo 2)
	ld hl,0e3b4h		;8379   ; el hueco 0xE3B4
	ld a,(hl)			;837c
	and a			;837d
	jr nz,sale5		;837e   ; no: el turno 5
	ld (hl),002h		;8380   ; el tipo 2
	ret			;8382
sale5:		; El turno 5: 0xE344 (tipo 1)
	ld hl,0e344h		;8383   ; el hueco 0xE344
	ld a,(hl)			;8386
	and a			;8387
	ret nz			;8388   ; ocupado: nada
	ld (hl),001h		;8389   ; el tipo 1
	ret			;838b
sale_fase1:		; En la fase 1: hasta 10 (0xE1B2), del tipo 5 en un hueco al azar desde 0xE394
	ld a,(0e1b2h)		;838c   ; ya van 10?
	cp 00ah		;838f
	ret nc			;8391
	ld hl,0e374h		;8392   ; desde 0xE374...
	ld de,00020h		;8395   ; ...de 32 en 32
	ld c,001h		;8398   ; la fila (+2)
	ld a,r		;839a   ; uno de los cuatro al azar
	and 003h		;839c
	ld b,a			;839e
sale_fase1_hueco:
	inc c			;839f   ; el siguiente
	add hl,de			;83a0
	djnz sale_fase1_hueco		;83a1
	ld a,(hl)			;83a3   ; libre?
	and a			;83a4
	jr nz,sale_fase1_sig		;83a5
sale_fase1_pon:
	ld (hl),005h		;83a7   ; el tipo 5...
	inc hl			;83a9
	inc hl			;83aa
	ld (hl),c			;83ab   ; ...y su fila en +6
	ret			;83ac
sale_fase1_sig:
	inc c			;83ad   ; el siguiente...
	add hl,de			;83ae
	ld a,l			;83af
	cp 0f4h		;83b0   ; ...pasado 0xE3F4?
	jr nz,sale_fase1_mira		;83b2
	ld c,001h		;83b4   ; otra vez desde el principio
	ld hl,0e374h		;83b6
sale_fase1_mira:
	ld a,(hl)			;83b9   ; libre?
	and a			;83ba
	ret nz			;83bb   ; tampoco: nada
	jr sale_fase1_pon		;83bc
otros:		; Los dieciseis de 0xE300 (16 bytes): los que estan (+4), cada uno
	ld iy,0e300h		;83be   ; desde 0xE300
	ld b,010h		;83c2   ; dieciseis
otros_uno:
	push bc			;83c4   ; la cuenta
	ld a,(iy+004h)		;83c5   ; esta?
	and a			;83c8
	jr nz,otros_mueve		;83c9
otros_sig:
	ld de,00010h		;83cb   ; el siguiente: + 16
	add iy,de		;83ce
	pop bc			;83d0
	djnz otros_uno		;83d1
	ret			;83d3
otros_mueve:
	call otro		;83d4   ; se mueve
	jr otros_sig		;83d7
otro_fuera:		; Fuera de la pantalla (Y menos de 4 o 0xC0 o mas, X 0xF6 o mas): borrado
	ld a,(iy+000h)		;83d9   ; la Y
	cp 004h		;83dc   ; arriba del todo?
	jr c,otro_borra		;83de
	cp 0c0h		;83e0   ; abajo del todo?
	jr nc,otro_borra		;83e2
	ld a,(iy+001h)		;83e4   ; la X
	cp 0f6h		;83e7   ; a la derecha del todo?
	jr nc,otro_borra		;83e9
	ret			;83eb   ; dentro
otro_borra:
	ld a,(iy+004h)		;83ec   ; el tipo 8?
	cp 008h		;83ef
	jr nz,otro_borra_va		;83f1
	xor a			;83f3   ; ya puede salir otro
	ld (0e1d0h),a		;83f4
otro_borra_va:
	push iy		;83f7   ; sus 16 bytes...
	pop hl			;83f9
	ld b,010h		;83fa
otro_borra_byte:
	ld (hl),000h		;83fc   ; ...a cero
	inc hl			;83fe
	djnz otro_borra_byte		;83ff
	ld (iy+000h),0ech		;8401   ; fuera (Y 0xEC)
	ret			;8405
cerca_y:		; ¿Toca en Y? A = la Y de IY menos la del protagonista (IX): C si queda entre B y C (con signo, de B a C)
	ld a,(iy+000h)		;8406   ; la Y del otro...
	sub (ix+000h)		;8409   ; ...menos la del protagonista
cerca_mira:
	cp b			;840c   ; por debajo de B: no
	ret c			;840d
	cp c			;840e   ; por debajo de C: si
	jr c,cerca_no		;840f
	scf			;8411   ; C: toca
	ret			;8412
cerca_no:
	and a			;8413   ; NC: no
	ret			;8414
cerca_x:		; Lo mismo en X
	ld a,(iy+000h)		;8415   ; la X
	sub (ix+008h)		;8418
	jr cerca_mira		;841b
cerca_x2:		; En X contra +9 del protagonista
	ld a,(iy+001h)		;841d
	sub (ix+009h)		;8420
	jr cerca_mira		;8423
cerca_x1:		; En X contra +1 del protagonista
	ld a,(iy+001h)		;8425
	sub (ix+001h)		;8428
	jr cerca_mira		;842b

; ----------------------------------------------------------------------
; DATOS cerca_otras: Dos variantes mas de 0x8406 ("ld a,(iy+0Ah) / sub (ix+0)
;   / jr" y con +8): ningun call ni salto llega aqui y no corren en las
;   medidas de openMSX
;   0x842d..0x843d  (16 bytes)
DATA_cerca_otras:
	defb 0fdh,07eh,00ah,0ddh,096h,000h,018h,0d7h	; 842d  .~......
	defb 0fdh,07eh,00ah,0ddh,096h,008h,018h,0cfh	; 8435  .~......

; ======================================================================
; CODIGO 0x843d..0x8edb  (2718 bytes)
; ======================================================================


lado_azar:		; +8 al azar y +9 = 0 o 0x10 al azar (el lado por donde sale); Z si 0
	ld a,r		;843d   ; al azar
	res 7,a		;843f   ; 0-127
	ld (iy+008h),a		;8441   ; en +8
	and 001h		;8444   ; el bit 0...
	rlca			;8446
	rlca			;8447
	rlca			;8448
	rlca			;8449
	ld (iy+009h),a		;844a   ; ...x 16 en +9: el lado
	and a			;844d
	ret			;844e
otro:		; Uno de los otros, segun su tipo (+4): 1, 2, 3 y 8, 4 y 7, 5, 6
	ld a,(iy+004h)		;844f   ; el tipo
	cp 001h		;8452   ; 1?
	jr z,tipo1		;8454
	cp 002h		;8456   ; 2?
	jp z,tipo2		;8458
	cp 003h		;845b   ; 3?
	jp z,tipo3		;845d
	cp 004h		;8460   ; 4?
	jp z,tipo4		;8462
	cp 005h		;8465   ; 5?
	jp z,tipo5		;8467
	cp 006h		;846a   ; 6?
	jp z,tipo6		;846c
	cp 007h		;846f   ; 7: como el 4
	jp z,tipo4		;8471
	cp 008h		;8474   ; 8: como el 3
	jp z,tipo3		;8476
	ret			;8479   ; otro: nada
tipo1:		; El tipo 1: sale a una altura y cruza la pantalla de lado, 3 puntos por cuadro; si toca al protagonista, 0xE183 = 1
	ld a,(0e183h)		;847a   ; el protagonista ya tocado?
	and a			;847d
	ret nz			;847e
	ld a,(iy+005h)		;847f   ; ya ha salido?
	and a			;8482
	jp nz,tipo1_anda		;8483
	call sale_altura		;8486   ; sale
	ld a,(0e198h)		;8489   ; el protagonista en una escalera?
	and a			;848c
	jr z,tipo1_y		;848d
	ld a,(0e00ah)		;848f   ; en la escalera, en la fase 5: a la altura del protagonista
	cp 005h		;8492
	jr nz,tipo1_azar		;8494
tipo1_y_prota:		; La Y del protagonista
	ld a,(ix+000h)		;8496
	jr tipo1_y_pon		;8499
tipo1_azar:		; En la escalera fuera de la 5: la mitad de las veces a la altura del protagonista
	ld a,r		;849b   ; al azar
	bit 0,a		;849d
	jr z,tipo1_y_prota		;849f
tipo1_y:		; Su piso
	ld a,(iy+000h)		;84a1
tipo1_y_pon:		; - 12
	sub 00ch		;84a4   ; 12 por encima
	ld (iy+000h),a		;84a6
	ret			;84a9
sale_altura:		; La altura por donde sale, al azar entre los pisos de la fase (0x9F, 0x6F, 0x3F o 0xE8 en la 5); y el lado
	ld a,r		;84aa   ; al azar
	bit 4,a		;84ac   ; bit 4: abajo
	jr z,sale_abajo		;84ae
	bit 5,a		;84b0   ; bit 5: en medio
	jr z,sale_medio		;84b2
	bit 6,a		;84b4   ; bit 6: arriba
	jr z,sale_arriba		;84b6
	ld a,(iy+004h)		;84b8   ; el tipo 1...
	cp 001h		;84bb
	jr nz,sale_altura_piso		;84bd
	ld a,(ix+000h)		;84bf   ; ...a la altura del protagonista
	ld (iy+000h),a		;84c2
	jr sale_lado		;84c5
sale_altura_piso:		; Segun el piso del protagonista (0xE190)
	ld a,(0e190h)		;84c7   ; el piso
	cp 002h		;84ca   ; 2: arriba
	jr z,sale_arriba		;84cc
	cp 001h		;84ce   ; 1: en medio
	jr z,sale_medio		;84d0
sale_abajo:		; El piso de abajo: 0x9F (0xE8 en la fase 5)
	ld a,(0e00ah)		;84d2   ; la fase 5?
	cp 005h		;84d5
	jr z,sale_abajo5		;84d7
	ld (iy+000h),09fh		;84d9   ; Y 0x9F
	jr sale_lado		;84dd
sale_abajo5:
	ld (iy+000h),0e8h		;84df   ; Y 0xE8
	jr sale_lado		;84e3
sale_medio:		; El de en medio: 0x6F
	ld (iy+000h),06fh		;84e5   ; Y 0x6F
	jr sale_lado		;84e9
sale_arriba:		; El de arriba: 0x3F
	ld a,(0e190h)		;84eb   ; en el piso 7 (lo alto de la 5): abajo
	cp 007h		;84ee
	jr z,sale_abajo5		;84f0
	ld (iy+000h),03fh		;84f2   ; Y 0x3F
sale_lado:		; Por la derecha (X 0xF5, dibujo 0x78) o por la izquierda (X 0, dibujo 0x7C)
	call lado_azar		;84f6   ; al azar
	jr nz,sale_izquierda		;84f9
	ld (iy+001h),0f5h		;84fb   ; X 0xF5...
	ld (iy+002h),078h		;84ff   ; ...mirando a la izquierda
	jr sale_color		;8503
sale_izquierda:
	ld (iy+001h),000h		;8505   ; X 0...
	ld (iy+002h),07ch		;8509   ; ...mirando a la derecha
sale_color:		; Color 15 y ya ha salido (+5)
	ld (iy+003h),00fh		;850d   ; color 15
	inc (iy+005h)		;8511   ; ya ha salido
	ret			;8514
tipo1_anda:		; 3 puntos por cuadro hacia su lado
	ld a,(iy+009h)		;8515   ; hacia donde va?
	and a			;8518
	jr nz,tipo1_derecha		;8519   ; hacia la derecha?
	dec (iy+001h)		;851b   ; 3 a la izquierda
	dec (iy+001h)		;851e
	dec (iy+001h)		;8521
	jr tipo1_toca		;8524
tipo1_derecha:
	inc (iy+001h)		;8526   ; 3 a la derecha
	inc (iy+001h)		;8529
	inc (iy+001h)		;852c
tipo1_toca:		; Si toca al protagonista: 0xE183 = 1
	ld a,(0e1beh)		;852f   ; agachado (0xE1BE)?
	and a			;8532   ; agachado: le pasa por encima
	jr nz,tipo1_fase2		;8533
	ld bc,001f2h		;8535   ; en Y...
	call cerca_y		;8538   ; cerca_y
	jr nc,tipo1_fase2		;853b
	ld bc,008f8h		;853d   ; ...y en X?
	call cerca_x1		;8540   ; cerca_x1
	jr nc,tipo1_fase2		;8543
	ld a,001h		;8545   ; tocado
	ld (0e183h),a		;8547
	ret			;854a
tipo1_fase2:		; En la fase 2, con 0xE1B4 y 0xE19B: si toca lo de 0xE108, se va (Y 0xE8)
	ld a,(0e00ah)		;854b   ; la fase 2...
	cp 002h		;854e
	jp nz,otro_fuera		;8550
	ld a,(0e1b4h)		;8553   ; ...con el objeto 0x6A...
	and a			;8556
	jp z,otro_fuera		;8557
	ld a,(0e19bh)		;855a   ; ...y una estrella en vuelo?
	and a			;855d
	jp z,otro_fuera		;855e
	ld bc,001f1h		;8561   ; la estrella le da?
	call cerca_x		;8564
	jp nc,otro_fuera		;8567
	ld bc,00cf4h		;856a
	call cerca_x2		;856d
	jp nc,otro_fuera		;8570
	ld (iy+000h),0e8h		;8573   ; si: fuera (Y 0xE8)
	jp otro_fuera		;8577
tipo2:		; El tipo 2: sale como el 1 y cruza de punto en punto, cambiando de dibujo (0x80/0x84) y de color (9/10)
	ld a,(0e183h)		;857a   ; el protagonista ya tocado?
	and a			;857d
	ret nz			;857e
	ld a,(iy+005h)		;857f   ; ya ha salido?
	and a			;8582
	jr nz,tipo2_anda		;8583
	call sale_altura		;8585   ; sale
	ld (iy+006h),080h		;8588   ; (+6 = 0x80)
	ld (iy+002h),080h		;858c   ; el dibujo 0x80...
	ld (iy+003h),009h		;8590   ; ...color 9
	ret			;8594
tipo2_anda:
	ld a,(iy+009h)		;8595   ; hacia donde va?
	and a			;8598
	jr nz,tipo2_derecha		;8599
	dec (iy+001h)		;859b   ; un punto a la izquierda
	jr tipo2_dibujo		;859e
tipo2_derecha:
	inc (iy+001h)		;85a0   ; un punto a la derecha
tipo2_dibujo:		; El dibujo y el color cambian con la cuenta 0xE01F
	ld a,(0e01fh)		;85a3   ; 0x80 o 0x84 cada 4 cuadros
	and 004h		;85a6
	add a,080h		;85a8
	ld (iy+002h),a		;85aa
	ld a,(0e01fh)		;85ad   ; color 9 o 10 cada 2
	and 002h		;85b0
	rrca			;85b2
	add a,009h		;85b3
	ld (iy+003h),a		;85b5
	ld bc,008f8h		;85b8   ; toca al protagonista?
	call cerca_y		;85bb
	jr nc,tipo2_fase2		;85be
	ld bc,006fah		;85c0   ; en X?
	call cerca_x1		;85c3
	jr nc,tipo2_fase2		;85c6
	ld a,001h		;85c8   ; tocado
	ld (0e183h),a		;85ca
tipo2_fase2:		; En la fase 2, igual que el tipo 1
	ld a,(0e00ah)		;85cd   ; la fase 2...
	cp 002h		;85d0
	jp nz,otro_fuera		;85d2
	ld a,(0e1b4h)		;85d5   ; ...con el objeto 0x6A...
	and a			;85d8
	jp z,otro_fuera		;85d9
	ld a,(0e19bh)		;85dc   ; ...y una estrella?
	and a			;85df
	jp z,otro_fuera		;85e0
	ld bc,00cf4h		;85e3   ; la estrella le da?
	call cerca_x		;85e6
	jp nc,otro_fuera		;85e9
	ld bc,00cf4h		;85ec
	call cerca_x2		;85ef
	jp nc,otro_fuera		;85f2
	ld (iy+000h),0e8h		;85f5   ; si: fuera
	jp otro_fuera		;85f9
tipo5:		; El tipo 5: sale en una fila (+6 x 24 + 0x38 + algo al azar, hasta 0x97), color 13, por un lado
	ld (iy+007h),001h		;85fc   ; +7 = 1
	ld a,(iy+005h)		;8600   ; ya ha salido?
	and a			;8603
	jp nz,tipo3_tira		;8604
	inc (iy+005h)		;8607   ; ya ha salido
	ld b,(iy+006h)		;860a   ; su fila (+6, de 2 a 5)...
	ld c,018h		;860d   ; ...x 24...
tipo5_fila:
	add a,c			;860f
	djnz tipo5_fila		;8610
	add a,038h		;8612   ; ...+ 0x38
	ld b,a			;8614
	ld a,r		;8615   ; al azar
	ld (iy+008h),a		;8617   ; la espera, al azar (+8)
	and 007h		;861a   ; + 0-7
	add a,b			;861c
	cp 097h		;861d   ; no mas abajo de 0x97
	jr c,tipo5_pon		;861f
	ld a,097h		;8621   ; 0x97
tipo5_pon:
	ld (iy+000h),a		;8623   ; la Y
	ld (iy+003h),00dh		;8626   ; color 13
	call lado_azar		;862a   ; al azar
	jr nz,tipo5_izquierda		;862d
	ld (iy+001h),0f5h		;862f   ; X 0xF5
	jr tipo5_cuenta		;8633
tipo5_izquierda:
	ld (iy+001h),000h		;8635   ; X 0
tipo5_cuenta:
	ld (iy+006h),050h		;8639   ; +6 = 0x50
	ret			;863d
tipo3:		; Los tipos 3 y 8: salen en un piso (+0x0E: 1 abajo, 2 en medio, si no arriba), con el dibujo 0x50 o 0x60 segun el lado
	ld a,(iy+005h)		;863e
	and a			;8641   ; ya ha salido?
	jr nz,tipo3_tira		;8642
	call sale_altura		;8644   ; la altura y el lado
	ld a,(iy+00eh)		;8647   ; su piso
	cp 001h		;864a   ; abajo?
	jr z,tipo3_abajo		;864c
	cp 002h		;864e   ; en medio?
	jr z,tipo3_medio		;8650
	ld a,(0e190h)		;8652   ; arriba: con el protagonista en el piso 7, no sale
	cp 007h		;8655
	jp z,otro_borra		;8657
	ld (iy+000h),03fh		;865a   ; Y 0x3F
	jr tipo3_lado		;865e
tipo3_medio:
	ld (iy+000h),06fh		;8660   ; Y 0x6F
	jr tipo3_lado		;8664
tipo3_abajo:
	ld a,(0e00ah)		;8666   ; abajo: en la fase 5 con el protagonista en el piso 0, no sale
	cp 005h		;8669
	jr nz,tipo3_abajo_pon		;866b
	ld a,(0e190h)		;866d
	and a			;8670
	jp z,otro_borra		;8671
tipo3_abajo_pon:
	ld (iy+000h),09fh		;8674   ; Y 0x9F
tipo3_lado:
	ld (iy+006h),050h		;8678   ; +6 = 0x50
	ld a,(iy+009h)		;867c   ; hacia donde va?
	and a			;867f
	jr nz,tipo3_derecha		;8680
	ld (iy+002h),050h		;8682   ; a la izquierda: el dibujo 0x50...
	ld (iy+003h),009h		;8686   ; ...color 9
	ret			;868a
tipo3_derecha:
	ld (iy+002h),060h		;868b   ; a la derecha: 0x60, color 9
	ld (iy+003h),009h		;868f
	ret			;8693
tipo3_tira:		; Ya en marcha: de vez en cuando (+8 a 0) tira algo (16 bytes antes, -0x10): de dibujo 0x9C (el tipo 8) o 0xA4
	cp 001h		;8694
	jp nz,tipo3_estado2		;8696
	ld a,(iy+008h)		;8699   ; la espera...
	and a			;869c
	jr nz,tipo3_anda		;869d
	ld a,(0e00ah)		;869f   ; en la fase 3 con 0xE1B4, no tira
	cp 003h		;86a2
	jr nz,tipo3_tira_va		;86a4
	ld a,(0e1b4h)		;86a6
	and a			;86a9
	jr nz,tipo3_anda		;86aa
tipo3_tira_va:
	ld a,(iy-00ch)		;86ac   ; ya tiene algo en marcha?
	and a			;86af
	jr nz,tipo3_espera		;86b0
	ld a,(iy+000h)		;86b2   ; su Y + 4...
	add a,004h		;86b5
	ld (iy-010h),a		;86b7
	ld a,(iy+001h)		;86ba   ; ...su X...
	ld (iy-00fh),a		;86bd
	ld a,(iy+009h)		;86c0   ; ...su lado
	ld (iy-007h),a		;86c3
	ld a,(iy+004h)		;86c6   ; el tipo 8?
	cp 008h		;86c9   ; el tipo 8 tira 0x9C...
	jr nz,tipo3_tira_a4		;86cb
	ld (iy-00eh),09ch		;86cd   ; el dibujo 0x9C, color 15, el tipo 7
	ld (iy-00dh),00fh		;86d1
	ld (iy-00ch),007h		;86d5
	jr tipo3_espera		;86d9
tipo3_tira_a4:		; El dibujo 0xA4, color 7, el tipo 4
	ld (iy-00eh),0a4h		;86db
	ld (iy-00dh),007h		;86df
	ld (iy-00ch),004h		;86e3
tipo3_espera:		; Una espera al azar; salvo el tipo 5, un lado al azar
	ld a,r		;86e7   ; la espera, al azar (0-127)
	and 07fh		;86e9
	ld (iy+008h),a		;86eb
	ld a,(iy+004h)		;86ee   ; el tipo 5...
	cp 005h		;86f1   ; ...no cambia de lado
	ret z			;86f3
	ld a,r		;86f4   ; al azar
	bit 0,a		;86f6
	jr nz,tipo3_lado_der		;86f8
	ld (iy+009h),000h		;86fa   ; a la izquierda
	ret			;86fe
tipo3_lado_der:
	ld (iy+009h),010h		;86ff   ; a la derecha
	ret			;8703
tipo3_anda:		; En marcha: anda hacia su lado (el tipo 3, un paso de cada dos) y mira el suelo (0x888B)
	dec (iy+008h)		;8704   ; la espera, uno menos
	inc (iy+007h)		;8707   ; la cuenta de pasos
	call suelo		;870a   ; el suelo
	ld a,(iy+004h)		;870d   ; el tipo 8...
	cp 008h		;8710   ; ...anda siempre
	jr z,tipo3_anda_fase3		;8712
	ld a,(iy+007h)		;8714   ; un paso de cada dos
	and 001h		;8717   ; en los impares, quieto
	jr nz,tipo8_salta		;8719
tipo3_anda_fase3:		; En la fase 3 con 0xE1B4, quieto
	ld a,(0e00ah)		;871b   ; la fase 3...
	cp 003h		;871e
	jr nz,tipo3_paso		;8720
	ld a,(0e1b4h)		;8722   ; ...con el objeto 0x6A: quietos
	and a			;8725
	jr z,tipo3_paso		;8726
	jr tipo8_salta		;8728
tipo3_paso:		; Un punto hacia su lado
	ld a,(iy+009h)		;872a   ; hacia donde va?
	and a			;872d
	jr nz,tipo3_paso_der		;872e
	dec (iy+001h)		;8730   ; un punto a la izquierda
	jr tipo8_salta		;8733
tipo3_paso_der:
	inc (iy+001h)		;8735   ; un punto a la derecha
tipo8_salta:		; El tipo 8 en las columnas 0x50-0x57 o 0x9E-0xA1: el estado 3 (0xE1D0 = 2)
	ld a,(iy+004h)		;8738   ; el tipo 8?
	cp 008h		;873b
	jr nz,tipo3_toca		;873d
	ld a,(0e00ah)		;873f   ; en la fase 3 con el objeto, no
	cp 003h		;8742
	jr nz,tipo8_columna		;8744
	ld a,(0e1b4h)		;8746
	and a			;8749
	jr nz,tipo3_toca		;874a
tipo8_columna:
	ld a,(iy+001h)		;874c   ; su X
	cp 050h		;874f   ; 0x50-0x57?
	jr c,tipo3_toca		;8751
	cp 058h		;8753
	jr c,tipo8_estado3		;8755
	cp 09eh		;8757   ; 0x9E-0xA1?
	jr c,tipo3_toca		;8759
	cp 0a2h		;875b
	jr nc,tipo3_toca		;875d
tipo8_estado3:
	ld (iy+005h),003h		;875f   ; el estado 3
	ld (iy+008h),000h		;8763   ; la espera a 0
	ld a,002h		;8767   ; 0xE1D0 = 2
	ld (0e1d0h),a		;8769
tipo3_toca:		; Su dibujo; si toca al protagonista: 0xE183 = 2 (salvo con 0xE197); si le da lo del protagonista (+8, con 0xE19B), cae
	ld a,(0e01fh)		;876c   ; el paso: cada 8 cuadros
	and 008h		;876f
	call tipo3_dibujo		;8771   ; su dibujo
	ld bc,008f8h		;8774   ; en Y...
	call cerca_y		;8777   ; cerca_y
	jr nc,tipo3_le_dan		;877a
	ld bc,008f8h		;877c   ; ...y en X?
	call cerca_x1		;877f   ; cerca_x1
	jr nc,tipo3_le_dan		;8782
	ld a,(0e197h)		;8784   ; saltando de lado?
	and a			;8787
	jr nz,tipo3_cae		;8788   ; si: le tumba
	ld a,002h		;878a   ; tocado: 0xE183 = 2
	ld (0e183h),a		;878c
	ret			;878f
tipo3_le_dan:		; Lo que tira el protagonista (0xE108), con 0xE19B, le da?
	ld a,(0e19bh)		;8790   ; una estrella en vuelo?
	and a			;8793
	jp z,otro_fuera		;8794
	ld bc,002f2h		;8797   ; le da en X?
	call cerca_x		;879a
	jr nc,tipo3_fuera		;879d
	ld bc,008f8h		;879f
	call cerca_x2		;87a2   ; cerca_x2
	jr nc,tipo3_fuera		;87a5
	ld a,(0e00ah)		;87a7   ; desde la fase 4, la estrella se acaba
	cp 004h		;87aa
	jr nc,tipo3_quita		;87ac
	ld a,(0e1b4h)		;87ae   ; con el objeto 0x6A, la estrella sigue
	and a			;87b1
	jr nz,tipo3_cae		;87b2
tipo3_quita:		; Lo del protagonista fuera (Y 0xF0)
	ld (ix+008h),0f0h		;87b4
	ld (ix+009h),000h		;87b8
tipo3_cae:		; Cae: el efecto 2, una espera, uno mas en la cuenta de 0xE1B2 (en la pantalla, fila 1, columna 15) y sus puntos
	ld a,002h		;87bc   ; el efecto 2
	call efecto_pide		;87be
	ld (iy+008h),01ch		;87c1   ; una espera de 28 cuadros
	inc (iy+005h)		;87c5   ; el estado 2 (cayendo)
	ld a,(0e1b2h)		;87c8   ; uno mas
	inc a			;87cb
	ld (0e1b2h),a		;87cc
	ld hl,0182fh		;87cf   ; la cuenta en la fila 1, columna 15...
	call 0004dh		;87d2   ; WRTVRM
	ld a,(0e1b2h)		;87d5   ; 10?
	cp 00ah		;87d8
	jr c,tipo3_puntos		;87da
	xor a			;87dc   ; 10: 0 y 1 delante
	call 0004dh		;87dd   ; WRTVRM: el 0...
	dec hl			;87e0   ; ...y delante...
	ld a,001h		;87e1
	call 0004dh		;87e3   ; ...el 1
	ld a,(0e00ah)		;87e6   ; en la fase 1, 0xE1D1 = 1: ya se puede salir
	cp 001h		;87e9
	jr nz,tipo3_puntos		;87eb
	ld (0e1d1h),a		;87ed
tipo3_puntos:		; En partida: el tipo 8 o en la fase 1, 10 puntos; si no, 5
	ld a,(0e000h)		;87f0   ; en partida?
	and a			;87f3
	ret z			;87f4
	ld a,(iy+004h)		;87f5   ; el tipo 8?
	cp 008h		;87f8
	jr nz,tipo3_puntos5		;87fa
tipo3_puntos10:
	ld a,010h		;87fc   ; 10 puntos
	jr tipo3_puntos_pon		;87fe
tipo3_puntos5:
	ld a,(0e00ah)		;8800   ; la fase 1?
	cp 001h		;8803
	jr z,tipo3_puntos10		;8805
	ld a,005h		;8807   ; 5 puntos
tipo3_puntos_pon:
	jp puntos		;8809   ; a los puntos
tipo3_fuera:
	jp otro_fuera		;880c
tipo3_estado2:		; El estado 2: cayendo hasta acabar la espera
	cp 002h		;880f   ; el estado 2?
	jp nz,tipo3_estado3		;8811
	dec (iy+008h)		;8814   ; la espera...
	ld a,(iy+008h)		;8817
	and a			;881a
	jp z,otro_borra		;881b   ; acabada: borrado
	ld (iy+009h),000h		;881e   ; +9 = 0...
	ld (iy+006h),088h		;8822   ; ...+6 = 0x88: el dibujo de caer
	ld a,(0e01fh)		;8826   ; cada 8 cuadros
	and 008h		;8829
	call tipo3_dibujo		;882b   ; su dibujo
	jp otro_fuera		;882e   ; fuera?
tipo3_dibujo:		; Su dibujo: +6 + el lado + el paso (bit 0 de +8) x 4 + A; y su color segun el estado y el tipo
	ld b,a			;8831   ; el paso (0 u 8)
	ld a,(iy+009h)		;8832   ; + el lado (0 o 0x10)
	add a,b			;8835
	ld b,a			;8836
	ld a,(iy+008h)		;8837   ; + el bit 0 de la espera x 4
	and 001h		;883a
	rlca			;883c
	rlca			;883d
	add a,b			;883e
	ld b,a			;883f
	ld a,(iy+006h)		;8840   ; + la base (+6)
	add a,b			;8843
	ld (iy+002h),a		;8844   ; el dibujo
	ld a,(iy+008h)		;8847   ; en los impares...
	and 001h		;884a
	jr nz,tipo3_color11		;884c   ; ...color 11
	ld a,(iy+005h)		;884e   ; cayendo (estado 2)?
	cp 002h		;8851
	jr nz,tipo3_color		;8853
	ld (iy+003h),00fh		;8855   ; color 15
	ret			;8859
tipo3_color:
	ld a,(0e00ah)		;885a   ; en la fase 3 con el objeto 0x6A...
	cp 003h		;885d
	jr nz,tipo3_color_tipo		;885f
	ld a,(0e1b4h)		;8861
	and a			;8864
	jr z,tipo3_color_tipo		;8865
	ld (iy+003h),00ah		;8867   ; ...color 10
	ret			;886b
tipo3_color_tipo:		; 13; el tipo 5, 14; el tipo 8, 3
	ld a,(iy+004h)		;886c   ; el tipo 5?
	cp 005h		;886f
	jr z,tipo3_color14		;8871
	cp 008h		;8873   ; el tipo 8?
	jr z,tipo3_color3		;8875
	ld (iy+003h),00dh		;8877   ; color 13
	ret			;887b
tipo3_color11:
	ld (iy+003h),00bh		;887c   ; color 11
	ret			;8880
tipo3_color14:
	ld (iy+003h),00eh		;8881   ; color 14
	ret			;8885
tipo3_color3:
	ld (iy+003h),003h		;8886   ; color 3
	ret			;888a
suelo:		; Lo que tiene debajo (el mapa de la fase en 0xE720/0xE760): sin suelo (0x6C), cae (el estado 2); contra una pared (0x40), se da la vuelta
	ld a,(0e00ah)		;888b   ; la fase 5?
	cp 005h		;888e
	jr nz,suelo_otras		;8890
	ld a,(0e19ah)		;8892   ; su fila en el mapa
	ld b,a			;8895
	ld de,(0e1ceh)		;8896   ; el ancho
	ld hl,0e720h		;889a   ; desde la fila 1 del mapa
suelo_fila:
	add hl,de			;889d
	djnz suelo_fila		;889e
	push hl			;88a0
	ld a,(iy+000h)		;88a1   ; su Y / 8...
	call fila8		;88a4
	call filas_por_ancho		;88a7   ; ...filas
	pop hl			;88aa
	add hl,de			;88ab   ; la fila de sus pies
	ld a,(iy+001h)		;88ac   ; su X / 8
	call fila8		;88af
	jr suelo_casilla		;88b2
suelo_otras:
	ld a,(iy+000h)		;88b4   ; en las otras: su Y / 8...
	call fila8		;88b7
	call filas_por_ancho		;88ba   ; ...filas...
	ld hl,0e760h		;88bd   ; ...desde la fila 2 (0xE760)
	add hl,de			;88c0
	ld a,(iy+001h)		;88c1   ; su X / 8...
	call fila8		;88c4
	ld a,(0e193h)		;88c7   ; ...+ la columna corrida
	add a,b			;88ca
suelo_casilla:
	add a,l			;88cb   ; la casilla
	jr nc,suelo_casilla_hl		;88cc
	inc h			;88ce
suelo_casilla_hl:
	ld l,a			;88cf
	ld a,(hl)			;88d0   ; 0x6C?
	cp 06ch		;88d1
	jr nz,suelo_lado		;88d3
	inc hl			;88d5   ; la de la derecha
	ld a,(hl)			;88d6   ; y la de al lado?
	cp 06ch		;88d7
	jr nz,vuelta_der		;88d9
	ld (iy+005h),002h		;88db   ; las dos: el estado 2 (cae)...
	ld (iy+008h),01ch		;88df   ; ...28 cuadros...
	ld a,(iy+000h)		;88e3   ; ...y 6 puntos abajo
	add a,006h		;88e6
	ld (iy+000h),a		;88e8
	jr suelo_fin		;88eb
fila8:		; B = A / 8
	and 0f8h		;88ed   ; la Y o la X...
	rrca			;88ef   ; ...entre 8
	rrca			;88f0
	rrca			;88f1
	ld b,a			;88f2
	ret			;88f3
suelo_lado:		; La de al lado: una pared?
	inc hl			;88f4   ; la siguiente a la derecha
	ld a,(hl)			;88f5
	cp 06ch		;88f6   ; un agujero: hacia la izquierda
	jr z,vuelta_izq		;88f8
	ld a,(iy+009h)		;88fa   ; hacia donde va?
	and a			;88fd
	jr z,suelo_izq		;88fe
	inc hl			;8900   ; a la derecha: la de mas alla
suelo_pared:
	ld de,(0e1ceh)		;8901   ; una fila arriba...
	and a			;8905
	sbc hl,de		;8906
	ld a,(hl)			;8908
	cp 040h		;8909   ; ...un muro (0x40)?
	jr nz,suelo_fin		;890b
	ld (iy+008h),030h		;890d   ; una espera de 48...
	ld a,(iy+009h)		;8911   ; ...y la vuelta
	and a			;8914
	jr z,vuelta_der		;8915
	jr vuelta_izq		;8917
suelo_izq:
	dec hl			;8919   ; a la izquierda: la de antes
	jr suelo_pared		;891a
vuelta_izq:		; Se da la vuelta: hacia la izquierda
	ld (iy+009h),000h		;891c   ; X va a menos
	jr suelo_fin		;8920
vuelta_der:		; Hacia la derecha
	ld (iy+009h),010h		;8922   ; X va a mas
suelo_fin:
	ret			;8926
tipo3_estado3:		; El estado 3: parpadea 64 cuadros (dibujos 0x70/0x74, colores 2/11)
	cp 003h		;8927   ; el estado 3?
	jp nz,tipo3_estado4		;8929
	inc (iy+00dh)		;892c   ; la cuenta
	ld a,(iy+00dh)		;892f
	cp 040h		;8932   ; 64?
	jr c,tipo3_estado3_dibujo		;8934
	inc (iy+005h)		;8936   ; el estado 4
	ret			;8939
tipo3_estado3_dibujo:
	ld a,(iy+00dh)		;893a   ; en los impares...
	and 001h		;893d
	ld b,a			;893f
	rlca			;8940
	rlca			;8941
	add a,070h		;8942   ; ...0x74; en los pares 0x70
	ld (iy+002h),a		;8944
	ld a,b			;8947   ; los pares...
	and a			;8948
	jr nz,tipo3_estado3_color		;8949
	ld (iy+003h),002h		;894b   ; ...color 2
	ret			;894f
tipo3_estado3_color:
	ld (iy+003h),00bh		;8950   ; color 11
	ret			;8954
tipo3_estado4:		; El estado 4: cada tanto (al azar) salta hacia el protagonista con el efecto 7; cae por los huecos; si toca, 0xE183 = 1
	dec (iy+00dh)		;8955   ; la espera, uno menos
	ld a,(iy+00dh)		;8958
	and a			;895b
	jr nz,tipo3_estado4_suelo		;895c
	ld a,007h		;895e   ; el efecto 7
	call efecto_pide		;8960   ; el efecto 7
	ld a,r		;8963   ; la espera al azar
	and 03fh		;8965   ; 32-95...
	add a,030h		;8967   ; ...+ 0x30
	ld (iy+00dh),a		;8969
	ld a,(ix+001h)		;896c   ; el protagonista, a un lado u otro
	ld b,(iy+001h)		;896f
	cp b			;8972   ; a su izquierda?
	jr c,tipo3_salto_izq		;8973
	ld a,008h		;8975   ; salta 8 a la derecha
	jr tipo3_salto		;8977
tipo3_salto_izq:
	ld a,0f8h		;8979   ; 8 a la izquierda
tipo3_salto:
	ld b,(iy+001h)		;897b   ; su X + eso
	add a,b			;897e
	ld (iy+001h),a		;897f
tipo3_estado4_suelo:
	call suelo		;8982   ; el suelo
	ld a,(iy+005h)		;8985   ; cae?
	cp 002h		;8988
	jr nz,tipo3_estado4_dibujo		;898a
	ld a,(0e000h)		;898c   ; en partida?
	and a			;898f
	jr z,tipo3_estado4_dibujo		;8990
	ld a,002h		;8992   ; al caer: el efecto 2 y 100 puntos
	call efecto_pide		;8994
	ld a,001h		;8997   ; 100 puntos
	call puntos_centenas		;8999
tipo3_estado4_dibujo:		; Los dibujos 0xB8 (color 3) y 0xBC (color 6)
	ld a,(iy+00dh)		;899c   ; los impares...
	and 001h		;899f
	and a			;89a1
	jr nz,tipo3_estado4_dibujo2		;89a2
	ld (iy+002h),0b8h		;89a4   ; 0xB8...
	ld (iy+003h),003h		;89a8   ; ...color 3
	jr tipo3_estado4_toca		;89ac
tipo3_estado4_dibujo2:
	ld (iy+002h),0bch		;89ae   ; 0xBC...
	ld (iy+003h),006h		;89b2   ; ...color 6
tipo3_estado4_toca:
	ld bc,00cf4h		;89b6   ; toca al protagonista?
	call cerca_y		;89b9
	jr nc,tipo3_estado4_fuera		;89bc
	ld bc,00bf5h		;89be   ; en X?
	call cerca_x1		;89c1
	jr nc,tipo3_estado4_fuera		;89c4
	ld a,001h		;89c6   ; tocado
	ld (0e183h),a		;89c8
tipo3_estado4_fuera:
	ld a,(iy+001h)		;89cb   ; por la derecha?
	cp 0f0h		;89ce
	jr c,tipo3_bajo		;89d0
tipo3_borra:
	jp otro_borra		;89d2
tipo3_bajo:
	ld a,(iy+000h)		;89d5   ; abajo del todo (0xBE)?
	cp 0beh		;89d8
	ret c			;89da
	jr tipo3_borra		;89db
tipo4:		; Los tipos 4 y 7 (lo que tiran los otros): 2 puntos por cuadro; si toca al protagonista, 0xE183 = 1; si da con lo del protagonista, los dos se van
	ld a,(0e183h)		;89dd   ; el protagonista ya tocado?
	and a			;89e0
	ret nz			;89e1
	ld a,(iy+009h)		;89e2   ; hacia la derecha?
	and a			;89e5
	jr nz,tipo4_derecha		;89e6
	dec (iy+001h)		;89e8   ; 2 a la izquierda
	dec (iy+001h)		;89eb
	jr tipo4_dibujo		;89ee
tipo4_derecha:
	inc (iy+001h)		;89f0   ; 2 a la derecha
	inc (iy+001h)		;89f3
tipo4_dibujo:		; El tipo 7: 0x9C/0xA0; el 4: 0xA4/0xA8
	ld a,(iy+004h)		;89f6   ; el tipo 4?
	cp 004h		;89f9
	jr z,tipo4_dibujo4		;89fb
	ld a,(0e01fh)		;89fd   ; 0x9C o 0xA0 cada 4 cuadros
	and 004h		;8a00
	add a,09ch		;8a02
	ld (iy+002h),a		;8a04
	jr tipo4_toca		;8a07
tipo4_dibujo4:
	ld a,(0e01fh)		;8a09   ; 0xA4 o 0xA8
	and 004h		;8a0c
	add a,0a4h		;8a0e
	ld (iy+002h),a		;8a10
tipo4_toca:
	ld bc,008f8h		;8a13   ; toca al protagonista: en X...
	call cerca_x1		;8a16
	jr nc,tipo4_choca		;8a19
	ld bc,008ffh		;8a1b   ; ...y en Y?
	call cerca_y		;8a1e
	jr nc,tipo4_choca		;8a21
	ld a,001h		;8a23   ; tocado
	ld (0e183h),a		;8a25
	ret			;8a28
tipo4_choca:		; Contra lo del protagonista: el efecto 3 y fuera
	ld bc,006fah		;8a29   ; la estrella le da?
	call cerca_x2		;8a2c
	jr nc,tipo4_sigue		;8a2f
	ld bc,006fah		;8a31
	call cerca_x		;8a34
	jr nc,tipo4_sigue		;8a37
	ld a,003h		;8a39   ; el efecto 3
	call efecto_a_pide		;8a3b
	ld a,(0e00ah)		;8a3e   ; desde la fase 4 la estrella se acaba...
	cp 004h		;8a41
	jr nc,tipo4_quita		;8a43
	ld a,(0e1b4h)		;8a45   ; ...antes, con el objeto 0x6A, sigue
	and a			;8a48
	jr z,tipo4_quita		;8a49
	jr tipo4_fuera		;8a4b
tipo4_quita:
	ld (ix+008h),0f0h		;8a4d   ; la estrella fuera
	ld (ix+009h),000h		;8a51
tipo4_fuera:
	ld (iy+001h),0feh		;8a55   ; fuera por la derecha (X 0xFE)
tipo4_sigue:
	jp otro_fuera		;8a59
tipo6:		; El tipo 6: cae desde arriba (Y 0x38) en una de cuatro columnas al azar (0x18, 0x40, 0xB0, 0xD8), espera 16 cuadros y baja hacia el protagonista
	ld a,(0e183h)		;8a5c   ; el protagonista ya tocado?
	and a			;8a5f
	ret nz			;8a60
	ld a,(iy+005h)		;8a61   ; ya ha salido?
	and a			;8a64
	jr nz,tipo6_espera		;8a65
	inc (iy+005h)		;8a67   ; ya ha salido
	ld a,r		;8a6a   ; al azar...
	and 003h		;8a6c   ; 0-3
	and a			;8a6e
	jr z,tipo6_18		;8a6f   ; 0: la columna 0x18
	cp 001h		;8a71   ; 1: 0x40
	jr z,tipo6_40		;8a73
	cp 002h		;8a75   ; 2: 0xB0
	jr z,tipo6_b0		;8a77
	ld a,0d8h		;8a79   ; 3: 0xD8
	jr tipo6_pon		;8a7b
tipo6_b0:
	ld a,0b0h		;8a7d   ; 0xB0
	jr tipo6_pon		;8a7f
tipo6_40:
	ld a,040h		;8a81   ; 0x40
	jr tipo6_pon		;8a83
tipo6_18:
	ld a,018h		;8a85   ; 0x18
tipo6_pon:		; Su sitio, el dibujo 0x98, color 11, y hacia donde baja segun el protagonista (+7, 0-4)
	ld (iy+001h),a		;8a87   ; la X
	ld (iy+000h),038h		;8a8a   ; Y 0x38
	ld (iy+002h),098h		;8a8e   ; el dibujo 0x98...
	ld (iy+003h),00bh		;8a92   ; ...color 11
	ld c,000h		;8a96   ; 0: recto
	ld a,(iy+001h)		;8a98   ; su X menos la del protagonista
	sub (ix+001h)		;8a9b
	cp 008h		;8a9e   ; menos de 8: recto
	jr c,tipo6_dir		;8aa0
	inc c			;8aa2   ; 1: un poco a la izquierda
	cp 040h		;8aa3
	jr c,tipo6_dir		;8aa5
	inc c			;8aa7   ; 2: mas a la izquierda
	cp 080h		;8aa8
	jr c,tipo6_dir		;8aaa
	inc c			;8aac   ; 3: mucho a la derecha
	cp 0c0h		;8aad
	jr c,tipo6_dir		;8aaf
	inc c			;8ab1   ; 4: un poco a la derecha
	cp 0f8h		;8ab2
	jr c,tipo6_dir		;8ab4
	ld c,000h		;8ab6   ; casi encima: recto
tipo6_dir:
	ld (iy+007h),c		;8ab8   ; en +7
	ret			;8abb
tipo6_espera:		; El estado 1: 16 cuadros y el dibujo 0xA4, color 9
	cp 001h		;8abc   ; el estado 1?
	jr nz,tipo6_baja		;8abe
	inc (iy+008h)		;8ac0   ; la espera
	ld a,(iy+008h)		;8ac3
	cp 010h		;8ac6   ; 16?
	ret c			;8ac8
	ld (iy+002h),0a4h		;8ac9   ; el dibujo 0xA4...
	ld (iy+003h),009h		;8acd   ; ...color 9
	inc (iy+005h)		;8ad1   ; el estado 2
	ret			;8ad4
tipo6_baja:		; Baja 2 puntos por cuadro y de lado segun +7
	ld a,(iy+007h)		;8ad5   ; de lado?
	and a			;8ad8   ; 0: recto
	jr z,tipo6_abajo		;8ad9
	cp 001h		;8adb   ; 1: un punto a la izquierda
	jr z,tipo6_izq1		;8add
	cp 002h		;8adf   ; 2: dos
	jr z,tipo6_izq2		;8ae1
	cp 003h		;8ae3   ; 3: dos a la derecha
	jr z,tipo6_der2		;8ae5
	cp 004h		;8ae7   ; 4: uno a la derecha
	jr z,tipo6_der1		;8ae9
tipo6_abajo:
	inc (iy+000h)		;8aeb   ; 2 abajo
	inc (iy+000h)		;8aee
	jr tipo6_dibujo		;8af1
tipo6_izq1:
	dec (iy+001h)		;8af3   ; 1 a la izquierda
	jr tipo6_abajo		;8af6
tipo6_izq2:
	dec (iy+001h)		;8af8   ; 2 a la izquierda
	jr tipo6_izq1		;8afb
tipo6_der2:
	inc (iy+001h)		;8afd   ; 2 a la derecha
tipo6_der1:
	inc (iy+001h)		;8b00   ; 1 a la derecha
	jr tipo6_abajo		;8b03
tipo6_dibujo:
	jp tipo4_dibujo		;8b05   ; el dibujo y si toca, como el tipo 4
pantalla_juego:		; La pantalla del juego: apagada, en blanco, la fase, el marcador y las casillas del juego en los tres tercios
	call 00041h		;8b08   ; DISSCR
	call ram_borra		;8b0b   ; la RAM del juego a cero
	call pantalla_borra		;8b0e   ; la pantalla en blanco
	call tiempo_1100		;8b11   ; TIME 1100
	xor a			;8b14
	ld (0e046h),a		;8b15   ; los botones a 0
	ld (0e040h),a		;8b18
	ld (0e042h),a		;8b1b
	ld (0e044h),a		;8b1e
	ld (0e180h),a		;8b21
	ld de,00180h		;8b24   ; las casillas del juego desde la 0x30, en los tres tercios
	call vram_casillas_a800		;8b27
	ld de,00980h		;8b2a   ; el segundo tercio
	call vram_casillas_a800		;8b2d
	ld de,01180h		;8b30   ; el tercero
	call vram_casillas_a800		;8b33
	ld de,02180h		;8b36   ; y sus colores
	call vram_casillas_b000		;8b39
	ld de,02980h		;8b3c   ; el segundo tercio
	call vram_casillas_b000		;8b3f
	ld de,03180h		;8b42   ; el tercero
	call vram_casillas_b000		;8b45
	jp sprites_dibujos		;8b48   ; los dibujos de los sprites
espera_musica:		; 8 cuadros, y espera a que acabe la musica (o el boton en la demostracion); despues el sonido callado y 16 cuadros
	xor a			;8b4b   ; la cuenta a 0
	ld (0e011h),a		;8b4c
espera_musica8:
	ld a,(0e011h)		;8b4f   ; 8 cuadros
	cp 008h		;8b52
	jr c,espera_musica8		;8b54
espera_musica_va:
	ld a,(0e000h)		;8b56   ; en partida?
	and a			;8b59
	jr nz,espera_musica_suena		;8b5a
	ld a,(0e046h)		;8b5c   ; el boton?
	and a			;8b5f
	ret nz			;8b60
espera_musica_suena:
	ld a,(0e2bdh)		;8b61   ; una musica sonando?
	and a			;8b64
	jr nz,espera_musica_va		;8b65
	ld a,(0e2beh)		;8b67   ; o pedida?
	and a			;8b6a
	jr nz,espera_musica_va		;8b6b
	ld (0e011h),a		;8b6d   ; la cuenta a 0
	call sonido_pide_calla		;8b70   ; el sonido callado
espera_musica16:
	ld a,(0e011h)		;8b73   ; 16 cuadros
	cp 010h		;8b76
	jr c,espera_musica16		;8b78
	ret			;8b7a
tocado:		; El protagonista tocado (0xE183): desde la fase 4 con 0xE1B4, nada; si no, la musica 5, se queda parado y cae; una vida menos
	ld a,(0e1b4h)		;8b7b   ; el objeto 0x6A (0xE1B4)?
	and a			;8b7e
	jr z,tocado_va		;8b7f
	ld a,(0e00ah)		;8b81   ; desde la fase 4: el objeto 0x6A hace al protagonista intocable
	cp 004h		;8b84
	jr c,tocado_va		;8b86
	xor a			;8b88   ; nada
	ld (0e183h),a		;8b89
	jp fase_cuadro		;8b8c
tocado_va:
	call sonido_pide_calla		;8b8f   ; el sonido callado
	xor a			;8b92   ; la cuenta a 0
	ld (0e011h),a		;8b93
tocado_espera2:
	ld a,(0e011h)		;8b96   ; 2 cuadros
	cp 002h		;8b99
	jr c,tocado_espera2		;8b9b
	ld a,005h		;8b9d   ; la musica 5
	call musica_pide		;8b9f
	xor a			;8ba2   ; la otra cuenta a 0
	ld (0e012h),a		;8ba3
tocado_cuadro:		; Un cuadro: los otros se mueven, el protagonista parpadea (los dibujos 0x88/0x90)
	ld a,(0e011h)		;8ba6   ; un cuadro
	cp 001h		;8ba9
	jr c,tocado_cuadro		;8bab
	xor a			;8bad
	ld (0e011h),a		;8bae
	call otros		;8bb1   ; los otros
	call sprites_tabla		;8bb4   ; a la tabla
	call sprites_vram		;8bb7   ; los sprites a la VRAM
	ld a,(0e013h)		;8bba   ; 0x88 o 0x90 cada 8 cuadros
	and 008h		;8bbd
	add a,088h		;8bbf
	ld (ix+002h),a		;8bc1   ; el primero
	add a,004h		;8bc4   ; y el segundo, + 4
	ld (ix+006h),a		;8bc6
	ld a,(0e183h)		;8bc9   ; 0xE183 = 5 (de una caida)?
	cp 005h		;8bcc
	jr nz,tocado_espera		;8bce
	ld a,(0e1c7h)		;8bd0   ; 32 cuadros quieto...
	inc a			;8bd3
	ld (0e1c7h),a		;8bd4
	cp 020h		;8bd7   ; 32?
	jr c,tocado_cuadro		;8bd9
	cp 028h		;8bdb   ; 40?
	jr nc,tocado_espera		;8bdd
	inc (ix+000h)		;8bdf   ; ...y despues cae 8
	inc (ix+004h)		;8be2
	jr tocado_cuadro		;8be5
tocado_espera:		; 64 cuadros
	ld a,(0e012h)		;8be7   ; 64 cuadros
	cp 040h		;8bea
	jr c,tocado_cuadro		;8bec
	call sonido_pide_calla		;8bee   ; el sonido callado
tocado_fin:
	ld a,(0e012h)		;8bf1   ; y 3 mas
	cp 043h		;8bf4
	jr c,tocado_fin		;8bf6
	ld a,(0e00bh)		;8bf8   ; quedan vidas?
	and a			;8bfb
	jp z,game_over		;8bfc
	dec a			;8bff   ; una menos...
	ld (0e00bh),a		;8c00
	jp fase		;8c03   ; ...y la fase otra vez
game_over:		; GAME OVER (0x8F6B) en la fila 10, columna 12, la musica 1 y al titulo
	call ram_sprites		;8c06   ; los sprites fuera
	ld de,0194ch		;8c09   ; en la fila 10, columna 12
	ld hl,08f6bh		;8c0c   ; GAME OVER
	ld bc,00009h		;8c0f
	call 0005ch		;8c12   ; LDIRVM
	ld a,001h		;8c15   ; la musica 1
	call musica_pide		;8c17
	call espera_musica		;8c1a   ; espera a que acabe
	xor a			;8c1d   ; sin demostracion...
	ld (0e048h),a		;8c1e
	ld (0e000h),a		;8c21   ; ...ni partida
	ld (0e046h),a		;8c24
	jp titulo		;8c27   ; al titulo
puerta_izq:		; Cinco filas de la puerta, una casilla a la izquierda (en el mapa de la RAM)
	ld b,005h		;8c2a   ; cinco filas
puerta_izq_fila:
	ld a,(hl)			;8c2c   ; la casilla...
	ld (hl),010h		;8c2d   ; ...en blanco...
	dec hl			;8c2f
	ld (hl),a			;8c30   ; ...una a la izquierda
	ld de,00021h		;8c31   ; la fila siguiente (0x20 + 1)
	add hl,de			;8c34
	djnz puerta_izq_fila		;8c35
	ret			;8c37
puerta_der:		; Cinco filas, una casilla a la derecha, y el mapa a la pantalla
	ld b,005h		;8c38   ; cinco filas
puerta_der_fila:
	ld a,(hl)			;8c3a   ; la casilla...
	ld (hl),010h		;8c3b   ; ...en blanco...
	inc hl			;8c3d
	ld (hl),a			;8c3e   ; ...una a la derecha
	ld de,0001fh		;8c3f   ; la fila siguiente (0x20 - 1)
	add hl,de			;8c42
	djnz puerta_der_fila		;8c43
	call mapa_pantalla		;8c45   ; a la pantalla
	ret			;8c48
fase_fin:		; La fase acaba (0xE186): en la fase 1, la puerta del castillo se abre, el protagonista sube y entra; despues TIME a puntos y la fase siguiente
	call ram_sprites		;8c49   ; los sprites fuera
	ld a,(0e00ah)		;8c4c   ; la fase 1?
	cp 001h		;8c4f
	jp nz,fin_cuenta		;8c51
	ld a,003h		;8c54   ; la musica 3
	call musica_pide		;8c56
	xor a			;8c59
	ld (0e011h),a		;8c5a
puerta_espera:		; 32 cuadros
	ld a,(0e011h)		;8c5d   ; 32 cuadros
	cp 020h		;8c60
	jr c,puerta_espera		;8c62
	xor a			;8c64
	ld (0e011h),a		;8c65
	ld a,(0e1d1h)		;8c68   ; la puerta, un paso (0xE1D1: 1 y 2)
	cp 001h		;8c6b
	jr nz,puerta_paso2		;8c6d
	inc a			;8c6f   ; el paso 2
	ld (0e1d1h),a		;8c70
	ld hl,0e76fh		;8c73   ; la hoja de la izquierda (fila 3, columna 15)...
	call puerta_izq		;8c76
	ld hl,0e770h		;8c79   ; ...y la de la derecha
	call puerta_der		;8c7c
	jr puerta_espera		;8c7f
puerta_paso2:
	cp 002h		;8c81   ; el paso 2?
	jr nz,puerta_sube		;8c83
	inc a			;8c85   ; el paso 3
	ld (0e1d1h),a		;8c86
	ld hl,0e76eh		;8c89   ; otra casilla mas afuera
	call puerta_izq		;8c8c
	ld hl,0e771h		;8c8f
	call puerta_der		;8c92
puerta_sube:		; El protagonista sube hasta Y 0x3C, con sus dibujos 0x28/0x30
	ld a,(0e011h)		;8c95   ; un cuadro
	cp 001h		;8c98
	jr c,puerta_sube		;8c9a
	xor a			;8c9c
	ld (0e011h),a		;8c9d
	call sprites_vram		;8ca0   ; los sprites a la VRAM
	dec (ix+000h)		;8ca3   ; un punto arriba
	dec (ix+004h)		;8ca6
	ld a,(0e010h)		;8ca9   ; 0x28 o 0x30 cada 8 cuadros
	and 008h		;8cac
	add a,028h		;8cae
	ld (ix+002h),a		;8cb0
	add a,004h		;8cb3
	ld (ix+006h),a		;8cb5
	ld a,(ix+000h)		;8cb8   ; arriba del todo (0x3C)?
	cp 03ch		;8cbb
	jr nc,puerta_sube		;8cbd
	ld (ix+000h),0e8h		;8cbf   ; dentro: fuera de la pantalla
	ld (ix+004h),0e8h		;8cc3
	call sprites_vram		;8cc7   ; a la VRAM
	ld hl,0e76dh		;8cca   ; la puerta abierta (0x91EA): 5 filas de 6
	ld de,091eah		;8ccd   ; de 0x91EA
	ld b,005h		;8cd0
puerta_fila:
	ld c,006h		;8cd2   ; seis casillas
puerta_casilla:
	ld a,(de)			;8cd4
	ld (hl),a			;8cd5
	inc hl			;8cd6
	inc de			;8cd7
	dec c			;8cd8
	jr nz,puerta_casilla		;8cd9
	push de			;8cdb
	ld de,0001ah		;8cdc   ; la fila siguiente (0x20 - 6)
	add hl,de			;8cdf
	pop de			;8ce0
	djnz puerta_fila		;8ce1
	call mapa_pantalla		;8ce3   ; el mapa a la pantalla
fin_cuenta:		; TIME baja de uno en uno: cada uno, un punto (en la fase 1 o sin nada en 0xE1B2, 0); a cero, la fase siguiente
	ld a,003h		;8ce6   ; la musica 3
	call musica_pide		;8ce8
	ld a,(0e080h)		;8ceb   ; las unidades?
	cp 000h		;8cee
	jr nz,fin_unidad		;8cf0
	ld a,(0e081h)		;8cf2   ; las decenas?
	cp 000h		;8cf5
	jr nz,fin_decena		;8cf7
	ld a,(0e082h)		;8cf9   ; las centenas?
	cp 000h		;8cfc
	jr nz,fin_centena		;8cfe
	jr fase_siguiente		;8d00   ; TIME a 0: la fase siguiente
fin_unidad:
	dec a			;8d02   ; una unidad menos
	ld (0e080h),a		;8d03
	jr fin_puntos		;8d06
fin_decena:
	dec a			;8d08   ; una decena menos...
	ld (0e081h),a		;8d09
	ld a,009h		;8d0c   ; ...y las unidades a 9
	ld (0e080h),a		;8d0e
	jr fin_puntos		;8d11
fin_centena:
	dec a			;8d13   ; una centena menos...
	ld (0e082h),a		;8d14
	ld a,009h		;8d17   ; ...y lo de abajo a 9
	ld (0e081h),a		;8d19
	ld (0e080h),a		;8d1c
fin_puntos:
	ld a,(0e00ah)		;8d1f   ; en la fase 1, 1 punto por unidad
	cp 001h		;8d22
	jr z,fin_puntos_pon		;8d24
	ld a,(0e1b2h)		;8d26   ; en las otras, tantos como otros tumbados (0xE1B2)...
	and a			;8d29
	jr nz,fin_puntos_pon		;8d2a
	inc a			;8d2c   ; ...y 1 si ninguno
fin_puntos_pon:
	call puntos		;8d2d   ; los puntos
	call tiempo_pinta		;8d30   ; TIME en la pantalla
	call marcador_cifras		;8d33   ; y los puntos
	jr fin_cuenta		;8d36
fase_siguiente:		; La fase siguiente: tras la 5, la 1 otra vez y una vuelta mas (0xE009, hasta 9)
	call espera_musica		;8d38   ; espera a que acabe la musica
	ld hl,0e00ah		;8d3b
	inc (hl)			;8d3e   ; una mas
	ld a,(hl)			;8d3f
	cp 006h		;8d40   ; pasa de 5?
	jp nz,fase		;8d42
	ld (hl),001h		;8d45   ; la 1...
	dec hl			;8d47   ; la vuelta
	inc (hl)			;8d48   ; ...y una vuelta mas
	ld a,(hl)			;8d49
	cp 00ah		;8d4a   ; pasa de 9?
	jp nz,fase		;8d4c
	ld (hl),000h		;8d4f   ; a 0
	jp fase		;8d51
marcador:		; El marcador: TIME y HISCORE (fila 0, columna 7), SCORE (fila 1, columna 19), las cifras y las vidas
	ld de,01807h		;8d54   ; en la fila 0, columna 7...
	ld hl,08f44h		;8d57   ; ...TIME:01 y HISCORE (25 casillas)
	ld bc,00019h		;8d5a
	call 0005ch		;8d5d   ; LDIRVM
	ld de,01833h		;8d60   ; en la fila 1, columna 19...
	ld hl,08f50h		;8d63   ; ...SCORE: 13 casillas desde 0x8F50, el HISCORE sin el HI
	ld bc,0000dh		;8d66
	call 0005ch		;8d69   ; LDIRVM
	call marcador_cifras		;8d6c   ; las cifras
	call fase_pinta		;8d6f   ; la fase
	call tiempo_vram		;8d72   ; TIME
	call vidas_pinta		;8d75   ; las vidas
	ld de,0182ch		;8d78   ; en la fila 1, columna 12...
	ld hl,08f5dh		;8d7b   ; ...el dibujo del ninja y ":00"
	ld bc,00004h		;8d7e
	call 0005ch		;8d81   ; LDIRVM
	ret			;8d84
tiempo:		; TIME baja: uno cada (7 - la vuelta, como poco 2) cuadros; con menos de 100, el efecto 1; a cero, OVER y la fase perdida (0xE183 = 40)
	ld a,(0e186h)		;8d85   ; la fase acaba?
	and a			;8d88
	ret nz			;8d89
	ld a,(0e183h)		;8d8a   ; tocado?
	and a			;8d8d
	ret nz			;8d8e
	ld a,(0e182h)		;8d8f   ; ya sin tiempo?
	and a			;8d92
	ret nz			;8d93
	ld a,(0e009h)		;8d94   ; la vuelta...
	cp 005h		;8d97
	jr c,tiempo_cada		;8d99
	ld a,005h		;8d9b   ; 5 como mucho
tiempo_cada:
	ld b,a			;8d9d
	ld a,007h		;8d9e   ; ...7 menos ella
	sub b			;8da0
	ld b,a			;8da1
	ld a,(0e010h)		;8da2   ; la cuenta de cuadros
	cp b			;8da5
	jp c,tiempo_vram		;8da6   ; aun no
	xor a			;8da9   ; la cuenta a 0
	ld (0e010h),a		;8daa
	ld hl,0e083h		;8dad   ; los millares a 0...
	cp (hl)			;8db0
	jr nz,tiempo_baja		;8db1
	dec hl			;8db3   ; ...y las centenas?
	cp (hl)			;8db4
	jr nz,tiempo_baja		;8db5
	inc a			;8db7   ; menos de 100: el efecto 1
	call efecto_pide		;8db8   ; el efecto 1
tiempo_baja:
	xor a			;8dbb
	ld hl,0e080h		;8dbc   ; las unidades?
	cp (hl)			;8dbf
	jr nz,tiempo_unidad		;8dc0
	inc hl			;8dc2   ; las decenas?
	cp (hl)			;8dc3
	jr nz,tiempo_decena		;8dc4
	inc hl			;8dc6   ; las centenas?
	cp (hl)			;8dc7
	jr nz,tiempo_centena		;8dc8
	inc hl			;8dca   ; los millares?
	cp (hl)			;8dcb
	jr nz,tiempo_millar		;8dcc
	ld (0e1b4h),a		;8dce   ; todo a 0: sin tiempo
	inc a			;8dd1   ; sin tiempo (0xE182)
	ld (0e182h),a		;8dd2
	ld a,(0e185h)		;8dd5   ; 0xE185 (nadie lo escribe: siempre 0)?
	and a			;8dd8
	jr nz,tiempo_over		;8dd9
	ld a,028h		;8ddb   ; la fase perdida: 0xE183 = 40
	ld (0e183h),a		;8ddd
tiempo_over:		; OVER (0x8F61)
	ld hl,08f61h		;8de0
	jp tiempo_vram_hl		;8de3   ; en el sitio de TIME
tiempo_millar:		; Un millar menos y las de abajo a 9
	dec (hl)			;8de6   ; el millar
	ld a,009h		;8de7   ; y las otras a 9
	dec hl			;8de9
	ld (hl),a			;8dea
tiempo_nueve2:
	dec hl			;8deb
	ld (hl),a			;8dec
tiempo_nueve1:
	dec hl			;8ded
	ld (hl),a			;8dee
	jr tiempo_pinta		;8def
tiempo_centena:		; Una centena menos
	dec (hl)			;8df1   ; la centena
	ld a,009h		;8df2
	jr tiempo_nueve2		;8df4
tiempo_decena:		; Una decena menos
	dec (hl)			;8df6   ; la decena
	ld a,009h		;8df7
	jr tiempo_nueve1		;8df9
tiempo_unidad:		; Una unidad menos
	dec (hl)			;8dfb   ; la unidad
tiempo_pinta:		; TIME en la pantalla: las cifras al reves en 0xE084 y los ceros de la izquierda, espacios (0x10)
	ld b,004h		;8dfc   ; cuatro cifras...
	ld de,0e087h		;8dfe   ; al reves...
	ld hl,0e080h		;8e01   ; ...al reves...
tiempo_copia:
	ld a,(hl)			;8e04   ; una cifra
	ld (de),a			;8e05   ; ...en 0xE084-0xE087
	inc hl			;8e06
	dec de			;8e07
	djnz tiempo_copia		;8e08   ; cuatro
	ld bc,00400h		;8e0a   ; los ceros de la izquierda: B = 4, C = 0x10 (el espacio)
	xor a			;8e0d
tiempo_ceros:
	cp (hl)			;8e0e   ; 0?
	jr nz,tiempo_vram		;8e0f
	ld (hl),c			;8e11   ; un espacio
	inc hl			;8e12   ; la siguiente
	djnz tiempo_ceros		;8e13
tiempo_vram:		; Cuatro casillas de 0xE084...
	ld hl,0e084h		;8e15   ; las cifras
tiempo_vram_hl:		; ...o de HL en la fila 1, columna 18
	ld de,0180ch		;8e18   ; en la fila 1, columna 18
	ld bc,00004h		;8e1b
	jp 0005ch		;8e1e
tiempo_1100:		; TIME a 1100 de partida: las cifras a 0 y luego 0xE083 y 0xE084 a 1 (TIME guarda al reves: 0xE080 las unidades)
	call tiempo_borra		;8e21   ; todo a 0
	ld a,001h		;8e24   ; un 1...
	ld (0e084h),a		;8e26   ; ...en la copia de los millares
	ld (0e083h),a		;8e29   ; ...y en las centenas
	ret			;8e2c
tiempo_borra:		; Las cifras de TIME y su copia a 0
	xor a			;8e2d   ; la copia y las cifras a 0...
	ld (0e087h),a		;8e2e   ; la copia...
	ld (0e086h),a		;8e31
	ld (0e085h),a		;8e34
	ld (0e080h),a		;8e37   ; ...y las cifras
	ld (0e081h),a		;8e3a
	ld (0e082h),a		;8e3d
	ret			;8e40
ram_borra:		; La RAM del juego de 0xE100 a 0xF07F a cero, los 32 sprites de 0xE300 fuera y todo a la VRAM
	ld hl,0e100h		;8e41   ; desde 0xE100...
	ld bc,00f80h		;8e44   ; ...0xF80 bytes
ram_sprites_borra:
	ld (hl),000h		;8e47   ; a cero
	inc hl			;8e49
	dec bc			;8e4a   ; los 16 bits...
	ld a,c			;8e4b   ; ...hasta 0
	or b			;8e4c
	jr nz,ram_sprites_borra		;8e4d
ram_sprites:		; Los 32 sprites de la RAM (0xE300, 16 bytes cada uno) con la Y fuera (0xF0) y pasados a la VRAM
	ld hl,0e300h		;8e4f   ; los sprites de la RAM...
	ld de,00010h		;8e52   ; ...de 16 en 16...
	ld b,020h		;8e55   ; ...32...
ram_sprites_fuera:
	ld (hl),0f0h		;8e57   ; ...con la Y fuera
	add hl,de			;8e59
	djnz ram_sprites_fuera		;8e5a
	call sprites_tabla		;8e5c   ; a la tabla de 4 bytes (0xE100)
	call sprites_vram		;8e5f   ; y a la VRAM
	ret			;8e62
pantalla_borra:		; La pantalla en blanco (la casilla 0x10) y los sprites fuera
	ld a,010h		;8e63   ; el espacio
	ld hl,01800h		;8e65   ; toda la tabla de nombres
	ld bc,00300h		;8e68   ; 768 casillas
	call 00056h		;8e6b   ; FILVRM
	ld hl,0e100h		;8e6e   ; la tabla de sprites que va a la VRAM...
	ld b,07fh		;8e71   ; ...127 bytes...
pantalla_borra_sprites:
	ld (hl),000h		;8e73   ; ...a cero
	inc hl			;8e75
	djnz pantalla_borra_sprites		;8e76
	call sprites_vram		;8e78   ; a la VRAM
	ret			;8e7b
vram_copia_pon:		; Las letras de la BIOS desde 0x1D3F (0x180 bytes: de "0" a "_") a DE en la VRAM, y DE al siguiente tercio
	push bc			;8e7c   ; el contador de tercios
	ld hl,01d3fh		;8e7d   ; de 0x1D3F (la BIOS)...
	ld bc,00180h		;8e80   ; ...0x180 bytes
vram_copia:		; LDIRVM y DE + 0x800: al mismo sitio del siguiente tercio
	call 0005ch		;8e83   ; LDIRVM: vuelve con HL = la VRAM y DE = la RAM + BC
	ld bc,00800h		;8e86   ; + 0x800...
vram_tercio:		; HL + BC en DE, y B (los tercios que faltan) de vuelta
	add hl,bc			;8e89
	ex de,hl			;8e8a   ; ...en DE
	pop bc			;8e8b
	ret			;8e8c
vram_casillas_a800:		; Las casillas 0xA800-0xADFF (0x600 bytes) a la VRAM (DE), y DE al siguiente tercio
	push bc			;8e8d
	ld hl,0a800h		;8e8e   ; de 0xA800...
	ld bc,00600h		;8e91   ; ...0x600 bytes
	jr vram_copia		;8e94
vram_casillas_b000:		; Lo mismo desde 0xB000 (0x600 bytes): los colores
	push bc			;8e96
	ld hl,0b000h		;8e97   ; de 0xB000...
	ld bc,00600h		;8e9a   ; ...0x600 bytes
	jr vram_copia		;8e9d
vram_fila:		; Una fila de 19 casillas de HL a DE en la VRAM y DE una fila mas abajo (+ 0x20)
	push bc			;8e9f
	ld bc,00013h		;8ea0   ; 19 casillas
	call 0005ch		;8ea3   ; LDIRVM
	ld bc,00020h		;8ea6   ; la siguiente fila
	jr vram_tercio		;8ea9
vram_llena8:		; FILVRM de 8 bytes con A en HL, y HL al siguiente tercio
	push bc			;8eab
	ld bc,00008h		;8eac   ; 8 bytes
vram_llena:		; FILVRM y HL + 0x800
	call 00056h		;8eaf   ; FILVRM
	ld de,00800h		;8eb2   ; el siguiente tercio
	add hl,de			;8eb5
	pop bc			;8eb6
	ret			;8eb7
vram_color_f0:		; 0x200 bytes de color 0xF0 (blanco sobre transparente) en HL, y HL al siguiente tercio
	push bc			;8eb8
	ld bc,00200h		;8eb9   ; 0x200 bytes...
	ld a,0f0h		;8ebc   ; ...de 0xF0
	jr vram_llena		;8ebe
vram_casillas_ae00:		; Las casillas 0xAE00-0xAFFF (0x200 bytes) a la VRAM (DE)
	push bc			;8ec0
	ld hl,0ae00h		;8ec1   ; de 0xAE00...
	ld bc,00200h		;8ec4   ; ...0x200 bytes
	jr vram_copia		;8ec7
sprites_dibujos:		; Los dibujos de los sprites (0xB800, 0x800 bytes) en 0x3800
	ld de,03800h		;8ec9   ; a 0x3800
	ld hl,0b800h		;8ecc   ; de 0xB800...
	ld bc,00800h		;8ecf   ; ...0x800 bytes
	jp 0005ch		;8ed2   ; LDIRVM
sonido_pide_calla:		; 0xE097 = 0xFF: la interrupcion callara el sonido en el siguiente cuadro
	ld a,0ffh		;8ed5   ; 0xFF...
	ld (0e097h),a		;8ed7   ; ...en 0xE097
	ret			;8eda

; ----------------------------------------------------------------------
; DATOS titulo_kanji: Las casillas de 伊賀忍法帖 en letras grandes: tres filas de
;   19 (cinco kanji de 3 x 3 con un espacio, 0x10), copiadas fila a fila a la
;   fila 8
;   0x8edb..0x8f14  (57 bytes)
DATA_titulo_kanji:
	defb 040h,041h,042h,010h,043h,047h,04bh,010h,052h,053h,054h,010h,05bh,05ch,05dh,010h	; 8edb  @AB.CGK.RST.[\].
	defb 064h,065h,066h,044h,045h,046h,010h,04ch,04dh,04eh,010h,055h,056h,057h,010h,05eh	; 8eeb  defDEF.LMN.UVW.^
	defb 05fh,060h,010h,067h,068h,069h,048h,049h,04ah,010h,04fh,050h,051h,010h,058h,059h	; 8efb  _`.ghiHIJ.OPQ.XY
	defb 05ah,010h,061h,062h,063h,010h,06ah,06bh,06ch	; 8f0b  Z.abc.jkl

; ----------------------------------------------------------------------
; DATOS titulo_casio: CASIO en seis casillas (0xEA-0xEF), en la fila 15
;   0x8f14..0x8f1a  (6 bytes)
DATA_titulo_casio:
	defb 0eah,0ebh,0ech,0edh,0eeh,0efh	; 8f14

; ----------------------------------------------------------------------
; DATOS texto_push: "PUSH TRIG:1 OR SPACE" en las casillas de letras (0x10
;   espacio, 0x11 A ... 0x2A Z, 0x0A dos puntos)
;   0x8f1a..0x8f2e  (20 bytes)
DATA_texto_push:
	defb 020h,025h,023h,018h,010h,024h,022h,019h,017h,00ah,001h,010h,01fh,022h,010h,023h	; 8f1a   %#..$"......".#
	defb 020h,011h,013h,015h	; 8f2a

; ----------------------------------------------------------------------
; DATOS texto_copyright: "COPYRIGHT 1985 (C) CASIO" (0xE9 es la C en un
;   circulo)
;   0x8f2e..0x8f44  (22 bytes)
DATA_texto_copyright:
	defb 013h,01fh,020h,029h,022h,019h,017h,018h,024h,010h,001h,009h,008h,005h,010h,0e9h	; 8f2e  .. )"...$.......
	defb 010h,013h,011h,023h,019h,01fh	; 8f3e

; ----------------------------------------------------------------------
; DATOS texto_time: "TIME:01" del marcador
;   0x8f44..0x8f4b  (7 bytes)
DATA_texto_time:
	defb 024h,019h,01dh,015h,00ah,000h,001h	; 8f44

; ----------------------------------------------------------------------
; DATOS texto_hiscore: "   HISCORE:000000" del marcador; SCORE es el mismo
;   texto desde 0x8F50, sin el HI
;   0x8f4b..0x8f5d  (18 bytes)
DATA_texto_hiscore:
	defb 010h,010h,010h,018h,019h,023h,013h,01fh,022h,015h,00ah,000h,000h,000h,000h,000h	; 8f4b  .....#..".......
	defb 000h,000h	; 8f5b

; ----------------------------------------------------------------------
; DATOS texto_vidas: 0xE7 (el dibujo del ninja) y ":00", las vidas del
;   marcador
;   0x8f5d..0x8f61  (4 bytes)
DATA_texto_vidas:
	defb 0e7h,00ah,000h,000h	; 8f5d

; ----------------------------------------------------------------------
; DATOS texto_over: "OVER100000", la linea del bonus de las vidas
;   0x8f61..0x8f6b  (10 bytes)
DATA_texto_over:
	defb 01fh,026h,015h,022h,001h,000h,000h,000h,000h,000h	; 8f61  .&."......

; ----------------------------------------------------------------------
; DATOS texto_game_over: "GAME OVER"
;   0x8f6b..0x8f74  (9 bytes)
DATA_texto_game_over:
	defb 017h,011h,01dh,015h,010h,01fh,026h,015h,022h	; 8f6b  ......&."

; ======================================================================
; CODIGO 0x8f74..0x915a  (486 bytes)
; ======================================================================


sprites_vram:		; Los 32 sprites a 0x1B00, de 0xE100; antes, la tabla de la RAM (16 bytes por sprite, desde 0xE300) se pasa a 4 bytes por sprite, en otro orden
	ld de,01b00h		;8f74   ; a 0x1B00...
	ld hl,0e100h		;8f77   ; ...desde 0xE100...
	ld bc,00080h		;8f7a   ; ...32 sprites
	call 0005ch		;8f7d   ; LDIRVM
	ret			;8f80
interrupcion:		; La interrupcion (H.TIMI): el sonido (callado si 0xE097 = 0xFF), 16 cuentas de cuadros (0xE010-0xE01F) y la palanca y los botones; en la demostracion, al azar
	ld a,(0e097h)		;8f81   ; callar el sonido?
	cp 0ffh		;8f84
	jr nz,interrupcion_sonido		;8f86   ; no
	call sonido_calla		;8f88   ; callado...
	xor a			;8f8b
	ld (0e097h),a		;8f8c   ; ...y hecho
interrupcion_sonido:
	ld a,(0e2bdh)		;8f8f   ; el canal de musica 1...
	ld b,a			;8f92
	ld a,(0e2c1h)		;8f93   ; ...y el 2
	add a,b			;8f96   ; sonando alguno?
	and a			;8f97   ; un efecto?
	jr nz,interrupcion_motor		;8f98
	ld e,000h		;8f9a   ; sin efecto: los canales B y C a volumen 0
	ld a,009h		;8f9c   ; ...a volumen 0
	call 00093h		;8f9e   ; WRTPSG
	ld e,000h		;8fa1   ; el C...
	ld a,00ah		;8fa3
	call 00093h		;8fa5   ; ...WRTPSG
interrupcion_motor:
	call sonido		;8fa8   ; el motor de sonido
	ld hl,0e010h		;8fab   ; dieciseis cuentas...
	ld b,010h		;8fae
interrupcion_cuenta:
	inc (hl)			;8fb0   ; ...una mas cada una
	inc hl			;8fb1
	djnz interrupcion_cuenta		;8fb2
	ld a,(0e000h)		;8fb4   ; en partida?
	and a			;8fb7   ; en partida?
	jr z,interrupcion_quieto		;8fb8
	ld de,0e040h		;8fba   ; 0xE040: el boton B del mando 1 (GTTRIG 3), con lo sostenido en 0xE041
	ld hl,0e041h		;8fbd   ; lo sostenido
	ld a,003h		;8fc0
	call boton_mando		;8fc2
	ld de,0e042h		;8fc5   ; 0xE042: el boton A del mando 1 (GTTRIG 1), sostenido en 0xE08D
	ld hl,0e08dh		;8fc8
	ld a,001h		;8fcb
	call boton_mando		;8fcd
	ld de,0e040h		;8fd0   ; y del teclado: la barra en 0xE040 y GRAPH en 0xE042 (sostenidos en 0xE08B y 0xE08C)
	ld hl,0e08bh		;8fd3
	call botones_teclado		;8fd6
palanca:		; La palanca: los cursores o el mando 1 (GTSTCK 0 y 1), en 0xE180
	xor a			;8fd9
	call 000d5h		;8fda   ; GTSTCK 0: los cursores
	ld (0e181h),a		;8fdd
	ld a,001h		;8fe0
	call 000d5h		;8fe2   ; GTSTCK 1: el mando 1
	ld c,a			;8fe5
	ld a,(0e181h)		;8fe6
	or c			;8fe9   ; uno u otro
	ld (0e180h),a		;8fea
	ret			;8fed
interrupcion_quieto:		; Fuera de partida: con la demostracion en marcha (0xE048), cada 24 cuadros una direccion y un boton al azar; si no, el boton de empezar y la palanca
	ld a,(0e048h)		;8fee   ; la demostracion?
	and a			;8ff1
	jr z,interrupcion_titulo		;8ff2   ; no
	ld a,(0e015h)		;8ff4   ; 24 cuadros?
	cp 018h		;8ff7
	jr c,boton_empezar		;8ff9
	xor a			;8ffb   ; la cuenta a 0
	ld (0e015h),a		;8ffc
	ld a,r		;8fff   ; una direccion al azar (0-7)...
	and 007h		;9001
	ld (0e180h),a		;9003   ; ...a la palanca
	ld a,r		;9006   ; y el boton, al azar
	and 001h		;9008
	and a			;900a
	jr z,boton_empezar		;900b
	ld (0e040h),a		;900d   ; a 1: salta
	jr boton_empezar		;9010
interrupcion_titulo:
	call boton_empezar		;9012   ; el boton de empezar...
	jr palanca		;9015   ; ...y la palanca
boton_empezar:		; El boton de empezar (0xE046): la barra (sostenida en 0xE045) o el boton A del mando 1 (sostenido en 0xE041)
	ld de,0e046h		;9017   ; la barra...
	ld hl,0e045h		;901a
	call boton_barra		;901d   ; SNSMAT fila 8
	ld a,(de)			;9020   ; recien pulsada...
	ld (0e181h),a		;9021   ; ...guardada
	ld hl,0e041h		;9024   ; el boton A del mando 1
	ld a,001h		;9027
	call boton_mando		;9029   ; GTTRIG 1, al mismo 0xE046
	ld a,(de)			;902c   ; ...o lo del mando
	ld b,a			;902d
	ld a,(0e181h)		;902e   ; una...
	or b			;9031   ; ...u otro
	ld (de),a			;9032
	ret			;9033
boton_mando:		; GTTRIG A: lo recien pulsado en (DE) y lo sostenido en (HL)
	call 000d8h		;9034   ; GTTRIG
	and a			;9037
boton_mira:
	jr nz,boton_nuevo		;9038   ; pulsado
boton_suelto:
	ld (hl),000h		;903a   ; suelto
	ret			;903c
boton_nuevo:		; Recien pulsado: (HL) y (DE) a 1
	ld a,(hl)			;903d   ; ya estaba pulsado?
	and a			;903e
	ret nz			;903f
	inc a			;9040   ; recien pulsado
	ld (hl),a			;9041
	ld (de),a			;9042
	ret			;9043
boton_barra:		; La barra (fila 8, bit 0)
	ld a,008h		;9044   ; la fila 8...
	call 00141h		;9046   ; SNSMAT
	rrca			;9049   ; la barra
	jr nc,boton_nuevo		;904a
	jr boton_suelto		;904c
botones_teclado:		; La barra como boton 1 y GRAPH (fila 6, bit 2) como boton 2
	ld a,008h		;904e   ; la fila 8
	call 00141h		;9050
	cpl			;9053   ; pulsado = 1
	bit 0,a		;9054   ; la barra
	call boton_mira		;9056
	inc hl			;9059   ; GRAPH: sostenido en HL + 1...
	inc de			;905a   ; ...y en DE + 2
	inc de			;905b
	ld a,006h		;905c   ; la fila 6...
	call 00141h		;905e   ; SNSMAT
	cpl			;9061   ; pulsado = 1
	bit 2,a		;9062   ; GRAPH
	jr boton_mira		;9064
vidas_pinta:		; Las vidas (0xE00B, como mucho 5) en la fila 1, columna 7: tantas casillas 0xE8 como vidas
	ld a,(0e00bh)		;9066   ; las vidas
	and a			;9069   ; ninguna: nada
	ret z			;906a
	cp 005h		;906b   ; mas de 5...
	jr c,vidas_pinta_va		;906d
	ld a,005h		;906f   ; ...se ven 5
vidas_pinta_va:
	ld hl,01827h		;9071   ; la fila 1, columna 7
	ld c,a			;9074   ; tantas casillas...
	ld b,000h		;9075
	ld a,0e8h		;9077   ; ...0xE8
	call 00056h		;9079   ; FILVRM
	ret			;907c
fase_pinta:		; La fase (0xE00A) como tantos dibujos de pergamino: las casillas 0x64 en la fila 0 y 0x68 en la 1, desde la columna 1
	ld a,(0e00ah)		;907d   ; la fase...
	ld c,a			;9080   ; ...cuantas casillas
	ld b,000h		;9081
	push bc			;9083
	ld hl,01801h		;9084   ; la fila 0, columna 1
	ld a,064h		;9087   ; 0x64, la mitad de arriba
	call 00056h		;9089   ; FILVRM
	pop bc			;908c
	ld hl,01821h		;908d   ; la fila 1, columna 1
	ld a,068h		;9090   ; 0x68, la de abajo
	call 00056h		;9092   ; FILVRM
	ret			;9095
marcador_cifras:		; Las seis cifras de los puntos (0xE001) en la fila 1, columna 25, y las del record (0xE08E) en la fila 0
	ld hl,0e001h		;9096   ; los puntos...
	ld de,01839h		;9099   ; ...en la fila 1, columna 25
	ld bc,00006h		;909c
	call 0005ch		;909f   ; LDIRVM
	ld hl,0e08eh		;90a2   ; el record...
	ld de,01819h		;90a5   ; ...en la fila 0
	ld bc,00006h		;90a8
	jp 0005ch		;90ab   ; LDIRVM
puntos:		; Los puntos + A (BCD) en las unidades y decenas (0xE00E), con acarreo
	ld b,a			;90ae
	ld a,(0e00eh)		;90af   ; + A...
	add a,b			;90b2
	daa			;90b3   ; ...en BCD
	ld (0e00eh),a		;90b4   ; las unidades y decenas
	jr nc,puntos_vida3000		;90b7   ; sin acarreo
	ld a,001h		;90b9   ; se lleva una
puntos_centenas:		; + A en las centenas y millares (0xE00D)
	ld b,a			;90bb
	ld a,(0e00dh)		;90bc   ; las centenas y millares
	add a,b			;90bf
	daa			;90c0
	ld (0e00dh),a		;90c1
	jr nc,puntos_vida3000		;90c4   ; sin acarreo
	ld a,(0e00bh)		;90c6   ; al pasar los 10000: una vida mas, hasta 9
	cp 009h		;90c9   ; ya 9?
	jr nc,puntos_mas		;90cb
	inc a			;90cd   ; una mas
	ld (0e00bh),a		;90ce
	push hl			;90d1
	call vidas_pinta		;90d2   ; en la pantalla
	pop hl			;90d5
puntos_mas:
	ld a,001h		;90d6   ; se lleva una a 0xE00C
	ld b,a			;90d8
	ld a,(0e00ch)		;90d9   ; las decenas y centenas de millar
	add a,b			;90dc
	daa			;90dd
	ld (0e00ch),a		;90de
	jr nc,puntos_vida3000		;90e1   ; sin acarreo
	ld hl,0e00ch		;90e3   ; pasados de 999999: tope... pero el bucle no avanza HL y solo pone 0x99 en 0xE00C, tres veces
	ld b,003h		;90e6
puntos_tope:
	ld (hl),099h		;90e8   ; 0x99, siempre en el mismo byte
	djnz puntos_tope		;90ea
puntos_vida3000:		; Una vida de regalo la primera vez que las centenas y millares pasan de 3000 (0xE0D3 lo apunta)
	ld a,(0e0d3h)		;90ec   ; ya dada?
	and a			;90ef
	jr nz,puntos_fin		;90f0
	ld a,(0e00dh)		;90f2   ; los millares...
	cp 030h		;90f5   ; ...a 3000?
	jr c,puntos_fin		;90f7
	ld (0e0d3h),a		;90f9   ; dada
	ld a,(0e00bh)		;90fc   ; una vida mas
	inc a			;90ff
	ld (0e00bh),a		;9100
	call vidas_pinta		;9103   ; en la pantalla
puntos_fin:
	call puntos_cifras		;9106   ; las cifras sueltas
	call record		;9109   ; y el record
	ret			;910c
puntos_cifras:		; Las seis cifras sueltas de los puntos (0xE001), de los tres bytes BCD
	ld hl,0e001h		;910d   ; las seis cifras...
	ld de,0e00ch		;9110   ; ...de los tres bytes BCD
	ld b,003h		;9113   ; tres bytes
puntos_cifra:		; Un byte: la mitad alta...
	ld a,(de)			;9115   ; un byte
	ld c,a			;9116
	and 0f0h		;9117   ; la alta
	rrca			;9119
	rrca			;911a
	rrca			;911b
	rrca			;911c
	ld (hl),a			;911d
	inc hl			;911e
	ld a,c			;911f   ; la baja
	and 00fh		;9120
	ld (hl),a			;9122   ; la baja
	inc hl			;9123
	inc de			;9124
	djnz puntos_cifra		;9125
	ret			;9127
record:		; Si los puntos pasan del record, record nuevo
	ld de,0e094h		;9128   ; el record (0xE094)...
	ld hl,0e00ch		;912b   ; ...contra los puntos
	ld a,(de)			;912e   ; el byte alto
	ld b,a			;912f
	ld a,(hl)			;9130   ; los puntos
	cp b			;9131   ; menos: nada
	ret c			;9132
	jr nz,record_hl2		;9133   ; mas: record
	inc de			;9135   ; el del medio
	inc hl			;9136
	ld a,(de)			;9137
	ld b,a			;9138
	ld a,(hl)			;9139
	cp b			;913a
	ret c			;913b
	jr nz,record_hl1		;913c   ; mas: record
	inc de			;913e   ; el bajo
	inc hl			;913f
	ld a,(de)			;9140
	ld b,a			;9141
	ld a,(hl)			;9142
	cp b			;9143
	ret c			;9144
	jr record_nuevo		;9145   ; igual o mas: record
record_hl2:		; Los punteros al tercer byte para el lddr
	inc de			;9147
	inc hl			;9148
record_hl1:
	inc de			;9149
	inc hl			;914a
record_nuevo:		; Los tres bytes de los puntos al record y sus seis cifras (0xE08E)
	ld bc,00003h		;914b   ; los tres bytes...
	lddr		;914e   ; de atras adelante
	ld hl,0e08eh		;9150   ; las cifras del record...
	ld de,0e094h		;9153   ; ...de los bytes
	ld b,003h		;9156
	jr puntos_cifra		;9158

; ----------------------------------------------------------------------
; DATOS espacios16: 16 espacios (casilla 0x10): HL apunta aqui para borrar una
;   linea de texto
;   0x915a..0x916a  (16 bytes)
DATA_espacios16:
	defb 010h,010h,010h,010h,010h,010h,010h,010h,010h,010h,010h,010h,010h,010h,010h,010h	; 915a  ................

; ======================================================================
; CODIGO 0x916a..0x91ea  (128 bytes)
; ======================================================================


puerta_entra:		; Al empezar las fases 2 a 5: la puerta por la que entra el protagonista, un paso cada 6 cuadros (0xE1C8 de 0 a 8)
	ld a,(0e011h)		;916a   ; cada 6 cuadros
	cp 006h		;916d
	jr c,puerta_entra		;916f
	xor a			;9171   ; la cuenta a 0
	ld (0e011h),a		;9172
	call puerta_entra_paso		;9175   ; un paso de la puerta
	call mapa_pantalla		;9178   ; el mapa a la pantalla
	call sprites_vram		;917b   ; y los sprites
	ld a,(0e1c8h)		;917e   ; el paso 9?
	cp 009h		;9181
	jr c,puerta_entra		;9183
	xor a			;9185   ; hecho: 0xE1C8...
	ld (0e1c8h),a		;9186
	ld (0e186h),a		;9189   ; ...y 0xE186 (que pone 0xB711) a 0
	ret			;918c
puerta_entra_paso:		; Un paso: la puerta en el mapa (0xED30; 0xEDB0 en la 5): 0 medio abierta, 1 abierta, 2 el protagonista aparece, 3-6 baja en diagonal, 7 medio abierta, 8 cerrada
	ld a,(0e00ah)		;918d   ; la fase 5?
	cp 005h		;9190
	jr z,puerta_entra_5		;9192
	ld hl,0ed30h		;9194   ; la puerta en 0xED30 (fila 16, columna 48)
	jr puerta_entra_que		;9197
puerta_entra_5:
	ld hl,0edb0h		;9199   ; en la 5, 0xEDB0 (fila 53, columna 16)
puerta_entra_que:
	ld a,(0e1c8h)		;919c   ; el paso
	and a			;919f
	jp z,puerta_medio		;91a0   ; 0: medio abierta
	cp 001h		;91a3
	jp z,puerta_abierta_dib		;91a5   ; 1: abierta
	cp 003h		;91a8   ; 3 o mas?
	jr nc,puerta_entra_baja		;91aa
	ld a,(0e00ah)		;91ac   ; 2: el protagonista aparece en la puerta
	cp 005h		;91af
	jr z,puerta_entra_y5		;91b1
	ld (ix+000h),09bh		;91b3   ; Y 0x9B
	ld (ix+004h),09bh		;91b7
	jr puerta_entra_x		;91bb
puerta_entra_y5:
	ld (ix+000h),06fh		;91bd   ; en la 5, Y 0x6F
	ld (ix+004h),06fh		;91c1
puerta_entra_x:
	ld (ix+001h),079h		;91c5   ; X 0x79
	ld (ix+005h),079h		;91c9
	jr puerta_entra_sig		;91cd
puerta_entra_baja:
	cp 007h		;91cf   ; 7 u 8?
	jr nc,puerta_entra_cierra		;91d1
	inc (ix+000h)		;91d3   ; 3-6: un punto abajo y a la derecha
	inc (ix+004h)		;91d6
	inc (ix+001h)		;91d9
	inc (ix+005h)		;91dc
puerta_entra_sig:
	inc a			;91df   ; el paso siguiente
	ld (0e1c8h),a		;91e0
	ret			;91e3
puerta_entra_cierra:
	jp z,puerta_medio		;91e4   ; 7: medio abierta
	jp puerta_cerrada		;91e7   ; 8: cerrada

; ----------------------------------------------------------------------
; DATOS puerta_abierta: La puerta del castillo abierta en la fase 1: 5 filas
;   de 6 casillas (0xD1-0xD9), que 0x8CCA copia al mapa
;   0x91ea..0x9208  (30 bytes)
DATA_puerta_abierta:
	defb 0d1h,0d1h,0d5h,0d6h,0d1h,0d1h,0d2h,0d1h,0d5h,0d6h,0d1h,0d3h,0d1h,0d1h,0d4h,0d9h	; 91ea  ................
	defb 0d1h,0d1h,0d2h,0d1h,0d5h,0d6h,0d1h,0d3h,0d1h,0d1h,0d5h,0d6h,0d1h,0d1h	; 91fa  ..............

; ======================================================================
; CODIGO 0x9208..0x9787  (1407 bytes)
; ======================================================================


pantalla_corre:		; ¿Corre la pantalla en vez del protagonista? A = 0 si corre (el protagonista en el centro, X 0x7C/0x7D, y el mapa con sitio: 0xE193 de 0 a 0x40); 0xFF si se mueve el sprite. En las fases 1 y 5, nunca
	ld a,(0e00ah)		;9208   ; la fase 1 o la 5: no
	cp 005h		;920b
	jr z,pantalla_no		;920d
	cp 001h		;920f
	jr z,pantalla_no		;9211
	ld a,(0e19ch)		;9213   ; hacia la derecha?
	cp 001h		;9216
	jr nz,pantalla_corre_izq		;9218
	ld a,(ix+001h)		;921a   ; a la derecha: el protagonista en el centro?
	cp 07ch		;921d
	jr c,pantalla_no		;921f
	ld a,(0e193h)		;9221   ; el mapa ya al final (0x40)?
	cp 040h		;9224
	jr c,pantalla_si		;9226   ; no: corre
	jr pantalla_no		;9228
pantalla_corre_izq:
	ld a,(ix+001h)		;922a   ; a la izquierda: el protagonista en el centro?
	cp 07dh		;922d
	jr nc,pantalla_no		;922f
	ld a,(0e193h)		;9231   ; el mapa al principio?
	and a			;9234
	jr nz,pantalla_si		;9235   ; no: corre
	jr pantalla_no		;9237
pantalla_si:
	xor a			;9239   ; A = 0: corre la pantalla
	ret			;923a
pantalla_no:
	ld a,0ffh		;923b   ; A = 0xFF: se mueve el sprite
	ret			;923d
protagonista:		; El protagonista, cada cuadro: la estrella en vuelo, el cofre (0xE1C3), la puerta de salida; lo que coge saltando; el tiempo del objeto 0x6A (0xE1B4); y, si no esta tocado, tirar (boton A), saltar (boton B) o andar
	ld a,(0e19bh)		;923e   ; una estrella en vuelo?
	and a			;9241
	call nz,estrella		;9242   ; se mueve
	ld a,(0e1c3h)		;9245   ; el cofre abriendose?
	and a			;9248
	call nz,cofre		;9249   ; un paso
	ld a,(0e1c8h)		;924c   ; la puerta de salida (0xE1C8 de 2 en adelante)?
	cp 002h		;924f
	jp nc,puerta_sale		;9251   ; solo eso
	call salto_objetos		;9254   ; lo que coge saltando
	ld hl,0e1b4h		;9257   ; el objeto 0x6A en marcha?
	ld a,(hl)			;925a
	and a			;925b
	jr z,protagonista_mira		;925c
	inc hl			;925e   ; un cuadro mas (0xE1B5)...
	inc (hl)			;925f
	jr nz,protagonista_mira		;9260
	inc hl			;9262   ; ...cada 256, 0xE1B6
	inc (hl)			;9263
	ld a,(hl)			;9264
	cp 003h		;9265   ; 3 x 256 cuadros?
	jr c,protagonista_mira		;9267
	xor a			;9269   ; se acaba: 0xE1B4-0xE1B6 a 0
	ld b,003h		;926a
protagonista_objeto_fin:
	ld (hl),a			;926c
	dec hl			;926d
	djnz protagonista_objeto_fin		;926e
protagonista_mira:
	ld a,(0e183h)		;9270   ; tocado: nada mas
	and a			;9273
	ret nz			;9274
	ld a,(0e19bh)		;9275   ; ya hay una estrella?
	and a			;9278
	jr nz,protagonista_salta		;9279
	ld a,(0e042h)		;927b   ; el boton A (tirar)?
	and a			;927e
	jr z,protagonista_salta		;927f
	ld a,(0e1d0h)		;9281   ; 0xE1D0 = 2...
	cp 002h		;9284
	jr nz,tira		;9286
	ld a,(0e320h)		;9288   ; ...y el de 0xE320 a la altura del protagonista: no tira
	cp (ix+000h)		;928b
	jr nz,tira		;928e
	xor a			;9290   ; el boton gastado
	ld (0e042h),a		;9291
	jr protagonista_salta		;9294
tira:		; Tira una estrella: hacia donde mira (en la fase 1, hacia la palanca o la ultima direccion); el efecto 4
	ld a,(0e00ah)		;9296   ; la fase 1?
	cp 001h		;9299
	jr z,tira_fase1		;929b
	ld a,(0e19ch)		;929d   ; hacia donde mira
	ld (0e19bh),a		;92a0
	jr tira_efecto		;92a3
tira_fase1:
	ld a,(0e180h)		;92a5   ; la palanca...
	ld (0e19bh),a		;92a8
	and a			;92ab
	jr nz,tira_efecto		;92ac   ; ...o, quieta, la ultima direccion (0xE1D2)
	ld a,(0e1d2h)		;92ae
	ld (0e19bh),a		;92b1
tira_efecto:
	ld a,004h		;92b4   ; el efecto 4
	call efecto_a_pide		;92b6
	ld a,(0e1b4h)		;92b9   ; con el objeto 0x6A en la fase 2: otra estrella (dibujo 0xB0, color 15) a la altura del protagonista
	and a			;92bc
	jr z,tira_normal		;92bd
	ld a,(0e00ah)		;92bf
	cp 002h		;92c2
	jr nz,tira_normal		;92c4
	ld a,(ix+000h)		;92c6   ; su Y
	ld (ix+008h),a		;92c9
	ld (ix+00ah),0b0h		;92cc   ; el dibujo 0xB0...
	ld (ix+00bh),00fh		;92d0   ; ...color 15
	ld a,001h		;92d4   ; 0xE1B7 = 1
	ld (0e1b7h),a		;92d6
	jr tira_x		;92d9
tira_normal:		; La de siempre: dibujo 0xA4, color 5, 8 puntos por debajo
	xor a			;92db   ; 0xE1B7 = 0
	ld (0e1b7h),a		;92dc
	ld a,(ix+000h)		;92df   ; la Y + 8
	add a,008h		;92e2
	ld (ix+008h),a		;92e4
	ld (ix+00ah),0a4h		;92e7   ; el dibujo 0xA4...
	ld (ix+00bh),005h		;92eb   ; ...color 5
tira_x:
	ld a,(ix+001h)		;92ef   ; la X del protagonista
	ld (ix+009h),a		;92f2
protagonista_salta:		; ¿Saltando? Sigue el salto; si no, el boton B empieza uno (salvo a mitad de paso, fuera de la fase 1)
	ld a,(0e194h)		;92f5   ; saltando?
	and a			;92f8
	jp nz,salto_cuadro		;92f9   ; sigue
	ld a,(0e00ah)		;92fc   ; la fase 1?
	cp 001h		;92ff
	jr z,protagonista_boton_b		;9301
	ld a,(0e19eh)		;9303   ; a mitad de un paso?
	and a			;9306
	jr nz,protagonista_anda		;9307
protagonista_boton_b:
	ld a,(0e040h)		;9309   ; el boton B?
	and a			;930c
	jp nz,salto		;930d   ; salta
protagonista_anda:		; Andar: en la fase 1, en ocho direcciones (0x95EA); en las otras, por el piso y las escaleras
	ld a,(0e00ah)		;9310   ; la fase 1?
	cp 001h		;9313
	jp z,anda_fase1		;9315
	ld a,(0e180h)		;9318   ; la palanca
	ld b,a			;931b
	jr anda		;931c
protagonista_quieto:		; Quieto: si estaba agachado (0xE1BE), de pie otra vez
	ld a,(0e1beh)		;931e   ; agachado?
	and a			;9321
	ret z			;9322
	xor a			;9323   ; ya no
	ld (0e1beh),a		;9324
	jp prota_dibujo		;9327   ; de pie
anda:		; A mitad de un paso (0xE19E de 1 a 7)? lo sigue hacia su lado; si no, la palanca decide
	ld a,(0e19eh)		;932a   ; a mitad de paso?
	and a			;932d
	jr z,anda_palanca		;932e
	ld a,(0e19dh)		;9330   ; hacia la izquierda (6 o mas)?
	cp 006h		;9333
	jp nc,anda_izq_sigue		;9335
	jp anda_der_sigue		;9338   ; hacia la derecha
anda_palanca:		; La palanca: arriba o abajo solo valen en una escalera (0xE198: 1 la que sube a la derecha, 2 la que sube a la izquierda), y abajo fuera de ella agacha
	ld a,b			;933b   ; quieta?
	and a			;933c
	jr z,protagonista_quieto		;933d
	ld (0e19dh),a		;933f   ; la direccion
	cp 001h		;9342   ; arriba?
	jr z,anda_arriba		;9344
	cp 005h		;9346   ; abajo?
	jr nz,anda_derecha		;9348
	ld a,(0e198h)		;934a   ; en una escalera?
	and a			;934d
	jp z,agacha		;934e   ; no: agachado
	cp 001h		;9351   ; en la 1: abajo es a la izquierda (7)...
	jr nz,anda_abajo2		;9353
	ld a,007h		;9355
	jr anda_dir		;9357
anda_abajo2:
	ld a,003h		;9359   ; ...en la 2, a la derecha (3)
	jr anda_dir		;935b
anda_arriba:		; Arriba: en la escalera 1, a la derecha (3); en la 2, a la izquierda (7); fuera, nada
	ld a,(0e198h)		;935d   ; en una escalera?
	and a			;9360
	jr z,protagonista_quieto		;9361   ; no: quieto
	cp 001h		;9363
	jr nz,anda_arriba2		;9365
	ld a,003h		;9367
	jr anda_dir		;9369
anda_arriba2:
	ld a,007h		;936b
anda_dir:
	ld (0e19dh),a		;936d   ; la direccion nueva
	ld b,a			;9370
anda_derecha:		; A la derecha (2, 3 o 4): mira a la derecha, el efecto 7, un paso; un muro (0x40) arriba a la derecha lo para
	cp 006h		;9371   ; a la izquierda?
	jp nc,anda_izquierda		;9373
	ld a,001h		;9376   ; mira a la derecha
	ld (0e19ch),a		;9378
	ld a,007h		;937b   ; el efecto 7 (el paso)
	call efecto_a_pide		;937d
	ld a,(0e19eh)		;9380   ; un punto del paso
	inc a			;9383
	ld (0e19eh),a		;9384
	ld hl,(0e18ah)		;9387   ; la casilla de la derecha...
	inc hl			;938a
	call muro_mira		;938b   ; ...la de arriba es un muro?
	jp z,prota_dibujo_der		;938e
anda_der_mueve:		; Corre la pantalla o se mueve el sprite
	call pantalla_corre		;9391   ; corre la pantalla?
	and a			;9394
	jp z,prota_dibujo_der		;9395
anda_der_sprite:		; El sprite un punto a la derecha (hasta 0xEC)
	ld a,(ix+001h)		;9398   ; en el borde?
	cp 0ech		;939b
	jr c,anda_der_punto		;939d
	xor a			;939f   ; parado
	ld (0e19eh),a		;93a0
	jp prota_dibujo_der		;93a3
anda_der_punto:
	inc (ix+001h)		;93a6   ; un punto a la derecha
	inc (ix+005h)		;93a9
	jp prota_dibujo_der		;93ac
muro_mira:		; ¿Muro? La casilla de arriba (HL - el ancho) es 0x40: el paso parado (0xE19E = 0); Z si lo es
	ld de,(0e1ceh)		;93af   ; una fila arriba
	and a			;93b3
	sbc hl,de		;93b4
	ld a,(hl)			;93b6
	cp 040h		;93b7   ; 0x40?
	ret nz			;93b9
	xor a			;93ba   ; parado
	ld (0e19eh),a		;93bb
	ret			;93be
anda_der_sigue:		; Sigue el paso a la derecha: 8 puntos por casilla; al octavo, la casilla siguiente segun la direccion (3 llano, 2 sube, 4 baja) o la escalera
	ld a,007h		;93bf   ; el efecto 7
	call efecto_a_pide		;93c1
	ld a,(0e19eh)		;93c4   ; un punto mas
	inc a			;93c7
	ld (0e19eh),a		;93c8
	cp 008h		;93cb   ; 8: la casilla siguiente
	jr c,anda_der_mueve		;93cd
	xor a			;93cf   ; el paso a 0
	ld (0e19eh),a		;93d0
	ld a,(0e198h)		;93d3   ; en una escalera?
	and a			;93d6
	jr nz,escalera_der		;93d7
	ld hl,(0e18ah)		;93d9   ; la casilla de la derecha: un agujero?
	inc hl			;93dc
	call casilla_para		;93dd
	ld a,(0e19dh)		;93e0   ; la direccion
	cp 003h		;93e3   ; llano?
	jr nz,anda_der_sube		;93e5
anda_der_casilla:		; Una casilla a la derecha en el mapa (0xE18A); si corre la pantalla, una columna mas (0xE193) y los otros a la izquierda
	ld hl,(0e18ah)		;93e7   ; una casilla...
	inc hl			;93ea
	ld (0e18ah),hl		;93eb   ; ...a la derecha
	call pantalla_corre		;93ee   ; corre la pantalla?
	and a			;93f1
	jr nz,anda_der_sprite		;93f2
	ld hl,0e193h		;93f4   ; una columna mas
	inc (hl)			;93f7
	call otros_corren		;93f8   ; los otros 8 a la izquierda
	jp prota_dibujo_der		;93fb
anda_der_sube:		; Arriba a la derecha: el pie de la escalera 1 (0x39, arriba a la derecha) la empieza
	cp 002h		;93fe   ; arriba a la derecha?
	jr nz,anda_der_baja		;9400
	ld hl,(0e18ah)		;9402   ; la casilla de arriba a la derecha...
	inc hl			;9405
	ld de,(0e1ceh)		;9406
	and a			;940a
	sbc hl,de		;940b
	ld a,(hl)			;940d   ; ...el pie de la escalera (0x39)?
	cp 039h		;940e
	jp nz,anda_der_casilla		;9410
	xor a			;9413   ; en la escalera 1, paso 0
	ld (0e199h),a		;9414
	inc a			;9417
	ld (0e198h),a		;9418
	jr escalera_der_sube		;941b
anda_der_baja:		; Abajo a la derecha: la casilla 0x32 es lo alto de la escalera 2; un piso menos (0xE190), paso 6
	cp 004h		;941d   ; abajo a la derecha?
	ret nz			;941f
	ld a,(0e198h)		;9420   ; ya en una escalera?
	and a			;9423
	jr nz,escalera_der		;9424
	ld hl,(0e18ah)		;9426   ; la casilla...
	ld a,(hl)			;9429   ; ...0x32?
	cp 032h		;942a
	jp nz,anda_der_casilla		;942c
	ld a,002h		;942f   ; la escalera 2...
	ld (0e198h),a		;9431
	ld a,006h		;9434   ; ...desde arriba (6)
	ld (0e199h),a		;9436
	ld hl,0e190h		;9439   ; un piso menos
	dec (hl)			;943c
	jr escalera_der_baja		;943d
escalera_der:		; En la escalera hacia la derecha: el efecto 6; en la 1 sube, en la 2 baja
	ld a,006h		;943f   ; el efecto 6
	call efecto_a_pide		;9441
	ld a,(0e198h)		;9444   ; la 1?
	cp 001h		;9447
	jr nz,escalera_der_baja		;9449
escalera_der_sube:		; Sube: un peldano mas (0xE199); al sexto, fuera de la escalera y un piso mas (0xE190)
	ld hl,0e199h		;944b   ; un peldano mas
	inc (hl)			;944e
	ld a,(hl)			;944f
	cp 006h		;9450   ; el sexto?
	jr c,escalera_sube_8		;9452
	dec hl			;9454   ; fuera de la escalera
	ld (hl),000h		;9455
	ld hl,0e190h		;9457   ; un piso mas
	inc (hl)			;945a
	jr escalera_sube_8		;945b
escalera_der_baja:		; Baja: un peldano menos; al cero, fuera
	ld hl,0e199h		;945d   ; un peldano menos
	dec (hl)			;9460
	jr nz,escalera_baja_8		;9461
	dec hl			;9463   ; fuera
	ld (hl),000h		;9464
	jr escalera_baja_8		;9466
escalera_sube_8:		; Sube 8 puntos: en la fase 5 corre la pantalla (0xE19A, y los otros abajo); si no, el sprite. Y una fila arriba en el mapa
	ld a,(0e00ah)		;9468   ; la fase 5?
	cp 005h		;946b
	jr nz,escalera_sube_sprite		;946d
	ld hl,0e19ah		;946f   ; una fila arriba
	dec (hl)			;9472
	call otros_bajan		;9473   ; los otros, 8 abajo
	jr escalera_sube_fila		;9476
escalera_sube_sprite:
	call prota_sube8		;9478   ; el sprite 8 arriba
escalera_sube_fila:
	call mapa_fila_arriba		;947b   ; una fila arriba en el mapa
	jp anda_der_casilla		;947e   ; y una casilla a la derecha
escalera_baja_8:		; Baja 8 puntos: en la fase 5 corre la pantalla; si no, el sprite. Y una fila abajo
	ld a,(0e00ah)		;9481   ; la fase 5?
	cp 005h		;9484
	jr nz,escalera_baja_sprite		;9486
	ld hl,0e19ah		;9488   ; una fila abajo
	inc (hl)			;948b
	call otros_suben		;948c   ; los otros, 8 arriba
	jr escalera_baja_fila		;948f
escalera_baja_sprite:
	call prota_baja8		;9491   ; el sprite 8 abajo
escalera_baja_fila:
	call mapa_fila_abajo		;9494   ; una fila abajo en el mapa
	jp anda_der_casilla		;9497   ; y una casilla a la derecha
anda_izquierda:		; A la izquierda (6, 7 u 8): mira a la izquierda, el efecto 7 y un paso; un muro arriba a la izquierda lo para
	ld a,002h		;949a   ; mira a la izquierda
	ld (0e19ch),a		;949c
	ld a,007h		;949f   ; el efecto 7
	call efecto_a_pide		;94a1
	ld hl,0e19eh		;94a4   ; un punto del paso
	inc (hl)			;94a7
	ld hl,(0e18ah)		;94a8   ; la casilla de la izquierda...
	dec hl			;94ab
	ld de,(0e1ceh)		;94ac
	and a			;94b0
	sbc hl,de		;94b1
	ld a,(hl)			;94b3   ; ...la de arriba es un muro (0x40)?
	cp 040h		;94b4
	jr nz,anda_izq_mueve		;94b6
	xor a			;94b8   ; parado
	ld (0e19eh),a		;94b9
	jp prota_dibujo_izq		;94bc
anda_izq_mueve:
	call pantalla_corre		;94bf   ; corre la pantalla?
	and a			;94c2
	jp z,prota_dibujo_izq		;94c3
anda_izq_sprite:		; El sprite un punto a la izquierda (hasta 5)
	ld a,(ix+001h)		;94c6   ; en el borde?
	cp 005h		;94c9
	jr nc,anda_izq_punto		;94cb
	xor a			;94cd   ; parado
	ld (0e19eh),a		;94ce
	jp prota_dibujo_izq		;94d1
anda_izq_punto:
	dec (ix+001h)		;94d4   ; un punto a la izquierda
	dec (ix+005h)		;94d7
	jp prota_dibujo_izq		;94da
anda_izq_sigue:		; Sigue el paso a la izquierda: al octavo, la casilla siguiente (7 llano, 6 baja, 8 sube) o la escalera
	ld a,007h		;94dd   ; el efecto 7
	call efecto_a_pide		;94df
	ld a,(0e19eh)		;94e2   ; un punto mas
	inc a			;94e5
	ld (0e19eh),a		;94e6
	cp 008h		;94e9   ; 8?
	jr nz,anda_izq_mueve		;94eb
	xor a			;94ed   ; el paso a 0
	ld (0e19eh),a		;94ee
	ld a,(0e198h)		;94f1   ; en una escalera?
	and a			;94f4
	jr nz,escalera_izq		;94f5
	ld hl,(0e18ah)		;94f7   ; la casilla de la izquierda: un agujero?
	dec hl			;94fa
	call casilla_para		;94fb
	ld a,(0e19dh)		;94fe   ; la direccion
	cp 007h		;9501   ; llano?
	jr nz,anda_izq_baja		;9503
anda_izq_casilla:		; Una casilla a la izquierda (0xE18A); si corre la pantalla, una columna menos y los otros a la derecha
	ld hl,(0e18ah)		;9505   ; una casilla...
	dec hl			;9508
	ld (0e18ah),hl		;9509   ; ...a la izquierda
	call pantalla_corre		;950c   ; corre la pantalla?
	and a			;950f
	jp nz,anda_izq_sprite		;9510
	ld hl,0e193h		;9513   ; una columna menos
	dec (hl)			;9516
	call otros_corren		;9517   ; los otros 8 a la derecha
	jp prota_dibujo_izq		;951a
anda_izq_baja:		; Abajo a la izquierda: la casilla 0x35 es lo alto de la escalera 1; un piso menos, paso 6
	cp 006h		;951d   ; abajo a la izquierda?
	jr nz,anda_izq_sube		;951f
	ld a,(0e198h)		;9521   ; ya en una escalera?
	and a			;9524
	jr nz,escalera_izq		;9525
	ld hl,(0e18ah)		;9527   ; la casilla...
	ld a,(hl)			;952a   ; ...0x35?
	cp 035h		;952b
	jr nz,anda_izq_casilla		;952d
	ld hl,0e198h		;952f   ; la escalera 1...
	ld (hl),001h		;9532
	inc hl			;9534
	ld (hl),006h		;9535   ; ...desde arriba (6)
	ld hl,0e190h		;9537   ; un piso menos
	dec (hl)			;953a
	jr escalera_izq_baja		;953b
anda_izq_sube:		; Arriba a la izquierda: el pie de la escalera 2 (0x3A) la empieza
	cp 008h		;953d   ; arriba a la izquierda?
	ret nz			;953f
	ld hl,(0e18ah)		;9540   ; la casilla de arriba a la izquierda...
	dec hl			;9543
	ld de,(0e1ceh)		;9544
	and a			;9548
	sbc hl,de		;9549
	ld a,(hl)			;954b   ; ...0x3A?
	cp 03ah		;954c
	jp nz,anda_izq_casilla		;954e
	ld hl,0e198h		;9551   ; en la escalera 2, paso 0
	ld (hl),002h		;9554
	inc hl			;9556
	ld (hl),000h		;9557
	jr escalera_izq_sube		;9559
escalera_izq:		; En la escalera hacia la izquierda: el efecto 6; en la 1 baja, en la 2 sube
	ld a,006h		;955b   ; el efecto 6
	call efecto_a_pide		;955d
	ld a,(0e198h)		;9560   ; la 1?
	cp 001h		;9563
	jr nz,escalera_izq_sube		;9565
escalera_izq_baja:		; Baja: un peldano menos; al cero, fuera
	ld hl,0e199h		;9567   ; un peldano menos
	dec (hl)			;956a
	jp nz,escalera_izq_baja_8		;956b
	dec hl			;956e   ; fuera
	ld (hl),000h		;956f
	jr escalera_izq_baja_8		;9571
escalera_izq_sube:		; Sube: un peldano mas; al sexto, fuera y un piso mas
	ld hl,0e199h		;9573   ; un peldano mas
	inc (hl)			;9576
	ld a,(hl)			;9577   ; el sexto?
	cp 006h		;9578
	jp c,escalera_izq_sube_8		;957a
	dec hl			;957d   ; fuera
	ld (hl),000h		;957e
	ld hl,0e190h		;9580   ; un piso mas
	inc (hl)			;9583
	jr escalera_izq_sube_8		;9584
escalera_izq_baja_8:		; Baja 8 puntos (la pantalla en la fase 5, el sprite en las otras) y una fila abajo
	ld a,(0e00ah)		;9586   ; la fase 5?
	cp 005h		;9589
	jr nz,escalera_izq_baja_spr		;958b
	ld hl,0e19ah		;958d   ; una fila abajo
	inc (hl)			;9590
	call otros_suben		;9591
	jr escalera_izq_baja_fila		;9594
escalera_izq_baja_spr:
	call prota_baja8		;9596
escalera_izq_baja_fila:
	call mapa_fila_abajo		;9599
	jp anda_izq_casilla		;959c   ; y una casilla a la izquierda
escalera_izq_sube_8:		; Sube 8 puntos y una fila arriba
	ld a,(0e00ah)		;959f   ; la fase 5?
	cp 005h		;95a2
	jr nz,escalera_izq_sube_spr		;95a4
	ld hl,0e19ah		;95a6   ; una fila arriba
	dec (hl)			;95a9
	call otros_bajan		;95aa
	jr escalera_izq_sube_fila		;95ad
escalera_izq_sube_spr:
	call prota_sube8		;95af
escalera_izq_sube_fila:
	call mapa_fila_arriba		;95b2
	jp anda_izq_casilla		;95b5   ; y una casilla a la izquierda
mapa_fila_abajo:		; El protagonista una fila abajo en el mapa (0xE18A + el ancho)
	ld de,(0e1ceh)		;95b8   ; el ancho
	ld hl,(0e18ah)		;95bc
	add hl,de			;95bf   ; una fila mas
	ld (0e18ah),hl		;95c0
	ret			;95c3
mapa_fila_arriba:		; Una fila arriba (0xE18A - el ancho)
	ld de,(0e1ceh)		;95c4   ; el ancho
	ld hl,(0e18ah)		;95c8
	and a			;95cb
	sbc hl,de		;95cc   ; una fila menos
	ld (0e18ah),hl		;95ce
	ret			;95d1
prota_sube8:		; Los dos sprites del protagonista, 8 puntos arriba
	ld a,(ix+000h)		;95d2   ; la Y - 8
	sub 008h		;95d5
	ld (ix+000h),a		;95d7
	ld (ix+004h),a		;95da
	ret			;95dd
prota_baja8:		; Y 8 abajo
	ld a,008h		;95de   ; la Y + 8
	add a,(ix+000h)		;95e0
	ld (ix+000h),a		;95e3
	ld (ix+004h),a		;95e6
	ret			;95e9
anda_fase1:		; En la fase 1, delante del castillo: ocho direcciones, un punto por cuadro, entre Y 0x50 y 0x97 y X 8 y 0xE8
	ld a,(0e180h)		;95ea   ; quieta: nada
	and a			;95ed
	ret z			;95ee
	ld (0e1d2h),a		;95ef   ; la ultima direccion
	ld a,007h		;95f2   ; el efecto 7
	call efecto_a_pide		;95f4
	ld a,(0e180h)		;95f7   ; derecha?
	cp 003h		;95fa
	jp z,anda_der_sprite		;95fc
	cp 007h		;95ff   ; izquierda?
	jp z,anda_izq_sprite		;9601
	cp 001h		;9604   ; arriba?
	jr nz,fase1_abajo		;9606
fase1_arriba:
	ld a,(ix+000h)		;9608   ; arriba del todo (0x50)?
	cp 050h		;960b
	jp c,prota_dibujo		;960d
	dec (ix+000h)		;9610   ; un punto arriba
	dec (ix+004h)		;9613
	jp prota_dibujo		;9616
fase1_abajo:
	cp 005h		;9619   ; abajo?
	jr nz,fase1_diagonal		;961b
fase1_abajo_va:
	ld a,(ix+000h)		;961d   ; abajo del todo (0x97)?
	cp 097h		;9620
	jp nc,prota_dibujo		;9622
	inc (ix+000h)		;9625   ; un punto abajo
	inc (ix+004h)		;9628
	jp prota_dibujo		;962b
fase1_diagonal:		; Las diagonales: primero el lado y despues arriba o abajo
	cp 005h		;962e   ; a la izquierda (6, 8)?
	jr nc,fase1_izq		;9630
	ld a,001h		;9632   ; 2 o 4: a la derecha
	ld (0e19ch),a		;9634
	ld a,(ix+001h)		;9637   ; en el borde (0xE8)?
	cp 0e8h		;963a
	jr nc,fase1_der_y		;963c
	inc (ix+001h)		;963e   ; un punto a la derecha
	inc (ix+005h)		;9641
fase1_der_y:
	ld a,(0e180h)		;9644   ; arriba a la derecha?
	cp 002h		;9647
	jp z,fase1_arriba		;9649
	cp 004h		;964c   ; 4: abajo (el cp no sirve: salta igual)
	jp fase1_abajo_va		;964e
fase1_izq:
	ld a,002h		;9651   ; a la izquierda
	ld (0e19ch),a		;9653
	ld a,(ix+001h)		;9656   ; en el borde (8)?
	cp 008h		;9659
	jr c,fase1_izq_y		;965b
	dec (ix+001h)		;965d   ; un punto a la izquierda
	dec (ix+005h)		;9660
fase1_izq_y:
	ld a,(0e180h)		;9663   ; abajo a la izquierda?
	cp 006h		;9666
	jp z,fase1_abajo_va		;9668
	jp fase1_arriba		;966b   ; 8: arriba
prota_dibujo:		; Los dibujos del protagonista andando: 0x28/0x30 a la derecha, 0x00/0x08 a la izquierda (cambian cada 8 cuadros); con el objeto 0x6A desde la fase 4, un solo sprite
	ld a,(0e19ch)		;966e   ; hacia donde mira?
	cp 001h		;9671
	jr nz,prota_dibujo_izq		;9673
prota_dibujo_der:
	ld a,001h		;9675   ; a la derecha: 0x28
	ld b,028h		;9677
	jr prota_dibujo_va		;9679
prota_dibujo_izq:
	ld a,002h		;967b   ; a la izquierda: 0
	ld b,000h		;967d
prota_dibujo_va:
	ld (0e19ch),a		;967f   ; mira a ese lado
	ld a,(0e01fh)		;9682   ; + 8 cada 8 cuadros
	and 008h		;9685
	add a,b			;9687
	ld b,a			;9688
	ld a,(0e00ah)		;9689   ; la fase 4 o mas...
	cp 004h		;968c
	jr c,prota_dibujo_dos		;968e
	ld a,(0e1b4h)		;9690   ; ...con el objeto 0x6A?
	and a			;9693
	jr z,prota_dibujo_dos		;9694
	ld a,004h		;9696   ; el dibujo + 4 en el primer sprite...
	add a,b			;9698
	ld (ix+002h),a		;9699
	ld (ix+004h),0f0h		;969c   ; ...y el segundo fuera
prota_dibujo_fin:
	xor a			;96a0   ; ya no agachado
	ld (0e1beh),a		;96a1
	ret			;96a4
prota_dibujo_dos:		; Los dos sprites: el dibujo y el + 4 encima, a la misma Y
	ld (ix+002h),b		;96a5   ; el primero
	ld a,004h		;96a8   ; el segundo, + 4
	add a,b			;96aa
	ld (ix+006h),a		;96ab
	ld a,(ix+000h)		;96ae   ; a la misma Y
	ld (ix+004h),a		;96b1
	jr prota_dibujo_fin		;96b4
estrella:		; La estrella en vuelo (0xE108): dibujo 0xA4/0xA8 y 3 puntos por cuadro; con el objeto 0x6A en la fase 2, 0xB0/0xB4 y 1 punto; en la fase 1, en ocho direcciones; fuera de la pantalla, se acaba
	ld a,(0e1b4h)		;96b6   ; el objeto 0x6A...
	and a			;96b9
	jr z,estrella_normal		;96ba
	ld a,(0e00ah)		;96bc   ; ...en la fase 2...
	cp 002h		;96bf
	jr nz,estrella_normal		;96c1
	ld a,(0e1b7h)		;96c3   ; ...con la estrella grande?
	and a			;96c6
	jr z,estrella_normal		;96c7
	ld b,0b0h		;96c9   ; el dibujo 0xB0, 1 punto
	ld c,001h		;96cb
	jr estrella_vuela		;96cd
estrella_normal:
	ld b,0a4h		;96cf   ; el dibujo 0xA4, 3 puntos
	ld c,003h		;96d1
	ld a,(0e1b7h)		;96d3   ; era la grande?
	and a			;96d6
	jr z,estrella_vuela		;96d7
	ld (ix+00bh),005h		;96d9   ; color 5...
	ld a,008h		;96dd   ; ...8 puntos abajo
	add a,(ix+008h)		;96df
	ld (ix+008h),a		;96e2
	xor a			;96e5   ; ya no
	ld (0e1b7h),a		;96e6
estrella_vuela:
	ld a,(0e01fh)		;96e9   ; + 4 cada 4 cuadros: gira
	and 004h		;96ec
	add a,b			;96ee
	ld (ix+00ah),a		;96ef
	ld a,(0e00ah)		;96f2   ; la fase 1?
	cp 001h		;96f5
	jr z,estrella_fase1		;96f7
	ld a,(0e19bh)		;96f9   ; hacia la derecha?
	cp 001h		;96fc
	jr nz,estrella_izq		;96fe
estrella_der:
	ld a,(ix+009h)		;9700   ; C puntos a la derecha
	add a,c			;9703
	ld (ix+009h),a		;9704
	jr estrella_borde		;9707
estrella_izq:
	ld a,(ix+009h)		;9709   ; C puntos a la izquierda
	sub c			;970c
	ld (ix+009h),a		;970d
estrella_borde:
	ld a,(ix+009h)		;9710   ; fuera por la izquierda (menos de 4)...
	cp 004h		;9713
	jr c,estrella_fin		;9715
	cp 0f0h		;9717   ; ...o por la derecha (0xF0)?
	jr nc,estrella_fin		;9719
	ret			;971b
estrella_fase1:		; En la fase 1, ocho direcciones a 3 puntos
	ld c,003h		;971c   ; 3 puntos
	ld a,(0e19bh)		;971e   ; derecha?
	cp 003h		;9721
	jr z,estrella_der		;9723
	cp 007h		;9725   ; izquierda?
	jr z,estrella_izq		;9727
	cp 001h		;9729   ; arriba?
	jr nz,estrella_diag		;972b
estrella_sube:
	dec (ix+008h)		;972d   ; 3 arriba
	dec (ix+008h)		;9730
	dec (ix+008h)		;9733
estrella_borde_y:
	ld a,(ix+008h)		;9736   ; (el cp 0 nunca da C)
	cp 000h		;9739
	jr c,estrella_fin		;973b
	cp 0a8h		;973d   ; abajo del todo (0xA8)?
	jr nc,estrella_fin		;973f
	jr estrella_borde		;9741
estrella_diag:
	cp 002h		;9743   ; arriba a la derecha
	jr nz,estrella_diag4		;9745
	call estrella_der		;9747
	jr estrella_sube		;974a
estrella_diag4:
	cp 004h		;974c   ; abajo a la derecha
	jr nz,estrella_abajo		;974e
	call estrella_der		;9750
	jr estrella_baja		;9753
estrella_abajo:
	cp 005h		;9755   ; abajo
	jr nz,estrella_diag6		;9757
estrella_baja:
	inc (ix+008h)		;9759   ; 3 abajo
	inc (ix+008h)		;975c
	inc (ix+008h)		;975f
	jr estrella_borde_y		;9762
estrella_diag6:
	cp 006h		;9764   ; abajo a la izquierda
	jr nz,estrella_diag8		;9766
	call estrella_izq		;9768
	jr estrella_baja		;976b
estrella_diag8:
	call estrella_izq		;976d   ; arriba a la izquierda
	jr estrella_sube		;9770
estrella_fin:		; Se acaba: 0xE19B a 0, el sprite fuera y el boton A gastado
	xor a			;9772   ; sin estrella
	ld (0e19bh),a		;9773
	ld (ix+008h),0f0h		;9776   ; fuera (Y 0xF0)
	ld (ix+009h),a		;977a
	ld (ix+00ah),a		;977d
	ld (ix+00bh),a		;9780
	ld (0e042h),a		;9783   ; el boton A gastado
	ret			;9786

; ----------------------------------------------------------------------
; DATOS jr_muerto: "jr 0x97D6": detras de un ret y sin salto que llegue aqui
;   0x9787..0x9789  (2 bytes)
DATA_jr_muerto:
	defb 018h,04dh	; 9787

; ======================================================================
; CODIGO 0x9789..0x9bc5  (1084 bytes)
; ======================================================================


salto:		; Empieza un salto (boton B), salvo con la palanca abajo o en una escalera: el efecto 5; hacia la derecha (palanca 2-4), la izquierda (6-8) o arriba
	ld a,(0e180h)		;9789   ; la palanca abajo?
	cp 005h		;978c
	jr z,salto_no		;978e
	ld a,(0e198h)		;9790   ; en una escalera?
	and a			;9793
	jr z,salto_empieza		;9794
salto_no:
	xor a			;9796   ; el boton gastado
	ld (0e040h),a		;9797
	ret			;979a
salto_empieza:
	ld a,005h		;979b   ; el efecto 5
	call efecto_a_pide		;979d
	ld a,001h		;97a0   ; saltando
	ld (0e194h),a		;97a2
	xor a			;97a5   ; el paso a 0
	ld (0e19eh),a		;97a6
	ld a,(0e180h)		;97a9   ; la palanca: 0 o 1?
	cp 002h		;97ac
	jr c,salto_arriba		;97ae
	cp 005h		;97b0   ; 5 o mas?
	jr nc,salto_izq		;97b2
	ld a,003h		;97b4   ; 2-4: a la derecha
	ld (0e19dh),a		;97b6
	ld a,001h		;97b9
	ld (0e19ch),a		;97bb
	ld (0e197h),a		;97be   ; salto a la derecha (0xE197 = 1)
	jr salto_cuadro		;97c1
salto_izq:
	ld a,007h		;97c3   ; 6-8: a la izquierda
	ld (0e19dh),a		;97c5
	ld a,002h		;97c8
	ld (0e19ch),a		;97ca
	ld (0e197h),a		;97cd   ; salto a la izquierda (0xE197 = 2)
	jr salto_cuadro		;97d0
salto_arriba:
	xor a			;97d2   ; salto en el sitio
	ld (0e197h),a		;97d3
salto_cuadro:		; Un cuadro del salto (0xE196 sube a 0x1B y baja a 0): los primeros 8 pasos 2 puntos, luego 1, luego uno de cada dos; arriba del todo se cogen las cosas
	ld a,(0e195h)		;97d6   ; bajando?
	and a			;97d9
	jr nz,salto_baja		;97da
	ld a,(0e196h)		;97dc   ; la cuenta de subida
	cp 01bh		;97df   ; arriba del todo?
	jr nc,salto_arriba_del_todo		;97e1
salto_sube:
	inc a			;97e3   ; un paso mas
	ld (0e196h),a		;97e4
	cp 009h		;97e7   ; del 1 al 8...
	jr nc,salto_sube1		;97e9
	dec (ix+000h)		;97eb   ; ...un punto arriba...
	dec (ix+004h)		;97ee
	bit 0,a		;97f1   ; ...y otro: dos por cuadro
	jr nz,salto_sube		;97f3
	jp salto_lado		;97f5
salto_sube1:
	cp 011h		;97f8   ; del 9 al 16: uno
	jr nc,salto_sube_lento		;97fa
	dec (ix+000h)		;97fc
	dec (ix+004h)		;97ff
	jp salto_lado		;9802
salto_sube_lento:
	cp 019h		;9805   ; del 17 al 24: uno de cada dos
	jr nc,salto_mira_sube		;9807
	bit 0,a		;9809
	jr z,salto_coge		;980b
	dec (ix+000h)		;980d
	dec (ix+004h)		;9810
	jr salto_coge		;9813
salto_arriba_del_todo:		; Arriba del todo: ya baja (0xE195)
	ld a,(0e195h)		;9815
	inc a			;9818
	ld (0e195h),a		;9819
	jp salto_lado		;981c
salto_mira_sube:
	jr salto_coge		;981f
salto_baja:		; Bajando: lo mismo al reves; al llegar a 0, cae al suelo
	ld a,(0e196h)		;9821   ; la cuenta
	and a			;9824   ; en el suelo?
	jp z,salto_suelo		;9825
	dec a			;9828   ; un paso menos
	ld (0e196h),a		;9829
	cp 018h		;982c   ; del 24 al 27: quieto
	jr c,salto_baja_lento		;982e
	jr salto_coge		;9830
salto_baja_lento:
	cp 010h		;9832   ; del 16 al 23: uno de cada dos
	jr c,salto_baja_rapido		;9834
	bit 0,a		;9836
	jr z,salto_coge		;9838
	inc (ix+000h)		;983a   ; un punto abajo
	inc (ix+004h)		;983d
salto_coge:		; Arriba: el cofre (0x61, cinco filas por encima) empieza a abrirse; el objeto 0x6A (cuatro filas por encima) se coge: 0xE1B4 y 100 puntos
	ld hl,(0e18ah)		;9840   ; la casilla del protagonista
	ld a,(0e197h)		;9843   ; (estas comparaciones no cambian nada: todos los caminos llegan a 0x9858 igual)
	and a			;9846
	jr z,salto_coge_mira		;9847
	cp 001h		;9849
	jr nz,salto_coge_va		;984b
salto_coge_va:
	jr salto_coge_casilla		;984d
salto_coge_mira:
	ld a,(0e19ch)		;984f
	cp 001h		;9852
	jr nz,salto_coge_va		;9854
	jr salto_coge_va		;9856
salto_coge_casilla:
	push hl			;9858
	ld b,005h		;9859   ; cinco filas...
	call filas_por_ancho		;985b
	pop hl			;985e
	and a			;985f
	sbc hl,de		;9860   ; ...por encima
	ld a,(hl)			;9862
	cp 061h		;9863   ; el cofre (0x61)?
	jr z,salto_cofre		;9865
	ld de,(0e1ceh)		;9867   ; una fila mas abajo
	add hl,de			;986b
	ld a,(hl)			;986c
	cp 06ah		;986d   ; el objeto 0x6A?
	jp nz,salto_lado		;986f
	ld a,(0e1b4h)		;9872   ; cogido: 0xE1B4 + 1
	inc a			;9875
	ld (0e1b4h),a		;9876
	ld (hl),0a0h		;9879   ; borrado
	ld a,(0e000h)		;987b   ; en partida...
	and a			;987e
	jp z,salto_lado		;987f
	ld a,001h		;9882   ; ...100 puntos
	call puntos_centenas		;9884
	jp salto_lado		;9887
salto_cofre:		; El cofre empieza a abrirse: 0xE1C3 = 1, 0xE192 = 1 y donde esta (0xE1C5)
	xor a			;988a   ; la cuenta del cofre a 0
	ld (0e1c4h),a		;988b
	inc a			;988e   ; el cofre en marcha
	ld (0e1c3h),a		;988f
	ld (0e192h),a		;9892
	ld (0e1c5h),hl		;9895   ; donde
	jp salto_lado		;9898
salto_baja_rapido:		; Del 8 al 15: un punto; del 7 abajo, dos
	cp 008h		;989b   ; 8 o mas?
	jr c,salto_baja2		;989d
	inc (ix+000h)		;989f   ; un punto abajo
	inc (ix+004h)		;98a2
	jr salto_coge		;98a5
salto_baja2:
	dec a			;98a7   ; un paso mas
	ld (0e196h),a		;98a8
	inc (ix+000h)		;98ab   ; dos puntos abajo
	inc (ix+000h)		;98ae
	inc (ix+004h)		;98b1
	inc (ix+004h)		;98b4
	jp salto_lado		;98b7
salto_suelo:		; En el suelo: los dibujos de estar de pie; si fue en el sitio, mira la casilla 0x6C; se acaba el salto
	ld hl,(0e18ah)		;98ba   ; (este HL no se usa)
	ld a,(0e19ch)		;98bd   ; hacia donde mira?
	cp 001h		;98c0
	jr nz,salto_suelo_izq		;98c2
	ld a,(0e00ah)		;98c4   ; la fase 4 o mas con el objeto 0x6A: un sprite
	cp 004h		;98c7
	jr c,salto_suelo_der		;98c9
	ld a,(0e1b4h)		;98cb
	and a			;98ce
	jr z,salto_suelo_der		;98cf
	ld (ix+002h),02ch		;98d1   ; 0x2C...
	ld (ix+004h),0f0h		;98d5   ; ...y el segundo fuera
	jr salto_suelo_der2		;98d9
salto_suelo_der:
	ld (ix+002h),028h		;98db   ; 0x28 y 0x2C
	ld a,(ix+000h)		;98df
	ld (ix+004h),a		;98e2
	ld (ix+006h),02ch		;98e5
salto_suelo_der2:
	ld a,(ix+001h)		;98e9   ; (el inc hl no sirve: HL se carga otra vez en 0x991A)
	cp 07ch		;98ec
	jr c,salto_fin		;98ee
	inc hl			;98f0
	jr salto_fin		;98f1
salto_suelo_izq:
	ld a,(0e00ah)		;98f3   ; a la izquierda: la fase 4 o mas con el objeto, un sprite
	cp 004h		;98f6
	jr c,salto_suelo_izq2		;98f8
	ld a,(0e1b4h)		;98fa
	and a			;98fd
	jr z,salto_suelo_izq2		;98fe
	ld (ix+002h),004h		;9900   ; 0x04 y el segundo fuera
	ld (ix+004h),0f0h		;9904
	jr salto_suelo_izq3		;9908
salto_suelo_izq2:
	ld (ix+002h),000h		;990a   ; 0x00 y 0x04
	ld (ix+006h),004h		;990e
salto_suelo_izq3:
	ld a,(ix+001h)		;9912
	cp 07dh		;9915
	jr nc,salto_fin		;9917
	dec hl			;9919
salto_fin:
	ld hl,(0e18ah)		;991a   ; la casilla del protagonista
	ld a,(0e197h)		;991d   ; fue en el sitio?
	and a			;9920
	jr z,salto_fin_sitio		;9921
	jr salto_fin_todo		;9923
salto_fin_sitio:
	xor a			;9925
	ld (0e194h),a		;9926
	call casilla_para		;9929   ; un agujero?
salto_fin_todo:
	xor a			;992c   ; se acaba el salto
	ld (0e194h),a		;992d
	ld (0e195h),a		;9930
	ld (0e197h),a		;9933
	ld (0e192h),a		;9936
	ld (0e040h),a		;9939   ; el boton B gastado
	ret			;993c
salto_lado:		; El salto de lado (0xE197): un punto por cuadro hacia su lado, 8 por casilla, con el muro y la pantalla como al andar
	ld a,(0e197h)		;993d   ; en el sitio?
	and a			;9940
	jp z,salto_dibujo		;9941
	cp 001h		;9944   ; a la derecha?
	jr nz,salto_izq_lado		;9946
	ld a,(0e19eh)		;9948   ; un punto mas
	inc a			;994b
	ld (0e19eh),a		;994c
	cp 001h		;994f   ; el primero?
	jr nz,salto_der_sigue		;9951
	ld hl,(0e18ah)		;9953   ; la casilla de arriba a la derecha...
	inc hl			;9956
	ld de,(0e1ceh)		;9957
	and a			;995b
	sbc hl,de		;995c
	ld a,(hl)			;995e
	cp 040h		;995f   ; ...un muro?
	jr nz,salto_der_mueve		;9961
salto_lado_para:
	xor a			;9963   ; parado: ya en el sitio
	ld (0e19eh),a		;9964
	ld (0e197h),a		;9967
	jp salto_dibujo		;996a
salto_der_mueve:
	call pantalla_corre		;996d   ; corre la pantalla?
	and a			;9970
	jr nz,salto_der_sprite		;9971
	jp salto_dibujo		;9973
salto_der_sprite:
	ld a,(ix+001h)		;9976   ; en el borde?
	cp 0ech		;9979
	jr nc,salto_lado_para		;997b
	inc (ix+001h)		;997d   ; un punto a la derecha
	inc (ix+005h)		;9980
	jp salto_dibujo		;9983
salto_der_sigue:
	cp 008h		;9986   ; 8?
	jr c,salto_der_mueve		;9988
	xor a			;998a   ; la casilla siguiente
	ld (0e19eh),a		;998b
	ld hl,(0e18ah)		;998e
	inc hl			;9991
	ld (0e18ah),hl		;9992
	call pantalla_corre		;9995   ; corre la pantalla?
	and a			;9998
	jr nz,salto_der_sprite		;9999
	ld a,(0e193h)		;999b   ; una columna mas
	inc a			;999e
	ld (0e193h),a		;999f
	call otros_corren		;99a2   ; los otros a la izquierda
	jp salto_dibujo		;99a5
salto_izq_lado:		; A la izquierda
	ld a,(0e19eh)		;99a8   ; un punto mas
	inc a			;99ab
	ld (0e19eh),a		;99ac
	cp 001h		;99af   ; el primero?
	jr nz,salto_izq_sigue		;99b1
	ld hl,(0e18ah)		;99b3   ; la casilla de arriba a la izquierda...
	dec hl			;99b6
	ld de,(0e1ceh)		;99b7
	and a			;99bb
	sbc hl,de		;99bc
	ld a,(hl)			;99be
	cp 040h		;99bf   ; ...un muro?
	jr nz,salto_izq_mueve		;99c1
salto_izq_para:
	xor a			;99c3
	ld (0e19eh),a		;99c4
	ld (0e197h),a		;99c7
	jr salto_dibujo		;99ca
salto_izq_mueve:
	call pantalla_corre		;99cc   ; corre la pantalla?
	and a			;99cf
	jr z,salto_dibujo		;99d0
salto_izq_sprite:
	ld a,(ix+001h)		;99d2   ; en el borde?
	cp 005h		;99d5
	jr c,salto_izq_para		;99d7
	dec (ix+001h)		;99d9   ; un punto a la izquierda
	dec (ix+005h)		;99dc
	jr salto_dibujo		;99df
salto_izq_sigue:
	cp 008h		;99e1   ; 8?
	jr c,salto_izq_mueve		;99e3
	xor a			;99e5
	ld (0e19eh),a		;99e6
	ld hl,(0e18ah)		;99e9   ; la casilla siguiente
	dec hl			;99ec
	ld (0e18ah),hl		;99ed
	call pantalla_corre		;99f0   ; corre la pantalla?
	and a			;99f3
	jr nz,salto_izq_sprite		;99f4
	ld a,(0e193h)		;99f6   ; una columna menos
	dec a			;99f9
	ld (0e193h),a		;99fa
	call otros_corren		;99fd   ; los otros a la derecha
salto_dibujo:		; Los dibujos del salto: en el sitio 0x40 (derecha) o 0x18 (izquierda); de lado, 0x38 o 0x10
	ld a,(0e197h)		;9a00   ; de lado?
	and a			;9a03
	jr nz,salto_dibujo_lado		;9a04
	ld a,(0e19ch)		;9a06   ; hacia donde mira?
	cp 001h		;9a09
	jr nz,salto_dibujo_izq		;9a0b
	ld b,040h		;9a0d   ; 0x40
	jr salto_dibujo_pon		;9a0f
salto_dibujo_izq:
	ld b,018h		;9a11   ; 0x18
salto_dibujo_pon:
	xor a			;9a13
	add a,b			;9a14
	ld b,a			;9a15
	ld a,(0e00ah)		;9a16   ; la fase 4 o mas con el objeto: un sprite
	cp 004h		;9a19
	jr c,salto_dibujo_dos		;9a1b
	ld a,(0e1b4h)		;9a1d
	and a			;9a20
	jr z,salto_dibujo_dos		;9a21
	ld a,004h		;9a23   ; el dibujo + 4...
	add a,b			;9a25
	ld (ix+002h),a		;9a26
	ld (ix+004h),0f0h		;9a29   ; ...y el segundo fuera
	ret			;9a2d
salto_dibujo_dos:
	ld a,b			;9a2e   ; el primero
	ld (ix+002h),a		;9a2f
	add a,004h		;9a32   ; el segundo, + 4
	ld (ix+006h),a		;9a34
	ld a,(ix+000h)		;9a37   ; a la misma Y
	ld (ix+004h),a		;9a3a
	ret			;9a3d
salto_dibujo_lado:
	ld a,(0e19ch)		;9a3e   ; hacia donde mira?
	cp 001h		;9a41
	jr nz,salto_dibujo_lado_izq		;9a43
	ld b,038h		;9a45   ; 0x38
	jr salto_dibujo_pon		;9a47
salto_dibujo_lado_izq:
	ld b,010h		;9a49   ; 0x10
	jr salto_dibujo_pon		;9a4b
mapa_fase:		; El mapa de la fase en la RAM (0xE700): la 1 sale comprimida de 0x9EBC; la 5, de 0xB764 y relleno; la 2 a la 4 se hacen con filas fijas y luego las piezas de la tabla 0xBE3F
	ld a,(0e00ah)		;9a4d   ; la fase 5?
	cp 005h		;9a50
	jp z,mapa_fase5		;9a52
	cp 001h		;9a55   ; la 1?
	jp z,mapa_fase1		;9a57
	call mapa_blanco		;9a5a   ; el mapa en blanco (0xA0)
	ld hl,0e700h		;9a5d   ; la fila 0: 0xB1 0xB2 (48 parejas = 96 casillas, una fila de 0x60)
	ld b,030h		;9a60
mapa_fila_b1:
	ld (hl),0b1h		;9a62   ; 0xB1...
	inc hl			;9a64
	ld (hl),0b2h		;9a65   ; ...0xB2
	inc hl			;9a67
	djnz mapa_fila_b1		;9a68
	ld b,030h		;9a6a   ; 48 parejas
mapa_fila_b5:		; La fila 1: 0xB5 0xB6
	ld (hl),0b5h		;9a6c   ; 0xB5...
	inc hl			;9a6e
	ld (hl),0b6h		;9a6f   ; ...0xB6
	inc hl			;9a71
	djnz mapa_fila_b5		;9a72
	ld b,060h		;9a74   ; una fila
mapa_fila_bf53:		; La fila 2: las seis casillas de 0xBF53 repetidas
	ld de,0bf53h		;9a76
	ld c,006h		;9a79
mapa_fila_bf53_casilla:
	ld a,(de)			;9a7b
	ld (hl),a			;9a7c
	inc hl			;9a7d
	inc de			;9a7e
	dec b			;9a7f   ; 0x60 casillas
	jr z,mapa_suelo		;9a80
	dec c			;9a82   ; seis y otra vez
	jr z,mapa_fila_bf53		;9a83
	jr mapa_fila_bf53_casilla		;9a85
mapa_suelo:		; El suelo: la fila 21 (0xEEE0) de 0x5E
	ld hl,0eee0h		;9a87
	ld b,060h		;9a8a
mapa_suelo_casilla:
	ld (hl),05eh		;9a8c
	inc hl			;9a8e
	djnz mapa_suelo_casilla		;9a8f
	ld hl,0ea00h		;9a91   ; las filas 8, 14 y 20: 0xB0 (los pisos)
	ld de,001e0h		;9a94
	ld c,003h		;9a97
mapa_piso:
	ld b,060h		;9a99
mapa_piso_casilla:
	ld (hl),0b0h		;9a9b
	inc hl			;9a9d
	djnz mapa_piso_casilla		;9a9e
	add hl,de			;9aa0   ; y cinco filas mas
	dec c			;9aa1
	jr nz,mapa_piso		;9aa2
	jp mapa_piezas		;9aa4   ; y las piezas
mapa_fase5:		; La 5: comprimida desde 0xB764, y despues ocho bandas de 0xA0 en blanco + 32 de 0xB0, y ocho filas de 0x5E 0x5F
	call mapa_blanco		;9aa7
	ld hl,0b764h		;9aaa   ; comprimida
	call mapa_rle		;9aad
	ex de,hl			;9ab0   ; DE (el final) a HL
	ld de,000a0h		;9ab1
	ld c,008h		;9ab4   ; ocho veces
mapa5_banda:
	ld b,020h		;9ab6
	add hl,de			;9ab8   ; cinco filas en blanco...
mapa5_b0:
	ld (hl),0b0h		;9ab9   ; ...y una de 0xB0
	inc hl			;9abb
	djnz mapa5_b0		;9abc
	dec c			;9abe
	jr nz,mapa5_banda		;9abf
	ld c,008h		;9ac1
mapa5_suelo:
	ld b,010h		;9ac3
mapa5_suelo_casilla:
	ld (hl),05eh		;9ac5   ; 0x5E...
	inc hl			;9ac7
	ld (hl),05fh		;9ac8   ; ...0x5F
	inc hl			;9aca
	djnz mapa5_suelo_casilla		;9acb
	dec c			;9acd   ; ocho filas
	jr nz,mapa5_suelo		;9ace
	jp mapa_piezas		;9ad0   ; y las piezas
mapa_fase1:		; La 1: comprimida desde 0x9EBC
	ld hl,09ebch		;9ad3
mapa_rle:		; Descomprime HL a 0xE700: un byte con la mitad alta a 0 es una cuenta (el siguiente se repite tantas veces); cualquier otro va tal cual; 0xFF acaba
	ld de,0e700h		;9ad6   ; a 0xE700
mapa_rle_byte:
	ld a,(hl)			;9ad9
	cp 0ffh		;9ada   ; 0xFF: acaba
	ret z			;9adc
	and 0f0h		;9add   ; la mitad alta a 0: cuenta
	jr z,mapa_rle_cuenta		;9adf
	ld a,(hl)			;9ae1   ; tal cual
	ld (de),a			;9ae2
	inc hl			;9ae3
	inc de			;9ae4
	jr mapa_rle_byte		;9ae5
mapa_rle_cuenta:
	ld b,(hl)			;9ae7   ; la cuenta
	inc hl			;9ae8
	ld a,(hl)			;9ae9   ; el byte
	inc hl			;9aea
mapa_rle_repite:
	ld (de),a			;9aeb
	inc de			;9aec
	djnz mapa_rle_repite		;9aed
	jr mapa_rle_byte		;9aef
pieza_lista:		; La lista siguiente de piezas (0xE1C0): cuantas (0xE1C2) y la primera direccion del mapa en HL
	ld de,(0e1c0h)		;9af1   ; donde va la lista
pieza_lista_de:
	ld a,(de)			;9af5   ; cuantas
	ld (0e1c2h),a		;9af6
	inc de			;9af9
pieza_dir:		; La direccion siguiente de la lista en HL
	ld a,(de)			;9afa   ; la direccion...
	ld l,a			;9afb
	inc de			;9afc
	ld a,(de)			;9afd
	ld h,a			;9afe
	inc de			;9aff
	ld (0e1c0h),de		;9b00   ; ...y la lista sigue
	ret			;9b04
mapa_piezas:		; Las piezas de la fase (la tabla 0xBE3F por la fase, desde la 2): seis listas, una por clase (la septima desde la fase 4), cada una con cuantas y sus direcciones
	ld hl,0be3fh		;9b05   ; la tabla...
	ld a,(0e00ah)		;9b08   ; ...por (fase - 2) x 2
	dec a			;9b0b
	dec a			;9b0c
	add a,a			;9b0d
	add a,l			;9b0e
	jr nc,mapa_piezas_tabla		;9b0f
	inc h			;9b11
mapa_piezas_tabla:
	ld l,a			;9b12
	ld e,(hl)			;9b13   ; la lista de la fase
	inc hl			;9b14
	ld d,(hl)			;9b15
	call pieza_lista_de		;9b16
mapa_piezas1:		; La clase 1: 3 x 3 de 0xBE0D
	call pieza1		;9b19   ; una pieza
	ld a,(0e1c2h)		;9b1c   ; quedan?
	dec a			;9b1f   ; una menos
	jr z,mapa_piezas2		;9b20
	ld (0e1c2h),a		;9b22
	ld de,(0e1c0h)		;9b25   ; la direccion siguiente
	call pieza_dir		;9b29
	jr mapa_piezas1		;9b2c
mapa_piezas2:		; La clase 2: 3 x 3 de 0xBE36
	call pieza_lista		;9b2e   ; la lista siguiente
mapa_piezas2_una:
	call pieza2		;9b31   ; una pieza
	ld a,(0e1c2h)		;9b34
	dec a			;9b37   ; una menos
	jr z,mapa_piezas3		;9b38
	ld (0e1c2h),a		;9b3a
	ld de,(0e1c0h)		;9b3d
	call pieza_dir		;9b41   ; la direccion siguiente
	jr mapa_piezas2_una		;9b44
mapa_piezas3:		; La clase 3: 4 x 4 de 0xBE16
	call pieza_lista		;9b46   ; la lista siguiente
mapa_piezas3_una:
	call pieza3		;9b49   ; una pieza
	ld a,(0e1c2h)		;9b4c
	dec a			;9b4f   ; una menos
	jr z,mapa_piezas4		;9b50
	ld (0e1c2h),a		;9b52
	ld de,(0e1c0h)		;9b55
	call pieza_dir		;9b59   ; la direccion siguiente
	jr mapa_piezas3_una		;9b5c
mapa_piezas4:		; La clase 4: 4 x 4 de 0xBE26
	call pieza_lista		;9b5e   ; la lista siguiente
mapa_piezas4_una:
	call pieza4		;9b61   ; una pieza
	ld a,(0e1c2h)		;9b64
	dec a			;9b67   ; una menos
	jr z,mapa_piezas5		;9b68
	ld (0e1c2h),a		;9b6a
	ld de,(0e1c0h)		;9b6d
	call pieza_dir		;9b71   ; la direccion siguiente
	jr mapa_piezas4_una		;9b74
mapa_piezas5:		; La clase 5: la escalera de 0xBE01 (seis filas de 3, la casilla 0x3F al final)
	call pieza_lista		;9b76   ; la lista siguiente
mapa_piezas5_una:
	call pieza5		;9b79   ; una pieza
	ld a,(0e1c2h)		;9b7c
	dec a			;9b7f   ; una menos
	jr z,mapa_piezas6		;9b80
	ld (0e1c2h),a		;9b82
	ld de,(0e1c0h)		;9b85
	call pieza_dir		;9b89   ; la direccion siguiente
	jr mapa_piezas5_una		;9b8c
mapa_piezas6:		; La clase 6: la escalera de 0xBE07
	call pieza_lista		;9b8e   ; la lista siguiente
mapa_piezas6_una:
	call pieza6		;9b91   ; una pieza
	ld a,(0e1c2h)		;9b94
	dec a			;9b97   ; una menos
	jr z,mapa_piezas7		;9b98
	ld (0e1c2h),a		;9b9a
	ld de,(0e1c0h)		;9b9d
	call pieza_dir		;9ba1   ; la direccion siguiente
	jr mapa_piezas6_una		;9ba4
mapa_piezas7:		; Desde la fase 4, la clase 7: cinco filas de una casilla (0xBE00)
	ld a,(0e00ah)		;9ba6   ; la fase 4 o mas?
	cp 004h		;9ba9
	ret c			;9bab
	call pieza_lista		;9bac   ; la lista siguiente
mapa_piezas7_una:
	call pieza7		;9baf   ; una pieza
	ld a,(0e1c2h)		;9bb2
	dec a			;9bb5   ; una menos
	jr z,mapa_piezas_fin		;9bb6
	ld (0e1c2h),a		;9bb8
	ld de,(0e1c0h)		;9bbb
	call pieza_dir		;9bbf   ; la direccion siguiente
	jr mapa_piezas7_una		;9bc2
mapa_piezas_fin:
	ret			;9bc4

; ----------------------------------------------------------------------
; DATOS ret_muerto: Un "ret" detras de otro: nadie salta aqui
;   0x9bc5..0x9bc6  (1 bytes)
DATA_ret_muerto:
	defb 0c9h	; 9bc5

; ======================================================================
; CODIGO 0x9bc6..0x9c8c  (198 bytes)
; ======================================================================


pieza7:		; Cinco filas de la casilla de 0xBE00, una debajo de otra
	ld b,005h		;9bc6   ; cinco filas
	ld de,0be00h		;9bc8
pieza7_fila:
	ld a,(de)			;9bcb   ; la casilla
	ld (hl),a			;9bcc
	push de			;9bcd   ; la fila siguiente: 0x60 casillas mas (0x20 en la 5)
	ld a,(0e00ah)		;9bce   ; la fase 5?
	cp 005h		;9bd1
	jr nz,pieza7_ancho		;9bd3
	ld de,00020h		;9bd5
	jr pieza7_baja		;9bd8
pieza7_ancho:
	ld de,00060h		;9bda
pieza7_baja:
	add hl,de			;9bdd
	pop de			;9bde
	djnz pieza7_fila		;9bdf
	ret			;9be1
pieza5:		; La escalera de 0xBE01: la primera fila de 0xBE01, las otras cinco de 0xBE04, cada una una casilla a la derecha; y 0x3F al final
	ld b,006h		;9be2   ; seis filas
	ld de,0be01h		;9be4   ; la primera fila de 0xBE01
	ld c,003h		;9be7
	jr pieza5_casilla		;9be9
pieza5_fila:
	ld c,003h		;9beb
	ld de,0be04h		;9bed   ; las otras de 0xBE04
pieza5_casilla:
	ld a,(de)			;9bf0   ; una casilla
	ld (hl),a			;9bf1
	inc hl			;9bf2
	inc de			;9bf3
	dec c			;9bf4
	jr nz,pieza5_casilla		;9bf5
	push de			;9bf7   ; la fila siguiente, una casilla a la derecha (0x60 - 3 + 1)
	ld a,(0e00ah)		;9bf8
	cp 005h		;9bfb
	jr nz,pieza5_ancho		;9bfd
	ld de,0001eh		;9bff
	jr pieza5_baja		;9c02
pieza5_ancho:
	ld de,0005eh		;9c04
pieza5_baja:
	add hl,de			;9c07
	pop de			;9c08
	djnz pieza5_fila		;9c09
	inc hl			;9c0b   ; y la casilla 0x3F
	ld (hl),03fh		;9c0c
	ret			;9c0e
pieza6:		; La escalera de 0xBE07: igual, cada fila una casilla a la izquierda (0x60 - 3 - 1)
	ld b,006h		;9c0f   ; seis filas
	ld de,0be07h		;9c11   ; la primera de 0xBE07
	ld c,003h		;9c14
	jr pieza6_casilla		;9c16
pieza6_fila:
	ld c,003h		;9c18
	ld de,0be0ah		;9c1a   ; las otras de 0xBE0A
pieza6_casilla:
	ld a,(de)			;9c1d   ; una casilla
	ld (hl),a			;9c1e
	inc hl			;9c1f
	inc de			;9c20
	dec c			;9c21
	jr nz,pieza6_casilla		;9c22
	push de			;9c24   ; la fila siguiente, una casilla a la izquierda
	ld a,(0e00ah)		;9c25
	cp 005h		;9c28
	jr nz,pieza6_ancho		;9c2a
	ld de,0001ch		;9c2c
	jr pieza6_baja		;9c2f
pieza6_ancho:
	ld de,0005ch		;9c31
pieza6_baja:
	add hl,de			;9c34
	pop de			;9c35
	djnz pieza6_fila		;9c36
	inc hl			;9c38   ; y la casilla 0x3F
	ld (hl),03fh		;9c39
	ret			;9c3b
pieza4:		; 4 x 4 casillas de 0xBE26
	ld de,0be26h		;9c3c   ; la puerta
	jr pieza4x4		;9c3f
pieza3:		; 4 x 4 casillas de 0xBE16
	ld de,0be16h		;9c41   ; el cofre
pieza4x4:
	ld b,004h		;9c44   ; cuatro filas
pieza4x4_fila:
	ld c,004h		;9c46   ; cuatro casillas
pieza4x4_casilla:
	ld a,(de)			;9c48   ; una casilla
	ld (hl),a			;9c49
	inc hl			;9c4a
	inc de			;9c4b
	dec c			;9c4c
	jr nz,pieza4x4_casilla		;9c4d
	push de			;9c4f   ; la fila siguiente: 0x60 - 4
	ld a,(0e00ah)		;9c50   ; la fase 5?
	cp 005h		;9c53
	jr nz,pieza4x4_ancho		;9c55
	ld de,0001ch		;9c57
	jr pieza4x4_baja		;9c5a
pieza4x4_ancho:
	ld de,0005ch		;9c5c
pieza4x4_baja:
	add hl,de			;9c5f
	pop de			;9c60
	djnz pieza4x4_fila		;9c61
	ret			;9c63
pieza2:		; 3 x 3 casillas de 0xBE36
	ld de,0be36h		;9c64   ; la del objeto 0x6A
	jr pieza3x3		;9c67
pieza1:		; 3 x 3 casillas de 0xBE0D
	ld de,0be0dh		;9c69   ; la de 0xBE0D
pieza3x3:
	ld b,003h		;9c6c   ; tres filas
pieza3x3_fila:
	ld c,003h		;9c6e   ; tres casillas
pieza3x3_casilla:
	ld a,(de)			;9c70   ; una casilla
	ld (hl),a			;9c71
	inc hl			;9c72
	inc de			;9c73
	dec c			;9c74
	jr nz,pieza3x3_casilla		;9c75
	push de			;9c77   ; la fila siguiente: 0x60 - 3
	ld a,(0e00ah)		;9c78
	cp 005h		;9c7b
	jr nz,pieza3x3_ancho		;9c7d
	ld de,0001dh		;9c7f
	jr pieza3x3_baja		;9c82
pieza3x3_ancho:
	ld de,0005dh		;9c84
pieza3x3_baja:
	add hl,de			;9c87
	pop de			;9c88
	djnz pieza3x3_fila		;9c89
	ret			;9c8b

; ----------------------------------------------------------------------
; DATOS codigo_muerto: 69 bytes de codigo que nadie llama ("ld a,(0xE19C) /
;   and a / ret z / ld b,0 / add hl,de / djnz..."): ni call ni salto llega, y
;   no corre en las medidas de openMSX
;   0x9c8c..0x9cd1  (69 bytes)
DATA_codigo_muerto:
	defb 03ah,09ch,0e1h,0a7h,0c8h,006h,018h,021h,004h,0e3h,07eh,0a7h,020h,007h,011h,020h	; 9c8c  :......!..~. .. 
	defb 000h,019h,010h,0f6h,0c9h,02bh,02bh,02bh,03ah,09ch,0e1h,0feh,001h,07eh,020h,004h	; 9c9c  .....+++:....~ .
	defb 0d6h,008h,018h,002h,0c6h,008h,038h,008h,077h,011h,023h,000h,019h,010h,0dbh,0c9h	; 9cac  ......8.w.#.....
	defb 0e5h,02bh,0cdh,0c7h,09ch,0e1h,023h,023h,023h,018h,0d3h,0c5h,006h,020h,036h,000h	; 9cbc  .+....###.... 6.
	defb 023h,010h,0fbh,0c1h,0c9h	; 9ccc

; ======================================================================
; CODIGO 0x9cd1..0x9ebc  (491 bytes)
; ======================================================================


sprites_tabla:		; Los 14 de 0xE300 (16 bytes cada uno) a la tabla de sprites de la RAM, desde 0xE110: sus cuatro primeros bytes (Y, X, dibujo, color)
	ld hl,0e300h		;9cd1   ; de 0xE300...
	ld de,0e110h		;9cd4   ; ...a 0xE110 (los cuatro primeros son del protagonista y lo que tira)
	ld b,00eh		;9cd7   ; 14
sprites_copia:		; B sprites: 4 bytes de cada 16
	push bc			;9cd9
	ld bc,00004h		;9cda   ; Y, X, dibujo, color
	ldir		;9cdd   ; copiados
	ld bc,0000ch		;9cdf   ; los otros 12 bytes, no
	add hl,bc			;9ce2
	pop bc			;9ce3
	djnz sprites_copia		;9ce4
	ret			;9ce6
casilla_para:		; La casilla del mapa en HL y las de arriba (DE = el ancho): el agujero (0x6C) tumba al protagonista si no salta (0xE183 = 5, cae); las de 0x30-0x7F que paran devuelven la casilla en A
	ld a,(hl)			;9ce7   ; la casilla
	ld b,a			;9ce8
	cp 06ch		;9ce9   ; el agujero (0x6C)?
	jr z,casilla_6c		;9ceb
	and 0f0h		;9ced   ; la clase (mitad alta)
	cp 050h		;9cef   ; 0x5x o 0x3x: para
	jr z,casilla_para_si		;9cf1
	cp 030h		;9cf3
	jr z,casilla_para_si		;9cf5
	and a			;9cf7   ; la de arriba
	sbc hl,de		;9cf8
	ld a,(hl)			;9cfa
	and 0f0h		;9cfb
	cp 030h		;9cfd   ; 0x3x o 0x4x: para
	jr z,casilla_para_si		;9cff
	cp 040h		;9d01
	jr z,casilla_para_si		;9d03
	and a			;9d05   ; la de mas arriba
	sbc hl,de		;9d06
	ld a,(hl)			;9d08
	and 0f0h		;9d09
	cp 060h		;9d0b   ; 0x6x o 0x7x: para
	jr z,casilla_para_si		;9d0d
	cp 070h		;9d0f
	jr z,casilla_para_si		;9d11
	ld a,b			;9d13   ; nada: la casilla del principio
	ret			;9d14
casilla_6c:
	ld a,(0e194h)		;9d15   ; saltando, nada
	and a			;9d18
	jr nz,casilla_para_si		;9d19
	ld a,005h		;9d1b   ; si no, tocado (5)
	ld (0e183h),a		;9d1d
casilla_para_si:
	ld a,(hl)			;9d20
	ret			;9d21
presentacion:		; La presentacion de CASIO: el logotipo crece desde el centro (0xE1BA de 1 a 20, cada 3 cuadros), la musica 4 y espera 128 cuadros o el boton
	ld a,001h		;9d22   ; el paso 1
	ld (0e1bah),a		;9d24
	ld hl,0180ch		;9d27   ; 0x180C y 0x1AEC: donde van las dos lineas de arriba y de abajo
	ld (0e1bbh),hl		;9d2a
	ld hl,01aech		;9d2d
	ld (0e1bdh),hl		;9d30
presentacion_cuadro:
	ld a,(0e046h)		;9d33   ; el boton?
	and a			;9d36
	jr nz,presentacion_fin		;9d37
	ld a,(0e014h)		;9d39   ; cada 3 cuadros
	cp 003h		;9d3c
	jr c,presentacion_cuadro		;9d3e
	xor a			;9d40   ; la cuenta a 0
	ld (0e014h),a		;9d41
	call presentacion_lineas		;9d44   ; el final, si toca
	call presentacion_crece		;9d47   ; el logotipo
	ld hl,0e1bah		;9d4a
	inc (hl)			;9d4d
	ld a,(hl)			;9d4e
	cp 015h		;9d4f   ; 21: se acaba
	jr nc,presentacion_musica		;9d51
	cp 009h		;9d53   ; desde el 9...
	jr c,presentacion_sigue		;9d55
	ld hl,(0e1bbh)		;9d57   ; ...la de arriba baja una fila...
	ld bc,00020h		;9d5a
	add hl,bc			;9d5d
	ld (0e1bbh),hl		;9d5e
	ld hl,(0e1bdh)		;9d61
	sbc hl,bc		;9d64
	ld (0e1bdh),hl		;9d66
presentacion_sigue:
	jr presentacion_cuadro		;9d69
presentacion_musica:
	ld a,004h		;9d6b   ; la musica 4
	call musica_pide		;9d6d
presentacion_espera:
	ld a,(0e046h)		;9d70   ; el boton?
	and a			;9d73
	jr nz,presentacion_fin		;9d74
	ld a,(0e014h)		;9d76   ; 128 cuadros
	cp 080h		;9d79
	jr c,presentacion_espera		;9d7b
presentacion_fin:
	xor a			;9d7d   ; el boton gastado
	ld (0e046h),a		;9d7e
	call sonido_pide_calla		;9d81   ; el sonido callado
	call pantalla_borra		;9d84   ; y la pantalla en blanco
	ret			;9d87
presentacion_lineas:		; Desde el paso 9: una fila del logotipo (0xA948 la de abajo, 0xA93F la de arriba) que baja desde arriba y otra que sube desde abajo, con una fila en blanco (0xBF59) detras
	ld a,(0e1bah)		;9d88   ; el paso 9 o mas?
	cp 009h		;9d8b
	ret c			;9d8d
	ld bc,00008h		;9d8e   ; 8 casillas
	ld hl,0a948h		;9d91
	ld de,(0e1bbh)		;9d94   ; en la linea que baja
	call 0005ch		;9d98
	ld de,00020h		;9d9b   ; la fila de encima...
	and a			;9d9e
	sbc hl,de		;9d9f
	ex de,hl			;9da1
	ld hl,0a93fh		;9da2   ; ...con la de arriba de CASIO
	ld bc,00008h		;9da5
	call 0005ch		;9da8
	ld de,00020h		;9dab   ; y la de encima...
	and a			;9dae
	sbc hl,de		;9daf
	ex de,hl			;9db1
	ld hl,0bf59h		;9db2   ; ...en blanco
	ld bc,00008h		;9db5
	call 0005ch		;9db8
	ld bc,00008h		;9dbb   ; la otra linea, la que sube
	ld hl,0a93fh		;9dbe
	ld de,(0e1bdh)		;9dc1   ; desde abajo
	call 0005ch		;9dc5
	ld de,00020h		;9dc8
	add hl,de			;9dcb
	ex de,hl			;9dcc
	ld hl,0a948h		;9dcd   ; con la de abajo
	ld bc,00008h		;9dd0
	call 0005ch		;9dd3
	ld de,00020h		;9dd6
	add hl,de			;9dd9
	ex de,hl			;9dda
	ld hl,0bf59h		;9ddb   ; y una en blanco
	ld bc,00008h		;9dde
	call 0005ch		;9de1
	ret			;9de4
presentacion_crece:		; El logotipo crece desde el centro (fila 12-13, columna 0): el paso (como mucho 9) es cuantas casillas se ven de cada mitad
	ld a,(0e1bah)		;9de5   ; el paso
	ld c,a			;9de8
	cp 009h		;9de9   ; ...no mas de 9
	jr c,presentacion_arriba		;9deb
	ld c,009h		;9ded   ; 9 como mucho
presentacion_arriba:
	ld hl,01980h		;9def   ; en la fila 12, columna 0, menos el paso
	ld b,a			;9df2   ; la columna, hacia la izquierda
	ld a,l			;9df3
	sub b			;9df4
	ld l,a			;9df5
	ex de,hl			;9df6
	ld hl,0a93fh		;9df7   ; la fila de arriba de CASIO...
	ld b,000h		;9dfa
	call 0005ch		;9dfc   ; LDIRVM
	ld de,00020h		;9dff   ; la fila de abajo
	add hl,de			;9e02
	ex de,hl			;9e03
	ld hl,0a948h		;9e04
	ld a,(0e1bah)		;9e07   ; el paso
	cp 009h		;9e0a
	jr c,presentacion_abajo		;9e0c
	ld a,009h		;9e0e   ; 9 como mucho
presentacion_abajo:
	ld c,a			;9e10
	call 0005ch		;9e11   ; LDIRVM
	ld hl,01960h		;9e14   ; la otra mitad, desde la fila 11
	ld a,(0e1bah)		;9e17   ; el paso
	ld c,a			;9e1a
	cp 009h		;9e1b
	jr c,presentacion_izq		;9e1d
	sub 009h		;9e1f   ; pasado el 9: se corre
	add a,l			;9e21
	ld l,a			;9e22
	ld c,009h		;9e23   ; 9
presentacion_izq:
	ex de,hl			;9e25
	ld hl,0a947h		;9e26   ; desde el final, hacia atras
	ld a,l			;9e29
	sub c			;9e2a
	jr nc,presentacion_izq_va		;9e2b
	dec h			;9e2d
presentacion_izq_va:
	ld l,a			;9e2e
	call 0005ch		;9e2f   ; LDIRVM
	ld de,00020h		;9e32   ; la fila de abajo
	add hl,de			;9e35
	ex de,hl			;9e36
	ld a,(0e1bah)		;9e37   ; el paso
	ld c,a			;9e3a
	cp 009h		;9e3b
	jr c,presentacion_abajo2		;9e3d
	ld c,009h		;9e3f   ; 9 como mucho
presentacion_abajo2:
	ld hl,0a950h		;9e41   ; la fila de abajo, desde el final
	ld a,l			;9e44
	sub c			;9e45
	jr nc,presentacion_abajo2_va		;9e46
	dec h			;9e48
presentacion_abajo2_va:
	ld l,a			;9e49
	call 0005ch		;9e4a   ; LDIRVM
	ret			;9e4d
otros_corren:		; La pantalla corre: los 28 de 0xE300 que estan (+4) se mueven 8 puntos al otro lado (a la izquierda si el protagonista va a la derecha, 0xE19C = 1)
	ld iy,0e300h		;9e4e   ; desde 0xE300
	ld de,00010h		;9e52   ; de 16 en 16
	ld b,01ch		;9e55   ; 28
	ld a,(0e19ch)		;9e57   ; hacia donde va?
	cp 001h		;9e5a
	jr nz,otros_corren_der		;9e5c
otros_corren_izq:
	ld a,(iy+004h)		;9e5e   ; esta?
	and a			;9e61
	jr z,otros_corren_sig		;9e62
	ld a,(iy+001h)		;9e64   ; 8 a la izquierda
	sub 008h		;9e67
	ld (iy+001h),a		;9e69
otros_corren_sig:
	add iy,de		;9e6c
	djnz otros_corren_izq		;9e6e
	ret			;9e70
otros_corren_der:
	ld a,(iy+004h)		;9e71   ; esta?
	and a			;9e74
	jr z,otros_corren_der_sig		;9e75
	ld a,(iy+001h)		;9e77   ; 8 a la derecha
	add a,008h		;9e7a
	ld (iy+001h),a		;9e7c
otros_corren_der_sig:
	add iy,de		;9e7f
	djnz otros_corren_der		;9e81
	ret			;9e83
otros_bajan:		; En la fase 5 la pantalla corre hacia arriba: los que estan, 8 puntos abajo
	ld iy,0e300h		;9e84   ; desde 0xE300
	ld de,00010h		;9e88
	ld b,01ch		;9e8b
otros_bajan_uno:
	ld a,(iy+004h)		;9e8d   ; esta?
	and a			;9e90
	jr z,otros_bajan_sig		;9e91
	ld a,(iy+000h)		;9e93   ; 8 abajo
	add a,008h		;9e96
	ld (iy+000h),a		;9e98
otros_bajan_sig:
	add iy,de		;9e9b
	djnz otros_bajan_uno		;9e9d
	ret			;9e9f
otros_suben:		; ...y hacia abajo: 8 puntos arriba
	ld iy,0e300h		;9ea0   ; desde 0xE300
	ld de,00010h		;9ea4
	ld b,01ch		;9ea7
otros_suben_uno:
	ld a,(iy+004h)		;9ea9   ; esta?
	and a			;9eac
	jr z,otros_suben_sig		;9ead
	ld a,(iy+000h)		;9eaf   ; 8 arriba
	sub 008h		;9eb2
	ld (iy+000h),a		;9eb4
otros_suben_sig:
	add iy,de		;9eb7
	djnz otros_suben_uno		;9eb9
	ret			;9ebb

; ----------------------------------------------------------------------
; DATOS mapa1_rle: El mapa de la fase 1 comprimido (lo descomprime 0x9AD6): un
;   byte 0x01-0x0F es una cuenta y el siguiente se repite; los demas van tal
;   cual; 0xFF al final
;   0x9ebc..0x9fd5  (281 bytes)
DATA_mapa1_rle:
	defb 0b1h,0b2h,0b1h,0b2h,0b1h,0b2h,0b1h,0b2h,0b1h,0b2h,0b1h,00ah,0bah,0b1h,0b2h,0b1h	; 9ebc  ................
	defb 0b2h,0b1h,0b2h,0b1h,0b2h,0b1h,0b2h,0b1h,0b5h,0b6h,0b5h,0b6h,0b5h,0b6h,0b5h,0b6h	; 9ecc  ................
	defb 0b5h,0b6h,0b5h,00ah,0bah,0b5h,0b6h,0b5h,0b6h,0b5h,0b6h,0b5h,0b6h,0b5h,0b6h,0b5h	; 9edc  ................
	defb 00bh,082h,00ah,0b6h,00bh,082h,00bh,083h,082h,0d0h,0d1h,0d1h,0d5h,0d6h,0d1h,0d1h	; 9eec  ................
	defb 0d0h,082h,00bh,083h,003h,083h,090h,092h,003h,083h,090h,092h,002h,083h,0d0h,0d2h	; 9efc  ................
	defb 0d1h,0d5h,0d6h,0d1h,0d3h,0d0h,002h,083h,090h,092h,003h,083h,090h,092h,003h,083h	; 9f0c  ................
	defb 003h,083h,091h,093h,003h,083h,091h,093h,002h,083h,0d0h,0d1h,0d1h,0d4h,0d9h,0d1h	; 9f1c  ................
	defb 0d1h,0d0h,002h,083h,091h,093h,003h,083h,091h,093h,003h,083h,00ch,083h,0d0h,0d2h	; 9f2c  ................
	defb 0d1h,0d5h,0d6h,0d1h,0d3h,0d0h,00ch,083h,05ch,05dh,05ch,05dh,05ch,05dh,05ch,05dh	; 9f3c  ........\]\]\]\]
	defb 05ch,05dh,05ch,05dh,0d0h,0d1h,0d1h,0d5h,0d6h,0d1h,0d1h,0d0h,05ch,05dh,05ch,05dh	; 9f4c  \]\]........\]\]
	defb 05ch,05dh,05ch,05dh,05ch,05dh,05ch,05dh,00ch,0a0h,0d0h,006h,0d7h,0d0h,00ch,0a0h	; 9f5c  \]\]\]\]........
	defb 00ch,0a0h,008h,0a0h,00ch,0a0h,00ch,0a0h,008h,0a0h,00ch,0a0h,00fh,0a0h,00fh,0a0h	; 9f6c  ................
	defb 002h,0a0h,00fh,0a0h,00fh,0a0h,002h,0a0h,00fh,0a0h,00fh,0a0h,002h,0a0h,00fh,0a0h	; 9f7c  ................
	defb 00fh,0a0h,002h,0a0h,00fh,0a0h,00fh,0a0h,002h,0a0h,00fh,0a0h,00fh,0a0h,002h,0a0h	; 9f8c  ................
	defb 00fh,0a0h,00fh,0a0h,002h,0a0h,00fh,0a0h,00fh,0a0h,002h,0a0h,00fh,0beh,00fh,0beh	; 9f9c  ................
	defb 002h,0beh,05eh,05fh,05eh,05fh,05eh,05fh,05eh,05fh,05eh,05fh,05eh,05fh,05eh,05fh	; 9fac  ..^_^_^_^_^_^_^_
	defb 05eh,05fh,05eh,05fh,05eh,05fh,05eh,05fh,05eh,05fh,05eh,05fh,05eh,05fh,05eh,05fh	; 9fbc  ^_^_^_^_^_^_^_^_
	defb 05eh,05fh,00fh,0cfh,00fh,0cfh,002h,0cfh,0ffh	; 9fcc  ^_.......

; ======================================================================
; CODIGO 0x9fd5..0xa0d0  (251 bytes)
; ======================================================================


cofre:		; El cofre (0x61) abriendose, un paso cada 3 cuadros (0xE1C3 de 1 a 4): en el primero se decide que sale (0xE1BF) y, si es 0 o 1, se abre un agujero (casillas 0x6C) en el piso; luego cuatro dibujos de 4 x 4 y el efecto
	ld a,(0e1c4h)		;9fd5   ; cada 3 cuadros
	inc a			;9fd8
	ld (0e1c4h),a		;9fd9
	cp 003h		;9fdc
	ret c			;9fde
	xor a			;9fdf   ; la cuenta a 0
	ld (0e1c4h),a		;9fe0
	ld a,(0e1c3h)		;9fe3   ; el primer paso?
	cp 001h		;9fe6
	jr nz,cofre_dibujo		;9fe8
	ld a,(0e1cah)		;9fea   ; un cofre mas abierto (0xE1CA)
	inc a			;9fed
	ld (0e1cah),a		;9fee
	ld hl,0e1cah		;9ff1
	ld a,(0e00ah)		;9ff4   ; el cofre que da la 2 en cada fase: el 10 en la fase 2...
	cp 002h		;9ff7
	jr nz,cofre_fase3		;9ff9
	ld a,00ah		;9ffb
	jr cofre_cual		;9ffd
cofre_fase3:
	cp 003h		;9fff
	jr nz,cofre_fase4		;a001
	ld a,012h		;a003   ; ...el 18 en la 3...
	jr cofre_cual		;a005
cofre_fase4:
	cp 004h		;a007
	jr nz,cofre_fase5		;a009
	ld a,014h		;a00b   ; ...el 20 en la 4...
	jr cofre_cual		;a00d
cofre_fase5:
	ld a,009h		;a00f   ; ...y el 9 en la 5
cofre_cual:
	cp (hl)			;a011   ; es ese?
	jr nz,cofre_azar		;a012
	ld a,002h		;a014   ; si: sale la 2
	jr cofre_sale		;a016
cofre_azar:
	ld a,r		;a018   ; si no, al azar: 0-3...
	ld c,a			;a01a
	and 003h		;a01b
	cp 002h		;a01d   ; ...el 2 no vale: 0 o 1 segun otro bit
	jr nz,cofre_sale		;a01f
	ld a,c			;a021
	and 004h		;a022
	rrca			;a024
	rrca			;a025
cofre_sale:
	ld (0e1bfh),a		;a026   ; lo que sale
	ld a,(0e1bfh)		;a029
	cp 002h		;a02c   ; 0 o 1: el agujero
	jr nc,cofre_dibujo		;a02e
	ld b,005h		;a030   ; cinco filas mas abajo del cofre
	call filas_por_ancho		;a032
	ld hl,(0e1c5h)		;a035
	add hl,de			;a038
	ld a,(0e00ah)		;a039   ; la fase: cuantas casillas
	ld e,a			;a03c
	ld d,000h		;a03d
	ld b,a			;a03f
cofre_suelo:		; Busca en esa fila un tramo de casillas 0xB0 (el piso) tan largo como la fase, hacia un lado al azar, y lo llena de agujero (0x6C)
	ld a,(hl)			;a040   ; el piso (0xB0)?
	cp 0b0h		;a041
	jr nz,cofre_suelo_otro		;a043
	inc hl			;a045
	djnz cofre_suelo		;a046
	jr cofre_suelo_pon		;a048
cofre_suelo_otro:
	ld b,e			;a04a
	bit 0,c		;a04b   ; hacia la derecha o la izquierda
	jr z,cofre_suelo_izq		;a04d
	inc hl			;a04f
	jr cofre_suelo		;a050
cofre_suelo_izq:
	and a			;a052
	sbc hl,de		;a053
	jr cofre_suelo		;a055
cofre_suelo_pon:
	and a			;a057
	sbc hl,de		;a058
	ld b,e			;a05a
cofre_suelo_6c:
	ld (hl),06ch		;a05b   ; 0x6C
	inc hl			;a05d
	djnz cofre_suelo_6c		;a05e
cofre_dibujo:		; El dibujo del paso: los de 0xA110 (sale 0), 0xA150 (1), 0xA0D0 (2) o 0xBF61 (3), 16 bytes por paso
	ld a,(0e1bfh)		;a060   ; lo que sale
	and a			;a063
	jr z,cofre_dib0		;a064
	cp 001h		;a066
	jr z,cofre_dib1		;a068
	cp 002h		;a06a
	jr z,cofre_dib2		;a06c
	ld hl,0bf61h		;a06e   ; 3: 0xBF61
	jr cofre_dib_paso		;a071
cofre_dib0:
	ld hl,0a110h		;a073   ; 0: 0xA110
	jr cofre_dib_paso		;a076
cofre_dib1:
	ld hl,0a150h		;a078   ; 1: 0xA150
	jr cofre_dib_paso		;a07b
cofre_dib2:
	ld hl,0a0d0h		;a07d   ; 2: 0xA0D0
cofre_dib_paso:
	ld a,(0e1c3h)		;a080   ; + (paso - 1) x 16
	dec a			;a083
	jr z,cofre_pinta		;a084
	ld b,a			;a086
	ld de,00010h		;a087
cofre_dib_suma:
	add hl,de			;a08a
	djnz cofre_dib_suma		;a08b
cofre_pinta:		; 4 x 4 casillas en el mapa, donde esta el cofre (0xE1C5)
	ex de,hl			;a08d
	ld hl,(0e1c5h)		;a08e   ; donde esta
	ld c,004h		;a091   ; cuatro filas
cofre_pinta_fila:
	ld b,004h		;a093
cofre_pinta_casilla:
	ld a,(de)			;a095
	ld (hl),a			;a096
	inc hl			;a097
	inc de			;a098
	djnz cofre_pinta_casilla		;a099
	push de			;a09b   ; la fila siguiente (el ancho - 4)
	ld de,(0e1ceh)		;a09c
	ld a,e			;a0a0
	sub 004h		;a0a1
	ld e,a			;a0a3
	add hl,de			;a0a4
	pop de			;a0a5
	dec c			;a0a6
	jr nz,cofre_pinta_fila		;a0a7
	ld a,(0e1c3h)		;a0a9   ; el paso siguiente
	inc a			;a0ac
	ld (0e1c3h),a		;a0ad
	cp 005h		;a0b0   ; el quinto: acabado
	ret c			;a0b2
	ld a,(0e1bfh)		;a0b3   ; lo que salio: 0 o 1, el efecto 6
	cp 002h		;a0b6
	jr nc,cofre_efecto2		;a0b8
	ld a,006h		;a0ba
	jr cofre_fin		;a0bc
cofre_efecto2:
	cp 002h		;a0be   ; 2: el efecto 4
	jr nz,cofre_efecto3		;a0c0
	ld a,004h		;a0c2
	jr cofre_fin		;a0c4
cofre_efecto3:
	ld a,005h		;a0c6   ; 3: el efecto 5
cofre_fin:
	call efecto_pide		;a0c8   ; el efecto
	xor a			;a0cb   ; el cofre, acabado
	ld (0e1c3h),a		;a0cc
	ret			;a0cf

; ----------------------------------------------------------------------
; DATOS cofre_dib2_tabla: El cofre que da la 2 (el que toca en cada fase):
;   cuatro pasos de 4 x 4 casillas
;   0xa0d0..0xa110  (64 bytes)
DATA_cofre_dib2_tabla:
	defb 063h,0a1h,0a2h,0a3h,063h,0a5h,0a6h,0a7h,062h,0a5h,0a6h,0a7h,0a0h,0a9h,0a4h,0a8h	; a0d0  c...c...b.......
	defb 063h,0a1h,0a2h,0a3h,063h,0a5h,0a6h,0a7h,063h,0a9h,0a4h,0a8h,062h,0a0h,049h,0a0h	; a0e0  c...c...c...b.I.
	defb 063h,0a1h,0a2h,0a3h,063h,0a9h,0a4h,0a8h,063h,04ah,068h,048h,062h,0a0h,049h,0a0h	; a0f0  c...c...cJhHb.I.
	defb 063h,0cch,0cdh,0ceh,063h,04ah,064h,048h,063h,04ah,068h,048h,062h,0a0h,049h,0a0h	; a100  c...cJdHcJhHb.I.

; ----------------------------------------------------------------------
; DATOS cofre_dib0_tabla: El cofre 0: cuatro pasos de 4 x 4 casillas
;   0xa110..0xa150  (64 bytes)
DATA_cofre_dib0_tabla:
	defb 063h,0a1h,0a2h,0a3h,063h,0a5h,0a6h,0a7h,062h,0a5h,0aah,0a7h,0a0h,0a9h,0a4h,0a8h	; a110  c...c...b.......
	defb 063h,0a1h,0a2h,0a3h,063h,0a5h,0a6h,0a7h,063h,0a9h,0a4h,0a8h,062h,09dh,09eh,09fh	; a120  c...c...c...b...
	defb 063h,0a1h,0a2h,0a3h,063h,0a9h,0a4h,0a8h,063h,099h,09ah,09bh,062h,09dh,09eh,09fh	; a130  c...c...c...b...
	defb 063h,0cch,0cdh,0ceh,063h,095h,096h,097h,063h,099h,09ah,09bh,062h,09dh,09eh,09fh	; a140  c...c...c...b...

; ----------------------------------------------------------------------
; DATOS cofre_dib1_tabla: El cofre 1: cuatro pasos de 4 x 4
;   0xa150..0xa190  (64 bytes)
DATA_cofre_dib1_tabla:
	defb 063h,0a1h,0a2h,0a3h,063h,0a5h,0a6h,0a7h,062h,0a5h,0aah,0a7h,0a0h,0a9h,0a4h,0a8h	; a150  c...c...b.......
	defb 063h,0a1h,0a2h,0a3h,063h,0a5h,0a6h,0a7h,063h,0a9h,0a4h,0a8h,062h,0a0h,09ch,0a0h	; a160  c...c...c...b...
	defb 063h,0a1h,0a2h,0a3h,063h,0a9h,0a4h,0a8h,063h,0a0h,098h,0a0h,062h,0a0h,09ch,0a0h	; a170  c...c...c...b...
	defb 063h,0cch,0cdh,0ceh,063h,0a0h,094h,0a0h,063h,0a0h,098h,0a0h,062h,0a0h,09ch,0a0h	; a180  c...c...c...b...

; ----------------------------------------------------------------------
; DATOS relleno_a190: 128 bytes sin lectura: 19 de casillas como las del cofre
;   y luego 0xFB 0x00 / 0xFF 0x00 alternados; los dibujos del cofre acaban en
;   0xA18F (el paso 4 de 0xA150)
;   0xa190..0xa210  (128 bytes)
DATA_relleno_a190:
	defb 0a0h,09ch,0a0h,063h,0cch,0cdh,0ceh,063h,0a0h,094h,0a0h,063h,0a0h,098h,0a0h,062h	; a190  ...c...c...c...b
	defb 0a0h,09ch,0a0h,0fbh,000h,0fbh,000h,0fbh,000h,0fbh,000h,0ffh,000h,0fbh,000h,0fbh	; a1a0  ................
	defb 0fbh,000h,0fbh,000h,0fbh,000h,0fbh,000h,0fbh,000h,0fbh,000h,0fbh,000h,0ffh,000h	; a1b0  ................
	defb 000h,0fbh,000h,0fbh,000h,0fbh,000h,0fbh,000h,0fbh,000h,0fbh,000h,0fbh,000h,0fbh	; a1c0  ................
	defb 0fbh,000h,0fbh,000h,0fbh,000h,0ffh,000h,0fbh,000h,0fbh,000h,0fbh,000h,0ffh,000h	; a1d0  ................
	defb 000h,0fbh,000h,0fbh,000h,0ffh,000h,0fbh,000h,0fbh,000h,0fbh,000h,0ffh,000h,0ffh	; a1e0  ................
	defb 0fbh,000h,0fbh,000h,0fbh,000h,0fbh,000h,0fbh,000h,0fbh,000h,0fbh,000h,0fbh,000h	; a1f0  ................
	defb 004h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh	; a200  ................

; ----------------------------------------------------------------------
; DATOS tabla_musicas: Las musicas 0-5 (0 callada), tres punteros cada una
;   (los canales A, B y C)
;   0xa210..0xa234  (36 bytes)
DATA_tabla_musicas:
	defw 0a6a2h,0a6a2h,0a6a2h	; a210
	defw 0a6a6h,0a6c6h,0a6cbh	; a216
	defw 0a6e0h,0a710h,0a719h	; a21c
	defw 0a749h,0a763h,0a773h	; a222
	defw 0a78dh,0a791h,0a795h	; a228
	defw 0a79bh,0a7a2h,0a7a6h	; a22e

; ----------------------------------------------------------------------
; DATOS tabla_efectos_a: Los efectos 0-7 en el canal A: un puntero cada uno
;   0xa234..0xa244  (16 bytes)
DATA_tabla_efectos_a:
	defw 0a642h,0a646h,0a654h,0a65ah,0a65eh,0a678h,0a692h,0a69ah	; a234

; ----------------------------------------------------------------------
; DATOS tabla_efectos_bc: Los efectos 0-7 en los canales B y C: dos punteros
;   cada uno
;   0xa244..0xa264  (32 bytes)
DATA_tabla_efectos_bc:
	defw 0a6a2h,0a6a2h	; a244
	defw 0a7aah,0a7aah	; a248
	defw 0a7b1h,0a7b1h	; a24c
	defw 0a7c3h,0a7c3h	; a250
	defw 0a7c8h,0a7cch	; a254
	defw 0a7d0h,0a7d4h	; a258
	defw 0a7d8h,0a7dch	; a25c
	defw 0a7e0h,0a7e0h	; a260

; ======================================================================
; CODIGO 0xa264..0xa539  (725 bytes)
; ======================================================================


efecto_a_pide:		; Pide el efecto A del canal A (0xE2C0), solo en partida, con la misma regla: se queda el de numero mas bajo
	ld b,a			;a264   ; el numero
	ld a,(0e000h)		;a265   ; en partida?
	and a			;a268
	ret z			;a269
	ld a,b			;a26a
	ld hl,0e2c0h		;a26b   ; el efecto del canal A pedido
	jr pide_va		;a26e
efecto_pide:		; Pide el efecto A (0xE2C2), solo en partida: si ya hay uno, se queda el de numero mas bajo
	ld b,a			;a270   ; el numero
	ld a,(0e000h)		;a271   ; en partida?
	and a			;a274
	ret z			;a275
	ld a,b			;a276
	ld hl,0e2c2h		;a277   ; el efecto pedido
pide_va:
	ld b,a			;a27a
	ld a,(hl)			;a27b   ; ya hay uno?
	and a			;a27c
	jr z,pide_pon		;a27d
	cp b			;a27f   ; el de antes es menor: se queda
	ret c			;a280
pide_pon:
	ld (hl),b			;a281   ; el nuevo
	ret			;a282
musica_pide:		; Pide la musica A (0xE2BE), con la misma regla
	ld hl,0e2beh		;a283   ; la musica pedida
	jr pide_va		;a286
sonido:		; El sonido de cada cuadro (desde la interrupcion): una musica nueva o un efecto nuevo empiezan; los tres canales (0xE280, 0xE292, 0xE2A4, 18 bytes) siguen
	ld hl,0e2bdh		;a288   ; una musica sonando?
	xor a			;a28b
	cp (hl)			;a28c   ; sonando?
	jr nz,sonido_musica_sigue		;a28d
	inc hl			;a28f   ; una pedida?
	cp (hl)			;a290
	jp nz,musica_empieza		;a291
	inc hl			;a294   ; un efecto en el canal A?
	cp (hl)			;a295
	jr nz,sonido_efecto_a_sigue		;a296
	inc hl			;a298   ; pedido?
	cp (hl)			;a299
	jp nz,efecto_a_empieza		;a29a
sonido_mira_bc:
	xor a			;a29d
	inc hl			;a29e   ; un efecto en B y C?
	cp (hl)			;a29f
	jr nz,sonido_efecto_bc_sigue		;a2a0
	inc hl			;a2a2   ; pedido?
	cp (hl)			;a2a3
	jp nz,efecto_empieza		;a2a4
sonido_musica_sigue:		; Una musica sonando: si la pedida tiene numero mas bajo, empieza
	call pide_gana		;a2a7   ; la pedida gana?
	jp c,musica_empieza		;a2aa
	jr sonido_canal_a		;a2ad
sonido_efecto_a_sigue:		; Un efecto en el canal A: igual
	call pide_gana		;a2af   ; la pedida gana?
	jp c,efecto_a_empieza		;a2b2
	jr sonido_mira_bc		;a2b5
sonido_efecto_bc_sigue:		; Un efecto en B y C: igual
	call pide_gana		;a2b7   ; la pedida gana?
	jp c,efecto_empieza		;a2ba
sonido_canal_a:		; El canal A: su bloque a 0xE2C3, un paso y de vuelta
	ld a,(0e2bdh)		;a2bd   ; la musica?
	and a			;a2c0
	jr nz,sonido_canal_a_va		;a2c1
	ld a,(0e2bfh)		;a2c3   ; o un efecto que use el canal A?
	and a			;a2c6
	jr z,sonido_canal_b		;a2c7
sonido_canal_a_va:
	ld hl,0e280h		;a2c9   ; el canal A
	call canal_a_trabajo		;a2cc   ; al canal de trabajo
	ld bc,00008h		;a2cf   ; los registros 0 y 8
	xor a			;a2d2   ; el canal 0
	call canal_va		;a2d3
	push af			;a2d6
	ld de,0e280h		;a2d7   ; y de vuelta
	call canal_de_trabajo		;a2da
	pop af			;a2dd
	and a			;a2de   ; sigue?
	jr z,sonido_canal_b		;a2df
	cp 001h		;a2e1   ; 1: acabada
	jp z,musica_acaba		;a2e3
	cp 002h		;a2e6   ; 2: 0xF7, el efecto del canal A acaba
	jp z,efecto_a_acaba		;a2e8
sonido_canal_b:		; El canal B
	ld a,(0e2bdh)		;a2eb   ; la musica o un efecto?
	and a			;a2ee
	jr nz,sonido_canal_b_va		;a2ef
	ld a,(0e2c1h)		;a2f1
	and a			;a2f4
	ret z			;a2f5
sonido_canal_b_va:
	ld hl,0e292h		;a2f6   ; el canal B
	call canal_a_trabajo		;a2f9
	ld bc,00209h		;a2fc   ; los registros 2 y 9
	ld a,(0e088h)		;a2ff   ; los bits del canal B
	rrca			;a302
	ld (0e088h),a		;a303
	ld a,001h		;a306   ; el canal 1
	call canal_va		;a308
	push af			;a30b
	ld de,0e292h		;a30c
	call canal_de_trabajo		;a30f
	pop af			;a312
	cp 003h		;a313   ; 3: sigue
	jr z,sonido_canal_c		;a315
	ld b,a			;a317
	ld a,(0e088h)		;a318   ; los bits de vuelta
	rlca			;a31b
	ld (0e088h),a		;a31c
	ld a,b			;a31f
	and a			;a320
	jp nz,efecto_acaba		;a321   ; acabado
sonido_canal_c:		; El canal C
	ld hl,0e2a4h		;a324
	call canal_a_trabajo		;a327
	ld bc,0040ah		;a32a   ; los registros 4 y 10
	ld a,(0e088h)		;a32d   ; los bits del canal C
	rrca			;a330
	rrca			;a331
	ld (0e088h),a		;a332
	ld a,002h		;a335   ; el canal 2
	call canal_va		;a337
	push af			;a33a
	ld de,0e2a4h		;a33b
	call canal_de_trabajo		;a33e
	pop af			;a341
	cp 003h		;a342
	jp z,ruido_barrido		;a344
	ld b,a			;a347
	ld a,(0e088h)		;a348
	rlca			;a34b
	rlca			;a34c
	ld (0e088h),a		;a34d
	ld a,b			;a350
	and a			;a351   ; acabado
	jp nz,efecto_acaba		;a352
	jp ruido_barrido		;a355
canal_a_trabajo:		; Copia el bloque del canal (HL, 18 bytes) a 0xE2C3
	ld de,0e2c3h		;a358   ; al canal de trabajo
copia18:
	ld bc,00012h		;a35b   ; 18 bytes
	ldir		;a35e
	ret			;a360
canal_de_trabajo:		; Y de vuelta a DE
	ld hl,0e2c3h		;a361
	jr copia18		;a364
canal_paso:		; Un paso del canal de trabajo: si la nota sigue, nada; si no, el byte siguiente de la pieza: una nota (menos de 0xF0) o una orden
	ld hl,0e2cdh		;a366   ; la nota sigue?
	ld a,(hl)			;a369
	and a			;a36a
	jr z,canal_lee		;a36b
	call canal_cuenta		;a36d   ; su cuenta
	and a			;a370
	ret z			;a371   ; sigue
canal_lee:
	ld iy,0e2cdh		;a372
	ld hl,(0e2c3h)		;a376   ; por donde va
	ld a,(hl)			;a379
	cp 0f0h		;a37a   ; una orden?
	jr nc,canal_orden		;a37c
	call nota_pon		;a37e   ; la nota
	call nota_tono		;a381
	ld (0e2c3h),hl		;a384
	ld a,(0e088h)		;a387   ; el canal con tono, sin ruido
	res 0,a		;a38a
	set 3,a		;a38c
canal_mezcla:
	ld c,a			;a38e
	ld a,(0e2d5h)		;a38f   ; corrido al canal
	and a			;a392
	ld b,a			;a393
	ld a,c			;a394
	jr z,canal_mezcla_pon		;a395
canal_mezcla_corre:
	rlca			;a397
	djnz canal_mezcla_corre		;a398
canal_mezcla_pon:
	ld (0e088h),a		;a39a   ; el registro 7
	call psg_mezcla		;a39d
	ld a,003h		;a3a0
	ret			;a3a2
canal_orden:		; Una orden (0xF0 o mas): 0xF0 ruido, 0xFF final, 0xF7 callar, 0xFE al principio, 0xFD-0xF8 las marcas y sus vueltas
	jp z,canal_ruido		;a3a3
	cp 0ffh		;a3a6   ; 0xFF: el final
	jr nz,canal_orden_f7		;a3a8
	ld a,001h		;a3aa
	ret			;a3ac
canal_orden_f7:
	cp 0f7h		;a3ad   ; 0xF7: callar
	jr nz,canal_orden_fe		;a3af
	ld a,002h		;a3b1
	ret			;a3b3
canal_orden_fe:
	cp 0feh		;a3b4   ; 0xFE: al principio
	jr nz,canal_orden_fd		;a3b6
	ld hl,(0e2c5h)		;a3b8
	jr canal_orden_sigue		;a3bb
canal_orden_fd:		; 0xFD n: la marca 1 y cuantas veces
	cp 0fdh		;a3bd
	jr nz,canal_orden_fc		;a3bf
	inc hl			;a3c1   ; cuantas veces...
	ld a,(hl)			;a3c2
	ld (iy+005h),a		;a3c3   ; ...en +5
	inc hl			;a3c6
	ld (0e2c7h),hl		;a3c7   ; la marca 1
	jr canal_orden_sigue		;a3ca
canal_orden_fc:		; 0xFC: vuelve a la marca 1 si quedan
	cp 0fch		;a3cc
	jr nz,canal_orden_fb		;a3ce
	dec (iy+005h)		;a3d0   ; una vez menos
	jr nz,canal_orden_fc_vuelve		;a3d3
	inc hl			;a3d5   ; ya: sigue
	jr canal_orden_sigue		;a3d6
canal_orden_fc_vuelve:
	ld hl,(0e2c7h)		;a3d8   ; a la marca 1
	jr canal_orden_sigue		;a3db
canal_orden_fb:		; 0xFB n: la marca 2
	cp 0fbh		;a3dd
	jr nz,canal_orden_fa		;a3df
	inc hl			;a3e1   ; cuantas veces...
	ld a,(hl)			;a3e2
	ld (iy+006h),a		;a3e3   ; ...en +6
	inc hl			;a3e6
	ld (0e2c9h),hl		;a3e7   ; la marca 2
canal_orden_sigue:		; Sigue leyendo
	ld (0e2c3h),hl		;a3ea   ; por donde va
	jr canal_lee		;a3ed
canal_orden_fa:		; 0xFA: vuelve a la marca 2
	cp 0fah		;a3ef
	jr nz,canal_orden_f9		;a3f1
	dec (iy+006h)		;a3f3   ; una vez menos
	jr nz,canal_orden_fa_vuelve		;a3f6
	inc hl			;a3f8   ; ya: sigue
	jr canal_orden_sigue		;a3f9
canal_orden_fa_vuelve:
	ld hl,(0e2c9h)		;a3fb   ; a la marca 2
	jr canal_orden_sigue		;a3fe
canal_orden_f9:		; 0xF9 n: la marca 3
	cp 0f9h		;a400
	jr nz,canal_orden_f8		;a402
	inc hl			;a404   ; cuantas veces...
	ld a,(hl)			;a405
	ld (iy+007h),a		;a406   ; ...en +7
	inc hl			;a409
	ld (0e2cbh),hl		;a40a   ; la marca 3
	jr canal_orden_sigue		;a40d
canal_orden_f8:		; 0xF8 (o mas): vuelve a la marca 3
	dec (iy+007h)		;a40f   ; una vez menos
	jr nz,canal_orden_f8_vuelve		;a412
	inc hl			;a414   ; ya: sigue
	jr canal_orden_sigue		;a415
canal_orden_f8_vuelve:
	ld hl,(0e2cbh)		;a417   ; a la marca 3
	jr canal_orden_sigue		;a41a
canal_ruido:		; 0xF0: una nota de ruido (el periodo y su barrido) y su duracion; el canal, a ruido en el registro 7
	call ruido_pon		;a41c   ; el ruido
	inc hl			;a41f
	call nota_pon		;a420
	inc hl			;a423
	ld (0e2c3h),hl		;a424   ; por donde va
	ld a,(0e088h)		;a427   ; el canal con ruido, sin tono
	res 3,a		;a42a
	set 0,a		;a42c
	jp canal_mezcla		;a42e
ruido_barrido:		; El barrido del ruido: cada tantos cuadros, el periodo + el paso, unas cuantas veces
	ld a,(0e2b6h)		;a431   ; hay ruido?
	and a			;a434
	ret z			;a435
	ld a,(0e2b7h)		;a436   ; con barrido?
	and a			;a439
	ret z			;a43a
	ld a,(0e2b9h)		;a43b   ; quedan pasos?
	and a			;a43e
	ret z			;a43f
	ld a,(0e2bbh)		;a440   ; la espera...
	dec a			;a443   ; ...un cuadro menos
	ld (0e2bbh),a		;a444
	ret nz			;a447
	ld a,(0e2b9h)		;a448   ; un paso menos
	dec a			;a44b
	ld (0e2b9h),a		;a44c
	ld a,(0e2bah)		;a44f   ; otra vez la espera
	ld (0e2bbh),a		;a452
	ld a,(0e2b8h)		;a455   ; el periodo...
	ld b,a			;a458
	ld a,(0e2bch)		;a459   ; ...mas el paso
	add a,b			;a45c
	ld (0e2b8h),a		;a45d
	jp psg_ruido		;a460   ; al registro 6
canal_va:		; El canal A (0, 1 o 2) en 0xE2D5 y un paso
	ld (0e2d5h),a		;a463
	call canal_paso		;a466
	ret			;a469
pide_gana:		; ¿La pedida (HL + 1) gana a la que suena (HL)? C si es menor; Z si no hay pedida
	ld b,(hl)			;a46a   ; la que suena
	inc hl			;a46b
	ld a,(hl)			;a46c   ; la pedida
	and a			;a46d
	ret z			;a46e
	cp b			;a46f
	ret			;a470
canal_cuenta:		; La nota en marcha: un cuadro menos; con envolvente (+3 la espera, +4 el volumen), el volumen baja uno cada tanto
	inc hl			;a471   ; la duracion...
	dec (hl)			;a472   ; ...un cuadro menos
	jp z,canal_cuenta_fin		;a473
	inc hl			;a476   ; sin envolvente?
	ld a,(hl)			;a477
	and a			;a478
	jp z,canal_cuenta_sigue		;a479
	cp 00fh		;a47c   ; 15: la envolvente corta
	jr z,canal_cuenta_15		;a47e
	inc hl			;a480
	dec (hl)			;a481   ; la cuenta de la envolvente
	jr nz,canal_cuenta_sigue		;a482
	dec hl			;a484
	ld a,(hl)			;a485   ; la espera...
	inc hl			;a486
	ld (hl),a			;a487   ; ...otra vez
	inc hl			;a488
	dec (hl)			;a489   ; el volumen, uno menos
	ld a,(hl)			;a48a
	call psg_c		;a48b   ; al PSG
	and a			;a48e
	jr nz,canal_cuenta_sigue		;a48f
	dec hl			;a491
	dec hl			;a492
	ld (hl),a			;a493
canal_cuenta_sigue:
	xor a			;a494
	ret			;a495
canal_cuenta_15:
	inc hl			;a496
	dec (hl)			;a497   ; la cuenta
	jr nz,canal_cuenta_sigue		;a498
	xor a			;a49a
	dec hl			;a49b
	ld (hl),a			;a49c   ; el volumen a 0
	call psg_c		;a49d
	ret			;a4a0
canal_cuenta_fin:
	dec hl			;a4a1
	xor a			;a4a2
	ld (hl),a			;a4a3   ; acabada: A = 1
	ld a,001h		;a4a4
	ret			;a4a6
ruido_pon:		; El ruido: su periodo fijo o con barrido (periodo, cuantas veces, cada cuanto, el paso)
	ld (iy+000h),a		;a4a7   ; la nota
	inc hl			;a4aa
	ld a,(hl)			;a4ab   ; con barrido?
	ld (0e2b7h),a		;a4ac
	and a			;a4af
	jr nz,ruido_barre		;a4b0
	inc hl			;a4b2
	ld a,(hl)			;a4b3   ; el periodo...
	ld (0e2b8h),a		;a4b4
	call psg_ruido		;a4b7   ; ...registro 6
	xor a			;a4ba   ; sin barrido
	ld (0e2b9h),a		;a4bb
	ld (0e2bah),a		;a4be
	ld (0e2bbh),a		;a4c1
	ld (0e2bch),a		;a4c4
	inc a			;a4c7   ; hay ruido
	ld (0e2b6h),a		;a4c8
	ret			;a4cb
ruido_barre:
	ld (0e2b6h),a		;a4cc   ; hay ruido con barrido
	ld (0e2bch),a		;a4cf
	inc hl			;a4d2
	ld a,(hl)			;a4d3   ; el periodo...
	ld (0e2b8h),a		;a4d4
	call psg_ruido		;a4d7   ; ...registro 6
	inc hl			;a4da
	ld a,(hl)			;a4db   ; cuantas veces...
	ld (0e2b9h),a		;a4dc
	inc hl			;a4df
	ld a,(hl)			;a4e0   ; ...cada cuanto
	ld (0e2bah),a		;a4e1
	ld (0e2bbh),a		;a4e4
	ret			;a4e7
nota_pon:		; Una nota: el byte de arriba es la duracion (0xA539, o el byte siguiente con 0xE), el de abajo el volumen (15: la mitad)
	ld a,(hl)			;a4e8   ; la nota...
	ld (iy+000h),a		;a4e9
	and 00fh		;a4ec   ; ...el volumen (la mitad baja)
	ld (iy+002h),a		;a4ee
	ld a,(hl)			;a4f1   ; la duracion (la mitad alta)...
	and 0f0h		;a4f2
	rrca			;a4f4
	rrca			;a4f5
	rrca			;a4f6
	rrca			;a4f7
	cp 00eh		;a4f8   ; ...0xE: en el byte siguiente
	jr z,nota_duracion_byte		;a4fa
	ld de,0a539h		;a4fc   ; la tabla de duraciones
	add a,e			;a4ff
	jr nc,nota_duracion		;a500
	inc d			;a502
nota_duracion:
	ld e,a			;a503
	ld a,(de)			;a504   ; la duracion
	jr nota_volumen		;a505
nota_duracion_byte:
	inc hl			;a507
	ld a,(hl)			;a508
nota_volumen:
	ld (iy+001h),a		;a509
	ld a,(iy+002h)		;a50c   ; volumen 15?
	cp 00fh		;a50f
	jr nz,nota_cuenta		;a511
	ld a,(iy+001h)		;a513   ; la duracion...
	push bc			;a516
	ld c,a			;a517
	srl a		;a518   ; ...menos la mitad: la espera
	ld b,a			;a51a
	ld a,c			;a51b
	sub b			;a51c
	pop bc			;a51d
nota_cuenta:
	ld (iy+003h),a		;a51e   ; la cuenta de la envolvente
	ld a,00fh		;a521   ; el volumen 15
	ld (iy+004h),a		;a523
	jp psg_c		;a526   ; al PSG
nota_tono:		; El tono de la nota: un byte (el registro B) o dos si el primero es menor de 0x10 (B + 1 el alto)
	inc hl			;a529
	ld a,(hl)			;a52a   ; el primer byte
	cp 010h		;a52b   ; 0x10 o mas: solo el bajo
	jr nc,nota_tono_bajo		;a52d
	call psg_b1		;a52f   ; el alto
	inc hl			;a532
	ld a,(hl)			;a533
nota_tono_bajo:
	call psg_b		;a534   ; el bajo
	inc hl			;a537
	ret			;a538

; ----------------------------------------------------------------------
; DATOS duraciones: Las duraciones de las notas (la mitad alta de la nota,
;   0-13): 0x80, 0x60, 0x40... 1 cuadros
;   0xa539..0xa547  (14 bytes)
DATA_duraciones:
	defb 080h,060h,040h,030h,020h,018h,010h,00ch,008h,006h,004h,003h,002h,001h	; a539  .`@0 .........

; ======================================================================
; CODIGO 0xa547..0xa642  (251 bytes)
; ======================================================================


psg_c:		; WRTPSG: el registro C
	ld e,a			;a547   ; el valor...
	ld a,c			;a548   ; ...el registro C
psg:
	jp 00093h		;a549   ; WRTPSG
psg_b:		; El registro B
	ld e,a			;a54c   ; el registro B
	ld a,b			;a54d
	jr psg		;a54e
psg_b1:		; El registro B + 1
	ld e,a			;a550   ; el registro B + 1
	ld a,b			;a551
	inc a			;a552
	jr psg		;a553
psg_mezcla:		; El registro 7
	ld e,a			;a555   ; el registro 7
	ld a,007h		;a556
	jr psg		;a558
psg_ruido:		; El registro 6
	ld e,a			;a55a   ; el registro 6
	ld a,006h		;a55b
	jr psg		;a55d
musica_empieza:		; Una musica: los tres canales de la tabla 0xA210 (6 bytes por musica)
	ld hl,0a210h		;a55f   ; la tabla de musicas
	ld a,(0e2beh)		;a562   ; la musica pedida...
	ld (0e2bdh),a		;a565   ; ...es la que suena
	ld b,a			;a568   ; x 6
	add a,b			;a569
	add a,b			;a56a
	add a,b			;a56b
	add a,b			;a56c
	add a,b			;a56d
	call canal_a_tabla		;a56e   ; el canal A
	inc hl			;a571
	call canales_bc		;a572
	ld (0e28ah),a		;a575
	ld (0e2beh),a		;a578   ; la pedida, gastada
	ld a,0f8h		;a57b   ; los tres canales con tono
sonido_mezcla:
	ld (0e088h),a		;a57d
	call psg_mezcla		;a580
	jp sonido_canal_a		;a583
musica_acaba:		; El canal A acaba: si hay otra musica pedida, empieza; si no, todo callado
	ld a,(0e2beh)		;a586   ; otra pedida?
	and a			;a589
	jr nz,musica_empieza		;a58a
	ld (0e2bdh),a		;a58c   ; sin musica
	dec a			;a58f   ; 0xFF: todo callado...
sonido_calla:		; Todo callado: el registro 7 a 0xFF y los canales (0xE280, 67 bytes) a cero
	ld (0e088h),a		;a590
	call psg_mezcla		;a593   ; ...registro 7
	ld hl,0e280h		;a596
	ld b,043h		;a599
borra_b:		; B bytes a cero desde HL
	ld (hl),000h		;a59b   ; a cero
	inc hl			;a59d
	djnz borra_b		;a59e
	ret			;a5a0
efecto_a_empieza:		; Un efecto en el canal A (la tabla 0xA234): la musica pierde el canal A mientras suena
	ld hl,0a234h		;a5a1   ; la tabla
	ld a,(0e2c0h)		;a5a4   ; el pedido...
	ld (0e2bfh),a		;a5a7   ; ...es el que suena
	add a,a			;a5aa   ; x 2
	call canal_a_tabla		;a5ab
	xor a			;a5ae   ; sin nota en marcha
	ld (0e28ah),a		;a5af
	ld (0e2c0h),a		;a5b2   ; el pedido, gastado
	ld a,(0e088h)		;a5b5   ; el canal A con tono
	res 0,a		;a5b8
	ld (0e088h),a		;a5ba
	call psg_mezcla		;a5bd
	ld hl,0e2c0h		;a5c0
	jp sonido_mira_bc		;a5c3
efecto_a_acaba:		; Acaba el efecto del canal A: otro pedido, o el canal A callado
	ld a,(0e2c0h)		;a5c6   ; otro pedido?
	and a			;a5c9
	jr nz,efecto_a_empieza		;a5ca
	ld (0e2bfh),a		;a5cc   ; ya no hay
	ld hl,0e280h		;a5cf   ; el canal A a cero
	ld b,012h		;a5d2
	call borra_b		;a5d4
	ld a,(0e088h)		;a5d7   ; el canal A callado
	or 009h		;a5da
mezcla_pon:
	ld (0e088h),a		;a5dc
	jp psg_mezcla		;a5df
efecto_empieza:		; Un efecto en los canales B y C (la tabla 0xA244)
	ld hl,0a244h		;a5e2   ; la tabla
	ld a,(0e2c2h)		;a5e5   ; el pedido es el que suena
	ld (0e2c1h),a		;a5e8
	add a,a			;a5eb   ; x 4
	add a,a			;a5ec
	add a,l			;a5ed
	ld l,a			;a5ee
	call canales_bc		;a5ef
	ld (0e2c2h),a		;a5f2   ; el pedido, gastado
	ld a,(0e088h)		;a5f5   ; B y C con tono
	and 0f9h		;a5f8
	jp sonido_mezcla		;a5fa
efecto_acaba:		; El canal B acaba: otro efecto pedido o los canales B y C callados
	ld a,(0e2c2h)		;a5fd   ; otro pedido?
	and a			;a600
	jr nz,efecto_empieza		;a601
	ld (0e2c1h),a		;a603   ; sin efecto
	ld hl,0e292h		;a606   ; los canales B y C...
	ld b,024h		;a609   ; ...36 bytes a cero
	call borra_b		;a60b
	ld a,(0e088h)		;a60e   ; B y C callados
	or 036h		;a611
	jr mezcla_pon		;a613
canales_bc:		; Los canales B y C desde la tabla HL
	ld e,(hl)			;a615   ; el canal B: su pieza...
	inc hl			;a616
	ld d,(hl)			;a617
	ld (0e292h),de		;a618   ; ...y su principio
	ld (0e294h),de		;a61c
	inc hl			;a620
	ld e,(hl)			;a621   ; el canal C
	inc hl			;a622
	ld d,(hl)			;a623
	ld (0e2a4h),de		;a624
	ld (0e2a6h),de		;a628
	xor a			;a62c   ; sin nota en marcha
	ld (0e29ch),a		;a62d
	ld (0e2aeh),a		;a630
	ret			;a633
canal_a_tabla:		; El canal A desde la tabla
	add a,l			;a634   ; + la musica x 6
	ld l,a			;a635
	ld e,(hl)			;a636   ; el canal A: su pieza...
	inc hl			;a637
	ld d,(hl)			;a638
	ld (0e280h),de		;a639   ; ...y su principio
	ld (0e282h),de		;a63d
	ret			;a641

; ----------------------------------------------------------------------
; DATOS musicas_datos: Las notas de las musicas y los efectos (tablas 0xA210,
;   0xA234 y 0xA244): notas con la duracion en la mitad alta y el volumen en
;   la baja, ordenes 0xF0-0xFF
;   0xa642..0xa7f2  (432 bytes)
DATA_musicas_datos:
	defb 01ch,000h,000h,0f7h,0b2h,000h,080h,0b2h,070h,0b2h,060h,0b2h,060h,0b2h,050h,0b2h	; a642  ........p.`.`.P.
	defb 040h,0f7h,081h,001h,080h,0a1h,040h,0f7h,063h,000h,040h,0f7h,0d1h,000h,010h,0d1h	; a652  @.....@.c.@.....
	defb 040h,0d1h,020h,0d1h,050h,0d1h,030h,0d1h,060h,0d1h,040h,0d1h,070h,0d1h,050h,0d1h	; a662  @. .P.0.`.@.p.P.
	defb 080h,0d1h,060h,0d1h,090h,0f7h,0c1h,000h,0f0h,0c1h,0e0h,0c1h,0d0h,0c1h,0c0h,0c1h	; a672  ..`.............
	defb 0b0h,0c1h,0a0h,0c1h,090h,0c1h,080h,0c1h,070h,0c1h,060h,0c1h,050h,0c1h,040h,0f7h	; a682  ........p.`.P.@.
	defb 0b1h,000h,0e0h,0b1h,050h,0b1h,0d0h,0f7h,0b1h,000h,030h,0b1h,0f0h,0b1h,040h,0f7h	; a692  ....P.....0...@.
	defb 01ch,000h,000h,0ffh,082h,000h,0aah,064h,0beh,082h,0d6h,064h,0e2h,082h,0feh,064h	; a6a2  .......d...d...d
	defb 0d6h,082h,0beh,082h,0aah,082h,0a0h,082h,07fh,064h,08fh,082h,0aah,064h,0beh,081h	; a6b2  .........d...d..
	defb 0d6h,048h,0d6h,0ffh,0f0h,000h,002h,081h,0feh,082h,003h,057h,082h,0f9h,082h,002h	; a6c2  .H.........W....
	defb 0a7h,082h,03bh,082h,001h,0ach,082h,0fch,082h,002h,03bh,082h,0a7h,0feh,062h,000h	; a6d2  ..;.......;...b.
	defb 0aah,062h,08fh,062h,07fh,062h,06bh,082h,07fh,082h,06bh,082h,07fh,082h,08fh,066h	; a6e2  .b.b.bk...k....f
	defb 07fh,082h,08fh,082h,0aah,081h,0beh,081h,0aah,081h,0beh,081h,0d6h,046h,0beh,081h	; a6f2  .............F..
	defb 0beh,081h,0aah,081h,0beh,081h,0d6h,064h,0feh,081h,0aah,081h,0aah,0ffh,081h,003h	; a702  .......d........
	defb 057h,082h,057h,064h,001h,0ach,0feh,082h,001h,053h,082h,0ach,082h,053h,082h,01dh	; a712  W.Wd.....S...S..
	defb 046h,053h,082h,0ach,082h,0fch,082h,0ach,082h,0fch,082h,0ach,082h,054h,046h,0ach	; a722  FS...........TF.
	defb 0feh,0aah,081h,0beh,081h,0d6h,046h,0beh,081h,0beh,081h,0aah,081h,0beh,081h,0d6h	; a732  ......F.........
	defb 064h,0feh,081h,0aah,081h,0aah,0ffh,082h,001h,053h,082h,0ach,082h,053h,082h,01dh	; a742  d........S...S..
	defb 046h,053h,082h,0ach,082h,0fch,082h,0ach,082h,0fch,082h,0ach,082h,054h,046h,0ach	; a752  FS...........TF.
	defb 0ffh,082h,001h,0ach,082h,053h,082h,002h,03bh,082h,0a7h,082h,03bh,082h,001h,0fch	; a762  .....S..;...;...
	defb 0feh,064h,003h,057h,081h,001h,0ach,081h,0ach,081h,0fch,081h,002h,03bh,0feh,0aah	; a772  .d.W.........;..
	defb 082h,08fh,082h,0aah,064h,0d6h,0feh,026h,000h,050h,0ffh,026h,000h,050h,0ffh,026h	; a782  ....d..&.P.&.P.&
	defb 000h,040h,0ffh,081h,000h,000h,026h,020h,0ffh,081h,004h,075h,053h,005h,001h,0ffh	; a792  .@....& ...uS...
	defb 044h,003h,05ah,0ffh,044h,002h,0fah,0ffh,0a2h,000h,040h,083h,000h,0f0h,0ffh,0b1h	; a7a2  D.Z.D.....@.....
	defb 001h,010h,0b1h,0f0h,0b1h,020h,0b1h,0e0h,0b1h,030h,0b1h,0d0h,0b1h,040h,0b1h,0c0h	; a7b2  ..... ...0...@..
	defb 0ffh,0f0h,000h,01fh,062h,0ffh,043h,000h,0d6h,0ffh,043h,000h,0aah,0ffh,043h,000h	; a7c2  ....b.C...C...C.
	defb 035h,0ffh,043h,000h,028h,0ffh,043h,003h,057h,0ffh,043h,002h,081h,0ffh,0c1h,001h	; a7d2  5.C.(.C.W.C.....
	defb 010h,0c1h,050h,0c1h,020h,0c1h,060h,0c1h,030h,0c1h,070h,0c1h,040h,0c1h,080h,0ffh	; a7e2  ..P. .`.0.p.@...

; ----------------------------------------------------------------------
; DATOS relleno_a7f2: 14 bytes sin lectura (0xFB 0x00 alternados) hasta los
;   dibujos de las casillas
;   0xa7f2..0xa800  (14 bytes)
DATA_relleno_a7f2:
	defb 0fbh,000h,0fbh,000h,0fbh,000h,0fbh,000h,0fbh,000h,0fbh,000h,0fbh,000h	; a7f2  ..............

; ----------------------------------------------------------------------
; DATOS casillas_dibujos1: Los dibujos de las casillas 0x30-0x4D: el principio
;   de los 0x600 bytes (0xA800-0xADFF) que pantalla_juego copia a la casilla
;   0x30 de cada tercio; las 0x4E-0x59 salen de lo que sigue (el codigo de
;   0xA8F0 y el logotipo)
;   0xa800..0xa8f0  (240 bytes)
DATA_casillas_dibujos1:
	defb 000h,000h,000h,000h,000h,000h,000h,000h,0ffh,003h,003h,003h,003h,003h,001h,0ffh	; a800  ................
	defb 0ffh,0feh,001h,0feh,0fch,0f0h,0c0h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0fch,0f0h,0c0h	; a810  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,03fh,00fh,00fh,0ffh,07fh,080h,07fh,03fh,00fh,003h,0ffh	; a820  .....?......?...
	defb 0ffh,0c0h,0c0h,0c0h,0c0h,0c0h,080h,0ffh,000h,000h,000h,000h,000h,000h,000h,000h	; a830  ................
	defb 000h,000h,000h,000h,0ffh,03fh,00fh,003h,00fh,01fh,03fh,07fh,03fh,00fh,003h,0ffh	; a840  .....?....?.?...
	defb 0f0h,0f8h,0fch,0feh,0fch,0f0h,0c0h,0ffh,000h,000h,000h,000h,0ffh,0fch,0f0h,0c0h	; a850  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,080h,0fch,0f8h,0f0h,0e0h,0c0h,080h,000h	; a860  ................
	defb 0ffh,03fh,01fh,00fh,007h,003h,001h,000h,0ffh,0ffh,0ffh,0ffh,020h,004h,0ffh,0ffh	; a870  .?.......... ...
	defb 0a1h,0a1h,0a5h,0adh,08dh,0e5h,0a1h,0a1h,008h,018h,038h,078h,0f8h,038h,018h,01ch	; a880  ..........8x.8..
	defb 016h,03fh,035h,01fh,03bh,03fh,01eh,00fh,000h,000h,0feh,0e7h,07ch,0f8h,0deh,0ffh	; a890  .?5.;?......|...
	defb 010h,018h,01ch,01eh,01fh,01ch,018h,038h,068h,0fch,0ach,0f8h,0dch,0fch,078h,0f0h	; a8a0  .......8h.....x.
	defb 000h,000h,07fh,0e7h,03eh,01fh,07bh,0ffh,000h,000h,000h,000h,000h,000h,000h,000h	; a8b0  ....>.{.........
	defb 0c0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0c0h,0ffh,0ffh,07eh,000h,000h,000h,000h,000h	; a8c0  ..........~.....
	defb 003h,007h,007h,007h,007h,007h,007h,003h,000h,000h,000h,000h,000h,000h,000h,000h	; a8d0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a8e0  ................

; ======================================================================
; CODIGO 0xa8f0..0xa93e  (78 bytes)
; ======================================================================


agacha:		; Agachado (la palanca abajo fuera de una escalera): 0xE1BE = 1 y los dibujos 0x48/0x4C (derecha) o 0x20/0x24 (izquierda)
	ld a,(0e198h)		;a8f0   ; en una escalera: nada
	and a			;a8f3
	ret nz			;a8f4
	inc a			;a8f5   ; agachado
	ld (0e1beh),a		;a8f6
	ld a,(0e1b4h)		;a8f9   ; el objeto 0x6A?
	and a			;a8fc
	jr nz,agacha_objeto		;a8fd
agacha_dos:
	ld a,(ix+000h)		;a8ff   ; los dos sprites a la misma Y
	ld (ix+004h),a		;a902
	ld a,(0e19ch)		;a905   ; hacia donde mira?
	cp 001h		;a908
	jr nz,agacha_izq		;a90a
	ld (ix+002h),048h		;a90c   ; 0x48 y 0x4C
	ld (ix+006h),04ch		;a910
	ret			;a914
agacha_izq:
	ld (ix+002h),020h		;a915   ; 0x20 y 0x24
	ld (ix+006h),024h		;a919
	ret			;a91d
agacha_objeto:
	ld a,(0e00ah)		;a91e   ; la fase 4 o mas?
	cp 004h		;a921
	jr c,agacha_dos		;a923
	ld a,(0e19ch)		;a925   ; hacia donde mira?
	cp 001h		;a928
	jr nz,agacha_objeto_izq		;a92a
	ld (ix+002h),04ch		;a92c   ; 0x4C y el segundo fuera
	ld (ix+004h),0f0h		;a930
	ret			;a934
agacha_objeto_izq:
	ld (ix+002h),024h		;a935   ; 0x24 y el segundo fuera
	ld (ix+004h),0f0h		;a939
	ret			;a93d

; ----------------------------------------------------------------------
; DATOS logotipo_casio: Las dos filas de casillas del logotipo de CASIO de la
;   presentacion: 0xA93F la de arriba y 0xA948 la de abajo (nueve cada una)
;   0xa93e..0xa951  (19 bytes)
DATA_logotipo_casio:
	defb 010h,070h,072h,074h,076h,078h,07ah,07ch,07eh,010h,071h,073h,075h,077h,079h,07bh	; a93e  .prtvxz|~.qsuwy{
	defb 07dh,07fh,010h	; a94e

; ----------------------------------------------------------------------
; DATOS casillas_dibujos2: Los dibujos de las casillas 0x5A-0xEF
;   0xa951..0xae00  (1199 bytes)
DATA_casillas_dibujos2:
	defb 081h,042h,03ch,081h,099h,018h,03ch,07ch,0feh,0feh,0fch,0f8h,0f0h,0feh,07fh,0feh	; a951  .B<...<|........
	defb 0fch,0f9h,0f3h,0e7h,0cfh,09fh,03fh,07fh,03fh,09fh,0cfh,0e7h,0f3h,0f9h,0fch,01fh	; a961  ......?.?.......
	defb 0cfh,0e3h,0f8h,0fbh,0f7h,0cfh,03fh,0fch,0fbh,0f7h,06fh,09fh,0cfh,0f7h,0f8h,018h	; a971  ......?...o.....
	defb 018h,018h,018h,01ch,014h,014h,000h,018h,018h,018h,018h,018h,018h,018h,018h,018h	; a981  ................
	defb 018h,018h,018h,01ch,014h,014h,000h,018h,018h,018h,018h,018h,018h,018h,018h,000h	; a991  ................
	defb 000h,038h,07ch,07ch,07ch,07ch,07ch,000h,000h,007h,00fh,01fh,07fh,003h,003h,000h	; a9a1  .8|||||.........
	defb 081h,07eh,07eh,0ffh,0ffh,0ffh,0ffh,000h,000h,0e0h,0f0h,0f8h,0feh,0c0h,0c0h,07ch	; a9b1  .~~............|
	defb 07ch,07ch,07ch,07ch,07ch,038h,000h,00fh,00fh,00fh,00bh,00bh,00fh,00fh,00fh,018h	; a9c1  |||||8..........
	defb 03ch,03ch,03ch,03ch,03ch,03ch,018h,0f0h,0f0h,0f0h,0d0h,0d0h,0f0h,0f0h,0f0h,000h	; a9d1  <<<<<<..........
	defb 000h,011h,011h,015h,055h,055h,0ffh,01fh,03fh,000h,000h,000h,000h,000h,000h,0ffh	; a9e1  ....UU..?.......
	defb 0ffh,000h,000h,000h,000h,000h,000h,0f8h,0fch,000h,000h,000h,000h,000h,000h,000h	; a9f1  ................
	defb 002h,00eh,01ah,032h,022h,062h,000h,07eh,0ffh,0ffh,0ffh,0ffh,0feh,0feh,000h,000h	; aa01  ...2"b.~........
	defb 040h,030h,018h,01ch,03ch,03eh,000h,000h,000h,066h,074h,018h,018h,02eh,066h,062h	; aa11  @0..<>...ft...fb
	defb 0e2h,0e2h,0e2h,0feh,0e2h,0e2h,062h,0fch,0f8h,0f8h,0f1h,0fdh,0e7h,0e3h,0e7h,07eh	; aa21  ......b........~
	defb 07fh,07fh,07fh,07fh,07fh,07fh,07eh,008h,009h,04eh,02ch,038h,018h,018h,008h,000h	; aa31  ......~..N,8....
	defb 062h,022h,032h,01ah,006h,002h,000h,000h,0c7h,0cfh,08fh,08fh,01fh,09fh,07eh,000h	; aa41  b"2...........~.
	defb 07eh,07ch,07ch,078h,070h,040h,000h,000h,000h,000h,000h,000h,000h,000h,000h,007h	; aa51  ~||xp@..........
	defb 003h,001h,001h,001h,001h,001h,007h,0ffh,0ffh,000h,07fh,05fh,07fh,000h,0ffh,0ffh	; aa61  ..........._....
	defb 0ffh,000h,07eh,07ah,07eh,000h,0ffh,0e0h,0c0h,080h,080h,080h,080h,080h,0e0h,0ffh	; aa71  ..~z~...........
	defb 07fh,07fh,07fh,07fh,07fh,07fh,07fh,0ffh,0feh,0feh,0feh,0feh,0feh,0feh,0feh,0ffh	; aa81  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,07fh	; aa91  ................
	defb 07fh,07fh,07fh,07fh,07fh,07fh,07fh,0feh,0feh,0feh,0feh,0feh,0feh,0feh,0feh,000h	; aaa1  ................
	defb 000h,000h,000h,000h,03ch,042h,0ffh,020h,040h,040h,040h,040h,001h,000h,001h,04fh	; aab1  ....<B. @@@@...O
	defb 04fh,07fh,07fh,07fh,07fh,07fh,07fh,0feh,0feh,0feh,0feh,0feh,0feh,0feh,0feh,07fh	; aac1  O...............
	defb 07fh,07fh,07fh,07fh,07fh,07fh,07fh,0f2h,0f2h,0feh,0feh,0feh,0feh,0feh,0feh,080h	; aad1  ................
	defb 080h,080h,080h,080h,07fh,07fh,0ffh,001h,001h,001h,001h,001h,0feh,0feh,0ffh,0ffh	; aae1  ................
	defb 008h,008h,03ch,07eh,040h,040h,07eh,001h,0ffh,042h,03ch,000h,000h,000h,000h,0ffh	; aaf1  ..<~@@~..B<.....
	defb 0ffh,0ffh,0ffh,0ffh,07fh,03fh,01fh,01fh,01fh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; ab01  .....?..........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0f8h,0f8h,0f8h,007h,003h,001h,0ffh,0ffh,0ffh,000h	; ab11  ................
	defb 000h,004h,002h,004h,032h,078h,0c6h,000h,000h,000h,001h,001h,002h,002h,000h,000h	; ab21  ....2x..........
	defb 000h,000h,082h,045h,024h,008h,0c3h,000h,000h,000h,000h,000h,080h,040h,000h,083h	; ab31  ...E$........@..
	defb 001h,000h,008h,018h,010h,030h,020h,001h,002h,001h,000h,000h,000h,000h,004h,065h	; ab41  .....0 ........e
	defb 056h,094h,020h,078h,020h,078h,022h,080h,040h,040h,000h,000h,000h,040h,020h,020h	; ab51  V. x x".@@...@  
	defb 030h,010h,018h,008h,008h,008h,008h,004h,002h,002h,001h,001h,000h,000h,000h,01ch	; ab61  0...............
	defb 000h,018h,024h,002h,080h,061h,01eh,040h,020h,000h,040h,040h,080h,000h,000h,000h	; ab71  ..$..a.@ .@@....
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,00fh,00fh,007h,007h,018h	; ab81  ................
	defb 024h,042h,081h,081h,081h,0ffh,0ffh,000h,000h,000h,000h,0f0h,0f0h,0e0h,0e0h,0ffh	; ab91  $B..............
	defb 0ffh,000h,000h,000h,000h,000h,000h,007h,007h,007h,007h,007h,007h,007h,007h,0ffh	; aba1  ................
	defb 0ffh,0ffh,0ffh,0ffh,0fbh,0ffh,0fbh,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0f0h	; abb1  ................
	defb 0f0h,000h,000h,000h,000h,000h,000h,00fh,00fh,000h,000h,000h,000h,000h,000h,0fbh	; abc1  ................
	defb 0dbh,0dfh,0cbh,0cfh,0dfh,0ffh,0dfh,000h,000h,000h,000h,000h,000h,000h,000h,0ffh	; abd1  ................
	defb 0ffh,0e0h,0efh,0efh,0efh,0efh,0efh,007h,007h,007h,007h,007h,007h,00fh,00fh,0ffh	; abe1  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0f0h,0f0h,0ffh	; abf1  ................
	defb 0ffh,0ffh,0ffh,070h,001h,0ffh,0ffh,07fh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,07fh,0f2h	; ac01  ...p............
	defb 0fah,0fah,0fah,0fah,0fah,0f8h,0f2h,000h,000h,000h,000h,000h,000h,000h,000h,0ffh	; ac11  ................
	defb 0ffh,000h,000h,000h,000h,000h,000h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0fah	; ac21  ................
	defb 0fah,0fah,0fah,0f8h,002h,005h,002h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; ac31  ................
	defb 0ffh,03fh,03fh,03fh,0ffh,0ffh,0ffh,0ffh,0ffh,03fh,03fh,03fh,03fh,03fh,0ffh,072h	; ac41  .???.....?????.r
	defb 0fah,0fah,0fah,0fah,0fah,0f8h,072h,0ffh,0f8h,002h,0fah,0fah,0fah,0fah,0fah,080h	; ac51  ......r.........
	defb 0c0h,01fh,00fh,007h,0fch,001h,0ffh,001h,003h,0f8h,0f0h,0e0h,03fh,080h,0ffh,000h	; ac61  ............?...
	defb 000h,000h,000h,000h,0ffh,0ffh,0ffh,000h,000h,000h,000h,000h,000h,000h,000h,0efh	; ac71  ................
	defb 0efh,0efh,0efh,0efh,0efh,0efh,0efh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; ac81  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0feh	; ac91  ................
	defb 0fdh,0fbh,00fh,017h,027h,047h,087h,087h,047h,027h,017h,00fh,0fbh,0fdh,0feh,0ffh	; aca1  ....'G..G'......
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,007h	; acb1  ................
	defb 007h,007h,007h,007h,007h,007h,007h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; acc1  ................
	defb 000h,000h,000h,000h,000h,000h,000h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h	; acd1  ................
	defb 000h,000h,000h,00fh,00fh,00fh,00fh,018h,024h,042h,081h,081h,081h,0ffh,0ffh,000h	; ace1  ........$B......
	defb 000h,000h,000h,0f0h,0f0h,0f0h,0f0h,0ffh,0ffh,060h,0ffh,002h,004h,020h,0ffh,0fbh	; acf1  .........`... ..
	defb 0fbh,0edh,0edh,0edh,0edh,0fdh,0fbh,0dfh,0dfh,0dbh,0bbh,0bbh,0b3h,0f7h,0f7h,0ffh	; ad01  ................
	defb 00fh,09fh,00fh,00fh,09fh,00fh,0ffh,0ffh,0f0h,0f9h,0f0h,0f0h,0f9h,0f0h,0ffh,0fch	; ad11  ................
	defb 0fch,0fch,0fch,0fch,0fch,0fch,0fch,0feh,0feh,0feh,0feh,0feh,0feh,0feh,0feh,07fh	; ad21  ................
	defb 07fh,07fh,07fh,07fh,07fh,07fh,07fh,0ffh,01fh,0f8h,0c7h,0ffh,0ffh,0ffh,0ffh,07fh	; ad31  ................
	defb 03fh,01fh,00fh,007h,003h,001h,0ffh,03fh,03fh,03fh,03fh,03fh,03fh,03fh,03fh,0feh	; ad41  ?......????????.
	defb 0fch,0f8h,0f0h,0e0h,0c0h,080h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; ad51  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; ad61  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,07fh	; ad71  ................
	defb 07fh,03fh,03fh,01fh,01fh,00fh,00fh,0e7h,0e7h,0f3h,0f3h,0f9h,0f9h,0fch,0fch,0ffh	; ad81  .??.............
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0feh,0feh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,007h	; ad91  ................
	defb 007h,003h,003h,0feh,0fch,0f8h,0f1h,0feh,0feh,0ffh,03fh,03fh,07fh,0ffh,0ffh,07fh	; ada1  ..........??....
	defb 07fh,03fh,03fh,09fh,0ffh,0ffh,0ffh,018h,03ch,07eh,03fh,035h,03fh,07fh,01ch,018h	; adb1  .??.....<~?5?...
	defb 07ch,0feh,0fch,0ach,0feh,07ch,000h,07eh,081h,0bdh,0a1h,0a1h,0bdh,081h,07eh,07fh	; adc1  |....|.~......~.
	defb 080h,080h,080h,080h,080h,080h,07fh,003h,004h,008h,008h,00fh,008h,008h,008h,0c0h	; add1  ................
	defb 020h,010h,010h,0f0h,010h,010h,010h,07fh,080h,080h,07eh,001h,001h,001h,0feh,010h	; ade1   .........~.....
	defb 010h,010h,010h,010h,010h,010h,010h,07eh,081h,081h,081h,081h,081h,081h,07eh	; adf1  .......~......~

; ----------------------------------------------------------------------
; DATOS titulo_dibujos: Los dibujos de las casillas 0x40-0x7F del titulo
;   (0x200 bytes): los kanji grandes, el logotipo y CASIO
;   0xae00..0xb000  (512 bytes)
DATA_titulo_dibujos:
	defb 000h,000h,004h,003h,003h,003h,003h,002h,000h,000h,000h,000h,080h,011h,00fh,003h	; ae00  ................
	defb 000h,000h,000h,000h,038h,0fch,0cch,0beh,000h,003h,001h,007h,003h,003h,006h,004h	; ae10  ....8...........
	defb 006h,006h,004h,00ah,012h,022h,002h,006h,001h,007h,03dh,001h,001h,007h,03dh,003h	; ae20  ....."....=...=.
	defb 0ffh,0d8h,090h,0f0h,0fch,098h,080h,080h,000h,080h,0e0h,03bh,034h,062h,0e3h,042h	; ae30  ...........;4b.B
	defb 006h,004h,00ch,00ch,004h,000h,000h,000h,003h,003h,003h,002h,006h,004h,004h,008h	; ae40  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,070h,0f8h,018h,020h,0f0h,000h	; ae50  ..........p.. ..
	defb 018h,020h,000h,000h,000h,000h,000h,000h,004h,07fh,081h,0b9h,0c1h,09dh,0e3h,083h	; ae60  . ..............
	defb 000h,080h,080h,000h,000h,000h,000h,000h,000h,000h,003h,000h,001h,003h,004h,008h	; ae70  ................
	defb 09fh,0f3h,083h,0c7h,080h,000h,000h,000h,000h,000h,000h,000h,0c0h,060h,030h,010h	; ae80  .............`0.
	defb 000h,000h,000h,000h,000h,003h,000h,001h,000h,000h,000h,006h,03dh,0c3h,023h,0a3h	; ae90  ............=.#.
	defb 000h,000h,000h,000h,080h,000h,000h,000h,000h,000h,000h,001h,003h,000h,000h,002h	; aea0  ................
	defb 076h,05eh,0c6h,03ch,018h,010h,007h,03ch,000h,000h,000h,000h,000h,038h,00ch,046h	; aeb0  v^.<...<.....8.F
	defb 011h,011h,030h,010h,018h,000h,000h,000h,008h,000h,0c0h,038h,01fh,001h,000h,000h	; aec0  ..0........8....
	defb 020h,020h,030h,03ch,0f8h,0c0h,000h,000h,000h,000h,000h,000h,00ch,002h,003h,001h	; aed0    0<............
	defb 000h,000h,010h,00eh,007h,003h,003h,003h,000h,000h,000h,000h,000h,000h,000h,0f0h	; aee0  ................
	defb 000h,040h,038h,00ch,004h,000h,000h,001h,003h,03fh,003h,003h,003h,00fh,074h,086h	; aef0  .@8......?....t.
	defb 0e0h,000h,000h,000h,0fch,00eh,000h,040h,004h,004h,00ch,058h,030h,010h,000h,000h	; af00  .......@...X0...
	defb 004h,00ch,018h,077h,03ch,030h,000h,000h,060h,030h,078h,09ch,00ch,004h,000h,000h	; af10  ...w<0..`0x.....
	defb 000h,000h,000h,008h,006h,003h,002h,002h,000h,000h,000h,000h,010h,00ch,006h,007h	; af20  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,003h,00eh,042h,032h,013h,012h,012h,002h	; af30  ..........B2....
	defb 083h,063h,043h,043h,0c3h,0c2h,087h,03ch,000h,01ch,0f8h,000h,000h,010h,0f8h,00ch	; af40  .cCC...<........
	defb 002h,002h,002h,006h,006h,002h,000h,000h,060h,030h,030h,010h,01fh,010h,000h,000h	; af50  ........`00.....
	defb 018h,030h,030h,0e0h,0f0h,030h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; af60  .00..0..........
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; af70  ................
	defb 000h,000h,03fh,07fh,0ffh,0f0h,0e0h,0e0h,0e0h,0e0h,0e0h,0f0h,0ffh,07fh,03fh,000h	; af80  ..?...........?.
	defb 000h,000h,0e0h,0f0h,0f8h,078h,000h,000h,000h,000h,039h,079h,0f9h,0f3h,0e3h,000h	; af90  .....x....9y....
	defb 000h,000h,03eh,03eh,07fh,077h,077h,0e3h,0e3h,0e3h,0ffh,0ffh,0c1h,080h,080h,000h	; afa0  ..>>.ww.........
	defb 000h,000h,003h,007h,00fh,00fh,00fh,08fh,087h,083h,0c0h,0cfh,0cfh,0e7h,0e3h,000h	; afb0  ................
	defb 000h,000h,0feh,0ffh,0ffh,007h,000h,0feh,0ffh,0ffh,007h,007h,0ffh,0ffh,0feh,000h	; afc0  ................
	defb 000h,000h,038h,039h,0bbh,0bbh,03bh,03bh,03bh,0bbh,0bbh,0bbh,0bbh,039h,038h,000h	; afd0  ..89..;;;....98.
	defb 000h,000h,0ffh,0ffh,0ffh,0c1h,080h,080h,080h,080h,080h,0c1h,0ffh,0ffh,0ffh,000h	; afe0  ................
	defb 000h,000h,080h,0c0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0c0h,080h,000h	; aff0  ................

; ----------------------------------------------------------------------
; DATOS casillas_colores: Los colores de las casillas 0x30-0xEF (0x600 bytes),
;   a 0x2180 en cada tercio
;   0xb000..0xb600  (1536 bytes)
DATA_casillas_colores:
	defb 0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,06fh,0a3h,0a6h,0a3h,0a3h,0a3h,0a3h,06fh	; b000  ........o......o
	defb 06fh,043h,064h,043h,0a6h,0a8h,0a8h,09fh,06fh,03fh,06fh,03fh,06fh,083h,083h,096h	; b010  oCdC....o?o?o...
	defb 06fh,03fh,06fh,03fh,06fh,083h,083h,096h,06fh,043h,064h,043h,0a6h,0a8h,0a8h,09fh	; b020  o?o?o...oCdC....
	defb 06fh,0a3h,0a6h,0a3h,0a3h,0a3h,0a3h,06fh,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h	; b030  o......o........
	defb 0f0h,0f0h,0f0h,0f0h,06fh,080h,080h,090h,0a0h,0a0h,0a0h,0a0h,0a6h,0a8h,0a8h,09fh	; b040  ....o...........
	defb 0a0h,0a0h,0a0h,0a0h,0a6h,0a8h,0a8h,09fh,0f0h,0f0h,0f0h,0f0h,06fh,080h,080h,090h	; b050  ............o...
	defb 0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0a9h,0a0h,0a0h,0a0h,0a0h,0a0h,0a0h,0f0h	; b060  ................
	defb 09fh,0a0h,0a0h,0a0h,0a0h,0a0h,0a0h,0f0h,04fh,04fh,04fh,03fh,063h,063h,03fh,06fh	; b070  ........OOO?cc?o
	defb 063h,063h,063h,063h,063h,063h,063h,063h,0b0h,0b0h,0b0h,0b0h,0b0h,0b0h,0b0h,0b0h	; b080  cccccccc........
	defb 0b0h,0b0h,0b6h,0b0h,0b0h,0b0h,0b6h,0b6h,0f0h,0f0h,0b6h,0b0h,0b0h,0b0h,0b6h,0bfh	; b090  ................
	defb 0b0h,0b0h,0b0h,0b0h,0b0h,0b0h,0b0h,0b0h,0b0h,0b0h,0b6h,0b0h,0b0h,0b0h,0b6h,0b6h	; b0a0  ................
	defb 0f0h,0f0h,0b6h,0b0h,0b0h,0b0h,0b6h,0bfh,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h	; b0b0  ................
	defb 070h,070h,070h,070h,070h,070h,070h,070h,07fh,07fh,070h,0f0h,0f0h,0f0h,0f0h,0f0h	; b0c0  pppppppp..p.....
	defb 070h,070h,070h,070h,070h,070h,070h,070h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h	; b0d0  pppppppp........
	defb 0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h	; b0e0  ................
	defb 0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h	; b0f0  ................
	defb 0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,020h,020h,020h,020h,020h,020h,020h,020h	; b100  ........        
	defb 020h,020h,020h,02fh,020h,020h,02fh,02fh,020h,020h,020h,020h,020h,020h,020h,020h	; b110     /  //        
	defb 0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,020h,020h,020h,020h,020h,020h,020h,020h	; b120  ........        
	defb 02fh,020h,02fh,020h,020h,020h,02fh,02fh,020h,020h,020h,020h,020h,020h,020h,020h	; b130  / /   //        
	defb 0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0c0h,0c0h,0c0h,0c0h,0c0h,0c0h,0c0h,0c2h	; b140  ................
	defb 02fh,032h,032h,032h,0c2h,0c2h,0c2h,0c2h,0c0h,0c0h,0c0h,0c0h,0c0h,0c0h,0c0h,0c2h	; b150  /222............
	defb 0d1h,0d1h,0d1h,0d1h,0d1h,0d1h,0d1h,0d1h,0d1h,0d1h,0d1h,0d1h,0d1h,0d1h,0d1h,0d1h	; b160  ................
	defb 0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h	; b170  ................
	defb 070h,070h,070h,070h,0d0h,0d0h,0d0h,0f0h,070h,070h,070h,070h,070h,070h,070h,070h	; b180  pppp....pppppppp
	defb 060h,060h,060h,060h,090h,090h,090h,0f0h,060h,060h,060h,060h,060h,060h,060h,060h	; b190  ````....````````
	defb 0f0h,0f0h,060h,0a0h,0b0h,0e0h,0e0h,070h,0f0h,0f0h,060h,080h,080h,090h,040h,0e0h	; b1a0  ..`....p..`...@.
	defb 0f0h,040h,064h,084h,08fh,09fh,04fh,0efh,0f0h,0f0h,060h,080h,080h,090h,040h,0e0h	; b1b0  .@d...O...`...@.
	defb 040h,070h,0e0h,0e0h,0b0h,0a0h,060h,0f0h,0a0h,0b0h,0b0h,0b0h,0b0h,0b0h,0b0h,0a0h	; b1c0  @p....`.........
	defb 090h,070h,070h,0f0h,0f0h,070h,070h,090h,0a0h,0b0h,0b0h,0b0h,0b0h,0b0h,0b0h,0a0h	; b1d0  .pp..pp.........
	defb 0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,06fh,080h,060h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h	; b1e0  .......o.`......
	defb 08fh,06fh,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,080h,060h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h	; b1f0  .o.......`......
	defb 0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0ffh,0ffh,0ffh,0ffh,0f0h,0f0h,0f0h	; b200  ................
	defb 0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0b0h,0b0h,090h,090h,0b0h,0b0h	; b210  ................
	defb 0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h	; b220  ................
	defb 0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,030h,030h,030h,030h,030h,030h,030h,030h	; b230  ........00000000
	defb 0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h	; b240  ................
	defb 0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h	; b250  ................
	defb 060h,060h,060h,060h,060h,060h,060h,060h,06fh,06fh,0f0h,0f0h,0f0h,0f0h,0f0h,06fh	; b260  ````````oo.....o
	defb 06fh,06fh,0f0h,0f0h,0f0h,0f0h,0f0h,06fh,060h,060h,060h,060h,060h,060h,060h,060h	; b270  oo.....o````````
	defb 06fh,0f6h,0f6h,0f6h,0f6h,0f6h,0f6h,0f6h,06fh,0f6h,0f6h,0f6h,0f6h,0f6h,0f6h,0f6h	; b280  o.......o.......
	defb 0efh,0efh,0efh,0efh,0efh,0efh,0efh,0efh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b290  ................
	defb 0f6h,0f6h,0f6h,0f6h,0f6h,0f6h,0f6h,0f6h,0f6h,0f6h,0f6h,0f6h,0f6h,0f6h,0f6h,0f6h	; b2a0  ................
	defb 0f0h,0f0h,0f0h,0f0h,0f0h,0b0h,0b0h,0bfh,0f0h,0fbh,0f6h,0fbh,0f6h,0ebh,0f0h,0ebh	; b2b0  ................
	defb 0f6h,0f6h,0f6h,0f6h,0f6h,0c6h,0c6h,0c6h,0f6h,0f6h,0f6h,0f6h,0f6h,0c6h,0c6h,0c6h	; b2c0  ................
	defb 0f6h,0f6h,0f6h,0f6h,0f6h,0c6h,0c6h,0c6h,0f6h,0f6h,0f6h,0f6h,0f6h,0c6h,0c6h,0c6h	; b2d0  ................
	defb 064h,064h,064h,064h,064h,0f6h,0f6h,06fh,064h,064h,064h,064h,064h,0f6h,0f6h,06fh	; b2e0  ddddd..oddddd..o
	defb 08fh,0b8h,0b8h,0b8h,0b8h,0fbh,0fbh,0b8h,0e6h,0bfh,0b0h,0b0h,0f0h,0f0h,0f0h,0f0h	; b2f0  ................
	defb 0efh,0efh,0efh,0efh,04fh,041h,041h,0f1h,0f1h,0f1h,01fh,01fh,01fh,0ffh,0ffh,0ffh	; b300  ....OAA.........
	defb 0efh,0efh,0efh,0efh,04fh,04fh,04fh,0f4h,0f4h,0f4h,041h,041h,041h,0ffh,0ffh,0ffh	; b310  ....OOO...AAA...
	defb 0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h	; b320  ................
	defb 0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h	; b330  ................
	defb 0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h	; b340  ................
	defb 0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h	; b350  ................
	defb 0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h	; b360  ................
	defb 0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h	; b370  ................
	defb 0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,060h,060h,0b0h,0b0h	; b380  ............``..
	defb 0f0h,0f0h,0f0h,0f0h,0f6h,0f6h,0bfh,0bfh,0f0h,0f0h,0f0h,0f0h,060h,060h,0b0h,0b0h	; b390  ............``..
	defb 0bfh,0bfh,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0b0h,0b0h,0b0h,0b0h,0b0h,0b0h,0b0h,0b0h	; b3a0  ................
	defb 0bfh,0bfh,0ffh,0ffh,0ffh,0f0h,0ffh,0f0h,0b0h,0b0h,0b0h,0b0h,0b0h,0b0h,0b0h,0b0h	; b3b0  ................
	defb 060h,060h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,060h,060h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h	; b3c0  ``......``......
	defb 0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0ffh,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h	; b3d0  ................
	defb 0afh,0afh,0a6h,0a6h,0a6h,0a6h,0a6h,0a6h,0b0h,0b0h,0b0h,0b0h,0b0h,0b0h,060h,060h	; b3e0  ..............``
	defb 0ffh,0ffh,0bfh,0bfh,0bfh,0bfh,06fh,06fh,0b0h,0b0h,0b0h,0b0h,0b0h,0b0h,060h,060h	; b3f0  ......oo......``
	defb 06fh,03fh,06fh,03fh,063h,063h,03fh,06fh,041h,04fh,04fh,04fh,04fh,04fh,04fh,041h	; b400  o?o?cc?oAOOOOOOA
	defb 041h,041h,041h,041h,041h,041h,041h,041h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h	; b410  AAAAAAAA........
	defb 01fh,01fh,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,04fh,04fh,04fh,04fh,04fh,01fh,04fh,01fh	; b420  ........OOOOO.O.
	defb 041h,041h,041h,041h,041h,0f1h,0f4h,0f1h,0efh,0efh,07fh,07fh,07fh,07fh,07fh,07fh	; b430  AAAAA...........
	defb 0efh,0efh,041h,041h,071h,01fh,01fh,07fh,0efh,0efh,074h,074h,074h,074h,074h,07fh	; b440  ..AAq.....ttttt.
	defb 041h,041h,041h,041h,041h,041h,041h,041h,01fh,041h,041h,041h,041h,041h,041h,041h	; b450  AAAAAAAA.AAAAAAA
	defb 040h,040h,064h,064h,064h,040h,064h,04fh,040h,040h,064h,064h,064h,040h,064h,04fh	; b460  @@ddd@dO@@ddd@dO
	defb 0f0h,0f0h,0f0h,0f0h,0f0h,0efh,0efh,01fh,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h	; b470  ................
	defb 0a6h,0a6h,0a6h,0a6h,0a6h,0a6h,0a6h,0a6h,06fh,06fh,06fh,06fh,06fh,06fh,06fh,06fh	; b480  ........oooooooo
	defb 08fh,08fh,08fh,08fh,08fh,08fh,08fh,08fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh,09fh	; b490  ................
	defb 054h,054h,054h,054h,054h,054h,054h,054h,054h,054h,054h,054h,054h,054h,054h,054h	; b4a0  TTTTTTTTTTTTTTTT
	defb 05fh,05fh,05fh,04fh,04fh,04fh,04fh,04fh,04fh,04fh,04fh,04fh,04fh,05fh,05fh,05fh	; b4b0  ___OOOOOOOOOO___
	defb 054h,054h,054h,054h,054h,054h,054h,054h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h	; b4c0  TTTTTTTT........
	defb 0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b4d0  ................
	defb 0f0h,0f0h,0f0h,0f0h,080h,080h,060h,060h,0f0h,0f0h,0f0h,0f0h,0f8h,0f8h,0bfh,0bfh	; b4e0  ......``........
	defb 0f0h,0f0h,0f0h,0f0h,080h,080h,060h,060h,04fh,04fh,0f4h,04fh,0f4h,0f4h,0f4h,04fh	; b4f0  ......``OO.O...O
	defb 061h,061h,061h,061h,061h,061h,061h,061h,0a6h,0a6h,0a6h,0a6h,0a6h,0a6h,0a6h,0a6h	; b500  aaaaaaaa........
	defb 0afh,0a4h,0a4h,0a4h,0a4h,0a4h,0a4h,0afh,0afh,0a4h,0a4h,0a4h,0a4h,0a4h,0a4h,0afh	; b510  ................
	defb 0a1h,0a1h,041h,0f1h,041h,041h,0a1h,0a1h,0a1h,0a1h,0a1h,0a1h,0a1h,0a1h,0a1h,0a1h	; b520  ..A.AA..........
	defb 0a1h,0a1h,0a1h,0a1h,0a1h,0a1h,0a1h,0a1h,06fh,061h,061h,061h,0efh,01fh,0efh,01fh	; b530  ........oaaa....
	defb 064h,064h,064h,064h,064h,064h,064h,04fh,0a1h,0a1h,041h,0f1h,041h,041h,0a1h,0a1h	; b540  dddddddO..A.AA..
	defb 064h,064h,064h,064h,064h,064h,064h,04fh,01fh,01fh,01fh,01fh,01fh,01fh,01fh,01fh	; b550  dddddddO........
	defb 01fh,01fh,06fh,01fh,01fh,01fh,06fh,06fh,01fh,01fh,06fh,06fh,06fh,01fh,06fh,06fh	; b560  ..o...oo..ooo.oo
	defb 08fh,06fh,06fh,08fh,06fh,08fh,08fh,06fh,09fh,08fh,08fh,09fh,08fh,09fh,09fh,08fh	; b570  .oo.o..o........
	defb 0a7h,0a7h,0a7h,0a7h,0a7h,097h,097h,097h,0a6h,0a6h,0a6h,0a6h,0a6h,096h,096h,096h	; b580  ................
	defb 0afh,0afh,0afh,0afh,0afh,09fh,09fh,09fh,096h,086h,08fh,08fh,07fh,07fh,07fh,07fh	; b590  ................
	defb 097h,087h,087h,087h,075h,075h,075h,075h,096h,086h,08fh,085h,075h,075h,07fh,07fh	; b5a0  ....uuuu....uu..
	defb 096h,086h,086h,086h,076h,07fh,07fh,07fh,090h,090h,090h,0b9h,0b9h,0b9h,090h,090h	; b5b0  ....v...........
	defb 050h,050h,050h,0b5h,0b5h,050h,050h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h	; b5c0  PPP..PP.........
	defb 080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h	; b5d0  ................
	defb 080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h	; b5e0  ................
	defb 080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h	; b5f0  ................

; ======================================================================
; CODIGO 0xb600..0xb740  (320 bytes)
; ======================================================================


salto_objetos:		; Saltando (0xE194, sin 0xE192): la casilla 0x86 cuatro filas por encima del protagonista se borra (tres filas) y da 100 puntos; el pergamino (0x64) da 500 y abre el camino de la puerta (0xE1C8 = 1)
	ld a,(0e194h)		;b600   ; saltando?
	and a			;b603
	jr z,puerta_llega		;b604
	ld a,(0e192h)		;b606   ; 0xE192?
	and a			;b609
	jr nz,puerta_llega		;b60a
	ld b,004h		;b60c   ; cuatro filas...
	call filas_por_ancho		;b60e
	ld hl,(0e18ah)		;b611   ; ...por encima del protagonista
	and a			;b614
	sbc hl,de		;b615
	ld a,(hl)			;b617   ; 0x86?
	cp 086h		;b618
	jr nz,salto_pergamino		;b61a
	ld (hl),0a0h		;b61c   ; borrada (0xA0)...
	ld de,(0e1ceh)		;b61e   ; ...tres filas
	add hl,de			;b622
	ld (hl),0a0h		;b623
	add hl,de			;b625
	ld (hl),0a0h		;b626
	ld a,(0e000h)		;b628   ; en partida...
	and a			;b62b
	jr z,salto_pergamino		;b62c
	ld a,001h		;b62e   ; ...100 puntos
	call puntos_centenas		;b630
salto_pergamino:
	ld a,(0e1c8h)		;b633   ; ya tiene el pergamino?
	and a			;b636
	jr nz,puerta_llega		;b637
	ld a,(0e192h)		;b639   ; 0xE192?
	and a			;b63c
	jr nz,puerta_llega		;b63d
	ld b,004h		;b63f   ; cuatro filas por encima
	call filas_por_ancho		;b641
	ld hl,(0e18ah)		;b644
	and a			;b647
	sbc hl,de		;b648
	ld a,(hl)			;b64a   ; el pergamino (0x64)?
	cp 064h		;b64b
	ret nz			;b64d
	ld a,001h		;b64e   ; cogido: 0xE1C8 = 1
	ld (0e1c8h),a		;b650
	ld (hl),0a0h		;b653   ; borrado, dos filas
	ld de,(0e1ceh)		;b655
	add hl,de			;b659
	ld (hl),0a0h		;b65a
	ld a,005h		;b65c   ; 500 puntos
	call puntos_centenas		;b65e
	ret			;b661
puerta_llega:		; Con el pergamino (0xE1C8 = 1): si el protagonista llega a la puerta de la fase (la casilla 0x81, en 0xEB1A, 0xEAC4, 0xEADC o 0xE865), 0xE1C8 = 2 y se abre
	ld a,(0e1c8h)		;b662   ; con el pergamino?
	cp 001h		;b665
	ret nz			;b667
	ld b,004h		;b668   ; cuatro filas por encima
	call filas_por_ancho		;b66a
	ld hl,(0e18ah)		;b66d
	and a			;b670
	sbc hl,de		;b671
	inc hl			;b673   ; y una a la derecha
	ld a,(hl)			;b674   ; la puerta (0x81)?
	cp 081h		;b675
	ret nz			;b677
	ld a,(0e00ah)		;b678   ; la fase 1: nada
	cp 002h		;b67b
	ret c			;b67d
	jr nz,puerta_llega3		;b67e
	ld a,01ah		;b680   ; la 2: 0x1A (0xEB1A)
	jr puerta_llega_mira		;b682
puerta_llega3:
	cp 003h		;b684
	jr nz,puerta_llega4		;b686
	ld a,0c4h		;b688   ; la 3: 0xC4 (0xEAC4)
	jr puerta_llega_mira		;b68a
puerta_llega4:
	cp 004h		;b68c
	jr nz,puerta_llega5		;b68e
	ld a,0dch		;b690   ; la 4: 0xDC (0xEADC)
	jr puerta_llega_mira		;b692
puerta_llega5:
	ld a,065h		;b694   ; la 5: 0x65 (0xE865)
puerta_llega_mira:
	dec l			;b696   ; la de la fase?
	cp l			;b697
	ret nz			;b698
	ld a,002h		;b699   ; si: se abre
	ld (0e1c8h),a		;b69b
	ret			;b69e
puerta_sale:		; La puerta de salida (0xE1C8 de 2 a 6, un paso cada 12 cuadros): medio abierta, abierta, el protagonista entra (4 cuadros arriba a la izquierda), medio abierta y cerrada; despues 0xE186 = 1, la fase acabada
	ld a,(0e1c8h)		;b69f   ; el paso 4?
	cp 004h		;b6a2
	jr z,puerta_entra_prota		;b6a4
	ld a,(0e1c9h)		;b6a6   ; cada 12 cuadros
	inc a			;b6a9
	ld (0e1c9h),a		;b6aa
	cp 00ch		;b6ad
	ret c			;b6af
	xor a			;b6b0
	ld (0e1c9h),a		;b6b1
	ld a,(0e00ah)		;b6b4   ; la puerta de la fase
	cp 002h		;b6b7
	jr nz,puerta_sale3		;b6b9
	ld hl,0eb1ah		;b6bb   ; la 2: 0xEB1A
	jr puerta_sale_paso		;b6be
puerta_sale3:
	cp 003h		;b6c0
	jr nz,puerta_sale4		;b6c2
	ld hl,0eac4h		;b6c4   ; la 3: 0xEAC4
	jr puerta_sale_paso		;b6c7
puerta_sale4:
	cp 004h		;b6c9
	jr nz,puerta_sale5		;b6cb
	ld hl,0eadch		;b6cd   ; la 4: 0xEADC
	jr puerta_sale_paso		;b6d0
puerta_sale5:
	ld hl,0e865h		;b6d2   ; la 5: 0xE865
puerta_sale_paso:
	ld a,(0e1c8h)		;b6d5   ; el paso 2?
	cp 002h		;b6d8
	jr nz,puerta_sale_que		;b6da
puerta_medio:		; La puerta medio abierta (0xB740)
	ld de,0b740h		;b6dc
	jr puerta_pinta		;b6df
puerta_sale_que:
	cp 006h		;b6e1   ; 6: cerrada
	jr z,puerta_cerrada		;b6e3
	cp 005h		;b6e5   ; 5: el protagonista fuera y medio abierta
	jr nz,puerta_abierta_dib		;b6e7
	ld (ix+000h),0eeh		;b6e9   ; Y 0xEE
	ld (ix+004h),0eeh		;b6ed
	jr puerta_medio		;b6f1
puerta_cerrada:		; Cerrada (0xB750)
	ld de,0b750h		;b6f3
	jr puerta_pinta		;b6f6
puerta_abierta_dib:		; Abierta (0xB748)
	ld de,0b748h		;b6f8
puerta_pinta:		; Cuatro filas de dos casillas de DE en el mapa (HL); el paso siguiente y, al 7, la fase acabada (0xE186)
	ld b,004h		;b6fb   ; cuatro filas
puerta_pinta_fila:
	ld a,(de)			;b6fd   ; dos casillas
	ld (hl),a			;b6fe
	inc de			;b6ff
	inc hl			;b700
	ld a,(de)			;b701
	ld (hl),a			;b702
	inc de			;b703
	push de			;b704
	ld de,(0e1ceh)		;b705   ; la fila siguiente (el ancho - 1)
	ld a,e			;b709
	sub 001h		;b70a
	ld e,a			;b70c
	add hl,de			;b70d
	pop de			;b70e
	djnz puerta_pinta_fila		;b70f
	ld a,(0e1c8h)		;b711   ; el paso siguiente
	inc a			;b714
	ld (0e1c8h),a		;b715
	cp 007h		;b718   ; el 7?
	ret c			;b71a
	ld a,001h		;b71b   ; la fase acabada
	ld (0e186h),a		;b71d
	ret			;b720
puerta_entra_prota:		; El paso 4: el protagonista, un punto arriba y a la izquierda por cuadro, 4 cuadros
	dec (ix+000h)		;b721
	dec (ix+004h)		;b724
	dec (ix+001h)		;b727
	dec (ix+005h)		;b72a
	ld a,(0e1c9h)		;b72d   ; 4 cuadros
	inc a			;b730
	ld (0e1c9h),a		;b731
	cp 004h		;b734
	ret c			;b736
	xor a			;b737   ; hecho...
	ld (0e1c9h),a		;b738
	ld hl,0e1c8h		;b73b   ; ...el paso siguiente
	inc (hl)			;b73e
	ret			;b73f

; ----------------------------------------------------------------------
; DATOS puerta_dibujos: La puerta en el mapa, cuatro filas de dos casillas:
;   medio abierta (0xB740), abierta (0xB748) y cerrada (0xB750)
;   0xb740..0xb758  (24 bytes)
DATA_puerta_dibujos:
	defb 081h,0c4h,085h,0c8h,08bh,0c8h,08dh,0c5h,0c6h,0c4h,0c9h,0c8h,0cah,0c8h,0c7h,0c5h	; b740  ................
	defb 080h,081h,084h,085h,08ah,08bh,08ch,08dh	; b750  ........

; ======================================================================
; CODIGO 0xb758..0xb764  (12 bytes)
; ======================================================================


filas_por_ancho:		; DE = B filas del mapa (B x el ancho, 0xE1CE)
	ld hl,00000h		;b758   ; cero...
	ld de,(0e1ceh)		;b75b
filas_suma:
	add hl,de			;b75f   ; ...+ el ancho, B veces
	djnz filas_suma		;b760
	ex de,hl			;b762   ; en DE
	ret			;b763

; ----------------------------------------------------------------------
; DATOS mapa5_rle: El principio del mapa de la fase 5 comprimido (como el de
;   la 1, 0x9AD6); 0xFF al final
;   0xb764..0xb7cc  (104 bytes)
DATA_mapa5_rle:
	defb 008h,0dbh,041h,00eh,0dbh,044h,008h,0dbh,008h,0dch,042h,043h,00ch,0dch,046h,045h	; b764  ..A..D....BC..FE
	defb 008h,0dch,007h,0ddh,0bdh,00fh,0bah,0bah,0bch,007h,0ddh,006h,0c1h,0dah,00fh,0b6h	; b774  ................
	defb 003h,0b6h,0d8h,006h,0c1h,008h,0deh,002h,082h,090h,092h,008h,082h,090h,092h,002h	; b784  ................
	defb 082h,008h,0deh,006h,0c2h,08eh,0c2h,002h,083h,091h,093h,002h,083h,0d1h,0d5h,0d6h	; b794  ................
	defb 0d1h,002h,083h,091h,093h,002h,083h,0c2h,08eh,006h,0c2h,006h,0dfh,00fh,0ach,005h	; b7a4  ................
	defb 0ach,006h,0dfh,006h,0c3h,00fh,0c0h,005h,0c0h,006h,0c3h,00fh,0bah,00fh,0bah,002h	; b7b4  ................
	defb 0bah,00fh,0b6h,00fh,0b6h,002h,0b6h,0ffh	; b7c4  ........

; ======================================================================
; CODIGO 0xb7cc..0xb7db  (15 bytes)
; ======================================================================


mapa_blanco:		; El mapa (0xE700, 0x840 bytes) entero a 0xA0, la casilla en blanco
	ld hl,0e700h		;b7cc   ; desde 0xE700...
	ld bc,00840h		;b7cf   ; ...0x840 bytes
mapa_blanco_casilla:
	ld (hl),0a0h		;b7d2   ; 0xA0
	inc hl			;b7d4
	dec bc			;b7d5   ; los 16 bits...
	ld a,b			;b7d6   ; ...hasta 0
	or c			;b7d7
	jr nz,mapa_blanco_casilla		;b7d8
	ret			;b7da

; ----------------------------------------------------------------------
; DATOS relleno_b7db: 37 bytes sin lectura (0xF0 y 0xFF) delante de los
;   dibujos de los sprites
;   0xb7db..0xb800  (37 bytes)
DATA_relleno_b7db:
	defb 0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0ffh,0ffh,0ffh,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h	; b7db  ................
	defb 0f0h,0ffh,0ffh,0ffh,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0f0h	; b7eb  ................
	defb 0f0h,0f0h,0f0h,0f0h,0f0h	; b7fb

; ----------------------------------------------------------------------
; DATOS sprites_dibujos_d: Los dibujos de los sprites (de 16 x 16, 32 bytes):
;   el protagonista 0x00-0x4C, la estrella 0xA4/0xA8 y 0xB0/0xB4, los otros;
;   sprites_dibujos copia 0xB800-0xBFFF a 0x3800, con lo que sigue (piezas y
;   codigo) como dibujos 0xC0-0xFF que no se usan
;   0xb800..0xbe00  (1536 bytes)
DATA_sprites_dibujos_d:
	defb 007h,00fh,01fh,01fh,001h,001h,001h,01fh,03ah,03dh,03fh,00fh,00fh,01ch,03ch,000h	; b800  ........:=?...<.
	defb 000h,080h,0c0h,0c0h,0e0h,0e0h,0e0h,0c0h,0f0h,0f0h,0e0h,0e0h,0f8h,078h,000h,000h	; b810  .............x..
	defb 000h,000h,000h,000h,01eh,00ah,01eh,000h,000h,0c0h,0c0h,000h,000h,000h,000h,078h	; b820  ...............x
	defb 000h,000h,000h,000h,000h,000h,000h,000h,00eh,00ch,000h,000h,000h,000h,018h,030h	; b830  ...............0
	defb 003h,007h,00fh,000h,000h,000h,00fh,01ah,01dh,01fh,00fh,00fh,00fh,00eh,00eh,000h	; b840  ................
	defb 080h,0c0h,0e0h,0f0h,0f0h,0e0h,0e0h,0c0h,0f0h,0f8h,0f8h,0e8h,0e0h,0e0h,0e0h,000h	; b850  ................
	defb 000h,000h,000h,00fh,005h,00fh,000h,060h,060h,000h,000h,000h,000h,000h,000h,006h	; b860  .......``.......
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,004h,006h,000h,000h,000h,0c0h	; b870  ................
	defb 000h,000h,000h,001h,000h,000h,000h,01fh,01fh,00fh,003h,01fh,01fh,01fh,000h,000h	; b880  ................
	defb 000h,070h,0f8h,0fch,01eh,01eh,01eh,0f3h,0f3h,05bh,0bdh,0feh,0feh,01eh,01eh,01ch	; b890  .p.......[......
	defb 000h,000h,000h,000h,001h,000h,001h,060h,020h,000h,000h,0e0h,060h,000h,000h,000h	; b8a0  .......` ...`...
	defb 000h,000h,000h,000h,0e0h,0a0h,0e0h,00ch,00ch,004h,000h,000h,000h,0e0h,060h,000h	; b8b0  ..............`.
	defb 000h,001h,003h,007h,000h,000h,038h,03fh,03dh,007h,007h,01fh,07fh,01eh,018h,000h	; b8c0  ......8?=.......
	defb 000h,0c0h,0e0h,0f0h,070h,070h,07ch,0fch,07ch,0f0h,0f0h,0fch,0ffh,038h,018h,000h	; b8d0  ....pp|.|....8..
	defb 000h,000h,000h,000h,007h,002h,0c7h,0c0h,040h,000h,000h,000h,000h,0e0h,060h,000h	; b8e0  ........@.....`.
	defb 000h,000h,000h,000h,080h,080h,083h,003h,002h,000h,000h,000h,000h,007h,006h,000h	; b8f0  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,00eh,01fh,03fh,003h,003h,003h,03eh	; b900  ...........?...>
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,010h,0b8h,0fch,0fch,03eh,03eh	; b910  ..............>>
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,03ch,03ch,054h,0c1h	; b920  ............<<T.
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,0c1h,0c1h	; b930  ................
	defb 000h,001h,003h,003h,007h,007h,007h,003h,00fh,00fh,007h,007h,01fh,01eh,000h,000h	; b940  ................
	defb 0e0h,0f0h,0f8h,0f8h,080h,080h,080h,0f8h,05ch,0bch,0fch,0f0h,0f0h,038h,03ch,000h	; b950  ........\....8<.
	defb 000h,000h,000h,000h,000h,000h,000h,000h,070h,030h,000h,000h,000h,000h,018h,00ch	; b960  ........p0......
	defb 000h,000h,000h,000h,078h,050h,078h,000h,000h,003h,003h,000h,000h,000h,000h,01eh	; b970  ....xPx.........
	defb 001h,003h,007h,00fh,00fh,007h,007h,003h,00fh,01fh,01fh,017h,007h,007h,007h,000h	; b980  ................
	defb 0c0h,0e0h,0f0h,000h,000h,000h,0f0h,058h,0b8h,0f8h,0f0h,0f0h,0f0h,070h,070h,000h	; b990  .......X.....pp.
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,020h,060h,000h,000h,000h,003h	; b9a0  .......... `....
	defb 000h,000h,000h,0f0h,0a0h,0f0h,000h,006h,006h,000h,000h,000h,000h,000h,000h,060h	; b9b0  ...............`
	defb 000h,00eh,01fh,03fh,078h,078h,078h,0cfh,0cfh,0dah,0bdh,07fh,07fh,078h,078h,038h	; b9c0  ...?xxx......xx8
	defb 000h,000h,000h,080h,000h,000h,000h,0f8h,0f8h,0f0h,0c0h,0f8h,0f8h,0f8h,000h,000h	; b9d0  ................
	defb 000h,000h,000h,000h,007h,005h,007h,030h,030h,020h,000h,000h,000h,007h,006h,000h	; b9e0  .......00 ......
	defb 000h,000h,000h,000h,080h,000h,080h,006h,004h,000h,000h,007h,006h,000h,000h,000h	; b9f0  ................
	defb 000h,003h,007h,00fh,00eh,00eh,03eh,03fh,03eh,00fh,00fh,03fh,0ffh,01ch,018h,000h	; ba00  ......>?>..?....
	defb 000h,080h,0c0h,0e0h,000h,000h,01ch,0fch,0bch,0e0h,0e0h,0f8h,0feh,078h,018h,000h	; ba10  .............x..
	defb 000h,000h,000h,000h,001h,001h,0c1h,0c0h,040h,000h,000h,000h,000h,0e0h,060h,000h	; ba20  ........@.....`.
	defb 000h,000h,000h,000h,0e0h,040h,0e3h,003h,002h,000h,000h,000h,000h,007h,006h,000h	; ba30  .....@..........
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,008h,01dh,03fh,03fh,07ch,07ch	; ba40  ............??||
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,070h,0f8h,0fch,0c0h,0c0h,0c0h,07ch	; ba50  .........p.....|
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,083h,083h	; ba60  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,03ch,03ch,02ah,083h	; ba70  ............<<*.
	defb 001h,003h,007h,00fh,000h,000h,007h,03ch,03eh,007h,000h,007h,007h,003h,002h,000h	; ba80  .......<>.......
	defb 080h,0e0h,0f0h,0f8h,070h,070h,0f8h,03ch,07eh,0f4h,000h,0f0h,0f0h,070h,040h,000h	; ba90  ....pp.<~....p@.
	defb 000h,000h,000h,000h,007h,002h,000h,0c3h,061h,000h,000h,000h,000h,000h,001h,007h	; baa0  ........a.......
	defb 000h,000h,000h,000h,080h,080h,000h,0c0h,080h,002h,006h,004h,000h,000h,030h,070h	; bab0  ..............0p
	defb 000h,007h,00fh,01fh,000h,000h,00fh,01fh,039h,07fh,077h,000h,007h,00fh,00eh,000h	; bac0  ........9.w.....
	defb 000h,080h,0c0h,0e0h,070h,060h,0e0h,0fch,0fch,0f0h,080h,070h,0fch,07ch,038h,000h	; bad0  ....p`.....p.|8.
	defb 000h,000h,000h,000h,00fh,00ah,000h,000h,006h,000h,080h,0c0h,000h,000h,010h,01ch	; bae0  ................
	defb 000h,000h,000h,000h,080h,080h,000h,003h,002h,000h,000h,000h,000h,000h,004h,01ch	; baf0  ................
	defb 001h,007h,00fh,01fh,00eh,00eh,01fh,03ch,07eh,02fh,000h,00fh,00fh,00eh,002h,000h	; bb00  .......<~/......
	defb 080h,0c0h,0e0h,0f0h,000h,000h,0e0h,03ch,07ch,0e0h,000h,0e0h,0e0h,0c0h,040h,000h	; bb10  .......<|.....@.
	defb 000h,000h,000h,000h,001h,001h,000h,003h,001h,040h,060h,020h,000h,000h,00ch,00eh	; bb20  .........@` ....
	defb 000h,000h,000h,000h,0e0h,040h,000h,0c3h,086h,000h,000h,000h,000h,000h,080h,0e0h	; bb30  .....@..........
	defb 000h,001h,003h,007h,00eh,006h,007h,03fh,03fh,00fh,001h,00eh,03fh,03eh,01ch,000h	; bb40  .......??...?>..
	defb 000h,0e0h,0f0h,0f8h,000h,000h,0f0h,0f8h,09ch,0feh,0eeh,000h,0e0h,0f0h,070h,000h	; bb50  ..............p.
	defb 000h,000h,000h,000h,001h,001h,000h,0c0h,040h,000h,000h,000h,000h,000h,020h,038h	; bb60  ........@..... 8
	defb 000h,000h,000h,000h,0f0h,050h,000h,000h,060h,000h,001h,003h,000h,000h,008h,038h	; bb70  .....P..`......8
	defb 001h,003h,00fh,01fh,008h,008h,00fh,01eh,03ch,01ch,00fh,000h,00fh,00fh,002h,000h	; bb80  ........<.......
	defb 080h,0c0h,0f0h,0f8h,030h,030h,0f0h,0f8h,07ch,078h,0f0h,000h,0f0h,0f0h,040h,000h	; bb90  ....00..|x....@.
	defb 000h,000h,000h,000h,007h,005h,000h,001h,003h,003h,000h,000h,000h,000h,00ch,01ch	; bba0  ................
	defb 000h,000h,000h,000h,0c0h,040h,000h,000h,080h,080h,000h,000h,000h,000h,030h,038h	; bbb0  .....@........08
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,040h,0ffh,040h,000h	; bbc0  ............@.@.
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,01fh,03eh,0e1h,03eh,01fh	; bbd0  ............>.>.
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,0f8h,07ch,087h,07ch,0f8h	; bbe0  ............|.|.
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,002h,0ffh,002h,000h	; bbf0  ................
	defb 000h,000h,000h,000h,001h,003h,027h,02fh,02eh,03ch,00ch,00eh,007h,003h,000h,007h	; bc00  ......'/.<......
	defb 000h,000h,0f0h,080h,0c0h,0e0h,0f0h,078h,038h,01eh,01ah,03ah,072h,0e0h,080h,080h	; bc10  .......x8..:r...
	defb 000h,000h,000h,008h,011h,02ah,004h,008h,009h,00bh,00bh,009h,004h,02bh,010h,008h	; bc20  .....*.......+..
	defb 000h,000h,000h,008h,0c4h,02ah,010h,088h,0c8h,0e8h,0e8h,0c8h,090h,0eah,004h,008h	; bc30  .....*..........
	defb 000h,003h,007h,00fh,018h,008h,00fh,007h,00dh,01eh,01fh,000h,00fh,00fh,002h,000h	; bc40  ................
	defb 000h,080h,0c0h,0e0h,030h,020h,0e0h,0c0h,070h,0f8h,0f8h,000h,0e0h,0f0h,060h,000h	; bc50  ....0 ..p.....`.
	defb 000h,000h,000h,000h,003h,005h,000h,000h,020h,060h,060h,000h,000h,000h,00ch,01ch	; bc60  ........ ``.....
	defb 000h,000h,000h,000h,080h,040h,000h,000h,004h,006h,006h,000h,000h,000h,010h,038h	; bc70  .....@.........8
	defb 000h,003h,007h,00fh,01eh,00eh,03fh,03fh,01dh,00eh,00fh,000h,00fh,00eh,008h,000h	; bc80  ......??........
	defb 000h,080h,0c0h,0e0h,000h,000h,0f8h,0f8h,078h,0f0h,0e0h,000h,0e0h,0f8h,060h,000h	; bc90  ........x.....`.
	defb 000h,000h,000h,000h,001h,060h,040h,000h,000h,000h,000h,000h,020h,010h,010h,000h	; bca0  .....`@..... ...
	defb 000h,000h,000h,000h,020h,0cch,004h,000h,000h,000h,000h,000h,000h,004h,018h,000h	; bcb0  .... ...........
	defb 003h,003h,003h,003h,003h,007h,005h,00ah,001h,000h,000h,000h,000h,000h,000h,000h	; bcc0  ................
	defb 0c0h,0c0h,0c0h,0e0h,0f0h,0f8h,068h,0d0h,040h,000h,000h,000h,000h,000h,000h,000h	; bcd0  ......h.@.......
	defb 000h,000h,000h,000h,000h,001h,003h,005h,006h,003h,001h,000h,000h,000h,000h,000h	; bce0  ................
	defb 000h,000h,000h,000h,000h,080h,0c0h,0e0h,0e0h,0c0h,080h,000h,000h,000h,000h,000h	; bcf0  ................
	defb 000h,000h,000h,000h,000h,001h,003h,007h,007h,003h,001h,000h,000h,000h,000h,000h	; bd00  ................
	defb 000h,000h,000h,000h,000h,080h,0c0h,060h,0a0h,0c0h,080h,000h,000h,000h,000h,000h	; bd10  .......`........
	defb 001h,001h,001h,007h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; bd20  ................
	defb 000h,000h,0e0h,080h,080h,080h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; bd30  ................
	defb 004h,002h,003h,001h,003h,004h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; bd40  ................
	defb 020h,0c0h,080h,0c0h,040h,020h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; bd50   ...@ ..........
	defb 000h,002h,00fh,01eh,037h,078h,0b7h,06eh,0deh,073h,03ch,037h,01dh,00fh,002h,000h	; bd60  ....7x.n.s<7....
	defb 000h,0e0h,0f0h,0d8h,0eeh,01ch,0e6h,03bh,03dh,0e6h,01eh,0ech,0b8h,0f0h,0c0h,000h	; bd70  .......;=.......
	defb 000h,000h,020h,000h,000h,004h,000h,040h,000h,000h,000h,004h,000h,040h,000h,000h	; bd80  .. ....@.....@..
	defb 000h,040h,000h,000h,004h,000h,000h,000h,080h,010h,000h,001h,000h,040h,004h,000h	; bd90  .@...........@..
	defb 000h,000h,001h,001h,000h,010h,000h,000h,005h,000h,020h,001h,000h,000h,004h,000h	; bda0  .......... .....
	defb 000h,000h,000h,022h,000h,000h,000h,010h,000h,042h,000h,000h,020h,004h,000h,020h	; bdb0  ...".....B.. .. 
	defb 01ch,033h,039h,01fh,00dh,007h,01fh,07bh,07eh,0ffh,0ddh,0eah,07dh,02fh,057h,0aah	; bdc0  .39....{~...}/W.
	defb 038h,0cch,09ch,0f8h,0b0h,0e0h,0f8h,0eeh,0beh,0ffh,0bbh,057h,0beh,0f4h,0eah,055h	; bdd0  8..........W...U
	defb 000h,00ch,006h,000h,000h,008h,020h,004h,081h,010h,00ah,004h,006h,010h,028h,07ch	; bde0  ...... .......(|
	defb 000h,030h,060h,000h,000h,010h,004h,010h,041h,008h,050h,020h,060h,008h,014h,03eh	; bdf0  .0`.....A.P `..>

; ----------------------------------------------------------------------
; DATOS piezas_casillas: Las casillas de las piezas del mapa: 0xBE00 (0x40, el
;   muro), las escaleras (0xBE01-0xBE0C), 3 x 3 de 0xBE0D, 4 x 4 del cofre
;   (0xBE16, el 0x61 arriba a la izquierda), 4 x 4 de la puerta (0xBE26) y 3 x
;   3 con el objeto 0x6A (0xBE36)
;   0xbe00..0xbe3f  (63 bytes)
DATA_piezas_casillas:
	defb 040h,031h,032h,033h,03eh,03ah,03bh,034h,035h,036h,038h,039h,03dh,070h,071h,072h	; be00  @123>:;45689=pqr
	defb 074h,075h,076h,078h,079h,07ah,061h,0a1h,0a2h,0a3h,060h,0a5h,0a6h,0a7h,0a0h,0a5h	; be10  tuvxyza...`.....
	defb 0aah,0a7h,0a0h,0adh,0aeh,0afh,080h,081h,080h,081h,084h,085h,084h,085h,088h,089h	; be20  ................
	defb 08ah,08bh,08ch,08dh,08ch,08dh,065h,066h,067h,069h,06ah,06bh,06dh,06eh,06fh	; be30  ......efgijkmno

; ----------------------------------------------------------------------
; DATOS piezas_fases: Las listas de piezas de las fases 2 a 5
;   0xbe3f..0xbe47  (8 bytes)
DATA_piezas_fases:
	defw 0be47h,0be83h,0bec5h,0bf10h	; be3f  -> DATA_piezas_listas 0xbe83 0xbec5 0xbf10

; ----------------------------------------------------------------------
; DATOS piezas_listas: Las listas: por clase, cuantas y las direcciones del
;   mapa donde va cada pieza
;   0xbe47..0xbf53  (268 bytes)
DATA_piezas_listas:
	defb 006h,08fh,0e8h,0a4h,0e8h,0b5h,0e8h,0c8h,0e8h,0e2h,0eah,0feh,0eah,001h,0f2h,0ech	; be47  ................
	defb 00ah,024h,0e8h,03ah,0e8h,04eh,0e8h,060h,0e8h,078h,0e8h,06ah,0eah,0b0h,0eah,0ach	; be57  .$.:.N.`.x.j....
	defb 0ech,0bah,0ech,0f8h,0ech,002h,018h,0ebh,02eh,0edh,005h,018h,0eah,034h,0eah,051h	; be67  .............4.Q
	defb 0ech,062h,0ech,085h,0ech,003h,02dh,0eah,04dh,0eah,07fh,0ech,005h,0c7h,0e8h,0f8h	; be77  .b....-.M.......
	defb 0eah,000h,0ebh,018h,0ebh,028h,0edh,002h,04fh,0e8h,076h,0eah,012h,024h,0e8h,030h	; be87  .....(..O.v..$.0
	defb 0e8h,03ch,0e8h,046h,0e8h,057h,0e8h,060h,0e8h,06ch,0e8h,078h,0e8h,06ah,0eah,085h	; be97  .<.F.W.`.l.x.j..
	defb 0eah,0a6h,0eah,0b2h,0eah,0a4h,0ech,0aeh,0ech,0c2h,0ech,0d4h,0ech,0e9h,0ech,0f9h	; bea7  ................
	defb 0ech,002h,0c2h,0eah,02eh,0edh,001h,07ch,0ech,002h,032h,0eah,05bh,0ech,003h,09bh	; beb7  .......|..2.[...
	defb 0e8h,0a6h,0e8h,010h,0ebh,003h,056h,0e8h,094h,0eah,0c8h,0ech,014h,024h,0e8h,02ch	; bec7  ......V......$.,
	defb 0e8h,034h,0e8h,040h,0e8h,04eh,0e8h,064h,0e8h,06eh,0e8h,078h,0e8h,064h,0eah,06ch	; bed7  .4.@.N.d.n.x.d.l
	defb 0eah,088h,0eah,0a8h,0eah,0b6h,0eah,0a4h,0ech,0ach,0ech,0b4h,0ech,0d8h,0ech,0eah	; bee7  ................
	defb 0ech,0f0h,0ech,0f8h,0ech,002h,0dah,0eah,02eh,0edh,002h,011h,0eah,080h,0ech,002h	; bef7  ................
	defb 041h,0eah,064h,0ech,002h,05ah,0e8h,090h,0eah,005h,069h,0e8h,075h,0e8h,07ah,0e8h	; bf07  A.d..Z....i.u.z.
	defb 0b1h,0eah,0fah,0ech,001h,0cch,0e9h,009h,04eh,0e8h,004h,0e9h,0dah,0e9h,086h,0eah	; bf17  ........N.......
	defb 04ah,0ebh,05ch,0ebh,003h,0ech,0c6h,0ech,085h,0edh,002h,063h,0e8h,0aeh,0edh,004h	; bf27  J.\........c....
	defb 0f6h,0e8h,0a2h,0e9h,030h,0ebh,0e6h,0ebh,006h,0b8h,0e9h,07ch,0eah,028h,0ebh,0f7h	; bf37  ....0......|.(..
	defb 0ebh,0b1h,0ech,07ah,0edh,003h,0d0h,0e9h,04fh,0ebh,00fh,0ech	; bf47  ...z....O...

; ----------------------------------------------------------------------
; DATOS fila_bf53: Las seis casillas que se repiten en las filas 4 y 5 del
;   mapa de las fases 2 a 4
;   0xbf53..0xbf59  (6 bytes)
DATA_fila_bf53:
	defb 0b7h,0b7h,0b8h,0b9h,0b7h,0b7h	; bf53

; ----------------------------------------------------------------------
; DATOS fila_blanco: Ocho espacios (0x10): la fila en blanco detras del
;   logotipo de la presentacion
;   0xbf59..0xbf61  (8 bytes)
DATA_fila_blanco:
	defb 010h,010h,010h,010h,010h,010h,010h,010h	; bf59  ........

; ----------------------------------------------------------------------
; DATOS cofre_dib3_tabla: El cofre 3: cuatro pasos de 4 x 4
;   0xbf61..0xbfa1  (64 bytes)
DATA_cofre_dib3_tabla:
	defb 063h,0a1h,0a2h,0a3h,063h,0a5h,0a6h,0a7h,062h,0a5h,0aah,0a7h,0a0h,0a9h,0a4h,0a8h	; bf61  c...c...b.......
	defb 063h,0a1h,0a2h,0a3h,063h,0a5h,0a6h,0a7h,063h,0a9h,0a4h,0a8h,062h,0a0h,08fh,0a0h	; bf71  c...c...c...b...
	defb 063h,0a1h,0a2h,0a3h,063h,0a9h,0a4h,0a8h,063h,0a0h,087h,0a0h,062h,0a0h,08fh,0a0h	; bf81  c...c...c...b...
	defb 063h,0cch,0cdh,0ceh,063h,0a0h,086h,0a0h,063h,0a0h,087h,0a0h,062h,0a0h,08fh,0a0h	; bf91  c...c...c...b...

; ======================================================================
; CODIGO 0xbfa1..0xbff0  (79 bytes)
; ======================================================================


mapa_pantalla:		; El mapa a la pantalla: 22 filas de 32 desde la fila 2; en las fases 1 y 5 corre de arriba abajo (0xE19A filas de 32), en las otras de lado (0xE193 columnas, filas de 0x60)
	ld hl,0e700h		;bfa1   ; el mapa
	ld a,(0e00ah)		;bfa4   ; la 5 o la 1?
	cp 005h		;bfa7
	jr z,mapa_pantalla_v		;bfa9
	cp 001h		;bfab
	jr nz,mapa_pantalla_h		;bfad
mapa_pantalla_v:
	ld a,(0e19ah)		;bfaf   ; las filas corridas
	and a			;bfb2
	jr z,mapa_pantalla_va		;bfb3
	ld b,a			;bfb5
	ld de,00020h		;bfb6   ; 32 casillas cada una
mapa_pantalla_fila:
	add hl,de			;bfb9
	djnz mapa_pantalla_fila		;bfba
	jr mapa_pantalla_va		;bfbc
mapa_pantalla_h:
	ld a,(0e193h)		;bfbe   ; las columnas corridas
	ld c,a			;bfc1
	ld b,000h		;bfc2
	add hl,bc			;bfc4
mapa_pantalla_va:
	ld b,016h		;bfc5   ; 22 filas...
	ld de,01840h		;bfc7   ; ...desde la fila 2
mapa_pantalla_una:
	push bc			;bfca
	push hl			;bfcb
	ld bc,00020h		;bfcc   ; 32 casillas
	call 0005ch		;bfcf   ; LDIRVM
	ld de,00020h		;bfd2   ; la fila siguiente de la pantalla
	add hl,de			;bfd5
	ex de,hl			;bfd6
	pop hl			;bfd7
	ld a,(0e00ah)		;bfd8   ; y la del mapa: 0x20 (fases 1 y 5) o 0x60
	cp 005h		;bfdb
	jr z,mapa_pantalla_32		;bfdd
	cp 001h		;bfdf
	jr z,mapa_pantalla_32		;bfe1
	ld bc,00060h		;bfe3
	jr mapa_pantalla_sig		;bfe6
mapa_pantalla_32:
	ld bc,00020h		;bfe8
mapa_pantalla_sig:
	add hl,bc			;bfeb
	pop bc			;bfec
	djnz mapa_pantalla_una		;bfed
	ret			;bfef

; ----------------------------------------------------------------------
; DATOS relleno_final: El final del cartucho: ceros y un 0x80 sueltos (sin
;   lectura)
;   0xbff0..0xc000  (16 bytes)
DATA_relleno_final:
	defb 000h,000h,000h,000h,000h,080h,0c0h,0e0h,060h,0c0h,080h,000h,000h,000h,000h,000h	; bff0  ........`.......
