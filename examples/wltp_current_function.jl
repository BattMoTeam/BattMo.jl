using CSV
using DataFrames
using Jutul

df = CSV.read("example_data/wltp.csv", DataFrame)

t = df[:, 1]
P = df[:, 2]

power_func = get_1d_interpolator(t, P, cap_endpoints = false)



function wltp_current_function(time, phi)

	factor = 4000 # Tot account for the fact that we're simulating a single cell instead of a battery pack

	return power_func(time) / phi / factor
end

P = []
for i in t
	push!(P, power_func(i))
end

f = Figure(size = (1000, 400))

ax = Axis(f[1, 1], title = "Power", xlabel = "Time / s", ylabel = "Voltage / V",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)
scatterlines!(ax, t, P; linewidth = 4, markersize = 10, marker = :cross, markercolor = :black)

f
