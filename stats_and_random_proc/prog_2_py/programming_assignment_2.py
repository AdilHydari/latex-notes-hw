import numpy as np
import matplotlib.pyplot as plt
from scipy.integrate import dblquad

fig, ax = plt.subplots()
x = np.linspace(0, 1, 100)
y = x.copy()
ax.fill_between(x, 0, y, alpha=0.5, color='blue')
ax.set_xlim(0, 1)
ax.set_ylim(0, 1)
ax.set_title("Region where $f_{XY}(x, y) > 0$")
ax.set_xlabel("$x$")
ax.set_ylabel("$y$")
plt.savefig('plot_a.png')

# Part (b): Deriving the constant c

# Define the joint PDF as a function
def joint_pdf(x, y, c):
    return c * x * y if 0 <= y <= x <= 1 else 0

# Integral calculation over the triangular region
# Here we use lambda functions to define the limits for y and x
integral_result, error = dblquad(lambda y, x: x*y, 0, 1, lambda x: 0, lambda x: x)
# Solve for c by setting the integral equal to 1
c = 1 / integral_result
print("c=",c,"integral=",integral_result)
# Part (c): Deriving the joint CDF FXY(x, y)

def joint_cdf(x, y, c):
    if x < 0 or y < 0:
        return 0
    elif x >= 1 and y >= 1:
        return 1
    elif x >= 1:
        # Integrate over y to min(x, 1) since x >= 1
        integral, _ = dblquad(lambda u, v: c*u*v, 0, y, lambda u: 0, lambda u: u)
        return integral
    elif y >= 1:
        return 1
    else:
        integral, _ = dblquad(lambda u, v: c*u*v, 0, x, lambda u: 0, lambda u: min(u, y))
        return integral

# Let's prepare to plot the CDF by calculating it over a grid
x_vals = np.linspace(0, 1, 50)
y_vals = np.linspace(0, 1, 50)
X, Y = np.meshgrid(x_vals, y_vals)
Z = np.zeros_like(X)

for i in range(len(x_vals)):
    for j in range(len(y_vals)):
        Z[j, i] = joint_cdf(x_vals[i], y_vals[j], c)

# Part (d): Plotting the joint CDF FXY(x, y)
fig = plt.figure()
ax = fig.add_subplot(111, projection='3d')
ax.plot_surface(X, Y, Z, cmap='viridis')
ax.set_title("Joint CDF $F_{XY}(x, y)$")
ax.set_xlabel("$x$")
ax.set_ylabel("$y$")
ax.set_zlabel("$F_{XY}(x, y)$")
plt.savefig('plot_d.png')


