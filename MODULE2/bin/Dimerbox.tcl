#############################
### DX POTENTIAL PARSER #####
#############################
#############################
### DIMER INTERFACE BOX  ####
#############################

namespace eval ::Dimerbox:: {
  
}


proc ::Dimerbox::main {} {

  # GETTING VARIABLES FROM SCRIPTS ARGUMENTS
  set arguments "protein extension dimx dimy dimz outfolder outname"
  set counter 0
  foreach a $arguments {
    set $a [lindex $argv $counter]
    incr counter
  }

  switch -exact -- $extension {
    pqr {mol load pqr $protein}
    pdb {mol load pdb $protein}
  }

  set chains [lsort -unique [[atomselect top all] get chain]]

  set A [measure center [atomselect top "chain [lindex $chains 0]"]]
  set B [measure center [atomselect top "chain [lindex $chains 1]"]]

  set Ax [lindex $A 0]
  set Ay [lindex $A 1]
  set Az [lindex $A 2]
  set Bx [lindex $B 0]
  set By [lindex $B 1]
  set Bz [lindex $B 2]
  set migx [vecmean [list $Ax $Bx]]
  set migy [vecmean [list $Ay $By]]
  set migz [vecmean [list $Az $Bz]]
  set mig [list $migx $migy $migz]


  set FILE [open dimer.coor w]
  puts $FILE $mig
  close $FILE

  set FILE [open "Atom_names.txt" w]
  puts $FILE "NA\tNA\tNA"
  close $FILE
}


proc ::Dimerbox::main_init { } {
  global errorInfo errorCode
  
  set errflag [catch { ::Dimerbox::main } errMsg]
  set savedInfo $errorInfo
  set savedCode $errorCode

  
   if $errflag { 
    puts stderr "Something went wrong while creating cylinders\n\nError: \n$errMsg\n$savedInfo\n$savedCode"
    exit
   }
   #if $errflag { error "Something went wrong while aligning\n\nError: \n$errMsg" }
}

::Dimerbox::main_init
