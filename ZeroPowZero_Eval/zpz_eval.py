import numpy as np
import matplotlib.pyplot as plt

# Define the range and number of points
num_points = int(1e5)
x = np.linspace(0, 1, num_points)

# Calculate y = x^x
y = x**x

# Plotting
plt.plot(x, y)
plt.xlabel('x')
plt.ylabel('y')
plt.title(r'Plot of $y = x^x$')
plt.grid(True)
plt.show()
