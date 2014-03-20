dxfiles=(B1.dx B2.dx AD.dx D3.dx CHA.dx RHO.dx)
#residues=(138 130 99 127 133 134)
ELFIN=~/ELFINv01/bin/ELFIN.sh

#i=0
for a in ${dxfiles[@]}; do 
  #b=`eval echo ${residues[$i]}`
  b=`echo $a | cut -d . -f1`.pqr 
  bash $ELFIN ${a} ${b} 10 3 5 10 15 0.5 3 0 0
  #let i+=1
done

