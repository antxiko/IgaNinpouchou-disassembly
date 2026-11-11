# Una partida con un piloto en Tcl: la barra en el cuadro 300 (el titulo) empieza. En la fase 1 el piloto se pone a la
# altura del otro mas cercano (los de 0xE300, 16 bytes, el tipo en +4) y le tira la estrella (GRAPH, con la
# palanca hacia el un cuadro) y se aparta de lo que le tiran (los tipos 4, 6 y 7); con la puerta abierta (0xE1D1) va a la columna 0x7B y sube. En las demas fases
# tira al que este en su piso, anda a un lado y a otro (300 cuadros) y salta cada 90. 20000 cuadros.
proc m {a} { return [debug read memory $a] }
proc pulsa {n a f b} {
    if {$n == $a} { keymatrixdown $f $b }
    if {$n == $a + 5} { keymatrixup $f $b }
}
proc palanca {d} {
    keymatrixup 8 0xF0
    switch $d {
        r { keymatrixdown 8 0x80 }
        l { keymatrixdown 8 0x10 }
        u { keymatrixdown 8 0x20 }
        d { keymatrixdown 8 0x40 }
    }
}
proc cercano {piso} {
    set hy [m 0xE100]
    set mejor -1
    set md 999
    for {set k 0} {$k < 16} {incr k} {
        set b [expr {0xE300 + 16 * $k}]
        set t [m [expr {$b + 4}]]
        set y [m $b]
        set x [m [expr {$b + 1}]]
        if {$t == 0 || $t == 4 || $t == 6 || $t == 7 || $y >= 0xC0 || $x >= 0xF0} continue
        set d [expr {abs($y - $hy)}]
        if {$piso && $d > 10} continue
        if {$d < $md} { set md $d; set mejor $b }
    }
    return $mejor
}
proc tira {n e} {
    set hx [m 0xE101]
    set ex [m [expr {$e + 1}]]
    if {$n % 12 == 0} {
        if {$ex < $hx} { palanca l } else { palanca r }
        keymatrixdown 6 0x04
    } else {
        palanca 0
    }
    if {$n % 12 == 4} { keymatrixup 6 0x04 }
}
proc peligro {} {
    set hy [m 0xE100]
    set hx [m 0xE101]
    for {set k 0} {$k < 16} {incr k} {
        set b [expr {0xE300 + 16 * $k}]
        set t [m [expr {$b + 4}]]
        if {$t == 0} continue
        set y [m $b]
        set x [m [expr {$b + 1}]]
        if {$y >= 0xC0 || $x >= 0xF0} continue
        if {$t == 5 || $t == 3 || $t == 8} {
            if {abs($x - $hx) < 28 && abs($y - $hy) < 18} {
                if {$y < $hy} { if {$hy < 0x95} { return d } else { return u } }
                if {$hy > 0x52} { return u } else { return d }
            }
            continue
        }
        if {$t == 6} {
            if {abs($x - $hx) < 30 && $y < $hy + 8 && $hy - $y < 70} {
                if {$x < $hx} { if {$hx < 0xE0} { return r } else { return l } }
                if {$hx > 0x10} { return l } else { return r }
            }
            continue
        }
        if {abs($x - $hx) < 40 && abs($y - $hy) < 22} {
            if {$y < $hy} { if {$hy < 0x95} { return d } else { return u } }
            if {$hy > 0x52} { return u } else { return d }
        }
    }
    return ""
}
proc fase1 {n} {
    set hy [m 0xE100]
    set hx [m 0xE101]
    set p [peligro]
    if {$p ne "" && [m 0xE1D1] == 0} { keymatrixup 6 0x04; palanca $p; return }
    if {[m 0xE1D1] != 0} {
        if {$hx < 0x79} { palanca r } elseif {$hx > 0x7D} { palanca l } else { palanca u }
        return
    }
    set e [cercano 0]
    if {$e < 0} { if {$hy > 0x78} { palanca u } elseif {$hy < 0x68} { palanca d } else { palanca 0 }; return }
    set dy [expr {[m $e] - $hy}]
    if {$dy > 3} { palanca d } elseif {$dy < -3} { palanca u } else { tira $n $e }
}
proc otras {n} {
    set e [cercano 1]
    if {$e >= 0} { tira $n $e; return }
    keymatrixup 6 0x04
    if {($n / 300) % 2 == 0} { palanca r } else { palanca l }
    if {$n % 90 == 0} { keymatrixdown 8 0x01 }
    if {$n % 90 == 5} { keymatrixup 8 0x01 }
}
proc guion {n} {
    pulsa $n 300 8 0x01
    if {$n > 600 && [m 0xE000] == 1} {
        if {[m 0xE00A] == 1} { fase1 $n } else { otras $n }
    }
    return [expr {$n >= 20000}]
}
