export highRateCalibration, highRateCalibrationWithPriors

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

    cell_parameters_calibrated2, history = solve(vc2;
                                                 scaling = scaling);

    # results = BattMo.solve_random_init(vc2;n_samples = 50, scaling = scaling)

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


""" Calibrates the kinetic parameters of the model with priors, not working optimally yet.
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

