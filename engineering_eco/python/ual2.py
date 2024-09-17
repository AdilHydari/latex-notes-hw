import numpy_financial as npf 

II = -21000
UL = 3
SV = 6000
OCPM = 0.36
MARR = 0.05
MPY = 6000
TP = 12

AC = OCPM * MPY 

CF = [II] + [-AC] * UL + [SV] 

PW = npf.npv(MARR, CF)

PW_CYCLE = [PW / ((1+MARR) ** (UL * cycle)) for cycle in range (4)]

PW_T = sum(PW_CYCLE)

print(PW_T)
