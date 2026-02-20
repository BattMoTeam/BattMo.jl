
using GLMakie

# ---------------------------------------------------------
# PARAMETERS
# ---------------------------------------------------------

h = 1e20          # Very large convection coefficient (external heat transfer coefficient) → fixed temperature at x = 0
alpha = 12            # Thermal conductivity
Text = 298           # Boundary temperature at x = 0 (K)
source = 1e4          # Volumetric heat generation term

# ---------------------------------------------------------
# SOLVE FOR CONSTANTS A AND B IN THE ANALYTIC SOLUTION
#
# Temperature form:
#   T(x) = -q/(2α) * x^2 - (A/α)*x + B
#
# Boundary conditions encoded in matrix system M * [A; B] = b
# ---------------------------------------------------------

M = [
	1              h;
	(1 + h/alpha)  -h
]

b = [
	h * Text;
	-source + h * (-source/(2*alpha) - Text)
]

coeffs = M \ b
A, B = coeffs

# ---------------------------------------------------------
# TEMPERATURE FUNCTION
# ---------------------------------------------------------

temp(x) = -source/(2*alpha) * x^2 - (A/alpha) * x + B

# ---------------------------------------------------------
# EVALUATE TEMPERATURE FIELD
# ---------------------------------------------------------

xs = 0:0.01:1
ys = temp.(xs)

# ---------------------------------------------------------
# PLOT TEMPERATURE PROFILE
# ---------------------------------------------------------

fig = Figure(size = (1000, 400))

ax = Axis(fig[1, 1],
	xlabel = "Position x",
	ylabel = "Temperature T(x)",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)

scatterlines!(
	ax,
	xs,
	ys;
	linewidth = 4,
	markersize = 10,
	marker = :cross,
	markercolor = :green,
)

display(GLMakie.Screen(), fig)
