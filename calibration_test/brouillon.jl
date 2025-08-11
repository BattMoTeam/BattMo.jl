
using Revise
using BattMo, Jutul
using CSV
using DataFrames
using GLMakie

include("equilibrium_calibration.jl")
include("function_parameters_MJ1.jl")


function dict_to_vec(parameter_targets::Dict{Vector{String}, Any})
    #Converts the vc.parameter_targets dict to a vector output (using lexographical order)
    keys_ordered = sort(collect(keys(parameter_targets)))
    values = [parameter_targets[k].v0 for k in keys_ordered]
    
    return values
end


function get_tV(x)
    t = [state[:Control][:Controller].time for state in x[:states]]
    V = [state[:Control][:Phi][1] for state in x[:states]]
    return (t, V)
end

function get_tV(x::DataFrame)
    return (x[:, 1], x[:, 2])
end


function getExpDataOrig()
    battmo_base = normpath(joinpath(pathof(BattMo) |> splitdir |> first, ".."))
    exdata = joinpath(battmo_base, "examples", "example_data")
    df_05 = CSV.read(joinpath(exdata, "Xu_2015_voltageCurve_05C.csv"), DataFrame)
    df_1 = CSV.read(joinpath(exdata, "Xu_2015_voltageCurve_1C.csv"), DataFrame)
    df_2 = CSV.read(joinpath(exdata, "Xu_2015_voltageCurve_2C.csv"), DataFrame)

    dfs = [df_05, df_1, df_2]
    return dfs
end

dfs = getExpDataOrig()
df_05 = dfs[1]
df_1 = dfs[2]
df_2 = dfs[3]



#Fetch experimental data from a .mat file
using MAT
using Statistics: mean

function getExpData(rate="all", flow="discharge")
    """Fetches experimental data from a .mat file. Returns a dictionary with time, rawRate, E, rawI, I, cap, and DRate."""

    # Determine file path
    if lowercase(flow) == "discharge"
        fn = joinpath(@__DIR__,"MJ1-DLR", "dlroutput.mat")
    elseif lowercase(flow) == "charge"
        error("Charge data not available")
    else
        error("Unknown flow $flow")
    end

    # Load data
    data = matread(fn)
    dlroutput = data["dlroutput"]  # Dict with 1×4 matrices for each variable

    @show keys(dlroutput)  # Show available keys in the data
    @show size(dlroutput["current"][1])  # Show size of the time matrix
    
    # Get number of experiments (4 in this case)
    num_experiments = size(dlroutput["time"], 2)
    
    # Process each experiment
    dlrdata = Vector{Dict{String,Any}}(undef, num_experiments)
    
    for k in 1:num_experiments
        # Extract data for this experiment (column k from each matrix)
        time_h = dlroutput["time"][k]
        time_s = time_h * 3600  # hours → seconds
        
        current =dlroutput["current"][k]
        current_segment =  Float64.(current[3:end-1])  # Skip first/last points

        # Create experiment dictionary
        dlrdata[k] = Dict{String,Any}(
            "time" => time_s,
            "rawRate" =>dlroutput["CRate"][k],
            "E" => dlroutput["voltage"][k],
            "rawI" => -current,
            "I" => abs(mean(current_segment)),
            "cap" => abs(trapz(time_s[3:end-1], current_segment)),
            "DRate" => 1.0 / time_h[end]
        )
    end

    # Sort by DRate
    sort!(dlrdata, by=x -> x["DRate"])

    # Select data based on rate
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

# Efficient trapezoidal integration
function trapz(x, y)
    sum((x[i+1] - x[i]) * (y[i] + y[i+1]) / 2 for i in 1:length(x)-1)
end

# Project directory function 
function getProjectDir()
    return dirname(@__DIR__)  
end

#Testing the getExpData function
exp_data = getExpData("all", "discharge")
println("Number of entries: ", length(exp_data))
@show exp_data[1]["rawRate"] 
@show exp_data[2]["rawRate"]
@show exp_data[3]["rawRate"]
@show exp_data[4]["rawRate"] # Show first entry for verification

battmo_base = normpath(joinpath(pathof(BattMo) |> splitdir |> first, ".."))

function runMJ1()

    cell_parameters = load_cell_parameters(; from_file_path = joinpath(@__DIR__,"mj1_tab1.json"))
    
    #cell_parameters = load_cell_parameters(; from_default_set = "Xu2015")
    println("successfully loaded cell parameters and cycling protocol")
    cycling_protocol = load_cycling_protocol(; from_file_path = joinpath(@__DIR__,"custom_discharge2.json"))

    #simulation_settings = load_simulation_settings(; from_file_path = joinpath(@__DIR__,"model2.json"))
    #simulation_settings = load_simulation_settings(; from_default_set = "P4D_pouch")
    simulation_settings = load_simulation_settings(; from_default_set = "P2D") # Ensure the model framework is set to P4D Pouch
    
    #model_settings = load_model_settings(;from_default_set = "P4D_pouch")
    model_settings = load_model_settings(;from_default_set = "P2D") 

    model_setup = LithiumIonBattery(; model_settings)

    sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings);
    print(sim.is_valid)
    #output0 = solve(sim;accept_invalid = true)
    return cycling_protocol, cell_parameters, model_setup, simulation_settings

end

function equilibriumCalibration(sim)


    t_exp = vec(exp_data[1]["time"])
    V_exp = vec(exp_data[1]["E"])
    I = exp_data[1]["I"]

    println("I = ", I  )


    vc = VoltageCalibration(t_exp, V_exp, sim)

    free_calibration_parameter!(vc, ["PositiveElectrode","ActiveMaterial","MaximumConcentration"];
        lower_bound=1e4, upper_bound=1e5)
    free_calibration_parameter!(vc, ["NegativeElectrode","ActiveMaterial","StoichiometricCoefficientAtSOC100"];
        lower_bound=0.0, upper_bound=1.0)
    free_calibration_parameter!(vc, ["PositiveElectrode","ActiveMaterial","StoichiometricCoefficientAtSOC100"];
        lower_bound=0.0, upper_bound=1.0)
    free_calibration_parameter!(vc, ["NegativeElectrode","ActiveMaterial","MaximumConcentration"];
        lower_bound=1e4, upper_bound=1e5)
    


    x = solve_equilibrium!(vc; I=I)

    println("calibration parameters: ", x)
    
    set_calibration_parameter!(vc,["NegativeElectrode","ActiveMaterial","StoichiometricCoefficientAtSOC100"], x[3])
    set_calibration_parameter!(vc,["PositiveElectrode","ActiveMaterial","StoichiometricCoefficientAtSOC100"], x[4])
    set_calibration_parameter!(vc,["NegativeElectrode","ActiveMaterial","MaximumConcentration"], x[1])
    set_calibration_parameter!(vc,["PositiveElectrode","ActiveMaterial","MaximumConcentration"], x[2])

    


    
    output = get_simulation_input(vc.sim)
    model = output[:model]
    ocp_ne = model[:NeAm].system.params[:ocp_func]
    ocp_pe = model[:PeAm].system.params[:ocp_func]

    Vne = sum(model[:NeAm].domain.representation[:volumes])
    Vpe = sum(model[:PeAm].domain.representation[:volumes])

    eps_ne = model[:NeAm].system.params[:volume_fraction]
    eps_pe = model[:PeAm].system.params[:volume_fraction]

    a_ne = model[:NeAm].system.params[:volume_fractions][1]
    a_pe = model[:PeAm].system.params[:volume_fractions][1]

    
    F = 96485.33289 # Faraday constant in C/mol
    C_exp = exp_data[1]["I"]*exp_data[1]["time"][end] # Capacity in Ah
    print("C_exp = ", C_exp, " Ah\n")
    
   
    Xparam = [
        Vpe, Vne, a_pe, a_ne, eps_pe, eps_ne
    ]

    
    mne = vc.sim.cell_parameters["NegativeElectrode"]["ActiveMaterial"]["MaximumConcentration"] * Vne * a_ne * eps_ne
    mpe = vc.sim.cell_parameters["PositiveElectrode"]["ActiveMaterial"]["MaximumConcentration"] * Vpe * a_pe * eps_pe

    θ_100_ne = vc.sim.cell_parameters["NegativeElectrode"]["ActiveMaterial"]["StoichiometricCoefficientAtSOC100"]
    θ_100_pe = vc.sim.cell_parameters["PositiveElectrode"]["ActiveMaterial"]["StoichiometricCoefficientAtSOC100"]
    θ_0_ne = vc.sim.cell_parameters["NegativeElectrode"]["ActiveMaterial"]["StoichiometricCoefficientAtSOC100"] - C_exp/(F*mne)
    θ_0_pe = vc.sim.cell_parameters["PositiveElectrode"]["ActiveMaterial"]["StoichiometricCoefficientAtSOC100"] + C_exp/(F*mpe)

    println("θ_100_ne = ", θ_100_ne, " θ_100_pe = ", θ_100_pe)
    println("θ_0_ne = ", θ_0_ne, " θ_0_pe = ", θ_0_pe)
    set_calibration_parameter!(vc,["NegativeElectrode","ActiveMaterial","StoichiometricCoefficientAtSOC0"], θ_0_ne)
    set_calibration_parameter!(vc,["PositiveElectrode","ActiveMaterial","StoichiometricCoefficientAtSOC0"], θ_0_pe)
   
    @info "calibrated mpe = $mpe, mne = $mne"
    # Compute mpe and mne based on the calibrated parameters
    Veq = compute_equilibrium_voltage(t_exp, x, Xparam, exp_data[1]["I"], ocp_pe, ocp_ne)


    return (vc.sim.cell_parameters, Veq, t_exp)


end

cycling_protocol,cell_parameters,model_setup, simulation_settings = runMJ1()

sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)

cell_parameters_calibrated, V_eq, t_eq = equilibriumCalibration(sim)


function highRateCalibration(exp_data,cycling_protocol, cell_parameters_calibrated,model_setup,simulation_settings; scaling = :linear)

    t_exp_hr = vec(exp_data[end]["time"])
    V_exp_hr = vec(exp_data[end]["E"])

    I = exp_data[end]["I"]
    

    cycling_protocol2 = deepcopy(cycling_protocol)
    cycling_protocol2["DRate"] = exp_data[end]["rawRate"]
    sim2 = Simulation(model_setup, cell_parameters_calibrated, cycling_protocol2; simulation_settings)
    output = get_simulation_input(sim2)
    model2 = output[:model]
    sim2.cycling_protocol["DRate"] = I * 3600 / computeCellCapacity(model2)  

    vc2 = VoltageCalibration(t_exp_hr, V_exp_hr, sim2)

    free_calibration_parameter!(vc2,
        ["NegativeElectrode","ActiveMaterial", "VolumetricSurfaceArea"];
        lower_bound = 1e3, upper_bound = 1e6)
    free_calibration_parameter!(vc2,
        ["PositiveElectrode","ActiveMaterial", "VolumetricSurfaceArea"];
        lower_bound = 1e3, upper_bound = 1e6)


    free_calibration_parameter!(vc2,
        ["Separator", "BruggemanCoefficient"];
        lower_bound = 1e-3, upper_bound = 1e2)
   

    free_calibration_parameter!(vc2,
        ["NegativeElectrode","ElectrodeCoating", "BruggemanCoefficient"];
        lower_bound = 1e-3, upper_bound = 1e2)
    free_calibration_parameter!(vc2,
        ["PositiveElectrode","ElectrodeCoating", "BruggemanCoefficient"];
        lower_bound = 1e-3, upper_bound = 1e2)
    
    free_calibration_parameter!(vc2,
        ["NegativeElectrode","ActiveMaterial", "DiffusionCoefficient"];
        lower_bound = 1e-16, upper_bound = 1e-10)
    free_calibration_parameter!(vc2,
        ["PositiveElectrode","ActiveMaterial", "DiffusionCoefficient"];
        lower_bound = 1e-16, upper_bound = 1e-10)
    print_calibration_overview(vc2)

    sim = deepcopy(vc2.sim)
    x0, x_setup = BattMo.vectorize_cell_parameters_for_calibration(vc2, sim)
    # Set up the objective function
    objective = BattMo.setup_calibration_objective(vc2)

    adj_cache = Dict()

    setup_battmo_case(X, step_info = missing) = BattMo.setup_battmo_case_for_calibration(X, sim, x_setup, step_info)
    solve_and_differentiate(x) = BattMo.solve_and_differentiate_for_calibration(x, setup_battmo_case, vc, objective;
            adj_cache = adj_cache,
        )
        

    @info length(vc2.parameter_targets)
    @info x0
    @info x_setup
    #cell_parameters_calibrated2, = solve(vc2;scaling = scaling);
    print_calibration_overview(vc2)


    return cell_parameters_calibrated2
end

sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)

cell_parameters_calibrated, V_eq, t_eq = equilibriumCalibration(sim)

cell_parameters_calibrated2 = highRateCalibration(exp_data,cycling_protocol,cell_parameters_calibrated,model_setup,simulation_settings; scaling = :log)