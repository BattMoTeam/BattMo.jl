
using BattMo, Jutul
using CSV
using DataFrames
using GLMakie
include("equilibrium_calibration.jl")
include("function_parameters_MJ1.jl")

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

    Xparam = [
        Vpe, Vne, a_pe, a_ne, eps_pe, eps_ne
    ]

    # Compute mpe and mne based on the calibrated parameters
    Veq = compute_equilibrium_voltage(t_exp, x, Xparam, exp_data[1]["I"], ocp_pe, ocp_ne)


    return (vc.sim.cell_parameters, Veq, t_exp)


end

function lowRateCalibration(cell_parameters,simulation_settings,exp_data,model_setup)
    
    
    t_exp_lr = vec(exp_data[1]["time"])
    V_exp_lr = vec(exp_data[1]["E"])
    
    cycling_protocol = load_cycling_protocol(; from_file_path = joinpath(@__DIR__,"custom_discharge2.json"))
    cycling_protocol["DRate"] = exp_data[1]["rawRate"]
    sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings);
    print(sim.is_valid)
    #t_exp_lr, V_exp_lr = get_tV(df_05)
     

    vc_lr= VoltageCalibration(t_exp_lr, V_exp_lr, sim)

    free_calibration_parameter!(vc_lr,
        ["NegativeElectrode","ActiveMaterial", "StoichiometricCoefficientAtSOC100"];
        lower_bound = 0.0, upper_bound = 1.0)
    free_calibration_parameter!(vc_lr,
        ["PositiveElectrode","ActiveMaterial", "StoichiometricCoefficientAtSOC100"];
        lower_bound = 0.0, upper_bound = 1.0)

    free_calibration_parameter!(vc_lr,
        ["NegativeElectrode","ActiveMaterial", "StoichiometricCoefficientAtSOC0"];
        lower_bound = 0.0, upper_bound = 1.0)
    free_calibration_parameter!(vc_lr,
        ["PositiveElectrode","ActiveMaterial", "StoichiometricCoefficientAtSOC0"];
        lower_bound = 0.0, upper_bound = 1.0)

    free_calibration_parameter!(vc_lr,
        ["NegativeElectrode","ActiveMaterial", "MaximumConcentration"];
        lower_bound = 10000.0, upper_bound = 1e5)
    free_calibration_parameter!(vc_lr,
        ["PositiveElectrode","ActiveMaterial", "MaximumConcentration"];
        lower_bound = 10000.0, upper_bound = 1e5)

    print_calibration_overview(vc_lr)
    print("calibration en cours")
    cell_parameters_calibrated, = solve(vc_lr);
    
    print_calibration_overview(vc_lr)

    

    return cell_parameters_calibrated
end

function highRateCalibration(exp_data,cycling_protocol, cell_parameters_calibrated,model_setup,simulation_settings)

    idx = lastindex(exp_data)
    print("index: ", idx, " for high rate calibration\n")
    t_exp_hr = vec(exp_data[idx]["time"])
    V_exp_hr = vec(exp_data[idx]["E"])

    #t_exp_hr,V_exp_hr = get_tV(df_2)

    cycling_protocol2 = deepcopy(cycling_protocol)
    cycling_protocol2["DRate"] = exp_data[idx]["rawRate"]
    sim2 = Simulation(model_setup, cell_parameters_calibrated, cycling_protocol2; simulation_settings)
    

    vc2 = VoltageCalibration(t_exp_hr, V_exp_hr, sim2)

    free_calibration_parameter!(vc2,
        ["NegativeElectrode","ActiveMaterial", "ReactionRateConstant"];
        lower_bound = 1e-16, upper_bound = 1e-10)
    free_calibration_parameter!(vc2,
        ["PositiveElectrode","ActiveMaterial", "ReactionRateConstant"];
        lower_bound = 1e-16, upper_bound = 1e-10)

    free_calibration_parameter!(vc2,
        ["NegativeElectrode","ActiveMaterial", "DiffusionCoefficient"];
        lower_bound = 1e-16, upper_bound = 1e-12)
    free_calibration_parameter!(vc2,
        ["PositiveElectrode","ActiveMaterial", "DiffusionCoefficient"];
        lower_bound = 1e-16, upper_bound = 1e-12)
    print_calibration_overview(vc2)

    cell_parameters_calibrated2, = solve(vc2);
    print_calibration_overview(vc2)

    return cell_parameters_calibrated2
end


cycling_protocol,cell_parameters,model_setup, simulation_settings = runMJ1()

sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)

cell_parameters_calibrated2, V_eq, t_eq = equilibriumCalibration(sim)
#cell_parameters_calibrated = lowRateCalibration(cell_parameters,simulation_settings,exp_data,model_setup)
#cell_parameters_calibrated2 = highRateCalibration(exp_data,cycling_protocol,cell_parameters_calibrated,model_setup,simulation_settings)

println("Calibration done:")

CRates = [exp_data[i]["rawRate"] for i in 1:length(exp_data)]
outputs_base = []
outputs_calibrated = []

for CRate in CRates
	cycling_protocol["DRate"] = CRate
	simuc = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)

	output = solve(simuc, info_level = -1; accept_invalid = true)

    # Store the output for the base case
    if CRate == CRates[1]
        output0 = output
    end

    # Store the output for the calibrated case
	push!(outputs_base, (CRate = CRate, output = output))

    simc = Simulation(model_setup, cell_parameters_calibrated2, cycling_protocol; simulation_settings)
	output_c = solve(simc, info_level = -1;accept_invalid = true)


    push!(outputs_calibrated, (CRate = CRate, output = output_c))
end

colors = Makie.wong_colors()

for (i, CRate) in enumerate(CRates)
    local fig = Figure(size = (800, 500))
    local ax = Axis(fig[1, 1],
        ylabel = "Voltage / V",
        xlabel = "Time / s",
        title = "Discharge curve at $(round(CRate, digits = 2))C"
    )

    if CRate == CRates[1]
      lines!(ax, t_eq, V_eq, linestyle = :dash, label = "Equilibrium", color = colors[4])
    
    end

    # Experimental curve
    t_exp = vec(exp_data[i]["time"])
    V_exp = vec(exp_data[i]["E"])
    lines!(ax, t_exp, V_exp, linestyle = :dot, label = "Experimental", color = colors[1])

    # Simulated curve (calibrated)
    t_sim, V_sim = get_tV(outputs_calibrated[i].output)
    lines!(ax, t_sim, V_sim, linestyle = :dash, label = "Simulated (calibrated)", color = colors[2])

    # Simulated curve (base)
    t_b, V_b = get_tV(outputs_base[i].output)
    lines!(ax, t_b, V_b, linestyle = :dash, label = "Simulated (base)", color = colors[3])

    axislegend(ax, position = :rb)
    display(fig)

    # Save figure as PNG
    save_path = joinpath(@__DIR__, "discharge_curve_$(round(CRate, digits=2))C.png")
    save(save_path, fig)
    println("Saved plot for $(round(CRate, digits=2))C at $save_path")
end

