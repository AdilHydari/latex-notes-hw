import numpy as np
import matplotlib.pyplot as plt

# Constants
MARR = 0.1
useful_life = 10
fuel_cost_per_gallon = 6.00
miles_per_gallon = 7
annual_mileage = np.linspace(0, 50000, 500)

# Deflector Costs
costs = {
    "Blow-on-by": {"investment": 2500, "maintenance": 100, "fuel_savings": 0.0343},
    "Wind-shear": {"investment": 7500, "maintenance": 180, "fuel_savings": 0.0686},
    "Air-vantage": {"investment": 15000, "maintenance": 230, "fuel_savings": 0.1029}
}

# Function to calculate equivalent annual cost
def annual_cost(investment, maintenance, fuel_savings, mileage):
    eac = investment * (MARR * (1 + MARR) ** useful_life) / ((1 + MARR) ** useful_life - 1)
    fuel_cost_per_mile = fuel_cost_per_gallon / miles_per_gallon
    total_fuel_cost = (fuel_cost_per_mile - fuel_savings) * mileage
    total_annual_cost = eac + maintenance + total_fuel_cost
    return total_annual_cost

# Calculate total annual cost for each deflector type
cost_blow_on_by = annual_cost(**costs["Blow-on-by"], mileage=annual_mileage)
cost_wind_shear = annual_cost(**costs["Wind-shear"], mileage=annual_mileage)
cost_air_vantage = annual_cost(**costs["Air-vantage"], mileage=annual_mileage)

# Plotting
plt.figure(figsize=(10, 6))
plt.plot(annual_mileage, cost_blow_on_by, label="Blow-on-by")
plt.plot(annual_mileage, cost_wind_shear, label="Wind-shear")
plt.plot(annual_mileage, cost_air_vantage, label="Air-vantage")

# Add labels and legend
plt.title('Annual Cost vs Mileage for Different Wind Deflectors')
plt.xlabel('Annual Mileage')
plt.ylabel('Annual Cost ($)')
plt.legend()
plt.grid(True)
# Show plot
plt.show()

