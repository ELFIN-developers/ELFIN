#################
### ELFIN  #####
#################
###############################
### printcontourn function ####
###############################
#!/usr/bin/python
# -*- coding: utf-8 -*-


import matplotlib.colors as matcol
from matplotlib.mlab import griddata
import matplotlib.pyplot as plt
import numpy as np
import sys

def printcontourn (name,outdir,outname):
    '''
    FUNCTION FOR PRINTING A CONTOURN OUT OF A FILE CONTAINING 
    X, Y AND POTENTIAL COLUMNS
    '''
    x = np.loadtxt(outdir+name+".txt", usecols=[0], skiprows=1)
    y = np.loadtxt(outdir+name+".txt", usecols=[1], skiprows=1)
    z = np.loadtxt(outdir+name+".txt", usecols=[2], skiprows=1)

    dimx=int(x[:1])
    dimy=int(y[:1])
    
    uniques=len(np.unique(x))-1
    xi = np.linspace(dimx,-dimx,uniques)
    yi = np.linspace(dimy,-dimy,uniques*2)
    zi = griddata(x,y,z,xi,yi,interp='nn')
    
    #limits=[]
    #limits.append(int(min(z)))
    #limits.append(int(max(z)))

    fig=plt.figure()
    #normal=matcol.Normalize(vmin=min(limits),vmax=max(limits))
    normal=matcol.Normalize(vmin=-10,vmax=10)
    cmap=plt.cm.RdBu
    CS1 = plt.contour(xi,yi,zi,20,linewidths=0.5,colors='k')
    CS2 = plt.contourf(xi,yi,zi,20,cmap=cmap,norm=normal)
    cb=plt.colorbar(drawedges='TRUE') 
    #plt.scatter(x,y,marker='o',c='b',s=0.1,zorder=10)
    plt.xlim(dimx,-dimx)
    plt.ylim(dimy,-dimy)
    plt.title(name)
    plt.savefig(outdir+outname+".png")

inname= str(sys.argv[1])
outdir=str(sys.argv[2])
outname=str(sys.argv[3])
printcontourn(inname,outdir,outname)
