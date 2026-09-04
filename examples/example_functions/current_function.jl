##################################################################################
# An example of a user defined current function using WLTP data from

using DelimitedFiles: readdlm
using Jutul: get_1d_interpolator

path = joinpath(@__DIR__, "../example_data/wltp.csv")
data, _ = readdlm(path, ',', Float64; header = true)

t = data[:, 1]
P = data[:, 2]

power_func = get_1d_interpolator(t, P, cap_endpoints = false)


function current_function(time, voltage)

    factor = 4000 # Tot account for the fact that we're simulating a single cell instead of a battery pack

    return power_func(time) / voltage / factor
end
