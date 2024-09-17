import numpy_financial as npf 

marr = 0.15

CashFlow_A = [-100000] + [34000] *5 + [38000]
CashFlow_B = [-125000] + [41000] *5 + [46000]

PW_A = npf.npv(marr, CashFlow_A) 
PW_B = npf.npv(marr, CashFlow_B) 

print("A is", PW_A)
print("B is", PW_B)
