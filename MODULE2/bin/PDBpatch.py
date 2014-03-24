# -*- coding: utf-8 -*-
#################
### ELFIN  #####
#################
########################
### PDBPatch class #####
########################
#!/usr/bin/python
# -*- coding: utf-8 -*-

from Bio.PDB import *
import warnings
import numpy as np
import sys


class PDBPatch():

    '''
    Parse PDB and extract certain coordinates dictated by user along with their respective atom names.
    '''
    def __init__(self,chain,coordmethod,res1,answ,atomname,dimx,dimy,dimz,spacing,res2,res3,res4):
      
      self.chain=chain
      self.coordmethod=coordmethod
      self.answ=answ
      self.res1=res1
      self.res2=res2
      self.res3=res3
      self.res4=res4
      self.atomname=atomname
      self.dimx=dimx
      self.dimy=dimy
      self.dimz=dimz
      self.spacing=spacing

      if coordmethod == 1:

	res = self.res(res1)
	self.print_coord_3Dpatch(res,chain,atomname,dimx,dimy,dimz,spacing)

      elif coordmethod == 2:

	seq = self.res_seq(answ,res1,res2,res3,res4)
	self.print_coord_res(seq,chain)
	
      elif coordmethod == 5:

	res = self.res(res1)
	self.print_coord_3Dpatch(res,chain,atomname,dimx,dimy,dimz,spacing)
	
      else:

	print 'Wrong option, insert 1, 2 or 5 next time...;)'
	exit()

    def res(self,res1):

      '''
      USERS INPUT FOR CATCHING RESIDUE ID FOR PATCH BUILDING
      '''
      
      res2 = res1
      seq = range(res1, res2+1)
      return seq

    def res_seq(self,answ,res1,res2,res3,res4):

	'''
	USERS INPUT FOR CATCHING SEQUENCE OF RESIDUES. IT RETURNS SUCH SEQUENCE.
	'''

	if answ == 1:

	  seq = range(res1, res2+1)

	elif answ == 2:

	  seq = range(res1, res2+1) + range(res3, res4+1)

	else:

	  print 'Wrong option, please start over and next time insert whether you\'ll process 1 or 2 patches...;)'
	  exit()

	return seq

    def print_coord_3Dpatch(self,seq,chain,atomname,dimx,dimy,dimz,spacing):

	'''
	CREATES COORDS AND ATOM FILE CONTAINING ATOM COORDINATES OF THE 3D PATCH CREATED BY THE USER
	'''	
	f = open('resid.coor','wr')
	f1 = open('Atom_names.txt','wr')
	residue = chain[(' ', seq[0], ' ')]	  
	for atom in residue:
	  if atom.name == atomname:
	    for c in np.arange(-dimx,dimx+spacing,spacing):
	      for a in np.arange(-dimy,dimy+spacing,spacing):
		for b in np.arange(-dimz,dimz+spacing,spacing):
		  print >>f, round(atom.coord[0]+a, 3), round(atom.coord[1]+b, 3), round(atom.coord[2]+c,3)
		  print >>f1, atom.name+str(seq[0])+" "+str(round(a, 1))+" "+str(round(b, 1))+" "+str(round(c, 1))

	f.close()
	f1.close()

    def print_coord_res(self,seq,chain):

	'''
	CREATES COORDS AND ATOM FILE CONTAINING ATOM COORDINATES OF THE RESIDUE SEQUENCE INSERTED BY THE USER
	'''

	f = open('resid.coor','wr')
	f1 = open('Atom_names.txt','wr')
	i = 0
	for residue in seq:
	  residue = chain[(' ', seq[i], ' ')]
	  for atom in residue:
	    print >>f, round(atom.coord[0], 3), round(atom.coord[1], 3), round(atom.coord[2],3)
	    print >>f1, atom.name
	  i += 1
	f.close()
	f1.close()


def load_structure(pdbpqr,chainID):
    '''
    LOADS UP STRUCTURE. APBS'S PQR FILE CONTAINS NON-VALID B-FACTOR & OCCUPANCY COLUMNS.
    THEREFORE WE IGNORE WARNINGS UPON LOADING UP STRUCTURE
    '''
    parser = PDBParser()
    warnings.filterwarnings('ignore')
    structure = parser.get_structure('protein', pdbpqr)
    warnings.filterwarnings('always')
    header = parser.get_header()
    trailer = parser.get_trailer()
    model = structure[0]
    chain = model[chainID]
    return chain

def alphacoords(chain, residue):
    '''
    GET ALPHA CARBON COORDINATES FROM A CERTAIN RESIDUE
    '''
    
    for atom in residue:
      if atom.name == 'CA':
	return (round(atom.coord[0], 3), round(atom.coord[1], 3), round(atom.coord[2],3))
    


option = int(sys.argv[1])
pdbpqr = str(sys.argv[2])
extension = str(sys.argv[3])

if extension == 'pdb':
  chainID = str(sys.argv[4])
elif extension == 'pqr':
  chainID = str(' ')
else:
  print 'Structure file need to be either .pdb or .pqr. I won\'t assign any chain ID'
  chainID = str(' ')

chain=load_structure(pdbpqr,chainID)

if option == 1 or option == 5:
    coords = (0., 0., 0.)
    if option == 1:
	reslastindex = 5
    elif option == 5:
	reslastindex = len(sys.argv) - 1
    for i in range(5, reslastindex + 1):
      residue = chain[(' ', int(sys.argv[i]) , ' ')]
      coords = tuple([sum(x) for x in zip(*[alphacoords(chain, residue), coords])])
      
    resnum = float(reslastindex - 4)
    coords = tuple([x/resnum for x in coords])
    f = open('CA.coor','wr')
    print >>f, round(coords[0], 3), round(coords[1], 3), round(coords[2], 3)
    f.close()

elif option == 2:

    PDBPatch(chain, int(sys.argv[5]), int(sys.argv[6]), int(sys.argv[7]), str(sys.argv[8]), float(sys.argv[9]), float(sys.argv[10]), float(sys.argv[11]), float(sys.argv[12]), int(sys.argv[13]), int(sys.argv[14]), int(sys.argv[15]))

else:

          print 'Wrong option, insert 1, 2 or 5 next time...;)'
          exit()




