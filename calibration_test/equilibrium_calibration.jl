

using Jutul
using ForwardDiff
export solve_equilibrium!, compute_equilibrium_voltage

"""
    compute_equilibrium_voltage(t, X, I, ocp_pe, ocp_ne)

Compute predicted voltage assuming equilibrium (low C-rate, negligible diffusion).
"""
function compute_equilibrium_voltage(t, X, Xparam, I, ocp_pe, ocp_ne)
    cne , cpe, θne100, θpe100  = X
    F = 96485.3329
    Vpe, Vne, a_pe, a_ne, eps_pe, eps_ne = Xparam 
    mpe = cpe * Vpe * a_pe * eps_pe 

    mne = cne * Vne * a_ne * eps_ne 
    
    #println("mpe = ", mpe, " mne = ", mne)
    θpe = θpe100 .+ (I / (F * mpe)) .* (t .- t[1])
    θne = θne100 .- (I / (F * mne)) .* (t .- t[1])

    return ocp_pe.(θpe) .- ocp_ne.(θne)
end

"""
    equilibrium_objective(X, t, V_exp, I, ocp_pe, ocp_ne)

Return mean squared error between experimental and predicted equilibrium voltage.
"""
function equilibrium_objective(X, Xparam, t, V_exp, I, ocp_pe, ocp_ne)
    V_pred = compute_equilibrium_voltage(t, X, Xparam, I, ocp_pe, ocp_ne)
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
        throw(ArgumentError("Expected 4 parameters (θpe100, mpe, θne100, mne), got $(length(pkeys))"))
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


    f(X) = equilibrium_objective(X, Xparam , vc.t, vc.v, I, ocp_pe, ocp_ne)

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

        return x
    
    
    
end



