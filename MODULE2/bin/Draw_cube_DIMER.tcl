namespace eval ::Draw_cube_DIMER:: {

  variable boxradius 0.1
  variable x
  variable y
  variable z
  variable x1
  variable y1
  variable z1
  variable dimx
  variable dimy
  variable dimz
  variable optionex

}

proc ::Draw_cube_DIMER::draw_slab {zvar} {
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

proc ::Draw_cube_DIMER::draw_cube {} {
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

proc ::Draw_cube_DIMER::main { } {
  
  variable x
  variable y
  variable z
  variable x1
  variable y1
  variable z1
  variable optionex
  set arguments "protein extension dimx dimy dimz outfolder outname optionex"
  set counter 0
  foreach a $arguments {
    set $a [lindex $argv $counter]
    incr counter
  }

  switch -exact -- $extension {
    pqr {mol load pqr $protein}
    pdb {mol load pdb $protein}
  }

  set FILE [open dimer.coor r] 
  set center [gets $FILE]

  draw color green
  draw sphere $center radius 0.6

  set distance [max $dimx $dimy $dimz]
  set x [lindex $center 0] 
  set y [lindex $center 1]
  set z [lindex $center 2]

  mol modstyle Lines top Cartoon
  mol modmaterial Opaque top Transparent
  mol modcolor 0 top ColorID 2
  mol addrep top
  mol modselect 1 top "same residue as (protein and sqrt((x-$x)*(x-$x)+(y-$y)*(y-$y)+(z-$z)*(z-$z)) <= $distance)"
  draw color yellow
  axes location lowerleft

  set x [expr {[lindex $center 0] - $dimx}]
  set y [expr {[lindex $center 1] - $dimy}]
  set z [expr {[lindex $center 2] - $dimz}]
  set x1 [expr {$x + ($dimx*2)}]
  set y1 [expr {$y + ($dimy*2)}]
  set z1 [expr {$z + ($dimz*2)}]


  draw_cube
  save_state $outfolder$outname.vmd



}
proc ::Draw_cube_DIMER::main_init { } {
  global errorInfo errorCode
  variable optionex
  set errflag [catch { ::Draw_cube_DIMER::main } errMsg]
  set savedInfo $errorInfo
  set savedCode $errorCode

  
   if $errflag { 
    puts stderr "Something went wrong while creating dimer cube\n\nError: \n$errMsg\n$savedInfo\n$savedCode"
    exit
   }
   #if $errflag { error "Something went wrong while aligning\n\nError: \n$errMsg" }

   switch -glob -- $optionex {
    [nN][oO] -
    [nN] -
    0 {exit}
   }
}

::Draw_cube_DIMER::main_init


