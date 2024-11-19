struct Source <: ScalarVariable end
struct Capacity <: ScalarVariable end

const ThermalParameters = JutulStorage

struct ThermalSystem{T} <: BattMoSystem where {T<:ThermalParameters}
    params::T
end

function ThermalSystem(params::ThermalParameters)
    params = Jutul.convert_to_immutable_storage(params)
    return ThermalSystem{typeof(params)}(params)
end

function ThermalSystem()
    ThermalSystem(Dict())
end

const ThermalModel = SimulationModel{O, S ,F, C} where {O<:JutulDomain, S<:ThermalSystem, F<:JutulFormulation, C<:JutulContext}

function Jutul.update_equation_in_entity!(eq_buf::AbstractVector{T_e}, self_cell, state, state0, eq::ConservationLaw{:Energy}, model::ThermalModel, Δt, ldisc = Jutul.local_discretization(eq, self_cell)) where T_e
    # Compute accumulation term
    conserved = Jutul.conserved_symbol(eq)
    M₀ = state0[conserved]
    M = state[conserved]
    # Compute ∇⋅V
    disc = eq.flow_discretization
    flux(face) = Jutul.face_flux(face, eq, state, model, Δt, disc, ldisc, Val(T_e))
    div_v = ldisc.div(flux)
    for i in eachindex(div_v)
        ∂M∂t = Jutul.accumulation_term(M, M₀, Δt, i, self_cell)
        @inbounds eq_buf[i] = ∂M∂t + div_v[i] + state[:Source][i]
    end
end

function select_minimum_output_variables!(out,
    system::ThermalSystem, model::SimulationModel
    )
    push!(out, :Temperature)
end

function select_primary_variables!(
    S, system::ThermalSystem, model::SimulationModel
    )
    S[:Temperature] = Temperature()
end

function select_secondary_variables!(
    S, system::ThermalSystem, model::SimulationModel
    )
    S[:Energy] = Energy()
end

@jutul_secondary function update_energy!(acc        ,
                                         tv::Energy ,
                                         model      ,
                                         Temperature,
                                         Volume,
                                         Capacity,
                                         ix)
    for i in ix
        @inbounds acc[i] = Volume[i]*Capacity[i]*Temperature[i]
    end
    
end

function select_parameters!(S,
                            system::ThermalSystem,
                            model::BattMoModel)

    S[:Conductivity]        = Conductivity()
    S[:Capacity]            = Capacity()
    S[:Source]              = Source()
    S[:BoundaryTemperature] = BoundaryTemperature() # BoundaryTemperature is declared below
    
end


function Jutul.face_flux!(::T, c, other, face, face_sign, eq::ConservationLaw{:Temperature, <:Any}, state, model::ThermalModel, dt, flow_disc) where T
    
    @inbounds trans = state.ECTransmissibilities[face]
    j = - half_face_two_point_kgrad(c, other, trans, state.Temperature, state.Conductivity)

    return T(j)
    
end


function select_equations!(eqs,
                           system::ThermalSystem,
                           model::SimulationModel)

    disc = model.domain.discretizations.heat_flow
    eqs[:energy_conservation] = ConservationLaw(disc, :Energy)
    
end

#######################
# Boundary conditions #
#######################

struct BoundaryTemperature <: ScalarVariable end
struct BoundaryThermalFaces <: Jutul.JutulEntity end

Jutul.associated_entity(::BoundaryTemperature) = BoundaryThermalFaces()

function apply_bc_to_equation!(storage, parameters, model::ThermalModel, eq::ConservationLaw{:Energy}, eq_s)
    
    acc   = get_diagonal_entries(eq, eq_s)
    state = storage.state

    apply_boundary_potential!(acc, state, parameters, model, eq)

end

function apply_boundary_potential!(acc, state, parameters, model::ThermalModel, eq::ConservationLaw{:Energy})

    dolegacy = false
    
    if model.domain.representation isa MinimalECTPFAGrid
        bc = model.domain.representation.boundary_cells
        if length(bc) > 0
            dobc = true
        else
            dobc = false
        end
        dolegacy = true
    elseif Jutul.hasentity(model.domain, BoundaryDirichletFaces())
        nc = count_active_entities(model.domain, BoundaryDirichletFaces())
        dobc = nc > 0
        if dobc
            bcdirhalftrans = model.domain.representation[:bcDirHalfTrans]
            bcdircells     = model.domain.representation[:bcDirCells]
            bcdirinds      = model.domain.representation[:bcDirInds]
        end
    else
        dobc = false
    end
    
    if dobc
        
        T            = state[:Temperature]
        BoundaryT    = state[:BoundaryTemperature]
        conductivity = state[:Conductivity]
        extcoef      = state[:ExternalHeatTransferCoefficient]
        
        if dolegacy
            T_hf = model.domain.representation.boundary_hfT
            for (i, c) in enumerate(bc)
                m = 1/(1/conductivity[c]*T_hf[i] + 1/extcoef)
                @inbounds acc[c] += m*(T[c] - value(BoundaryT[i]))
            end
        else
            for (ht, c, i) in zip(bcdirhalftrans, bcdircells, bcdirinds)
                m = 1/(1/conductivity[c]*ht[i] + 1/extcoef)
                @inbounds acc[c] += m*(T[c] - value(BoundaryT[i]))
            end
        end
    end
    
end

#######################
# setup thermal model #
#######################

function setup_thermal_model(inputparams::InputParams;
                             general_ad = true,
                             kwargs...)

    grids, couplings = setup_grids_and_couplings(inputparams)
    
    grid     = grids["ThermalModel"]
    coupling = couplings["ThermalModel"]["External"]

    thermalsystem = ThermalSystem()

    model = setup_component(grid, thermalsystem;
                            general_ad = general_ad)

    domain = model.domain.representation
    
    bfaces = coupling["boundaryfaces"]
    nb = size(bfaces,1)
    domain.entities[BoundaryThermalFaces()] =  nb

    bcDirFace = coupling["boundaryfaces"] # in BoundaryFaces indexing
    bcDirCell = coupling["cells"]
    
    bcDirInd  = Vector{Int64}(1 : nb)
    domain[:boundaryThermalHalfTrans, BoundaryThermalFaces()] = domain[:bcTrans][bcDirFace]
    domain[:boundaryThermalCells, BoundaryThermalFaces()]     = bcDirCell 
    domain[:boundaryThermalInds, BoundaryThermalFaces()]      = bcDirInd 
            
    # setup the parameters (for each model, some parameters are declared, which gives the possibility to compute
    # sensitivities)

    prm = Dict{Symbol, Any}()
    prm[:Capacity]            = inputparams["ThermalModel"]["capacity"]
    prm[:Conductivity]        = inputparams["ThermalModel"]["conductivity"]
    prm[:Source]              = inputparams["ThermalModel"]["source"]
    prm[:BoundaryTemperature] = inputparams["ThermalModel"]["externalTemperature"]

    parameters = setup_parameters(model, prm)
    
    return model, parameters

end
