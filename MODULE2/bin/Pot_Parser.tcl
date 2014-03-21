#############################
### DX POTENTIAL PARSER #####
#############################
####################
### TCL ROUTINE ####
####################
#set tcl_precision 12
namespace eval ::Pot_Parser:: {
  namespace path {::tcl::mathop ::tcl::mathfunc}
  variable switcher
  variable CHANNEL0
  variable dimx
  variable dimy
  variable dimz
  variable spacing
  variable method
}

# TCL8.5 calculating precision is set to 17 by default. I here set it to 12 in order to 
# print proper tables with the right decimal places


proc ::Pot_Parser::wc_l { filepath {buffer_size {524288}} } {
  
  set CHANNEL [open $filepath r]
  # Use a 512K buffer
  fconfigure $CHANNEL -buffersize $buffer_size -translation binary
  set rc 0
  while {![eof $CHANNEL]} {

    incr rc [llength [split [read $CHANNEL $buffer_size] "\n"]] 
    incr rc -1
    
  }
  
  return $rc
} 


# FUNCTION FOR GENERATING RANGES OF NUMBERS
proc ::Pot_Parser::range args {
    set variables "start stop step"
    set counter 0
    foreach a $variables {
      set $a [lindex $args $counter]
      incr counter
    }
    if {$step == 0} {error "Sorry, step cannot be 0...."}
    set range {}
    while { $start < $stop } {
	lappend range $start
	set start [expr {$start + $step}]
    }
    return $range
}

# FUNCTION FOR CREATING "resid.coor" & "box.coor", USED LATER ON FOR PRINTING ON TO TABLE
proc ::Pot_Parser::coord_box args {
  variable switcher
  variable CHANNEL0
  variable dimx
  variable dimy
  variable dimz
  variable spacing
  variable method

  switch -exact -- $switcher {
    1 -
    2 -
    5 {set CHANNEL0 [open CA.coor r]}
    3 {set CHANNEL0 [open surf_centers.coor r]}
    4 {set CHANNEL0 [open dimer.coor r]}
    default {error {Wrong source of coordinates, please insert 1, 2, 3, 4 or 5 next time}}
  }

  set patchcenter0 {}
  while { [gets $CHANNEL0 line] >= 0 } {
    lappend patchcenter0 $line
  }
  set patchcenter [lindex $patchcenter0 [lindex $args 0]]
  close $CHANNEL0

  set dimrangex [::Pot_Parser::range [expr {-$dimx}] [expr {$dimx+$spacing}] $spacing]
  set dimrangey [::Pot_Parser::range [expr {-$dimy}] [expr {$dimy+$spacing}] $spacing]
  set dimrangez [::Pot_Parser::range [expr {-$dimz}] [expr {$dimz+$spacing}] $spacing]
  set CHANNEL1 [open resid.coor w]
  set CHANNEL2 [open box.coor w]
  foreach c $dimrangex { 
    switch -exact -- $method {
    1 {
	puts -nonewline $CHANNEL1 "[format {% .17f} [expr {[lindex $patchcenter 0] + $c}]]\t"
	puts -nonewline $CHANNEL1 "[format {% .17f} [lindex $patchcenter 1]]\t"
	puts $CHANNEL1 [lindex $patchcenter 2]
	puts $CHANNEL2 "[format {% g} $c]\t[format {% g} 0]\t[format {% g} 0]"
      }
    2 {
	foreach a $dimrangey {
	  puts -nonewline $CHANNEL1 "[format {% .17f} [expr {[lindex $patchcenter 0] + $c}]]\t"
	  puts -nonewline $CHANNEL1 "[format {% .17f} [expr {[lindex $patchcenter 1] + $a}]]\t"
	  puts $CHANNEL1 [lindex $patchcenter 2]
	  puts $CHANNEL2 "[format {% g} $c]\t[format {% g} $a]\t[format {% g} 0]"
	}
      }
    3 {
	foreach a $dimrangey {
	  foreach b $dimrangez {
	    puts -nonewline $CHANNEL1 "[format {% .17f} [expr {[lindex $patchcenter 0] + $c}]]\t"
	    puts -nonewline $CHANNEL1 "[format {% .17f} [expr {[lindex $patchcenter 1] + $a}]]\t"
	    puts $CHANNEL1 "[format {% .17f} [expr {[lindex $patchcenter 2] + $b}]]\t"
	    puts $CHANNEL2 "[format {% g} $c]\t[format {% g} $a]\t[format {% g} $b]"
	  }
	}
      }
    default {error {Wrong method picked, please insert 1, 2 or 3 next time}}
    }
  }
  close $CHANNEL1
  close $CHANNEL2
}

# FUNCTION FOR LOADING UP COORDINATES FROM FILE RESID.COOR INTO A LIST (LATER ON CALLED $COORDS) AND
# GETTING ATOM NAMES INTO ANOTHER ONE (LATER ON CALLED $ATOMS)
proc ::Pot_Parser::getcoords args {
  switch -exact -- [lindex $args 1] {
      box.coor {set options {COORDS BOXCOORDS}}
      Atom_names.txt {set options {COORDS ATOMS}}
      default {error {wrong # of args: should be "getcoords ?coorfilename? atom/boxfilename"}}
  }
  foreach a $args b $options {
    set CHANNEL [open $a r]
    set $b {}
    while {[gets $CHANNEL line] >= 0} {
      lappend $b $line
    }
    close $CHANNEL
  }
  switch -exact -- [lindex $args 1] {
      box.coor {set both [dict create $COORDS $BOXCOORDS]
	 return $both}
      Atom_names.txt {set both [dict create $COORDS $ATOMS]
	 return $both}
      default {error {Wrong coor/atom dictionary returned by "proc getcoords", please start over}}
  } 
}

proc ::Pot_Parser::main {} {
  global argv
  variable switcher
  variable CHANNEL0
  variable dimx
  variable dimy
  variable dimz
  variable spacing
  variable method
  # GETTING VARIABLES FROM SCRIPTS ARGUMENTS
  set variables "nx ny nz origx origy origz deltax deltay deltaz switcher dimx dimy dimz spacing protein namestring method"
  set counter 1
  foreach a $variables {
    set $a [lindex $argv $counter]
    incr counter
  }

  # OBTAINING DX FILE LINE NUMBER - TAIL
  puts "LOADING UP DX FILE..."
  set linenumber [expr {[::Pot_Parser::wc_l [lindex $argv 0]] - 4}]

  # LOADING POTENTIAL VALUES INTO A LIST, SKIPPING EXTRA INFO ON FILE (HEADER AND TAIL)
  set CHANNEL [open [lindex $argv 0] r]
  set POTFILE {}
  set counter 0

  for {set linenum 1} {$linenum < 12} {incr linenum} {gets $CHANNEL}

  for {} {$linenum < $linenumber} {incr linenum} {
    foreach a [gets $CHANNEL] {
      lappend POTFILE $a
    }
  } 


  close $CHANNEL

  # SWITCHING OPTION FOR COORDINATES AND ATOM NAMES GENERATION
  set coorfile "resid.coor"
  set atomsfile "Atom_names.txt"
  set boxcoor "box.coor"
  #set surfcenters "surf_centers.coor"
  set sep "_"

  # # OBTAINING NUMBER OF SURFACES CENTERS FROM NUMBER OF FILE LINES
  # set linenumber 0
  # set CHANNELX [open surf_centers.coor r]
  # while { [gets $CHANNELX line] >= 0 } {
  #     incr linenumber
  # }
  # close $CHANNELX

  # CREATING SWITCH FOR 1 (INDIVIDUAL BOX) OR 4 (EXTERNAL SURFACE) CENTERS.
  switch -exact -- $switcher {
    1 -
    2 -
    4 -
    5 {
	set outname "$namestring"
	set patcheslen 1
      }

    3 {
	set patches {X1 Y1 X2 Y2}
	set surfid [lindex $patches $p]
	set patcheslen [llength $patches]
	set outname "$namestring$sep"
      }
    default {
	error {Wrong source of coordinates, please insert 1, 2, 3, 4 or 5 next time}
      }
  }
  
  # LOOPING OVER DIFFERENT SURFACES/BOXES IF MORE THAN 1
  set p 0
  while { $p < $patcheslen } {

    switch -exact -- $switcher {
      1 -
      4 -
      5	{
	  # CALLING CORD_BOX FUNCTION DEFINED ABOVE ALONG WITH REST OF PROCESSES
	  ::Pot_Parser::coord_box $p
	  set both [::Pot_Parser::getcoords $coorfile $boxcoor]
	  set datanames {COORDS BOXCOORDS}

	}

      3 {
	  set outname "$outname$p"
	  # CALLING CORD_BOX FUNCTION DEFINED ABOVE ALONG WITH REST OF PROCESSES
	  ::Pot_Parser::coord_box $p
	  set both [::Pot_Parser::getcoords $coorfile $boxcoor]
	  set datanames {COORDS BOXCOORDS}
	}

      2 {
	  set both [::Pot_Parser::getcoords $coorfile $atomsfile]
	  set datanames {COORDS BOXCOORDS}
	}

      default {
	  error {Wrong source of coordinates, please insert 1, 2, 3, 4 or 5 next time}
	}

    }

   
    foreach a $datanames b {0 1} {
	  set $a [lindex $both $b]
    }
    

    # CONVERTING COORDINATES TO I J K, OBTAINING LIST NUMBER FOR POTENTIAL FIGURE AND PRINTING RESULT
    set CHANNEL [open Output/$outname·4D.txt w]
    switch -exact -- $switcher {
      1 -
      3 -
      4 -
      5	{
	  puts $CHANNEL "INDEX\tX\tY\tZ\tPOTENTIAL"
	  upvar 0 BOXCOORDS POTID 
	}
      2 {
	  switch -exact -- $method {
	    1 {puts $CHANNEL "INDEX\tATOM\tX\tY\tZ\tPOTENTIAL"}
	    2 {puts $CHANNEL "INDEX\tATOM\tPOTENTIAL"}
	    default {error {Wrong coordinates collection method, please insert 1 or 2 next time}
	      }
	  }
	  upvar 0 ATOMS POTID
	}
      default {error {Wrong source of coordinates, please insert 1, 2, 3, 4 or 5 next time}}
    }
    
    set c 0
    while { $c < [llength $COORDS] } {  
      foreach a {0 1 2} b {xraw yraw zraw} {
	set $b [lindex [lindex $COORDS $c] $a]
      }
      set i [expr {round(($xraw - $origx) / $deltax )}]
      set j [expr {round(($yraw - $origy) / $deltay )}]
      set k [expr {round(($zraw - $origz) / $deltaz )}]
      set potnum [expr {($k + $j*$nz + $i*$ny*$nz)}]
      puts -nonewline $CHANNEL "$c\t"
      puts -nonewline $CHANNEL "[lindex $POTID $c]\t"; puts $CHANNEL [lindex $POTFILE $potnum]
      incr c
    }
    close $CHANNEL

    # MERGING Z COORDINATE FOR SUBSEQUENT 3D CONTOURN PLOTTING
    switch -exact -- $switcher {
      1	-
      3	-
      5	{
	set CHANNEL [open Output/$outname.txt w]
	puts $CHANNEL "X\tY\tPOTENTIAL"
	set c 0
	set d 1
	set zcounter [expr {round((($dimx+$dimy)/$spacing)+1)}]
	set potnumlist {}
	while { $c < [llength $COORDS] } {  
	  foreach a {0 1 2} b {xraw yraw zraw} {
	    set $b [lindex [lindex $COORDS $c] $a]
	  }
	  set i [expr {round(($xraw - $origx) / $deltax )}]
	  set j [expr {round(($yraw - $origy) / $deltay )}]
	  set k [expr {round(($zraw - $origz) / $deltaz )}]
	  set potnum [expr {($k + $j*$nz + $i*$ny*$nz)}]
	  lappend potnumlist [lindex $POTFILE $potnum]
	  if {$d == $zcounter} {
	    set e 1
	    set meanlist {}
	    while { $e < $zcounter } {
	      lappend meanlist [lindex $potnumlist [expr {int($c-($zcounter-$e))}]]
	      incr e
	    }
	    set mean [/ [+ {*}$meanlist] [llength $meanlist]]
	    puts $CHANNEL [format "% g\t% g\t% .17f" [lindex [lindex $BOXCOORDS $c] 0] [lindex [lindex $BOXCOORDS $c] 1] $mean]
	    set d 0
	  }
	  incr c
	  incr d
	}
	close $CHANNEL
     }
    }
    incr p
  }

}

proc ::Pot_Parser::main_init { } {
  #global errorInfo errorCode
  
  set errflag [catch { ::Pot_Parser::main } errMsg]
  #set savedInfo $errorInfo
  #set savedCode $errorCode

  
#   if $errflag { error "Something went wrong while aligning\n\nError: \n$errMsg\n$savedInfo\n$savedCode" }
    if $errflag { error "Something went wrong while parsing dx file\n\nError: \n$errMsg" }
}

::Pot_Parser::main_init
exit



