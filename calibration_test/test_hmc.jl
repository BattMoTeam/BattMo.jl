using AdvancedHMC, ForwardDiff
using LogDensityProblems
using LinearAlgebra

using BattMo, Jutul
using CSV
using DataFrames
using GLMakie
include("equilibrium_calibration.jl")
include("function_parameters_MJ1.jl")

cell_parameters = load_cell_parameters(; from_file_path = joinpath(@__DIR__,"mj1_tab1.json"))
print(cell_parameters["NegativeElectrode"]["ActiveMaterial"]["OpenCircuitPotential"])
#cell_parameters = load_cell_parameters(; from_default_set = "Xu2015")
#cycling_protocol = load_cycling_protocol(; from_default_set = "CCDischarge")
cycling_protocol = load_cycling_protocol(; from_file_path = joinpath(@__DIR__,"custom_discharge2.json"))
#model_settings = load_model_settings(; from_default_set = "P4D_pouch")
model_settings = load_model_settings(;from_default_set = "P2D") # Ensure the model framework is set to P4D Pouch
simulation_settings = load_simulation_settings(; from_file_path = joinpath(@__DIR__,"model2.json"))
#simulation_settings = load_simulation_settings(; from_default_set = "P4D_pouch")
simulation_settings = load_simulation_settings(; from_default_set = "P2D") # Ensure the model framework is set to P4D Pouch



model_setup = LithiumIonBattery(; model_settings)

# Define the target distribution using the `LogDensityProblem` interface
struct LogTargetDensity
    dim::Int
end
LogDensityProblems.logdensity(p::LogTargetDensity, θ) = -sum(abs2, θ) / 2  # standard multivariate normal
LogDensityProblems.dimension(p::LogTargetDensity) = p.dim
LogDensityProblems.capabilities(::Type{LogTargetDensity}) = LogDensityProblems.LogDensityOrder{0}()

# Choose parameter dimensionality and initial parameter value
D = 10; initial_θ = rand(D)
ℓπ = LogTargetDensity(D)

# Set the number of samples to draw and warmup iterations
n_samples, n_adapts = 2_000, 1_000

function ℓπ_(θ)
    return
end

function ℓπ_grad(θ)
    # Compute the gradient of the log density
    return -θ  # gradient of the standard multivariate normal
end

# Define a Hamiltonian system
metric = DiagEuclideanMetric(D)
hamiltonian = Hamiltonian(metric, ℓπ, ℓπ_grad)


# Define a leapfrog solver, with the initial step size chosen heuristically
initial_ϵ = find_good_stepsize(hamiltonian, initial_θ)
integrator = Leapfrog(initial_ϵ)

# Define an HMC sampler with the following components
#   - multinomial sampling scheme,
#   - generalised No-U-Turn criteria, and
#   - windowed adaption for step-size and diagonal mass matrix
kernel = HMCKernel(Trajectory{MultinomialTS}(integrator, GeneralisedNoUTurn()))
adaptor = StanHMCAdaptor(MassMatrixAdaptor(metric), StepSizeAdaptor(0.8, integrator))

# Run the sampler to draw samples from the specified Gaussian, where
#   - `samples` will store the samples
#   - `stats` will store diagnostic statistics for each sample
samples, stats = sample(hamiltonian, kernel, initial_θ, n_samples, adaptor, n_adapts; progress=true)