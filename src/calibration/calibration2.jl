""" get time and voltage from states
"""
function get_tV(x)
    t = [state[:Control][:Controller].time for state in x[:states]]
    V = [state[:Control][:Phi][1] for state in x[:states]]
    return (t, V)
end

""" get time and voltage from dataframe
"""
function get_tV(x::DataFrame)
    return (x[:, 1], x[:, 2])
end

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

    function trapz(x, y)
        sum((x[i+1] - x[i]) * (y[i] + y[i+1]) / 2 for i in 1:length(x)-1)
    end
    
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


""" Calibrates the equilibrium parameters of the model
"""
function equilibriumCalibration(sim)

    t_exp = vec(exp_data[1]["time"])
    V_exp = vec(exp_data[1]["E"])
    I     = exp_data[1]["I"]

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

    @info typeof(vc.parameter_targets)
    @info keys(vc.parameter_targets)

    cellparams = solve_equilibrium!(vc; I=I)

    println("calibration parameters: ", cellparams)

    for (key, value) in cellparams
        set_calibration_parameter!(vc, key, value)
    end
    
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
    X = [val for (key, val) in cellparams]
    Veq = compute_equilibrium_voltage(vc, X, Xparam, exp_data[1]["I"], ocp_pe, ocp_ne)

    return (allparameters = vc.sim.cell_parameters,
            V             = Veq,
            t             = t_exp,
            cellparams    = cellparams)


end

""" Calibrates the kinetic parameters of the model
"""
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
        lower_bound = 1e-3, upper_bound = 1e1)

    free_calibration_parameter!(vc2,
        ["NegativeElectrode","ElectrodeCoating", "BruggemanCoefficient"];
        lower_bound = 1e-3, upper_bound = 1e1)
    free_calibration_parameter!(vc2,
        ["PositiveElectrode","ElectrodeCoating", "BruggemanCoefficient"];
        lower_bound = 1e-3, upper_bound = 1e1)
    
    free_calibration_parameter!(vc2,
        ["NegativeElectrode","ActiveMaterial", "DiffusionCoefficient"];
        lower_bound = 1e-16, upper_bound = 1e-10)
    free_calibration_parameter!(vc2,
        ["PositiveElectrode","ActiveMaterial", "DiffusionCoefficient"];
        lower_bound = 1e-16, upper_bound = 1e-10)
    
    print_calibration_overview(vc2)

    cell_parameters_calibrated2, history = solve(vc2;scaling = scaling);

    results = BattMo.solve_random_init(vc2;n_samples = 50, scaling = scaling)

    """
    #Boxplots of the results
    for i in 1:length(results)
        result = results[i]
        fig = Figure(size = (800, 500))
        ax = Axis(fig[1, 1],
            ylabel = "Value",
            xlabel = "Parameter",
            title = "Calibration results "
        )
        boxplot!(ax, result[1], color = :blue, label = "Samples")
        axislegend(ax, position = :rb)
        display(fig)

        # Save figure as PNG
        save_path = joinpath(@__DIR__, "calibration_random_init.png")
        save(save_path, fig)
        println("Saved plot")
    end
    """
    
    print_calibration_overview(vc2)

    return cell_parameters_calibrated2,history #,results
end

""" Calibrates the kinetic parameters of the model with priors
"""
function highRateCalibrationWithPriors(exp_data,cycling_protocol, cell_parameters_calibrated,model_setup,simulation_settings; scaling = :linear)
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
        lower_bound = 1e3, upper_bound = 1e6, prior_mean = 1e4, prior_std = 10)
    free_calibration_parameter!(vc2,
        ["PositiveElectrode","ActiveMaterial", "VolumetricSurfaceArea"];
        lower_bound = 1e3, upper_bound = 1e6, prior_mean = 1e4, prior_std = 10)

    free_calibration_parameter!(vc2,
        ["Separator", "BruggemanCoefficient"];
        lower_bound = 1e-3, upper_bound = 1e1, prior_mean = 1, prior_std = 10)

    free_calibration_parameter!(vc2,
        ["NegativeElectrode","ElectrodeCoating", "BruggemanCoefficient"];
        lower_bound = 1e-3, upper_bound = 1e1, prior_mean = 1, prior_std = 10)
    free_calibration_parameter!(vc2,
        ["PositiveElectrode","ElectrodeCoating", "BruggemanCoefficient"];
        lower_bound = 1e-3, upper_bound = 1e1, prior_mean = 1, prior_std = 10)
    
    free_calibration_parameter!(vc2,
        ["NegativeElectrode","ActiveMaterial", "DiffusionCoefficient"];
        lower_bound = 1e-16, upper_bound = 1e-10,prior_mean = 1e-13, prior_std = 10)
    free_calibration_parameter!(vc2,
        ["PositiveElectrode","ActiveMaterial", "DiffusionCoefficient"];
        lower_bound = 1e-16, upper_bound = 1e-10, prior_mean =1e-13, prior_std = 10)
    
    print_calibration_overview(vc2)

    cell_parameters_calibrated2, history = solve_with_priors(vc2;scaling = scaling);

    """
    results = BattMo.solve_random_init(vc2;n_samples = 50, scaling = scaling)

    #Boxplots of the results
    for i in 1:length(results)
        result = results[i]
        fig = Figure(size = (800, 500))
        ax = Axis(fig[1, 1],
            ylabel = "Value",
            xlabel = "Parameter",
            title = "Calibration results "
        )
        boxplot!(ax, result[1], color = :blue, label = "Samples")
        axislegend(ax, position = :rb)
        display(fig)

        # Save figure as PNG
        save_path = joinpath(@__DIR__, "calibration_random_init.png")
        save(save_path, fig)
        println("Saved plot")
    end
    """

    print_calibration_overview(vc2)

    return cell_parameters_calibrated2,history #,results
end

