dxfiles=(B1.dx B2.dx AD.dx D3.dx CH.dx RHO.dx)
residues=(138 130 99 127 133 134)

ELFIN=~/ELFINv01/bin/ELFIN.sh


i=0
for a in ${dxfiles[@]}; do 
  b=`eval echo ${residues[$i]}`
  bash $ELFIN ${a} 1 ${b} 10 10 10 0.3 3 0
  let i+=1
done

