# # Hamiltonian Monte-Carlo setup

struct LogTargetDensity
    dim::Int
end

# Linear transformation functions for HMC to bring them to [0, 100] 
function x_to_u(x, lb, ub)

    δ = ub .- lb

    u= (x .- lb) ./ δ  # Scale to [0, 1]
    u = u .* 100  # Scale to [0, 100]
    
    return u
    
end

function u_to_x(u, lb, ub)
    
    δ = ub .- lb
    u = u ./ 100  # Scale back to [0, 1]
    x = lb .+ u .* δ  # Reverse the linear transformation
    
    return x
    
end

function dx_to_du!(g, x, lb, ub)
    
    δ = ub .- lb
    @. g = g #* (δ/100)
    
end

function get_bounds(vc::VoltageCalibration)

    sim = deepcopy(vc.sim)
    
    x0, x_setup = BattMo.vectorize_cell_parameters_for_calibration(vc, sim)
    # Recover parameter bounds
    
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

    return lb, ub, x0, x_setup
    
end

""" setup default prior based on initial value and bounds
"""
function setup_default_prior(vc::VoltageCalibration)

    lb, ub, x0, x_setup = get_bounds(vc)
    
    initial_θ = x_to_u(x0, lb, ub)

    """ Returns the log prior. It is chosen as a Gaussian prior with mean initial_θ and variance with default equal to 10
    """
    function logprior(x; variance = 10)
        @info "using gaussian prior"
        # gaussian prior with mean initial_θ
        log_prior      = -0.5 * sum((x .- initial_θ).^2) / variance
        grad_log_prior = -(x .- initial_θ) / variance

        return (log_prior, grad_log_prior)
    end

    return logprior
    
end

function runHMC(vc::VoltageCalibration, n_samples, n_adapts, logprior)

    # Setting up the HMC framework

    # # Set up the objective function
    # objective is given by square sum of difference between simulated and experimental voltage values
    objective = BattMo.setup_calibration_objective(vc)

    # # Recover parameter initial values, and lower and upper bounds in vector forms
    lb, ub, x0, x_setup = get_bounds(vc)

    initial_θ = x_to_u(x0, lb, ub)

    # # Setup Battmo to return objective and gradient.

    setup_battmo_case(X, step_info = missing) = BattMo.setup_battmo_case_for_calibration(X,
                                                                                         sim,
                                                                                         x_setup,
                                                                                         step_info)

    # The function `solve_and_differentiate` returns the objective function value and its gradient. 
    adj_cache = Dict()
    solve_and_differentiate(x) = BattMo.solve_and_differentiate_for_calibration(x,
                                                                                setup_battmo_case,
                                                                                vc,
                                                                                objective;
                                                                                adj_cache = adj_cache)

    # We wrap `solve_and_differentiate` in `evaluate` to return the log-likelihood and its gradient 

    """ evaluate objective function, returns the log-likelihood, which corresponds to sum of the square weighted by variance
    """
    function evaluate(x; σ2 = 0.1)
        #@info "Evaluating x = $x"

        # Default fallback values
        log_llh      = -Inf
        grad_log_llh = zero(x)

        try
            
            log_llh, grad_log_llh = solve_and_differentiate(x) #returns the sum squared error and its gradient
            log_llh               = -log_llh/(2*σ2)  # Convert to log-likelihood 
            grad_log_llh          = -grad_log_llh/(2*σ2)  # Convert to gradient of log-likelihood  

            # Sanity checks
            if !isfinite(log_llh) || any(!isfinite, grad_log_llh)
                @warn "Invalid result from solver at x = $x"

            end
        catch e
            @error "Error during solve_and_differentiate: $(e)"
        end

        return (log_llh, grad_log_llh)
    end

    """ compute log posterior and gradient from parameters θ
        """
    function LogDensityProblems.logdensity_and_gradient(p::LogTargetDensity, θ)
        
        @info "Calculating log density and gradient for θ = $θ"
        
        x = u_to_x(θ) #θ is in log-space, x in original space
        log_llh, grad_log_llh = evaluate(x)
        
        log_prior, grad_log_prior = logprior(θ)
        
        log_density = log_llh .+ log_prior
        dx_to_du!(grad_log_llh, x)

        gradient =  grad_log_llh .+ grad_log_prior
        
        return (log_density, gradient)
        
    end

    # # Setup Hamiltionian Monte Carlo 
    LogDensityProblems.dimension(p::LogTargetDensity) = p.dim

    function LogDensityProblems.capabilities(::Type{LogTargetDensity})
        return LogDensityProblems.LogDensityOrder{1}()
    end

    # Parameters
    D = length(vc.parameter_targets) 

    # Create target distribution, note that methods
    #
    # - LogDensityProblems.logdensity_and_gradient
    # - LogDensityProblems.capabilities
    # - LogDensityProblems.dimension
    #
    # have been specialized from this type

    target = LogTargetDensity(D)

    # # Define Hamiltonian system
    #
    # The parameters in the methods that can be adjusted are
    # - the metric
    # - the integration step (see initial_ϵ below)
    # - the number of steps (can be fix or dynamics, see `HMCKernel` setup)
    # 

    # The metric corresponds to the mass matrix in the Hamiltonion formulation
    metric      = DiagEuclideanMetric(D)
    hamiltonian = Hamiltonian(metric, target)

    # # Find initial step size
    #
    # There is the possibility to optimize initial step size by calling `initial_ϵ = find_good_stepsize(hamiltonian, initial_θ)`
    initial_ϵ = 0.01

    # # Setup integrator
    #
    # We choose a standard integrator
    integrator = Leapfrog(initial_ϵ)

    # # Setup sampler
    #
    # the `trajectory` determines the way to integrate the Hamiltonian dynamics. Here, we choose a fixed number of time step.
    #
    # We think that : If we choose a very short trajectory (small time step and few steps), we get a result equivalent
    # to a random walk Metropolis-Hastings. If we choose a long trajectory, we may be able to explore the space better,
    # but it has a computational cost and sometime it may be inefficient, see paper from Michael Betancourt, https://arxiv.org/abs/1701.02434

    trajectory = Trajectory{EndPointTS}(integrator, FixedNSteps(10))

    kernel  = HMCKernel(trajectory)

    # An adaptor can be used to find better parameters. We do not use it here.
    adaptor = StanHMCAdaptor(MassMatrixAdaptor(metric), StepSizeAdaptor(0.8, integrator))

    # # Run Hamiltonian sampling
    #
    samples, stats = sample(hamiltonian,
                            kernel,
                            initial_θ,
                            n_samples;
                            progress=true)

    return samples, states
    
end

# # Diagnostics tools
# 
function analyze_sampling_results(samples::Vector,
                                  stats::Vector,
                                  n_adapts::Int)
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

# Effective Sample Size calculation 
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

