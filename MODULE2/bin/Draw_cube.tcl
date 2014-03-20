namespace eval ::Draw_cube:: {

  variable boxradius 0.1
  variable x
  variable y
  variable z
  variable x1
  variable y1
  variable z1
  variable optionex

}

proc ::Draw_cube::draw_slab {zvar} {
  variable x
  variable y
  variable z
  variable x1
  variable y1
  variable boxradius
  draw cylinder "$x $y $zvar" "$x1 $y $zvar" radius $boxradius
  draw cylinder "$x $y $zvar" "$x $y1 $zvar" radius $boxradius
  draw cylinder "$x $y1 $zvar" "$x1 $y1 $zvar" radius $boxradius
  draw cylinder "$x1 $y $zvar" "$x1 $y1 $zvar" radius $boxradius
}

proc ::Draw_cube::draw_cube { } {
  variable x
  variable y
  variable z
  variable x1
  variable y1
  variable z1
  variable boxradius
  draw_slab $z 
  draw_slab $z1
  draw cylinder "$x $y $z" "$x $y $z1" radius $boxradius
  draw cylinder "$x1 $y $z" "$x1 $y $z1" radius $boxradius
  draw cylinder "$x $y1 $z" "$x $y1 $z1" radius $boxradius
  draw cylinder "$x1 $y1 $z" "$x1 $y1 $z1" radius $boxradius
}

proc ::Draw_cube::main { } {
  global argv
  variable x
  variable y
  variable z
  variable x1
  variable y1
  variable z1
  variable optionex

  set arguments "protein extension chain resID dimx dimy dimz outfolder outname optionex"
  set counter 0
  foreach a $arguments {
    set $a [lindex $argv $counter]
    incr counter
  }

  switch -exact -- $extension {
    pqr {mol load pqr $protein}
    pdb {mol load pdb $protein}
  }

  switch -exact -- [lsort -unique [[atomselect top all] get chain]] {
    X {set chain X}
  }

  mol modstyle Lines top Cartoon
  mol modmaterial Opaque top Transparent
  mol modcolor 0 top ColorID 2
  mol addrep top
  mol modselect 1 top "same residue as (within [expr {$dimx}] of (chain $chain and resid $resID))"
  draw color red
  label add Atoms 0/[[atomselect top "chain $chain and (resid $resID and name CA)"] get index]
  mol addrep top
  mol modselect 2 top "chain $chain and resid $resID"
  mol modstyle 2 top Licorice
  draw color yellow
  axes location lowerleft
  set CA [atomselect top "chain $chain and (resid $resID and name CA)"]
  set center "[$CA get x] [$CA get y] [$CA get z]"

  set x [expr {[lindex $center 0] - $dimx}]
  set y [expr {[lindex $center 1] - $dimy}]
  set z [expr {[lindex $center 2] - $dimz}]
  set x1 [expr {$x + ($dimx*2)}]
  set y1 [expr {$y + ($dimy*2)}]
  set z1 [expr {$z + ($dimz*2)}]


  draw_cube
  save_state $outfolder$outname.vmd

  
  

}

proc ::Draw_cube::main_init { } {
  global errorInfo errorCode
  variable optionex
  set errflag [catch { ::Draw_cube::main } errMsg]
  set savedInfo $errorInfo
  set savedCode $errorCode

  
  if $errflag { 
    puts stderr "Something went wrong while creating cube\n\nError: \n$errMsg\n$savedInfo\n$savedCode"
    exit
  }

  switch -glob -- $optionex {
    [nN][oO] -
    [nN] -
    0 {exit}
  }
   #if $errflag { error "Something went wrong while aligning\n\nError: \n$errMsg" }
}

::Draw_cube::main_init



