export equilibriumCalibration

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


function get_cell_parameters_from_vector(vc::VoltageCalibration, X)

    # pt    = vc.parameter_targets
    # pkeys = collect(keys(pt))

    cellparams = Dict{Vector{String}, Any}()

    for (ikey, (key, )) in enumerate(vc.parameter_targets)
        cellparams[key] = X[ikey]
    end

    return cellparams
end

"""
    compute_equilibrium_voltage(t, X, I, ocp_pe, ocp_ne)

Compute predicted voltage assuming equilibrium (low C-rate, negligible diffusion).
"""
function compute_equilibrium_voltage(vc, X, Xparam, I, ocp_pe, ocp_ne)

    t = vc.t
    
    s = get_cell_parameters_from_vector(vc, X)
    
    theta_ne100 = s[["NegativeElectrode","ActiveMaterial","StoichiometricCoefficientAtSOC100"]]
    theta_pe100 = s[["PositiveElectrode","ActiveMaterial","StoichiometricCoefficientAtSOC100"]]
    cne         = s[["NegativeElectrode","ActiveMaterial","MaximumConcentration"]]
    cpe         = s[["PositiveElectrode","ActiveMaterial","MaximumConcentration"]]

    F = 96485.3329

    Vpe, Vne, a_pe, a_ne, eps_pe, eps_ne = Xparam 

    mpe = cpe * Vpe * a_pe * eps_pe 
    mne = cne * Vne * a_ne * eps_ne 
    
    #println("mpe = ", mpe, " mne = ", mne)
    theta_pe = theta_pe100 .+ (I / (F * mpe)) .* (t .- t[1])
    theta_ne = theta_ne100 .- (I / (F * mne)) .* (t .- t[1])

    return ocp_pe.(theta_pe) .- ocp_ne.(theta_ne)
    
end

"""
    equilibrium_objective(X, t, V_exp, I, ocp_pe, ocp_ne)

Return mean squared error between experimental and predicted equilibrium voltage.
"""
function equilibrium_objective(X, Xparam, vc, I, ocp_pe, ocp_ne)

    V_exp = vc.v
    t     = vc.t
    
    V_pred = compute_equilibrium_voltage(vc, X, Xparam, I, ocp_pe, ocp_ne)
    
    return (sum((V_pred .- V_exp).^2))
    
end

"""
    solve_equilibrium!(vc::VoltageCalibration;
        I,
        ocp_pe,
        ocp_ne,
        grad_tol=1e-6,
        obj_tol=1e-6,
        kwarg...
    )

Perform equilibrium calibration using LBFGS with box constraints.
"""
function solve_equilibrium!(vc::VoltageCalibration;
                            I,
                            grad_tol=1e-10,
                            obj_tol=1e-10,
                            kwarg...
                                )

    pt = vc.parameter_targets
    pkeys = collect(keys(pt))
    
    print("Calibrating parameters: $(pkeys)... ")
    if length(pkeys) != 4
        throw(ArgumentError("Expected 4 parameters got $(length(pkeys))"))
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

    Xparam = [
        Vpe, Vne, a_pe, a_ne, eps_pe, eps_ne
    ]
    # Extract X0, bounds
    X0 = [pt[k].v0 for k in pkeys]
    lb = [pt[k].vmin for k in pkeys]
    ub = [pt[k].vmax for k in pkeys]

    f(X) = equilibrium_objective(X, Xparam, vc, I, ocp_pe, ocp_ne)

    jutul_message("Equilibrium Calibration", "Starting optimization with $(length(X0)) parameters.", color=:green)

    local x, history, v
    t_opt = @elapsed begin
        v, x, history = Jutul.LBFGS.box_bfgs(
            X0,
            x -> begin
                val = f(x)
                grad = ForwardDiff.gradient(f, x)
                return (val, grad)
            end,
            lb, ub;
            maximize=false,
            print=1,
            grad_tol=grad_tol,
            obj_change_tol=obj_tol,
            kwarg...
                )
    end

    jutul_message("Equilibrium Calibration",
                  "Finished in $t_opt seconds. Objective = $v", color=:green)

    return get_cell_parameters_from_vector(vc, x)
    
end



