struct EffectiveVolumetricHeatCapacity <: ScalarVariable end
struct EffectiveThermalConductivity <: ScalarVariable end

const ThermalParameters = JutulStorage

struct ThermalSystem{T} <: BattMoSystem where {T <: ThermalParameters}
    params::T
end

function ThermalSystem(params::ThermalParameters)
    params = Jutul.convert_to_immutable_storage(params)
    return ThermalSystem{typeof(params)}(params)
end

function ThermalSystem()
    return ThermalSystem(Dict())
end

const ThermalModel = SimulationModel{O, S, F, C} where {O <: JutulDomain, S <: ThermalSystem, F <: JutulFormulation, C <: JutulContext}


function Jutul.select_minimum_output_variables!(
        out,
        system::ThermalSystem, model::SimulationModel,
    )
    push!(out, :EffectiveVolumetricHeatCapacity)
    push!(out, :EffectiveThermalConductivity)
    push!(out, :Temperature)
    push!(out, :Temperature)
    return push!(out, :Energy)
end

function Jutul.select_primary_variables!(
        S, system::ThermalSystem, model::SimulationModel,
    )
    return S[:Temperature] = Temperature()
end

function Jutul.select_secondary_variables!(
        S, system::ThermalSystem, model::SimulationModel,
    )
    # S[:TPkGrad_Voltage] = TPkGrad{ElectricPotential}()
    return S[:Energy] = Energy()

end

@jutul_secondary function update_energy!(
        acc,
        tv::Energy,
        model,
        Temperature,
        Volume,
        EffectiveVolumetricHeatCapacity,
        ix,
    )
    for i in ix
        @inbounds acc[i] = Temperature[i] * Volume[i] * EffectiveVolumetricHeatCapacity[i]
    end

end

# @jutul_secondary function update_as_secondary!(acc,
# 	tv::Energy,
# 	model,
# 	Temperature,
# 	ix)
# 	for i in ix
# 		@inbounds acc[i] = Temperature[i]
# 	end

# end

function Jutul.select_parameters!(
        S,
        system::ThermalSystem,
        model::SimulationModel,
    )

    S[:EffectiveThermalConductivity] = EffectiveThermalConductivity()
    S[:EffectiveVolumetricHeatCapacity] = EffectiveVolumetricHeatCapacity()
    S[:BoundaryTemperature] = BoundaryTemperature() # BoundaryTemperature is declared below
    return S[:SurfaceHeatTransferCoefficient] = SurfaceHeatTransferCoefficient() # SurfaceHeatTransferCoefficient is declared below

end

# function select_parameters!(S,
# 	system::Thermal,
# 	model::SimulationModel)

# 	S[:EffectiveThermalConductivity] = EffectiveThermalConductivity()
# 	if Jutul.hasentity(model.data_domain, BoundaryDirichletFaces())
# 		if count_active_entities(model.data_domain, BoundaryDirichletFaces()) > 0
# 			S[:BoundaryTemperature] = BoundaryTemperature(:Temperature)
# 		end
# 	end

# end

function Jutul.face_flux!(::T, c, other, face, face_sign, eq::ConservationLaw{:Energy, <:Any}, state, model::ThermalModel, dt, flow_disc) where {T}

    htrans_cell, htrans_other = setup_half_trans(model, face, c, other, face_sign)

    j = - half_face_two_point_kgrad(c, other, htrans_cell, htrans_other, state.Temperature, state.EffectiveThermalConductivity)

    return T(j)

end

function Jutul.apply_forces_to_equation!(diag_part, storage, model::ThermalModel, eq::ConservationLaw{:Energy}, eq_s, force, time)

    for i in eachindex(force)
        diag_part[i] -= force[i]
    end

    return
end

function Jutul.select_equations!(
        eqs,
        system::ThermalSystem,
        model::SimulationModel,
    )

    disc = model.domain.discretizations.flow
    return eqs[:energy_conservation] = ConservationLaw(disc, :Energy)

end


#######################
# Boundary conditions #
#######################


struct BoundaryTemperature <: ScalarVariable end
Jutul.associated_entity(::BoundaryTemperature) = BoundaryFaces()

struct SurfaceHeatTransferCoefficient <: ScalarVariable end
Jutul.associated_entity(::SurfaceHeatTransferCoefficient) = BoundaryFaces()

function apply_bc_to_equation!(storage, parameters, model::ThermalModel, eq::ConservationLaw{:Energy}, eq_s)

    acc = get_diagonal_entries(eq, eq_s)
    state = storage.state

    return apply_boundary_temperature!(acc, state, parameters, model, eq)

end

function apply_boundary_temperature!(acc, state, parameters, model::ThermalModel, eq::ConservationLaw{:Energy})

    dolegacy = false

    bchalftrans = model.domain.representation[:bcTrans]
    bccells = model.domain.representation[:boundary_neighbors]

    dobc = true

    return if dobc

        T = state[:Temperature]
        BoundaryT = state[:BoundaryTemperature]
        conductivity = state[:EffectiveThermalConductivity]
        extcoef = state[:SurfaceHeatTransferCoefficient]

        if dolegacy
            T_hf = model.domain.representation.boundary_hfT
            for (i, c) in enumerate(bc)
                m = 1 / (1 / conductivity[c] * T_hf[i] + 1 / extcoef)
                @inbounds acc[c] += m * (T[c] - value(BoundaryT[i]))
            end
        else
            for (i, (ht, c)) in enumerate(zip(bchalftrans, bccells))
                if extcoef[i] > 0
                    m = 1 / (1 / (ht * conductivity[c]) + 1 / extcoef[i])

                else
                    m = 0
                end

                @inbounds acc[c] += m * (T[c] - value(BoundaryT[i]))
            end
        end
    end

end

#######################
# setup thermal model #
#######################

function effective_current_collector_heat_capacity(ccmodel, ccinputparams)
    return ccmodel.system[:density] * ccinputparams["SpecificHeatCapacity"]
end

function effective_current_collector_thermal_conductivity(ccinputparams)
    return ccinputparams["ThermalConductivity"]
end

function effective_electrolyte_heat_capacity(elytemodel, elyteparams)
    vf = elytemodel.domain.representation[:volumeFraction]
    return vf .* elyteparams["Density"] .* elyteparams["SpecificHeatCapacity"]
end

function effective_electrolyte_thermal_conductivity(elytemodel, elyteparams, separatorparams)
    vf = elytemodel.domain.representation[:volumeFraction]
    bg = separatorparams["BruggemanCoefficient"]
    return (vf .^ bg) .* elyteparams["ThermalConductivity"]
end

function effective_separator_heat_capacity(separatorparams)
    vf = 1 - separatorparams["Porosity"]
    return vf * separatorparams["Density"] * separatorparams["SpecificHeatCapacity"]
end

function effective_separator_thermal_conductivity(separatorparams)
    vf = 1 - separatorparams["Porosity"]
    bg = separatorparams["BruggemanCoefficient"]
    return (vf^bg) * separatorparams["ThermalConductivity"]
end

function setup_thermal_model(model, submodels, input, grids, global_maps)

    cell_parameters = input.cell_parameters

    maps = global_maps

    ne = :NegativeElectrode
    pe = :PositiveElectrode
    elyte = :Electrolyte
    sep = :Separator
    am = :ActiveMaterial
    bd = :Binder
    ad = :ConductiveAdditive
    cc = :CurrentCollector

    eldes = [ne, pe] # Electrode domains

    global_grid = grids["Global"]

    nc = Jutul.number_of_cells(global_grid)

    volumetric_heat_capacity = zeros(nc)
    thermal_conductivity = zeros(nc)

    for ind in eachindex(eldes)
        elde = eldes[ind]

        # Current collectors
        if haskey(model.settings, "CurrentCollectors")

            cc_map = maps[string(elde, cc)][:cellmap]
            ccmodel = submodels[Symbol(elde, cc)]
            ccparams = cell_parameters[string(elde)]["CurrentCollector"]
            cc_volumetric_heat_capacity = effective_current_collector_heat_capacity(ccmodel, ccparams)
            cc_thermal_conductivity = effective_current_collector_thermal_conductivity(ccparams)

            volumetric_heat_capacity[cc_map] .+= cc_volumetric_heat_capacity
            thermal_conductivity[cc_map] .+= cc_thermal_conductivity
        end

        # Active material (coating)
        am_map = maps[string(elde, am)].cellmap
        ammodel = submodels[Symbol(elde, am)]
        amparams = cell_parameters[string(elde)]
        am_volumetric_heat_capacity = compute_effective_heat_capacity(ammodel.system.params, amparams)
        am_thermal_conductivity = compute_effective_thermal_conductivity(ammodel.system.params, amparams)

        volumetric_heat_capacity[am_map] .+= am_volumetric_heat_capacity
        thermal_conductivity[am_map] .+= am_thermal_conductivity


    end

    # Electrolyte
    elyte_map = maps[string(elyte)].cellmap
    elytemodel = submodels[Symbol(elyte)]
    elyte_volumetric_heat_capacity = effective_electrolyte_heat_capacity(elytemodel, cell_parameters[string(elyte)])
    elyte_thermal_conductivity = effective_electrolyte_thermal_conductivity(elytemodel, cell_parameters[string(elyte)], cell_parameters[string(sep)])
    volumetric_heat_capacity[elyte_map] .+= elyte_volumetric_heat_capacity
    thermal_conductivity[elyte_map] .+= elyte_thermal_conductivity

    # Separator
    sep_map = maps[string(sep)].cellmap


    sep_volumetric_heat_capacity = effective_separator_heat_capacity(cell_parameters[string(sep)])
    sep_thermal_conductivity = effective_separator_thermal_conductivity(cell_parameters[string(sep)])

    volumetric_heat_capacity[sep_map] .+= sep_volumetric_heat_capacity
    thermal_conductivity[sep_map] .+= sep_thermal_conductivity


    # setup the parameters (for each model, some parameters are declared, which gives the possibility to compute
    # sensitivities)

    prm = JutulStorage()
    prm[:BoundaryTemperature] = input.cycling_protocol["AmbientTemperature"]
    prm[:SurfaceHeatTransferCoefficient] = cell_parameters["Cell"]["SurfaceHeatTransferCoefficient"]
    prm[:EffectiveVolumetricHeatCapacity] = volumetric_heat_capacity
    prm[:EffectiveThermalConductivity] = thermal_conductivity

    prm_dict = Dict{Symbol, Any}()
    prm_dict[:BoundaryTemperature] = input.cycling_protocol["AmbientTemperature"]
    prm_dict[:SurfaceHeatTransferCoefficient] = cell_parameters["Cell"]["SurfaceHeatTransferCoefficient"]
    prm_dict[:EffectiveVolumetricHeatCapacity] = volumetric_heat_capacity
    prm_dict[:EffectiveThermalConductivity] = thermal_conductivity

    # Setup system

    thermalsystem = ThermalSystem(prm)

    model = setup_component(global_grid, thermalsystem)

    parameters = setup_parameters(model, prm_dict)

    # parameters[:Source]                   .= parameters[:Source].*parameters[:Volume]
    parameters[:SurfaceHeatTransferCoefficient] .= model.domain.representation[:boundary_areas] .* parameters[:SurfaceHeatTransferCoefficient]

    return model, parameters

end

function setup_thermal_model(input, grids)

    cell_parameters = input.cell_parameters

    grid = grids["ThermalModel"]
    nc = Jutul.number_of_cells(grid)
    thermal_parameters = cell_parameters["ThermalModel"]

    # setup the parameters (for each model, some parameters are declared, which gives the possibility to compute
    # sensitivities)

    prm = Dict{Symbol, Any}()
    prm[:BoundaryTemperature] = input.cycling_protocol["ExternalTemperature"]
    prm[:ExternalHeatTransferCoefficient] = thermal_parameters["ExternalHeatTransferCoefficient"]

    prm[:EffectiveVolumetricHeatCapacity] = thermal_parameters["EffectiveVolumetricHeatCapacity"]

    prm[:EffectiveThermalConductivity] = thermal_parameters["EffectiveThermalConductivity"]

    thermalsystem = ThermalSystem(JutulStorage(prm))
    model = setup_component(grid, thermalsystem)
    parameters = setup_parameters(model, prm)

    # parameters[:Source]                   .= parameters[:Source].*parameters[:Volume]
    parameters[:SurfaceHeatTransferCoefficient] .= model.domain.representation[:boundary_areas] .* parameters[:SurfaceHeatTransferCoefficient]

    return model, parameters

end

function temperature_cell_maps(global_maps, parameters)
    out = Dict{Symbol, Vector{Int}}()
    for (k, v) in pairs(parameters)
        if haskey(v, :Temperature)
            out[k] = global_maps[String(k)].cellmap
        end
    end
    return out
end

function setup_thermal_state0(thermal_model, tcellmaps, parameters)
    nc = number_of_cells(thermal_model.domain)
    T0 = zeros(nc)
    for (k, cells) in pairs(tcellmaps)
        subT = parameters[k][:Temperature]
        T0[cells] .= subT
    end
    return setup_state(thermal_model, Temperature = T0)
end

function setup_thermal_post_ministep_hook(model, input, base_hook = missing; Temperature = missing, info_level = -1, kwarg...)
    model = deepcopy(model)
    s = Simulation(model, input.cell_parameters, input.cycling_protocol; simulation_settings = input.simulation_settings)
    # thermal_model, thermal_parameters = setup_thermal_model(input, s.grids)
    submodels = model.multimodel.models
    thermal_model, thermal_parameters = BattMo.setup_thermal_model(model, submodels, input, s.grids, s.global_maps)
    maps = s.global_maps

    tcellmaps = temperature_cell_maps(maps, s.parameters)
    if ismissing(Temperature)
        # We copy it from parameters of the simulation
        thermal_state0 = setup_thermal_state0(thermal_model, tcellmaps, s.parameters)
    else
        # We set it up as requested (possibly a bit inconsistent with what the
        # model will be initialized with). The thermal model will overwrite the
        # parameters during the simulation.
        thermal_state0 = setup_state(thermal_model, Temperature = Temperature)
    end

    thermal_sim = Simulator(
        thermal_model;
        state0 = thermal_state0,
        parameters = thermal_parameters,
        copy_state = true,
    )
    thermal_cfg = simulator_config(thermal_sim; info_level = info_level, kwarg...)

    return function thermal_post_hook(done, report, sim, dt, forces, max_iter, cfg)
        if done
            state = sim.storage.state0
            src, stepsources = BattMo.get_energy_source_by_type!(thermal_model, s.model, state, maps)
            tforce = (value = src,)
            Jutul.solve_timestep!(thermal_sim, dt, tforce, thermal_cfg[:max_nonlinear_iterations], thermal_cfg)
        end
        # Next: Copy over the temperature
        for (submodel_key, cells) in pairs(tcellmaps)
            sub_T = sim.storage[submodel_key].parameters.Temperature
            sub_T .= Jutul.value(thermal_sim.storage.state.Temperature[cells])
            # println("Updated $submodel_key: $(sum(sub_T)/length(sub_T))")
        end
        if !ismissing(base_hook)
            done, report = base_hook(done, report, sim, dt, forces, max_iter, cfg)
        end
        return (done, report)
    end
    # src, stepsources = BattMo.get_energy_source_by_type!(thermal_model, model, state, maps)
end


###########################################
# The following two setups are not working

# function setup_thermal_model(::Val{:simple}, inputparams::AdditionaInputFormats; N = 2, Nz = 10)

# 	grid = CartesianMesh((N, N, Nz), (1.0, 1.0, 1.0))
# 	grid = UnstructuredMesh(grid)

# 	sys = ThermalSystem()

# 	domain = DataDomain(grid)

# 	# operators only, use geometry, not property
# 	k = ones(number_of_cells(grid))

# 	T    = compute_face_trans(domain, k)
# 	T_hf = compute_half_face_trans(domain, k)
# 	T_b  = compute_boundary_trans(domain, k)

# 	domain[:trans, Faces()]           = T
# 	domain[:halfTrans, HalfFaces()]   = T_hf
# 	domain[:bcTrans, BoundaryFaces()] = T_b

# 	flow = PotentialFlow(grid)

# 	disc = (flow = flow,)
# 	domain = DiscretizedDomain(domain, disc)

# 	model = SimulationModel(domain, sys)

# 	prm                                   = Dict{Symbol, Any}()
# 	prm[:EffectiveVolumetricHeatCapacity]                        = inputparams["ThermalModel"]["capacity"]
# 	prm[:EffectiveThermalConductivity]                    = inputparams["ThermalModel"]["conductivity"]
# 	prm[:BoundaryTemperature]             = inputparams["ThermalModel"]["externalTemperature"]
# 	prm[:SurfaceHeatTransferCoefficient] = inputparams["ThermalModel"]["externalHeatTransferCoefficient"]

# 	parameters = setup_parameters(model, prm)

# 	parameters[:SurfaceHeatTransferCoefficient] .= model.domain.representation[:boundary_areas] .* parameters[:SurfaceHeatTransferCoefficient]

# 	vertfaces = [findBoundary(grid, 1, true); findBoundary(grid, 1, false)]
# 	vertfaces = append!(vertfaces, [findBoundary(grid, 2, true); findBoundary(grid, 2, false)])
# 	parameters[:SurfaceHeatTransferCoefficient][vertfaces] .= 0

# 	return model, parameters

# end


# function setup_thermal_model(inputparams::AdditionaInputFormats;
# 	general_ad = true,
# 	kwargs...)

# 	grids, = setup_grids_and_couplings(inputparams)

# 	grid = grids["ThermalModel"]

# 	thermalsystem = ThermalSystem()


# 	model = setup_component(grid, thermalsystem;
# 		general_ad = general_ad)


# 	# setup the parameters (for each model, some parameters are declared, which gives the possibility to compute
# 	# sensitivities)

# 	prm                                   = Dict{Symbol, Any}()
# 	prm[:EffectiveVolumetricHeatCapacity]                        = inputparams["ThermalModel"]["capacity"]
# 	prm[:EffectiveThermalConductivity]                    = inputparams["ThermalModel"]["conductivity"]
# 	prm[:BoundaryTemperature]             = inputparams["ThermalModel"]["externalTemperature"]
# 	prm[:SurfaceHeatTransferCoefficient] = inputparams["ThermalModel"]["externalHeatTransferCoefficient"]

# 	parameters = setup_parameters(model, prm)

# 	# parameters[:Source]                   .= parameters[:Source].*parameters[:Volume]
# 	parameters[:SurfaceHeatTransferCoefficient] .= model.domain.representation[:boundary_areas] .* parameters[:SurfaceHeatTransferCoefficient]

# 	return model, parameters

# end
