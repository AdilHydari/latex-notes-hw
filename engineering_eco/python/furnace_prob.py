import numpy_financial as npf

hot_cash_flow = [-148000] + [-45033]*10 
fire_cash_flow = [-110000] + [-53800]*10 
marr = 0.15

hot_res_pw = npf.npv(marr, hot_cash_flow)

fire_res_pw = npf.npv(marr, fire_cash_flow)

print(fire_res_pw)
print(hot_res_pw)

investment_diff = -148000 + 110000
expense_diff = 538000 - 450033

cash_flow = [investment_diff] + [expense_diff]*10

irr = npf.irr(cash_flow) 
irr_per = irr*100 
print(irr)
