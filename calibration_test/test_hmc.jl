using AdvancedHMC, ForwardDiff
using AbstractMCMC
using LogDensityProblems
using LinearAlgebra
using Plots

using MCMCDiagnosticTools

#BattMo setup

using Revise
using BattMo, Jutul
using CSV
using DataFrames
using GLMakie

include("equilibrium_calibration.jl")
include("function_parameters_MJ1.jl")

struct LogTargetDensity
        dim::Int
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

    simulation_settings = load_simulation_settings(; from_file_path = joinpath(@__DIR__,"simple.json"))
    #simulation_settings = load_simulation_settings(; from_default_set = "P4D_pouch")
    #simulation_settings = load_simulation_settings(; from_default_set = "P2D") # Ensure the model framework is set to P4D Pouch
    
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



###

t_exp_hr = vec(exp_data[end]["time"])
V_exp_hr = vec(exp_data[end]["E"])

I = exp_data[end]["I"]
    

cycling_protocol2 = deepcopy(cycling_protocol)
cycling_protocol2["DRate"] = exp_data[end]["rawRate"]
sim2 = Simulation(model_setup, cell_parameters_calibrated, cycling_protocol2; simulation_settings)
output = get_simulation_input(sim2)
model2 = output[:model]
sim2.cycling_protocol["DRate"] = I * 3600 / computeCellCapacity(model2)  

vc = VoltageCalibration(t_exp_hr, V_exp_hr, sim2)

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


#Setting up the HMC framework
    
sim = deepcopy(vc.sim)
x0, x_setup = BattMo.vectorize_cell_parameters_for_calibration(vc, sim)
# Set up the objective function
objective = BattMo.setup_calibration_objective(vc)

ub = similar(x0)
lb = similar(x0)
offsets = x_setup.offsets
for (i, k) in enumerate(x_setup.names)
    (; vmin, vmax) = vc.parameter_targets[k]
    for j in offsets[i]:(offsets[i+1]-1)
        lb[j] = vmin
        ub[j] = vmax
    end
end
adj_cache = Dict()


# Log-transform bounds
log_lb = log.(lb)
log_ub = log.(ub)
δ_log = log_ub .- log_lb

# Transformation functions
function x_to_u(x)
    log_x = log.(x)
    u = log_x
    return u
end

function u_to_x(u)
    log_x = u 
    x = exp.(log_x)
    return x
end

function dx_to_du!(g, x)
    g .= g .* x  # Chain rule: df/du = df/dx * dx/du
end

# Wrapped objective function
function F(u)
    x = u_to_x(u)
    obj, g = f(x)
    dx_to_du!(g, x)
    return (obj, g)
end


setup_battmo_case(X, step_info = missing) = BattMo.setup_battmo_case_for_calibration(X, sim, x_setup, step_info)
solve_and_differentiate(x) = BattMo.solve_and_differentiate_for_calibration(x, setup_battmo_case, vc, objective;
            adj_cache = adj_cache,
        )
        
function evaluate(x)
    #@info "Evaluating x = $x"

    # Default fallback values
    log_llh = -Inf
    grad_log_llh = zero(x)

    try
        log_llh, grad_log_llh = solve_and_differentiate(x) #returns the sum squared error and its gradient
        log_llh = -log_llh/(2*σ2)  # Convert to log-likelihood 
        grad_log_llh = -grad_log_llh/(2*σ2)  # Convert to gradient of log-likelihood  

        # Sanity checks
        if !isfinite(log_llh) || any(!isfinite, grad_log_llh)
            @warn "Invalid result from solver at x = $x"
            log_llh = -Inf
            grad_log_llh = zero(x)
        end
    catch e
        @error "Error during solve_and_differentiate: $(e)"
    end

    return (log_llh, grad_log_llh)
end


using SpecialFunctions  # for loggamma

"""
    logpdf_gamma_with_grad(x, k, θ; rate=false)

Return both the log-density and derivative w.r.t. x for a Gamma distribution.
"""
function logpdf_gamma_with_grad(x, k, θ; rate::Bool=false)
    if any(x .<= 0)
        throw(ArgumentError("x must be > 0 for Gamma distribution"))
    end
    
    if rate
        β = θ
        logpdf = (k-1) .* log.(x) .- β .* x .+ k*log(β) .- loggamma(k)
        grad    = (k-1) ./ x .- β
    else
        logpdf = (k-1) .* log.(x) .- x ./ θ .- k*log(θ) .- loggamma(k)
        grad    = (k-1) ./ x .- 1/θ
    end
    
    return logpdf, grad
end


    
σ2 = 1.0  # Variance of the Gaussian noise

function LogDensityProblems.logdensity_and_gradient(p::LogTargetDensity, θ)
    #θ is a (log-)normalized vector of parameters (θ∈[0,1]^D)
    @info "Calculating log density and gradient for θ = $θ"
    x = u_to_x(θ)
    log_llh, grad_log_llh = evaluate(x)
        
    log_prior = 0
    grad_log_prior = 0


        
    log_density = log_llh .+ log_prior
    gradient = grad_log_llh .+ grad_log_prior

    gradient = dx_to_du!(gradient, x) 
        
    return (log_density, gradient)
end

#LogDensityProblems.logdensity(p::LogTargetDensity, θ) = first(LogDensityProblems.logdensity_and_gradient(p, θ))
LogDensityProblems.dimension(p::LogTargetDensity) = p.dim
function LogDensityProblems.capabilities(::Type{LogTargetDensity})
    return LogDensityProblems.LogDensityOrder{1}()
end

    # Parameters
D = length(vc.parameter_targets) 
initial_θ = x_to_u(x0)
    
    # Create target distribution
target = LogTargetDensity(D)
    
    # HMC parameters
n_samples, n_adapts = 1000, 500
    
# Define Hamiltonian system
metric = DenseEuclideanMetric(D)
hamiltonian = Hamiltonian(metric, target)
    
    # Find initial step size
initial_ϵ = find_good_stepsize(hamiltonian, initial_θ)
integrator = Leapfrog(initial_ϵ)
    
    # Define sampler
#kernel = HMCKernel(Trajectory{MultinomialTS}(integrator, GeneralisedNoUTurn()))
kernel = HMCKernel(Trajectory{EndPointTS}(integrator, FixedNSteps(1)))
adaptor = StanHMCAdaptor(MassMatrixAdaptor(metric), StepSizeAdaptor(0.8, integrator))
    


    # Run sampling
samples, stats = sample(
        hamiltonian, kernel, initial_θ, n_samples, adaptor, n_adapts; progress=true
    )



"""
model = AdvancedHMC.LogDensityModel(target)

sampler = HMCSampler(kernel,metric,adaptor)

samples = AbstractMCMC.sample(
    model, sampler, n_adapts + n_samples; n_adapts=n_adapts, initial_params=initial_θ
)
"""

using Statistics

# Basic sampling statistics
function analyze_sampling_results(samples::Vector, stats::Vector, n_adapts::Int)
    println("\n" * "="^50)
    println("ESSENTIAL HMC DIAGNOSTICS")
    println("="^50)
    
    # Extract post-adaptation samples
    post_adapt_samples = samples[(n_adapts+1):end]
    post_adapt_stats = stats[(n_adapts+1):end]
    n_samples = length(post_adapt_samples)
    n_params = length(samples[1])
    
    # Acceptance rate (using the field from your stats)
    acceptance_rates = [s.acceptance_rate for s in post_adapt_stats]
    avg_acceptance_rate = mean(acceptance_rates)
    println("Average acceptance rate: $(round(avg_acceptance_rate*100, digits=1))%")
    
    # Numerical errors
    n_numerical_errors = count(s.numerical_error for s in post_adapt_stats)
    println("Numerical errors: $n_numerical_errors")
    
    # Step size statistics
    step_sizes = [s.step_size for s in post_adapt_stats]
    println("Final step size: $(round(step_sizes[end], digits=6))")
    println("Step size range: $(round(minimum(step_sizes), digits=6)) - $(round(maximum(step_sizes), digits=6))")
    
    # Energy statistics
    energies = [s.hamiltonian_energy for s in post_adapt_stats]
    energy_errors = [s.hamiltonian_energy_error for s in post_adapt_stats]
    println("Mean energy: $(round(mean(energies), digits=2))")
    println("Mean energy error: $(round(mean(energy_errors), digits=4))")
    
    # Convert to matrix for parameter analysis
    sample_matrix = reduce(hcat, post_adapt_samples)'
    
    println("\nParameter summary:")
    println("-"^40)
    
    for i in 1:n_params
        param_samples = sample_matrix[:, i]
        ess = effective_sample_size(param_samples)
        
        println("Param $i: mean=$(round(mean(param_samples), digits=4)), " *
                "std=$(round(std(param_samples), digits=4)), " *
                "ESS=$(round(ess, digits=1))")
    end
    
    return post_adapt_samples, post_adapt_stats
end

#Effective Sample Size calculation 
function effective_sample_size(x::Vector{Float64})
    n = length(x)
    if n < 10
        return n
    end
    
    # Simple autocorrelation approximation
    μ = mean(x)
    autocorr_sum = 0.0
    max_lag = min(100, n ÷ 2)
    
    for lag in 1:max_lag
        if n - lag < 2
            break
        end
        autocorr_val = cor(x[1:end-lag], x[lag+1:end])
        autocorr_sum += autocorr_val
    end
    
    ess = n / (1 + 2 * autocorr_sum)
    return max(ess, 1.0)
end


function plot_essential_diagnostics(samples::Vector, stats::Vector, n_adapts::Int)
    n_params = length(samples[1])
    
    fig = Figure(resolution=(800, 200 * (n_params + 2)))
    
    # Parameter trace plots
    for i in 1:n_params
        ax = Axis(fig[i, 1], title="Parameter $i - Trace")
        param_values = [s[i] for s in samples]
        lines!(ax, 1:length(samples), param_values, color=:blue)
        vlines!(ax, [n_adapts], color=:red, linestyle=:dash, linewidth=2)
    end
    
    # Energy plot
    ax_energy = Axis(fig[n_params+1, 1], title="Hamiltonian Energy")
    energies = [s.hamiltonian_energy for s in stats]
    lines!(ax_energy, 1:length(energies), energies, color=:purple)
    vlines!(ax_energy, [n_adapts], color=:red, linestyle=:dash, linewidth=2)
    
    # Energy error plot
    ax_energy_err = Axis(fig[n_params+2, 1], title="Energy Error")
    energy_errors = [s.hamiltonian_energy_error for s in stats]
    lines!(ax_energy_err, 1:length(energy_errors), energy_errors, color=:orange)
    vlines!(ax_energy_err, [n_adapts], color=:red, linestyle=:dash, linewidth=2)
    hlines!(ax_energy_err, [0], color=:black, linestyle=:dash)
    
    return fig
end

# Main diagnostic function
function run_essential_diagnostics(samples::Vector, stats::Vector, n_adapts::Int)
    
    post_adapt_samples, post_adapt_stats = analyze_sampling_results(samples, stats, n_adapts)
    
    
    diag_fig = plot_essential_diagnostics(samples, stats, n_adapts)
    
    println("\nDiagnostics completed!")
    return diag_fig
end


diag_fig = run_essential_diagnostics(samples, stats, n_adapts)