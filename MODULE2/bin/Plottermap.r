# DX POTENTIAL PARSER #
# R HEATMAP PLOTTING ROUTINE #

args <- commandArgs(trailingOnly = TRUE)
nametxt=paste(args[1],".txt",sep = "")
prot="args[2]"
setwd(args[3])
require(ggplot2)
prot <- read.table(nametxt, header=TRUE)

namepng1=paste(args[1],".png",sep = "")
p <- ggplot(prot, aes(X, Y, fill=POTENTIAL)) + 
  geom_tile() +
  scale_fill_gradient2(low="red", mid= "grey", high="blue", name='Potential')
ggsave(p, file=namepng1, width=8, height=6, title=namepng1)

if (length(args)==4) {
  namepng2=paste(args[4],".png",sep = "")
  v <- ggplot(prot, aes(X, Y, z = POTENTIAL)) 
  q <- v + stat_contour(geom="polygon", aes(fill=..level..)) + 
    scale_fill_gradient2(low="red", mid="grey", high="blue", name='Potential')
  ggsave(q, file=namepng2, width=8, height=6, title=namepng2)
}