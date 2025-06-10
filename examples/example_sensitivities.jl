using BattMo, Jutul
using CSV
using DataFrames
using GLMakie
using MAT

datacase = "Xu"
# datacase = "MJ1"

ratecase = "low"
# ratecase = "high"

goalfunction = "least-squares"
goalfunction = "energy-density"

function get_tV(x)
    t = [state[:Control][:Controller].time for state in x[:states]]
    V = [state[:Control][:Phi][1] for state in x[:states]]
    return (t, V)
end

function get_tV(x::DataFrame)
    return (x[:, 1], x[:, 2])
end

function get_tV(x::Tuple{Matrix{Any}, Matrix{Any}})
    return (x[1][1], x[2][1])
end

if datacase == "Xu"
    # Load the experimental data and set up a base case
    battmo_base = normpath(joinpath(pathof(BattMo) |> splitdir |> first, ".."))
    exdata = joinpath(battmo_base, "examples", "example_data")
    df_low = CSV.read(joinpath(exdata, "Xu_2015_voltageCurve_05C.csv"), DataFrame) # 0.5
    # df_1 = CSV.read(joinpath(exdata, "Xu_2015_voltageCurve_1C.csv"), DataFrame) # 1
    df_high = CSV.read(joinpath(exdata, "Xu_2015_voltageCurve_2C.csv"), DataFrame) # 2

    cell_parameters = load_cell_parameters(; from_default_set = "Xu2015")

    if ratecase == "low"
        rate = 0.5;
        df = df_low
    elseif ratecase == "high"
        rate = 2.0
        df = df_high
    else
        error()
    end

elseif datacase == "MJ1"

    fn = "/home/august/Projects/Battery/2025-DigiBatt-IntelLiGent-Symposium-Oslo/src/mj1-jl.json"
    cell_parameters = load_cell_parameters(; from_file_path=fn)

    matfile = "/home/august/Projects/Battery/2025 Battmo - Calibration and optimization-overleaf/scripts/data/MJ1-DLR/dlroutput.mat"
    matdata = MAT.matread(matfile)
    matdata = matdata["dlroutput"]

    if ratecase == "low"
        # NB order
        idx = 4
    elseif ratecase == "high"
        idx = 3
    else
        error()
    end

    df = DataFrame(time=vec(matdata["time"][idx]), E=vec(matdata["voltage"][idx]), I=vec(matdata["current"][idx]), CRate=matdata["CRate"][idx])
    rate = df.CRate[1] / 4

elseif datacase == "Chen"

    cell_parameters = load_cell_parameters(; from_default_set="Chen2020")

else
    error()
end

cycling_protocol = load_cycling_protocol(; from_default_set = "CCDischarge")
simulation_settings = load_simulation_settings(; from_default_set = "P2D")

t_refinement = 1 #10
x_refinement = 1 #10

simulation_settings["TimeStepDuration"] /= t_refinement

simulation_settings["TimeStepDuration"] *= 40

gr = "GridResolution"
simulation_settings[gr]["NegativeElectrodeActiveMaterial"] *= x_refinement
simulation_settings[gr]["NegativeElectrodeCoating"] *= x_refinement
simulation_settings[gr]["PositiveElectrodeActiveMaterial"] *= x_refinement
simulation_settings[gr]["PositiveElectrodeCoating"] *= x_refinement
simulation_settings[gr]["Separator"] *= x_refinement

if datacase == "MJ1"
    cycling_protocol["LowerVoltageLimit"] = 2.5
elseif datacase == "Xu"
    cycling_protocol["LowerVoltageLimit"] = 2.25
else
    error("Unknown data case: $datacase")
end
model_setup = LithiumIonBattery()

cycling_protocol["DRate"] = rate

sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)

output0 = solve(sim, accept_invalid=true)

t0, V0 = get_tV(output0)
t_exp, V_exp = get_tV(df)

fig = Figure()
ax = Axis(fig[1, 1], title = "CRate = 0.5", xlabel = "Time / s", ylabel = "Voltage / V")
lines!(ax, t0/3600, V0, label = "Base case")
lines!(ax, t_exp, V_exp, label = "Experimental data")
axislegend(position = :lb)
fig

voltage_calibration = VoltageCalibration(t_exp, V_exp, sim)

if goalfunction == "least-squares"
    nothing
elseif goalfunction == "energy-density"
    nothing
else
    error("Unknown goal function: $goalfunction")
end

# Loop over all cell parameters and add them as a free_calibration_parameter
function flatten_dict(d::Dict, prefix=[])
    flat = Dict{Vector{String}, Any}()
    for (k, v) in d
        new_prefix = [prefix...; k]
        if v isa Dict
            flat_nested = flatten_dict(v, new_prefix)
            merge!(flat, flat_nested)
        else
            flat[new_prefix] = v
        end
    end
    return flat
end

flat_cell_params = flatten_dict(cell_parameters.all)

params = Dict{Vector{String}, Float64}()
bounds = Dict{Vector{String}, Tuple{Float64, Float64}}()

for (k, v) in flat_cell_params
    if v isa Number && v > 1e-20 && cmp(k[1], "Cell") != 0
        params[k] = v

        # Set default bounds for numerical parameters
        vmin = v * 0.1
        vmax = v * 10.0

        if vmin < 0.0
            vmin = 0.0
        end

        if vmax <= vmin
            vmax = vmin + 1.0
        end

        bounds[k] = (vmin, vmax)

        # println(k, " ", v, " ", bounds[k][1], " ", bounds[k][2])

    end
end

for k in sort(collect(keys(params)))
    #println(k, " ", params[k], " ", bounds[k][1], " ", bounds[k][2])
    free_calibration_parameter!(voltage_calibration, k; lower_bound = bounds[k][1], upper_bound = bounds[k][2])
end

# print_calibration_overview(voltage_calibration)

names0, x00, gsc0, g0, f0 = solve(voltage_calibration)

function print_sorted(names0, x0, str; N=30)

    idx = sortperm(x0, rev=true)
    names = names0[idx]
    x = x0[idx]

    println("")
    println("Rate = ", cycling_protocol["DRate"])
    println(str)

    for i = 1:N

        # for name in names[i]
        #     print(name, " ")
        # end

        if names[i][1] == "NegativeElectrode"
            print("NE ")
        elseif names[i][1] == "PositiveElectrode"
            print("PE ")
        elseif names[i][1] == "Electrolyte"
            print("Elyte ")
        elseif names[i][1] == "Separator"
            print("Sep ")
        else
            print(names[i][1], " ")
        end

        print(names[i][end], " ");
        println(x[i])
    end

end


# Print special sorting
print_sorted(names0, abs.(g0), "abs dJ/dp")
print_sorted(names0, abs.(g0 .* x00), "abs dJ/dp*p")
print_sorted(names0, abs.(g0 .* x00 / f0), "abs dJ/dp*p/J")
