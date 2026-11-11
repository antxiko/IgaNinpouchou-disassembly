# LAS CINCO FASES, FORZADAS: el piloto de partida.tcl, pero
#  - en la fase 1 la cuenta de tumbados (0xE1B2) se pone en 9: el siguiente que cae abre la puerta del castillo;
#  - en las fases 2 a 5, 400 cuadros despues de empezar, el protagonista se lleva bajo un cofre (0xE18A, su
#    sitio en el mapa, la pantalla corrida 0xE193 o 0xE19A y su sprite) con la cuenta de cofres abiertos
#    (0xE1CA) en uno menos de los que tiene la fase: salta, el cofre se abre con el pergamino; se lleva dos
#    casillas a la derecha y salta para cogerlo; y se lleva delante de la puerta de salida, que se abre sola.
# 9000 cuadros.
source tools/guiones/partida.tcl
set ::fase -1
set ::inicio 0
proc w {a v} { debug write memory $a $v }
# fase: el suelo bajo el cofre (5 filas por debajo de su esquina), los cofres que tiene y donde mira la puerta
array set ::cofre {2 0xEE8C 3 0xEE84 4 0xEE84 5 0xEE25}
array set ::cofres {2 10 3 18 4 20 5 9}
array set ::puerta {2 0xEB1A 3 0xEAC4 4 0xEADC 5 0xE865}
proc lleva {f s} {
    if {$f == 5} { set ancho 0x20 } else { set ancho 0x60 }
    set c [expr {($s - 0xE700) % $ancho}]
    set r [expr {($s - 0xE700) / $ancho}]
    w 0xE18A [expr {$s & 0xFF}]
    w 0xE18B [expr {$s >> 8}]
    if {$f == 5} {
        set v [expr {$r - 14}]
        if {$v < 0} { set v 0 }
        if {$v > 44} { set v 44 }
        w 0xE19A $v
        set x [expr {$c * 8 - 4}]
        set y [expr {($r - $v) * 8 - 1}]
    } else {
        set h [expr {$c - 16}]
        if {$h < 0} { set h 0 }
        if {$h > 0x40} { set h 0x40 }
        w 0xE193 $h
        set x [expr {($c - $h) * 8 - 4}]
        set y [expr {$r * 8 - 1}]
        w 0xE190 [expr {(20 - $r) / 6}]
    }
    foreach a {0xE19E 0xE198 0xE194 0xE195 0xE196 0xE197} { w $a 0 }
    w 0xE100 $y
    w 0xE104 $y
    w 0xE101 $x
    w 0xE105 $x
}
proc fuerza {n} {
    set f [m 0xE00A]
    if {$f != $::fase} { set ::fase $f; set ::inicio $n }
    if {$f == 1} {
        if {[m 0xE1B2] < 9 && [m 0xE183] == 0} { w 0xE1B2 9 }
        return 0
    }
    set t [expr {$n - $::inicio}]
    if {$t < 400} { return 0 }
    palanca 0
    keymatrixup 6 0x04
    set s $::cofre($f)
    if {$t == 400} { lleva $f $s; w 0xE1CA [expr {$::cofres($f) - 1}] }
    if {$t == 402 || $t == 462} { keymatrixdown 8 0x01 }
    if {$t == 407 || $t == 467} { keymatrixup 8 0x01 }
    if {$t == 460} { lleva $f [expr {$s + 2}] }
    if {$f == 5} { set ancho 0x20 } else { set ancho 0x60 }
    if {$t == 530} { lleva $f [expr {$::puerta($f) + 4 * $ancho}] }
    return 1
}
proc guion {n} {
    pulsa $n 300 8 0x01
    if {$n > 600 && [m 0xE000] == 1} {
        if {![fuerza $n]} {
            if {[m 0xE00A] == 1} { fase1 $n } else { otras $n }
        }
    }
    return [expr {$n >= 9000}]
}
