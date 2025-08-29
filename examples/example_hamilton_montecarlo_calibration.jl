# # Load packages
using BattMo
using Statistics
using Jutul
using CSV
using MAT
using GLMakie

battmo_base = normpath(joinpath(pathof(BattMo) |> splitdir |> first, ".."))
datadir = joinpath(battmo_base, "examples", "example_data", "calibration_data_mj1")
nothing #hide

# # Experimental data setup
#
# We retrieve experimental data. It is given in matlab format

""" Fetches experimental data from a .mat file. Returns a dictionary with time, rawRate, E, rawI, I, cap, and DRate.
"""
function getExpData(filename, rate = "all")

    ## Load data
    data = matread(filename)
    dlroutput = data["dlroutput"]  # Dict with 1×4 matrices for each variable

    @show keys(dlroutput)  # Show available keys in the data
    @show size(dlroutput["current"][1])  # Show size of the time matrix
    
    ## Get number of experiments (4 in this case)
    num_experiments = size(dlroutput["time"], 2)
    
    ## Process each experiment
    dlrdata = Vector{Dict{String,Any}}(undef, num_experiments)

    function trapz(x, y)
        sum((x[i+1] - x[i]) * (y[i] + y[i+1]) / 2 for i in 1:length(x)-1)
    end
    
    for k in 1:num_experiments
        ## Extract data for this experiment (column k from each matrix)
        time_h = dlroutput["time"][k]
        time_s = time_h * 3600  # hours → seconds
        
        current = dlroutput["current"][k]
        current_segment =  Float64.(current[3:end-1])  # Skip first/last points

        ## Create experiment dictionary
        dlrdata[k] = Dict{String,Any}(
            "time" => time_s,
            "rawRate" =>dlroutput["CRate"][k],
            "E" => dlroutput["voltage"][k],
            "rawI" => -current,
            "I" => abs(Statistics.mean(current_segment)),
            "cap" => abs(trapz(time_s[3:end-1], current_segment)),
            "DRate" => 1.0 / time_h[end]
        )
    end

    ## Sort by DRate
    sort!(dlrdata, by=x -> x["DRate"])

    ## Select data based on rate
    if rate == "low"
        return dlrdata[1]
    elseif rate == "high"
        return dlrdata[end]
    elseif rate == "all"
        return dlrdata
    else
        error("Unknown rate $rate")
    end
    
end

fn = joinpath(datadir, "dlroutput.mat")
exp_data = getExpData(fn)

println("Number of entries: ", length(exp_data))
@show exp_data[1]["rawRate"] 
@show exp_data[2]["rawRate"]
@show exp_data[3]["rawRate"]
@show exp_data[4]["rawRate"] # Show first entry for verification
nothing #hide

# # Simulation setup
# The function `runMJ1` sets up the simulation for the MJ1 cell by loading the cell parameters and cycling protocol from JSON files. It also configures the model and simulation settings.

""" setup the simulation for the MJ1 cell
"""
function runMJ1()

    cell_parameters = load_cell_parameters(; from_file_path = joinpath(datadir, "mj1_tab1.json"))
    
    ## cell_parameters = load_cell_parameters(; from_default_set = "Xu2015")
    println("successfully loaded cell parameters and cycling protocol")
    cycling_protocol = load_cycling_protocol(; from_file_path = joinpath(datadir, "custom_discharge2.json"))

    ## simulation_settings = load_simulation_settings(; from_file_path = joinpath(datadir,"simple.json"))
    ## simulation_settings = load_simulation_settings(; from_default_set = "P4D_pouch")
    simulation_settings = load_simulation_settings(; from_default_set = "P2D") # Ensure the model framework is set to P4D Pouch
    
    #model_settings = load_model_settings(;from_default_set = "P4D_pouch")
    model_settings = load_model_settings(;from_default_set = "P2D") 

    model_setup = LithiumIonBattery(; model_settings)

    sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings);
    print(sim.is_valid)
    ## output0 = solve(sim;accept_invalid = true)
    return cycling_protocol, cell_parameters, model_setup, simulation_settings

end

# # Equilibrium calibration

cycling_protocol, cell_parameters,model_setup, simulation_settings = runMJ1()

sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)

cell_parameters_calibrated, V_eq, t_eq = equilibriumCalibration(sim, exp_data)

# # Hamiltonian Monte-Carlo setup

t_exp_hr = vec(exp_data[end]["time"])
V_exp_hr = vec(exp_data[end]["E"])

I = exp_data[end]["I"]

cycling_protocol2          = deepcopy(cycling_protocol)
cycling_protocol2["DRate"] = exp_data[end]["rawRate"]

# # Setup simulation case
#

sim = Simulation(model_setup, cell_parameters_calibrated, cycling_protocol2; simulation_settings)

output = get_simulation_input(sim)

model2 = output[:model]

sim.cycling_protocol["DRate"] = I * 3600 / computeCellCapacity(model2)  

# # Setup calibration problem
#
# We prepare the `VoltageCalibration` instance
#

vc = BattMo.VoltageCalibration(t_exp_hr,
                               V_exp_hr,
                               sim)

free_calibration_parameter!(vc,
                            ["NegativeElectrode","ActiveMaterial", "VolumetricSurfaceArea"];
                            lower_bound = 1e3, upper_bound = 1e6)
free_calibration_parameter!(vc,
                            ["PositiveElectrode","ActiveMaterial", "VolumetricSurfaceArea"];
                            lower_bound = 1e3, upper_bound = 1e6)

free_calibration_parameter!(vc,
                            ["Separator", "BruggemanCoefficient"];
                            lower_bound = 1e-3, upper_bound = 1e2)
free_calibration_parameter!(vc,
                            ["NegativeElectrode","ElectrodeCoating", "BruggemanCoefficient"];
                            lower_bound = 1e-3, upper_bound = 1e2)
free_calibration_parameter!(vc,
                            ["PositiveElectrode","ElectrodeCoating", "BruggemanCoefficient"];
                            lower_bound = 1e-3, upper_bound = 1e2)

free_calibration_parameter!(vc,
                            ["NegativeElectrode","ActiveMaterial", "DiffusionCoefficient"];
                            lower_bound = 1e-16, upper_bound = 1e-10)
free_calibration_parameter!(vc,
                            ["PositiveElectrode","ActiveMaterial", "DiffusionCoefficient"];
                            lower_bound = 1e-16, upper_bound = 1e-10)

print_calibration_overview(vc)

# Run HMC
#
# sampling parameters from HMC
n_samples, n_adapts = 1000, 500

# We use a default prior
logprior = setup_default_prior(vc)

samples, stats = runHMC(vc, n_samples, n_adapts, logprior)

# Run simple analysis
# 

diag_fig = run_essential_diagnostics(samples, stats, n_adapts)
