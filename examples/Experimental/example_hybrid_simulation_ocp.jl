#=
Electro-Chemical component
A component with electric potential, concentration and temperature
The different potentials are independent (diagonal onsager matrix),
and conductivity, diffusivity is constant.
=#

using Jutul, BattMo, Plots
using Flux, BSON

# define Ocp type with ML model
struct MLModelOcp{M} <: AbstractOcp
    ML_model::M
    function MLModelOcp(input_ML_model)
        new{typeof(input_ML_model)}(input_ML_model)
    end
end

# update Ocp variable with ML model
@jutul_secondary(
    function update_vocp!(Ocp,
                          tv::MLModelOcp,
                          model:: SimulationModel{<:Any, BattMo.ActiveMaterialP2D{D, T}, <:Any, <:Any},
                          Cs,
                          ix
                          ) where {D, T}

        cmax = model.system.params[:maximum_concentration]
        ML_model =  tv.ML_model
        # Ocp is computed for all cells in the electrode
        @views theta = Cs ./ cmax
        @inbounds Ocp .= vec(ML_model(reshape(theta, 1, :)))
    end
)

use_p2d = true

train_ML_model = false

if train_ML_model
    include("train_OCP_ML_models.jl")
    train_model_neg_electrode()
    train_model_pos_electrode()
end

name = "p2d_40_cccv"
fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/", name, ".json")
inputparams = readBattMoJsonInputFile(fn)

model, parameters = BattMo.setup_model(inputparams, use_groups=false, general_ad=false)#; info_level=0,  extra_timing=false)

# load ML model from file and define Ocp type with ML model
BSON.@load "OCP_ML_model_negative_electrode.bson" OCP_ML_model_negative_electrode
BSON.@load "OCP_ML_model_positive_electrode.bson" OCP_ML_model_positive_electrode
ocp_NeAM = MLModelOcp(OCP_ML_model_negative_electrode)
ocp_PeAM = MLModelOcp(OCP_ML_model_positive_electrode)

# replace Ocp with ML model in the model
replace_variables!(model[:NeAm], Ocp = ocp_NeAM, throw = true)
replace_variables!(model[:PeAm], Ocp = ocp_PeAM, throw = true)

state0 = BattMo.setup_initial_state(inputparams, model)

forces = BattMo.setup_forces(model)

sim = BattMo.Simulator(model; state0=state0, parameters=parameters, copy_state=true)

#Set up config and timesteps
timesteps = BattMo.setup_timesteps(inputparams; max_step=nothing)

cfg = BattMo.setup_config(sim, model, :direct, false)

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

