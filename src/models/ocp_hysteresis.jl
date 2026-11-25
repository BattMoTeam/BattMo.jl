############################################################################################
# One-state OCP hysteresis of an active material, as PyBaMM's "one-state hysteresis" model #
############################################################################################

export HysteresisState, HystereticOpenCircuitPotential, HysteresisEquation

"""
Hysteresis state `h` of the one-state OCP hysteresis model, in [-1, 1]: +1 on the delithiation
branch of the open-circuit potential, -1 on the lithiation branch.
"""
struct HysteresisState <: ScalarVariable end

Jutul.minimum_value(::HysteresisState) = -1.0
Jutul.maximum_value(::HysteresisState) = 1.0

"""
Open-circuit potential with one-state hysteresis, `(1 + h) / 2 * U_delith + (1 - h) / 2 * U_lith`,
plus the entropy term as for `OpenCircuitPotential`. It takes the place of `OpenCircuitPotential`
in the model, under the same name.
"""
struct HystereticOpenCircuitPotential <: ScalarVariable end

"""
The one-state hysteresis law per electrode cell, implicit Euler in the change `dtheta` of the
cell's mean stoichiometry over the time step:

    delithiation (dtheta < 0): h - h0 - gamma_delith * |dtheta| * (1 - h) / 2 = 0
    lithiation (dtheta >= 0):  h - h0 + gamma_lith * dtheta * (1 + h) / 2 = 0

By the particle mass balance `dtheta` is PyBaMM's `i_vol * dt / (F * c_max * eps_s)`, so the law
is PyBaMM's `dh/dt = gamma * r * (1 - sign(r) * h) / 2`. As there, the decay rates are evaluated
at the surface stoichiometry. `h` stays in [-1, 1] for any step: each step is a convex combination
of `h0` and the branch of the current direction.
"""
struct HysteresisEquation <: JutulEquation end

Jutul.local_discretization(::HysteresisEquation, i) = nothing
Jutul.number_of_equations_per_entity(model::ActiveMaterialModel, ::HysteresisEquation) = 1

# Input keys of the hysteresis parameters of an active material, by their names in the parameters.
# All four take the forms and the signature `(c, T, refT, cmax)` of an open-circuit potential.
const OCP_HYSTERESIS_INPUT = (
    ocp_lithiation = "OpenCircuitPotentialLithiation",
    ocp_delithiation = "OpenCircuitPotentialDelithiation",
    hysteresis_decay_lithiation = "HysteresisDecayRateLithiation",
    hysteresis_decay_delithiation = "HysteresisDecayRateDelithiation",
)

has_ocp_hysteresis(system::ActiveMaterial) = haskey(system.params, :ocp_lithiation_func)
has_ocp_hysteresis(model::SimulationModel) = model.system isa ActiveMaterial && has_ocp_hysteresis(model.system)

"""
    setup_ocp_hysteresis_parameters!(params, input, base_path, name)

Read the hysteresis parameters of the active material input `input` of electrode `name` into
`params`, if it gives the two OCP branches. Returns whether it does.
"""
function setup_ocp_hysteresis_parameters!(params, input, base_path, name)
    branches = (OCP_HYSTERESIS_INPUT.ocp_lithiation, OCP_HYSTERESIS_INPUT.ocp_delithiation)
    given = count(key -> haskey(input, key), branches)
    given == 0 && return false
    given == 2 || throw(ArgumentError("$name.ActiveMaterial needs both $(branches[1]) and $(branches[2]) for OCP hysteresis."))
    for (key, input_key) in pairs(OCP_HYSTERESIS_INPUT)
        haskey(input, input_key) || throw(ArgumentError("$name.ActiveMaterial.$input_key is required for OCP hysteresis."))
        func, func_type = setup_function(base_path, input[input_key], "ActiveMaterial", "OpenCircuitPotential")
        params[Symbol(key, :_func)] = func
        params[Symbol(key, :_func_type)] = func_type
    end
    return true
end

"""
    add_ocp_hysteresis!(model)

Give an active material model with hysteresis parameters (`setup_ocp_hysteresis_parameters!`) the
primary variable `HysteresisState`, its equation, and the hysteretic open-circuit potential.
"""
function add_ocp_hysteresis!(model::ActiveMaterialModel)
    Jutul.set_primary_variables!(model; HysteresisState = HysteresisState())
    Jutul.replace_variables!(model; OpenCircuitPotential = HystereticOpenCircuitPotential())
    model.equations[:hysteresis] = HysteresisEquation()
    push!(model.output_variables, :HysteresisState)
    return model
end

"""Lithiation and delithiation branch of the open-circuit potential at `c` and `T`."""
function ocp_branches(params, c, T)
    cmax = params[:maximum_concentration]
    refT = params[:reference_temperature]
    u_lith = evaluate_ocp_function(params[:ocp_lithiation_func], params[:ocp_lithiation_func_type], c, T, refT, cmax)
    u_delith = evaluate_ocp_function(params[:ocp_delithiation_func], params[:ocp_delithiation_func_type], c, T, refT, cmax)
    return u_lith, u_delith
end

"""Open-circuit potential at hysteresis state `h`, without the entropy term."""
function hysteretic_ocp(params, c, T, h)
    u_lith, u_delith = ocp_branches(params, c, T)
    return (1 + h) / 2 * u_delith + (1 - h) / 2 * u_lith
end

@jutul_secondary(
    function update_hysteretic_ocp!(
            OpenCircuitPotential,
            tv::HystereticOpenCircuitPotential,
            model::ActiveMaterialModel,
            Temperature,
            SurfaceConcentration,
            EntropyChange,
            HysteresisState,
            ix,
        )
        params = model.system.params
        for cell in ix
            @inbounds OpenCircuitPotential[cell] = hysteretic_ocp(params, SurfaceConcentration[cell], Temperature[cell], HysteresisState[cell])
        end
        if params[:include_entropy_change]
            refT = params[:reference_temperature]
            for cell in ix
                @inbounds OpenCircuitPotential[cell] += EntropyChange[cell] * (Temperature[cell] - refT)
            end
        end
    end
)

function Jutul.update_equation_in_entity!(
        eq_buf,
        self_cell,
        state,
        state0,
        eq::HysteresisEquation,
        model,
        dt,
        ldisc = nothing,
    )
    params = model.system.params
    vols = model.system.discretization[:vols]
    cmax = params[:maximum_concentration]
    refT = params[:reference_temperature]
    c, c0 = state.ParticleConcentration, state0.ParticleConcentration
    dc = sum(vols[i] * (c[i, self_cell] - c0[i, self_cell]) for i in eachindex(vols))
    dtheta = dc / (sum(vols) * cmax)
    h, h0 = state.HysteresisState[self_cell], state0.HysteresisState[self_cell]
    c_surface, T = state.SurfaceConcentration[self_cell], state.Temperature[self_cell]
    if dtheta < 0
        gamma = evaluate_ocp_function(
            params[:hysteresis_decay_delithiation_func], params[:hysteresis_decay_delithiation_func_type],
            c_surface, T, refT, cmax,
        )
        eq_buf[] = h - h0 + gamma * dtheta * (1 - h) / 2
    else
        gamma = evaluate_ocp_function(
            params[:hysteresis_decay_lithiation_func], params[:hysteresis_decay_lithiation_func_type],
            c_surface, T, refT, cmax,
        )
        eq_buf[] = h - h0 + gamma * dtheta * (1 + h) / 2
    end
    return eq_buf
end
