##################################################################################
# An example of a user defined current function using WLTP data from 

using CSV
using DataFrames
using Jutul

path = joinpath(@__DIR__, "../example_data/wltp.csv")
df = CSV.read(path, DataFrame)

t = df[:, 1]
P = df[:, 2]

power_func = get_1d_interpolator(t, P, cap_endpoints = false)



function current_function(time, voltage)

	factor = 4000 # Tot account for the fact that we're simulating a single cell instead of a battery pack

	return power_func(time) / voltage / factor
end


