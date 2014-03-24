#############################
### DX POTENTIAL PARSER #####
#############################
#############################
### MAIN BASH CONTROLLER ####
#############################
### ==> PLEASE HAVE A LOOK AT THE ATTACHED README FILE FOR INSTRUCTIONS!!!

# VERSION

version=0

echo -e "\n########################\n# Welcome to ELFINv${version} #\n########################"

# SETTING PATHS
# DIR PATHS
WHERE=`echo $PWD`
OUTPUT=$WHERE/Output/
SAMPLES=$WHERE/Samples/
# EXECUTABLE PATHS
BINPATH=/usr/bin
HOMEBIN=${HOME}${BINPATH}
#PYTHON=`alias | grep bin/python | cut -d = -f2 | sed s/\'//g`
#echo "$PYTHON"
PYTHON=/soft/devel/python-2.7/bin/python
TCL=tclsh8.5
RSCRIPT=Rscript
ACROREAD=acroread
VIEWER=evince
#VMD=`alias | grep vmd | cut -d = -f2 | sed s/\'//g`
#echo "$VMD"
VMD=vmd

sep=_

# GETTING ARGUMENTS IF ANY, OTHERWISE JUMP TO THE INTERACTIVE MODE
echo -e "--------------------------------------------------"
if [ $# -gt 0 ]
then
  echo "ARGUMENTS DETECTED, NON-INTERACTIVE MODE ACTIVATED"
  args=("$@")
  error="Wrong combination of arguments, please have a look at the README file and try again"
  if [ "${args[3]}" == 1 ]
  then
    variables=(dx pdbpqr chain coordsource refres dimx dimy dimz spacing patchmethod displayvmd displayplot) 
  elif [ "${args[3]}" == 2 ] && [ "${args[4]}" == 1 ]
  then
    variables=(dx pdbpqr chain coordsource coordmethod res1 atomname dimx dimy dimz spacing displayplot)
  elif [ "${args[3]}" == 2 ] && [ "${args[4]}" == 2 ] && [ "${args[5]}" == 1 ]
  then
    variables=(dx pdbpqr chain coordsource coordmethod answ res1 res2 displayplot)
  elif [ "${args[3]}" == 2 ] && [ "${args[4]}" == 2 ] && [ "${args[5]}" == 2 ]
  then
    variables=(dx pdbpqr chain coordsource coordmethod answ res1 res2 res3 res4 displayplot)
  elif [ "${args[3]}" == 3 ] && [ "${args[2]}" != 4 ]
  then
    variables=(dx pdbpqr distsurf coordsource dimx dimy dimz spacing patchmethod displayvmd displayplot) 
  elif [ "${args[2]}" == 4 ]
  then
    variables=(dx pdbpqr coordsource dimx dimy dimz spacing patchmethod displayvmd displayplot)
  elif [ "${args[3]}" == 5 ]
  then
    variables=(dx pdbpqr chain coordsource refres1 refres2 refres3 refres4 dimx dimy dimz spacing patchmethod displayvmd displayplot) 
  else
    echo $error
  fi

  if [ ${#args[*]} -eq ${#variables[*]} ]
  then
    i=0
    for x in ${args[@]}; do 
      eval `echo ${variables[$i]}`=`echo $x`
      let i+=1
    done
  else
    echo $error
    exit
  fi

else
# STARTING INTERACTIVE MODE
    echo "    NO ARGUMENTS, INTERACTIVE MODE ACTIVATED"
fi
echo -e "--------------------------------------------------"
# FILE NAME REMINDER
echo -e "\nRemember, .DX and .PDB files MUST have the same name!!!\n"

# DX, STRUCTURE & CHAIN SETTINGS
# USER INPUT IF NON INTERACTIVE MODE IS DETECTED
if [ "${dx}" == "" ]
then
  echo "Insert DX filename: "
  read -e dx
fi

if [ "${pdbpqr}" == "" ]
then
  echo "Insert structure filename: "
  read -e pdbpqr
fi

if [ "${chain}" == "" ] && [ "$coordsource" != 3 ] && [ "$coordsource" != 4 ]
then
  echo "Insert chain ID: "
  read -e chain
fi

# CREATING FOLDERS AND MOVING SAMPLE FILES IF NEEDED
for d in $SAMPLES $OUTPUT; do
  if [ -d  "${d}" ]
  then
    continue
  else
    mkdir ${d}
  fi
done

if [ -f ${dx} ]
then 
  mv ${dx} ${SAMPLES}
  echo "I moved your DX file to ${SAMPLES}${dx}"
  echo "I'll keep it there for future runs"
elif [ -f ${SAMPLES}${dx} ]
then
  echo -e "\n DX file in ${SAMPLES}${dx}"
else 
  echo "Sorry, I don't find your ${dx} file"
  echo "Do me a favour, place it into $SAMPLES dir and try again..."
  exit
fi

# GRABBING PROTEIN NAME AND EXTENSION  
protein=`echo ${dx} | cut -d . -f1`
extension=`echo ${pdbpqr} | cut -d . -f2`
filename=Samples/${dx}

# PARSING FILE HEADER IN ORDER TO OBTAIN GRID DIMENSIONS, CELL ORIGIN COORDINATES AND DELTA COORDINATES
i=`grep -m 1 'object' $filename | cut -d " " -f6`
j=`grep -m 1 'object' $filename | cut -d " " -f7`
k=`grep -m 1 'object' $filename | cut -d " " -f8`

origx=`grep 'origin' $filename | cut -d " " -f2`
origy=`grep 'origin' $filename | cut -d " " -f3`
origz=`grep 'origin' $filename | cut -d " " -f4`

deltax=`grep -m 1 'delta' $filename | cut -d " " -f2`
deltay=`grep -m 2 'delta' $filename | tail -n1 | cut -d " " -f3`
deltaz=`grep -m 3 'delta' $filename | tail -n1 | cut -d " " -f4`


# STRUCTURE FILE SETTINGS
structure=${SAMPLES}${pdbpqr}


if [ -f ${pdbpqr} ]
then 
  mv ${pdbpqr} ${structure}
  echo "I moved your ${structure} file to ${SAMPLES}${pdbpqr}"
  echo "I'll keep it there for future runs"
elif [ -f ${structure} ]
then
  echo -e " Structure file in ${structure}\n"
else
  echo "Sorry, I don't find your ${pdbpqr} file anywhere"
  echo "Do me a favour, place it into $SAMPLES dir and try again..."
fi


# USER DECIDES WHETHER USING STRUCTURE FILE FOR COORDINATE COLLECTION
# OR JUST FOR PARSING ALPHA CARBON COORDINATES OF CERTAIN RESIDUE
if [ "${coordsource}" == "" ]
then
  echo "Choose your method for coordinates collection:"
  echo "1 - Customize your own patch:"
  echo -e "2 - Residue coordinates collection:"
  echo -e "3 - Electrostatic surface:\n"
  echo -e "4 - Dimer interface:\n"
  echo -e "5 - Customize your own patch 4 res:\n"
  echo -n "Please insert 1, 2 or 3 to proceed: "
  read coordsource
fi

# GET PARAMETERS AND GO TO PYTHON ROUTINE

if [ $coordsource == 1 ]
then 

  # GETTING CARBON ALPHA COORDINATES FOR A CERTAIN RESIDUE
  if [ "${refres}" == "" ]
  then
    echo -n "Residue you'll use as reference:"
    read refres
  fi
  if [ "${patchmethod}" == "" ]
  then
    echo "What are you up to?:"
    echo -e "1 - Line (1D)\n2 - Slice (2D)\n3 - Cube / Other prism (3D)"
    echo -n "Insert 1, 2 or 3: "
    read patchmethod
  fi
  if [ "${dimx}" == "" ] 
  then
    echo "Desired patch dimensions in angstoms: "
    echo -n "X:"
    read dimx
    if [ "${patchmethod}" -eq 1 ]
    then
      dimy=0
      dimz=0
    fi
  fi
  if [ "${dimy}" == "" ]
  then
    echo -n "Y:"
    read dimy
    if [ "${patchmethod}" -eq 2 ]
    then
      dimy=0
      dimz=0
    fi
  fi
  if [ "${dimz}" == "" ]
  then
    echo -n "Z:"
    read dimz
  fi
  if [ "${spacing}" == "" ]
  then
    echo -n "Insert spacing for patch building: "
    read spacing
  fi
  outname=${protein}${chain}$sep${refres}$sep${dimx}$sep${dimy}$sep${dimz}$sep${spacing}
  outname2=${outname}_Rcontourn
  outname3=${outname}_PYcontourn

  # PYTHON ROUTINE: OBTAINING COORDINATES OF REFERENCE RESIDUE
  ${PYTHON} $ELFINDIR/PDBpatch.py $coordsource $structure $extension $chain $refres 

  # TCL ROUTINE: PARSING DX FILE DATA AND READING ELECTROSTATIC POTENTIAL INTO A TABLE
  ${TCL} $ELFINDIR/Pot_Parser.tcl $filename $i $j $k $origx $origy $origz $deltax $deltay $deltaz $coordsource $dimx $dimy $dimz $spacing $protein ${outname} $patchmethod 
  echo -e "  \nTable containing potentials should be in ${OUTPUT}data\n"


elif [ $coordsource == 2 ]
then

  # USER DECIDES TO BUILD A BOX AROUND A CERTAIN ATOM OR JUST PARSE ATOM COORDINATES
  # USER INSERT RESIDUE OR RESIDUE SEQUENCE PLUS BOX PARAMETERS
  if [ "${coordmethod}" == "" ]
  then
    echo -e "What coordinates would you like to use?:\n1 - A 3D patch around a certain atom\n2 - Literal coordinates of a residue/s I'll pick"
    echo -n "Please insert 1 or 2: " 
    read coordmethod
  fi
  if [ $coordmethod == 1 ]
  then
    if [ "${res1}" == "" ]
    then	
      echo -n "What residue will you use?: "
      read res1
    fi
    answ=0
    res2=0
    res3=0
    res4=0
    if [ "${atomname}" == "" ]
    then
      echo -n "Atom name where box will be built around(capitals): "
      read atomname
    fi
    if [ "${dimx}" == "" ]
    then
      echo "Desired patch dimensions in angstroms: "
      echo -n "X:"
      read dimx
    fi
    if [ "${dimy}" == "" ]
    then
      echo -n "Y:"
      read dimy
    fi
    if [ "${dimz}" == "" ]
    then
      echo -n "Z:"
      read dimz
    fi
    if [ "${spacing}" == "" ]
    then
      echo -n "Insert spacing for symmetric cube building(angstroms): "
      read spacing
    fi
    outname=${protein}${chain}$sep${atomname}${res1}$sep${dimx}$sep${dimy}$sep${dimz}$sep${spacing}
    outname2=${outname}_Rcontourn
    outname3=${outname}_PYcontourn

  elif [ $coordmethod == 2 ]
  then
    if [ "${answ}" == "" ]
    then
      echo "Will you process 1 or 2 different patches:"
      read answ
    fi
    if [ $answ == 1 ]
    then
      if [ "${res1}" == "" ]
      then
	echo "Please insert the RESIDUE SEQUENCE you want to extract the potential from:"
	echo -n "FROM RESIDUE: "
	read $res1
      fi
      if [ "${res2}" == "" ]
      then
	echo -n "TO RESIDUE: "
	read $res2
      fi
      res3=0
      res4=0
      atomname=NULL
      dimx=0
      dimy=0
      dimz=0
      spacing=0
      outname=${protein}${chain}$sep${res1}$sep${res2}
      outname2=${outname}_Rcontourn
      outname3=${outname}_PYcontourn
    elif [ $answ == 2 ]
    then
      if [ "${res1}" == "" ]
      then
	echo "SO, FIRST PATCH GOES:"
	echo -n "FROM RESIDUE: "
	read res1
      fi
      if [ "${res2}" == "" ]
      then
	echo -n "TO RESIDUE: "
	read res2
      fi
      if [ "${res3}" == "" ]
      then
	echo "AND SECOND PATCH TAKES: "
	echo "FROM RESIDUE: "
	read res3
      fi
      if [ "${res4}" == "" ]
      then
	echo "TO RESIDUE: "
	read res4
      fi
      atomname=NULL
      dimx=0
      dimy=0
      dimz=0
      spacing=0
      outname=${protein}${chain}$sep${res1}$sep${res2}$sep${res3}$sep${res4}
      outname2=${outname}_Rcontourn
      outname3=${outname}_PYcontourn
    else
      echo -e "Man, start over and state whether you want 1 or 2 patches..."
    fi
  else
    echo "You picked a wrong method, just pick method 1 or 2 next time..." 
  fi

  # PYTHON ROUTINE: OBTAINING COORDINATES FROM PDB OUT OF RESIDUE/S ID INSERTED BY USER

  # GET THE STATUS OF FILE 'RESID.COOR' PRIOR TO EXECUTING THE PYTHON ROUTINE
  if [ ! -f resid.coor ]
  then
      touch resid.coor
  fi

  check1=`stat -t resid.coor | cut -d " " -f13`

  ${PYTHON} $ELFINDIR/PDBpatch.py $coordsource $structure $extension $chain $coordmethod $res1 $answ $atomname $dimx $dimy $dimz $spacing $res2 $res3 $res4 

  # CHECK FILE 'RESID.COOR' STATUS AGAIN AND MAKE SURE IS DIFFERENT. 
  # OTHERWISE, IT MEANS THE PYTHON ROUTINE DID NOT EXECUTE PROPERLY
  check2=`stat -t resid.coor | cut -d " " -f13`

  if [ "$check2" != "$check1" ]
  then
    
    # TCL ROUTINE: PARSING DX FILE DATA AND READING ELECTROSTATIC POTENTIAL INTO A TABLE
    ${TCL} $ELFINDIR/Pot_Parser.tcl $filename $i $j $k $origx $origy $origz $deltax $deltay $deltaz $coordsource $dimx $dimy $dimz $spacing $protein ${outname} $coordmethod
    echo -e "  Table containing potentials sould be in ${OUTPUT}data\n"

  fi

elif [ $coordsource == 3 ]
then

  # GETTING COORDINATES FOR BUILDING UP SURFACE BOX AROUND PROTEIN
  surfs=(X1 Y1 X2 Y2)
  if [ "${patchmethod}" == "" ]
  then
    echo "Geometry of surface boxes?:"
    echo -e "1 - Line (1D)\n2 - Slice (2D)\n3 - Cube / Other prism (3D)"
    echo -n "Insert 1, 2 or 3: "
    read patchmethod
  fi
  if [ "${dimx}" == "" ] 
  then
    echo "Desired box dimensions in angstoms: "
    echo -n "X:"
    read dimx
    if [ "${patchmethod}" -eq 1 ]
    then
      dimy=0
      dimz=0
    fi
  fi
  if [ "${dimy}" == "" ]
  then
    echo -n "Y:"
    read dimy
    if [ "${patchmethod}" -eq 2 ]
    then
      dimy=0
      dimz=0
    fi
  fi
  if [ "${dimz}" == "" ]
  then
    echo -n "Z:"
    read dimz
  fi
  if [ "${spacing}" == "" ]
  then
    echo -n "Insert spacing for patch building: "
    read spacing
  fi
  if [ "${distsurf}" == "" ]
  then
    echo -n "Insert distance to protein's centre: "
    read distsurf
  fi
  outname=${protein}$sep"SURF"$sep$distsurf$sep${dimx}$sep${dimy}$sep${dimz}$sep${spacing}

  # TCL ROUTINE: OBTAINING COORDINATES OUT OF PROTEIN CENTER. 4 CENTERS WILL BE COLLECTED SO THAT 4 PRISMS CAN BE BUILT UP
  ${VMD} -dispdev text -e $ELFINDIR/Draw_surf.tcl -args $structure $extension $dimx $dimy $dimz $distsurf ${OUTPUT} ${outname} #1&>/dev/null

  # TCL ROUTINE: PARSING DX FILE DATA AND READING ELECTROSTATIC POTENTIAL INTO A TABLE
  ${TCL} $ELFINDIR/Pot_Parser.tcl $filename $i $j $k $origx $origy $origz $deltax $deltay $deltaz $coordsource $dimx $dimy $dimz $spacing $protein ${outname} $patchmethod 

elif [ $coordsource == 4 ]
then 

  if [ "${patchmethod}" == "" ]
  then
    echo "What are you up to?:"
    echo -e "1 - Line (1D)\n2 - Slice (2D)\n3 - Cube / Other prism (3D)"
    echo -n "Insert 1, 2 or 3: "
    read patchmethod
  fi
  if [ "${dimx}" == "" ] 
  then
    echo "Desired patch dimensions in angstoms: "
    echo -n "X:"
    read dimx
    if [ "${patchmethod}" -eq 1 ]
    then
      dimy=0
      dimz=0
    fi
  fi
  if [ "${dimy}" == "" ]
  then
    echo -n "Y:"
    read dimy
    if [ "${patchmethod}" -eq 2 ]
    then
      dimy=0
      dimz=0
    fi
  fi
  if [ "${dimz}" == "" ]
  then
    echo -n "Z:"
    read dimz
  fi
  if [ "${spacing}" == "" ]
  then
    echo -n "Insert spacing for patch building: "
    read spacing
  fi
  outname=${protein}$sep"DIMER"$sep${dimx}$sep${dimy}$sep${dimz}$sep${spacing}
  outname2=${outname}_Rcontourn
  outname3=${outname}_PYcontourn

  # TCL SCRIPT: OBTAINING COORDINATES OF DIMER INTERFACE
  ${VMD} -dispdev text -e $ELFINDIR/Dimerbox.tcl -args $structure $extension $dimx $dimy $dimz ${OUTPUT} ${outname} 1&>/dev/null

  # TCL ROUTINE: PARSING DX FILE DATA AND READING ELECTROSTATIC POTENTIAL INTO A TABLE
  ${TCL} $ELFINDIR/Pot_Parser.tcl $filename $i $j $k $origx $origy $origz $deltax $deltay $deltaz $coordsource $dimx $dimy $dimz $spacing $protein ${outname} $patchmethod 
  echo -e "  \nTable containing potentials sould be in ${OUTPUT}data\n"

elif [ $coordsource == 5 ]
then 

  # GETTING CARBON ALPHA COORDINATES FOR A CERTAIN RESIDUE
  if [ "${refres4}" == "" ]
  then
    echo -n "Residues you'll use as reference:"
    echo "Residue 1:"
    read refres1
    echo "Residue 2:"
    read refres2
    echo "Residue 3:"
    read refres3
    echo "Residue 4:"
    read refres4
  fi
  if [ "${patchmethod}" == "" ]
  then
    echo "What are you up to?:"
    echo -e "1 - Line (1D)\n2 - Slice (2D)\n3 - Cube / Other prism (3D)"
    echo -n "Insert 1, 2 or 3: "
    read patchmethod
  fi
  if [ "${dimx}" == "" ] 
  then
    echo "Desired patch dimensions in angstoms: "
    echo -n "X:"
    read dimx
    if [ "${patchmethod}" -eq 1 ]
    then
      dimy=0
      dimz=0
    fi
  fi
  if [ "${dimy}" == "" ]
  then
    echo -n "Y:"
    read dimy
    if [ "${patchmethod}" -eq 2 ]
    then
      dimy=0
      dimz=0
    fi
  fi
  if [ "${dimz}" == "" ]
  then
    echo -n "Z:"
    read dimz
  fi
  if [ "${spacing}" == "" ]
  then
    echo -n "Insert spacing for patch building: "
    read spacing
  fi
  outname=${protein}${chain}$sep${refres1}$sep${refres2}$sep${refres3}$sep${refres4}$sep${dimx}$sep${dimy}$sep${dimz}$sep${spacing}
  outname2=${outname}_Rcontourn
  outname3=${outname}_PYcontourn

  # PYTHON ROUTINE: OBTAINING COORDINATES OF REFERENCE RESIDUE
  ${PYTHON} $ELFINDIR/PDBpatch.py $coordsource $structure $extension $chain $refres1 $refres2 $refres3 $refres4

  # TCL ROUTINE: PARSING DX FILE DATA AND READING ELECTROSTATIC POTENTIAL INTO A TABLE
  ${TCL} $ELFINDIR/Pot_Parser.tcl $filename $i $j $k $origx $origy $origz $deltax $deltay $deltaz $coordsource $dimx $dimy $dimz $spacing $protein ${outname} $patchmethod 
  echo -e "  \nTable containing potentials should be in ${OUTPUT}data\n"

else

  echo "Error while generating coordinates, please start over..."

fi

#CREATING OUTPUT FOLDERS
for d in Output/Contourns_R Output/Contourns_PY Output/VMD_states Output/data Output/data_merged; do
  if [ -d  "${d}" ]
  then
    continue
  else
    mkdir ${d}
  fi
done
# PLOTTING THE RESULTS I (R ROUTINE)
if [ "$dimx" == "$dimy" ] && [ "$dimx" == "$dimz" ]
then
  if [ "$coordsource" -eq 3 ]
  then
    echo -e "\nCREATING HEATMAPS OF ELECTROSTATIC POTENTIAL..."
    for a in ${surfs[@]};do
      outname1=${outname}$sep${a}
      outname2=${outname1}_Rcontourn
      ${RSCRIPT} $ELFINDIR/Plottermap.r $outname1 $protein $OUTPUT $outname2 #2>/dev/null
    done
  else
    echo -e "\nCREATING HEATMAP OF ELECTROSTATIC POTENTIAL..."
    ${RSCRIPT} $ELFINDIR/Plottermap.r ${outname} $protein $OUTPUT ${outname2} #2>/dev/null
  fi
else
  echo -e "\nYOUR BOX IS NOT SYMMETRIC, NO R CONTOURN PLOT WILL BE YIELDED"
  ${RSCRIPT} $ELFINDIR/Plottermap.r $outname $protein $OUTPUT #2>/dev/null
fi


# PLOTTING THE RESULTS II (PYTHON ROUTINE)
echo -e "\nCREATING ELECTROSTATIC POTENTIAL CONTOURNS..."
if [ "$coordsource" -eq 3 ]
then
  for a in ${surfs[@]};do
    outname1=${outname}$sep${a}
    outname3=${outname1}_PYcontourn
    ${PYTHON} $ELFINDIR/Contourn.py $outname1 ${OUTPUT} ${outname3} #2>/dev/null
  done
  outname4=${outname}_PYcontourns_ALL
  ${PYTHON} $ELFINDIR/Surfaces.py $outname ${OUTPUT} ${outname4} #2>/dev/null
else
  ${PYTHON} $ELFINDIR/Contourn.py $outname ${OUTPUT} ${outname3} #2>/dev/null
fi

if [ "$dimx" == "$dimy" ] && [ "$dimx" == "$dimz" ]
then
  if [ $coordsource == 3 ]
  then
    echo -e "  \nDone. Your images should be at ${OUTPUT}Contourns folders"
    for a in ${surfs[@]};do
      outname2=${outname}$sep${a}_Rcontourn
      echo -e "   ${OUTPUT}$outname2.png"  
    done
    echo -e "  ${OUTPUT}$outname3.png\n" 
  else
    echo -e "  \nDone. Your PDF images are at:\n  ${OUTPUT}Contourns folders"  
  fi
else
  echo -e "  \nDone. Your PDF image is at:\n  at ${OUTPUT}Contourns folders\n"
fi

if [ "${displayplot}" == "" ]
then
  echo -n "Would you like to visualize your HEATMAP & CONTOURN plots? "
  read displayplot
fi

# OPENING UP PDF IMAGE OF RESULTS
if [[ "$displayplot" =~ yes|YES|y|1 ]]
then
  echo "YOU REQUIRED VISUALIZATION OF YOUR RESULTS"
  echo "OPENING IMAGES..."
  if [ $coordsource == 3 ]
  then
    for a in ${surfs[@]};do
      outname1=${outname}$sep${a}
      outname3=${outname1}_PYcontourn
      ${ACROREAD} ${OUTPUT}$outname3.png &
    done
    ${ACROREAD} ${OUTPUT}$outname4.png &
    ${VIEWER} ${OUTPUT}$outname4.png &
  else
    ${ACROREAD} ${OUTPUT}$outname.png &
    ${VIEWER} ${OUTPUT}$outname.png &
  fi
elif [[ "$displayplot" =~ no|NO|n|0 ]]
then
  echo -e "NO PDF VISUALIZATION REQUIRED"
else
  echo -e "SORRY, I DID NOT GET YOUR PDF VISUALIZATION REQUIREMENTS SO I AM RESUMING UP...\n"
fi

if [ "${displayvmd}" == "" ] && [ "${patchmethod}" -eq 3 ]
then
  echo -n "Would you like to visualize your cube/prims in VMD? "
  read displayvmd
fi

# IF CUBE METHOD PREVIOUSLY SELECTED, OPENING A CUBE IN VMD AND/OR SAVING VMD STATE
if [ "$patchmethod" == 3 ] && [[ "$displayvmd" =~ yes|YES|y|1 ]]
then
  if [ $coordsource == 3 ]
  then
    ${VMD} -e ${OUTPUT}${outname}.vmd 1&>/dev/null
  else
    echo "YOU REQUIRED VISUALIZATION OF YOUR CUBE/PRISMS"
    echo "OPENING VMD..."
    echo -e "WHEN DONE, PLEASE CLOSE VMD FOR RESUMING PROGRAM\n"
    if [ $coordsource == 4 ] 
    then
      ${VMD} -e $ELFINDIR/Draw_cube_DIMER.tcl -args $structure $extension $chain $refres $dimx $dimy $dimz ${OUTPUT} ${outname} ${displayvmd} >/dev/null
    elif [ $coordsource == 5 ]
    then
      ${VMD} -dispdev text -e $ELFINDIR/Draw_cube.tcl -args $structure $extension $chain $dimx $dimy $dimz ${OUTPUT} ${outname} ${displayvmd} 2 $refres1 $refres2 $refres3 $refres4   >/dev/null
        
    else
      ${VMD} -e $ELFINDIR/Draw_cube.tcl -args $structure $extension $chain $dimx $dimy $dimz ${OUTPUT} ${outname} ${displayvmd} 1 $refres >/dev/null
    fi
  fi
elif [ "$patchmethod" == 3 ] && [[ "$displayvmd" =~ no|NO|n|0 ]]
then
  echo -e "NO VMD VISUALIZATION REQUIRED. SAVING VMD STATE..."
  if [ "$coordsource" -ne 3 ]
  then
    if [ $coordsource == 4 ] 
    then
      ${VMD} -dispdev text -e $ELFINDIR/Draw_cube_DIMER.tcl -args $structure $extension $chain $refres $dimx $dimy $dimz ${OUTPUT} ${outname} ${displayvmd} >/dev/null
    elif [ $coordsource == 5 ]
    then
      ${VMD} -dispdev text -e $ELFINDIR/Draw_cube.tcl -args $structure $extension $chain $dimx $dimy $dimz ${OUTPUT} ${outname} ${displayvmd} 2 $refres1 $refres2 $refres3 $refres4   >/dev/null
    else
      ${VMD} -dispdev text -e $ELFINDIR/Draw_cube.tcl -args $structure $extension $chain $dimx $dimy $dimz ${OUTPUT} ${outname} ${displayvmd} 1 $refres >/dev/null
    fi
  fi
else
  echo -e "SORRY, I DID NOT GET YOUR VMD VISUALIZATION REQUIREMENTS SO I AM RESUMING UP...\n"
fi

#MOVING OUTPUT FILES TO THEIR RESPECTIVE FOLDERS
mv ${OUTPUT}$outname.png ${OUTPUT}Contourns_R
mv ${OUTPUT}$outname2.png ${OUTPUT}Contourns_R
mv ${OUTPUT}$outname3.png ${OUTPUT}Contourns_PY
mv ${OUTPUT}$outname.vmd ${OUTPUT}VMD_states
mv ${OUTPUT}$outname.txt ${OUTPUT}data_merged
mv ${OUTPUT}$outname·4D.txt ${OUTPUT}data

#CLEANING UP INTERMEDIATE FILES
for f in resid.coor box.coor dimer.coor CA.coor Atom_names.txt surf_centers.coor; do
  if [ -f ${f} ] 
  then
    rm ${f}
  fi
done
echo -e "##################################"
echo -e "THAT'S IT, THANKS FOR USING ELFIN${version}!\n"


