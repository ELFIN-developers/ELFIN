#set tcl_precision 12

namespace eval ::Draw_surf:: {

  variable boxradius 0.1
  variable textsize 0.7
  variable x
  variable y
  variable z
  variable x1
  variable y1
  variable z1
  variable center1
  variable distance
  variable dimx
  variable dimy
  variable dimz
  variable CHANNEL

}


proc draw_slab {zvar} {
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

proc draw_cube {} {
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


proc ::Draw_surf::draw_surf { patch } {

  variable x
  variable y
  variable z
  variable x1
  variable y1
  variable z1
  variable center1
  variable distance
  variable dimx
  variable dimy
  variable dimz
  variable CHANNEL
  variable textsize

  set adddistancevec [veczero]
  switch -glob -- $patch{
  [xX0]* {
	    lset adddistancevec 0 $distance
	 }
  [yY1]* {
	    lset adddistancevec 1 $distance
	 }
  default {
	    error {Wrong patch name.}
	 }
  }
  set center [vecadd $center1 $adddistancevec]
  set x [expr {[lindex $center 0] - $dimx}]
  set y [expr {[lindex $center 1] - $dimy}]
  set z [expr {[lindex $center 2] - $dimz}]
  set x1 [expr {$x + ($dimx*2)}]
  set y1 [expr {$y + ($dimy*2)}]
  set z1 [expr {$z + ($dimz*2)}]
  puts $CHANNEL $center
  draw_cube
  draw color red
  draw text $center [format {% g} $patch] size $textsize
  draw color yellow
}

proc ::Draw_surf::main { } {
  global argv

  set arguments "protein extension dimx dimy dimz distance outfolder outname"
  set counter 0
  foreach a $arguments {
    set $a [lindex $argv $counter]
    incr counter
  }


  switch -exact -- $extension {
    pqr {mol load pqr $protein}
    pdb {mol load pdb $protein}
  }

  mol modstyle Lines top Cartoon
  mol modmaterial Opaque top Transparent
  mol modcolor 0 top ColorID 2
  draw color yellow
  axes location lowerleft

  set center1 [measure center [atomselect top all]] 
  set CHANNEL [open surf_centers.coor w]

  draw_surf "X1"
  draw_surf "Y1"
  set distance [expr {-$distance}]
  draw_surf "X2"
  draw_surf "Y2"

  close $CHANNEL
  save_state $outfolder$outname.vmd


}




proc ::Draw_surf::main_init { } {
  global errorInfo errorCode
  
  set errflag [catch { ::Draw_surf::main } errMsg]
  set savedInfo $errorInfo
  set savedCode $errorCode

  
   if $errflag { 
    puts stderr "Something went wrong while creating cylinders\n\nError: \n$errMsg\n$savedInfo\n$savedCode"
    exit
   }
   #if $errflag { error "Something went wrong while aligning\n\nError: \n$errMsg" }
}

::Draw_surf::main_init
exit
