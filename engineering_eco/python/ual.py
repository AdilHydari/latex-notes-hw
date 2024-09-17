import numpy_financial as npf 
import numpy as np

MARR = 0.05
II = 27000
UL = 4
SV = 9000
OCPM = 0.42
MPY = 6000

operatingCost = OCPM * MPY 

PV = (1+MARR) ** (-UL)

CR = MARR * ((1+MARR) ** (UL)) / (((1+MARR) ** UL)-1)

AW = (II - SV * PV) * CR + operatingCost 

print(AW)

