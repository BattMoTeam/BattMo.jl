#=
Hybrid Simulation Example with Machine Learning OCP Model

This example demonstrates a hybrid simulation approach for a battery model,
combining physics-based modeling with machine learning. The open-circuit potential (OCP)
is modeled using a neural network, which is integrated into the BattMo framework.

Key features:
1. Custom MLModelOcp type to incorporate the ML model into the simulation
2. Integration of pre-trained neural networks for both negative and positive electrodes
3. Replacement of standard OCP calculations with ML-based predictions
4. Simulation of a P2D (Pseudo-2-Dimensional) battery model
5. Visualization of voltage and current profiles over time

This hybrid approach allows for potentially faster and more accurate OCP predictions
while maintaining the physical accuracy of the overall battery model.
=#

using Jutul, BattMo, Plots
using Lux, JLD2

include("train_OCP_ML_models.jl")

# define Ocp type with ML model
struct MLModelOcp{M, P, S} <: AbstractOcp
    ML_model::M
    parameters::P
    states::S
    function MLModelOcp(input_ML_model, parameters, states)
        new{typeof(input_ML_model), typeof(parameters), typeof(states)}(input_ML_model, parameters, states)
    end
end

# update Ocp variable with ML model
@jutul_secondary(
    function update_vocp!(Ocp,
                          tv::MLModelOcp,
                          model:: SimulationModel{<:Any, BattMo.ActiveMaterialP2D{label, D, T, Di}, <:Any, <:Any},
                          Cs,
                          ix
                          ) where {label, D, T, Di}

        cmax = model.system.params[:maximum_concentration]
        ML_model = tv.ML_model
        ps = tv.parameters
        st = tv.states
        
        @views theta = Cs ./ cmax
        
        # Reshape theta to a 2D array with singleton dimensions to match expected input shape
        theta = reshape(theta, 1, length(theta))
        
        # Apply the ML model
        Ocp_pred, st = Lux.apply(ML_model, theta, ps, st)
        
        # Reshape the output to match Ocp
        @inbounds Ocp .= vec(Ocp_pred)
    end
)

use_p2d = true

train_ML_model = false

if train_ML_model
    train_model_neg_electrode()
    train_model_pos_electrode()
end

name = "p2d_40_cccv"
fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/", name, ".json")
inputparams = readBattMoJsonInputFile(fn)

model, parameters = BattMo.setup_model(inputparams, use_groups=false, general_ad=false)

# load ML model from file and define Ocp type with ML model
@load joinpath(folder, "OCP_ML_model_negative_electrode.jld2") OCP_ML_model_neg_electrode ps_neg st_neg
@load joinpath(folder, "OCP_ML_model_positive_electrode.jld2") OCP_ML_model_pos_electrode ps_pos st_pos

ocp_NeAM = MLModelOcp(OCP_ML_model_neg_electrode, ps_neg, st_neg)
ocp_PeAM = MLModelOcp(OCP_ML_model_pos_electrode, ps_pos, st_pos)

# replace Ocp with ML model in the model
replace_variables!(model[:NeAm], Ocp = ocp_NeAM, throw = true)
replace_variables!(model[:PeAm], Ocp = ocp_PeAM, throw = true)

state0 = BattMo.setup_initial_state(inputparams, model)

forces = BattMo.setup_forces(model)

sim = BattMo.Simulator(model; state0=state0, parameters=parameters, copy_state=true)

#Set up config and timesteps
timesteps = BattMo.setup_timesteps(inputparams; max_step=nothing)

cfg = BattMo.setup_config(sim, model, parameters, :direct, false, true)

# Perform simulation
states, reports = BattMo.simulate(state0, sim, timesteps, forces=forces, config=cfg)

extra = Dict(:model => model,
                :state0 => state0,
                :parameters => parameters,
                :init => inputparams,
                :timesteps => timesteps,
                :config => cfg,
                :forces => forces,
                :simulator => sim)

cellSpecifications = BattMo.computeCellSpecifications(model)


t = [state[:Control][:ControllerCV].time for state in states]
E = [state[:Control][:Phi][1] for state in states]
I = [state[:Control][:Current][1] for state in states]


p1 = Plots.plot(t, E;
                label     = "",
                size      = (1000, 800),
                title     = "Voltage",
                xlabel    = "Time / s",
                ylabel    = "Voltage / V",
                markershape = :cross,
                markercolor = :black,
                markersize = 1,
                linewidth = 4,
                xtickfont = font(pointsize = 15),
                ytickfont = font(pointsize = 15))


p2 = Plots.plot(t, I;
                label     = "",
                size      = (1000, 800),
                title     = "Current",
                xlabel    = "Time / s",
                ylabel    = "Current / A",
                markershape = :cross,
                markercolor = :black,
                markersize = 1,
                linewidth = 4,
                xtickfont = font(pointsize = 15),
                ytickfont = font(pointsize = 15))


Plots.plot(p1, p2, layout = (2, 1))
