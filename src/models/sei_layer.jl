##################
# SEI model type #
##################

# Create a type for the model with SEI layer. It will be used to specialize the function
SEImodel = SimulationModel{O, S, F, C} where {O <: JutulDomain,
                                             S <: BattMo.ActiveMaterialP2D{:sei, D, T} where {D, T},
                                             F<: Jutul.JutulFormulation,
                                             C<: Jutul.JutulContext}

##################################################
# Variable for SEI model added to ActiveMaterial #
##################################################

struct normalizedSEIlength      <: ScalarVariable end
struct normalizedSEIvoltageDrop <: ScalarVariable end
struct SEIlength                <: ScalarVariable end
struct SEIvoltageDrop           <: ScalarVariable end


###################################################
# Equations for SEI model added to ActiveMaterial #
###################################################

# SEI mass conservation equation

struct SEImassCons <: JutulEquation end

Jutul.local_discretization(::SEImassCons, i) = nothing

function Jutul.number_of_equations_per_entity(model::SEImodel, ::SEImassCons)
    return 1
end

# SEI voltage drop equation

struct SEIvoltageDropEquation <: JutulEquation end
Jutul.local_discretization(::SEIvoltageDropEquation, i) = nothing

function Jutul.number_of_equations_per_entity(model::SEImodel, ::SEIvoltageDropEquation)
    return 1
end


###################################
# Declare variables for sei model #
###################################

function select_primary_variables!(S,
                                   system::ActiveMaterialP2D,
                                   model::SEImodel
                                   )
    
    S[:Phi]                      = Phi()
    S[:Cp]                       = Cp()
    S[:Cs]                       = Cs()
    S[:normalizedSEIlength]      = normalizedSEIlength()
    S[:normalizedSEIvoltageDrop] = normalizedSEIvoltageDrop()
    
end



function select_secondary_variables!(S,
                                     system::ActiveMaterialP2D,
                                     model::SEImodel
                                     )
    
    S[:Charge]            = Charge()
    S[:Ocp]               = Ocp()
    S[:ReactionRateConst] = ReactionRateConst()
    S[:SolidDiffFlux]     = SolidDiffFlux()
    S[:SEIlength]         = SEIlength()
    S[:SEIvoltageDrop]    = SEIvoltageDrop()
    
end

###################################
# Declare equations for sei model #
###################################

function select_equations!(eqs,
                           system::ActiveMaterialP2D,
                           model::SEImodel
                           )
    disc = model.domain.discretizations.charge_flow
    eqs[:charge_conservation] = ConservationLaw(disc, :Charge)
    eqs[:mass_conservation]   = SolidMassCons()
    eqs[:solid_diffusion_bc]  = SolidDiffusionBc()
    eqs[:sei_mass_cons]       = SEImassCons()
    eqs[:sei_voltage_drop]    = SEIvoltageDropEquation()
    
end

function Jutul.update_equation_in_entity!(eq_buf           ,
                                          self_cell        ,
                                          state            ,
                                          state0           ,
                                          eq::SEImassCons  ,
                                          model            ,
                                          dt               ,
                                          ldisc = nothing)
    # do nothing
end

function Jutul.update_equation_in_entity!(eq_buf                    ,
                                          self_cell                 ,
                                          state                     ,
                                          state0                    ,
                                          eq::SEIvoltageDropEquation,
                                          model                     ,
                                          dt                        ,
                                          ldisc = nothing)
    # do nothing    
end

function apply_bc_to_equation!(storage, parameters, model::SEImodel, eq::SEImassCons, eq_s)
    # do nothing
end

function apply_bc_to_equation!(storage, parameters, model::SEImodel, eq::SEIvoltageDropEquation, eq_s)
    # do nothing
end

##############################
# update secondary variables #
##############################

@jutul_secondary(
    function update_vocp!(SEIlength,
                          tv::SEIlength,
                          model::SEImodel,
                          normalizedSEIlength,
                          ix
                          )

        scaling = model.system.params[:SEIlengthRef]
        
        for cell in ix
            @inbounds SEIlength[cell] = scaling*normalizedSEIlength[cell]
        end
        
    end
)

@jutul_secondary(
    function update_vocp!(SEIvoltageDrop,
                          tv::SEIvoltageDrop,
                          model::SEImodel,
                          normalizedSEIvoltageDrop,
                          ix
                          )

        scaling = model.system.params[:SEIvoltageDropRef]
        for cell in ix
            @inbounds SEIvoltageDrop[cell] = scaling*normalizedSEIvoltageDrop[cell]
        end
    end
)


###################################
# setup update of the cross terms #
###################################

function Jutul.update_cross_term_in_entity!(out                            ,
                                            ind                            ,
                                            state_t                        ,
                                            state0_t                       ,
                                            state_s                        ,
                                            state0_s                       , 
                                            model_t                        ,
                                            model_s::SEImodel              ,
                                            ct::ButlerVolmerActmatToElyteCT,
                                            eq                             ,
                                            dt                             ,
                                            ldisc = Jutul.local_discretization(ct, ind)
                                            )

    activematerial = model_s.system
    electrolyte    = model_t.system
    
    n   = activematerial.params[:n_charge_carriers]
    vsa = activematerial.params[:volumetric_surface_area]
    
    ind_t = ct.target_cells[ind]
    ind_s = ct.source_cells[ind]

    phi_a = state_s.Phi[ind_s]  
    seiU  = state_s.SEIvoltageDrop[ind_s]
    ocp   = state_s.Ocp[ind_s]
    R0    = state_s.ReactionRateConst[ind_s]
    c_a   = state_s.Cs[ind_s]
    T     = state_s.Temperature[ind_s]

    vols  = state_t.Volume[ind_t]
    phi_e = state_t.Phi[ind_t]
    c_e   = state_t.C[ind_t]
    
    # overpotential include SEI voltage drop
    eta = phi_a - phi_e - ocp - seiU
    
    R = reaction_rate(eta           ,
                      c_a           ,
                      R0            ,
                      T             ,
                      c_e           ,
                      activematerial,
                      electrolyte)
    
    cs = conserved_symbol(eq)
    
    if cs == :Mass
        v = 1.0*vols*vsa*R
    else
        @assert cs == :Charge
        v = 1.0*vols*vsa*R*n*FARADAY_CONSTANT
    end
    out[] = -v
    
end


function Jutul.update_cross_term_in_entity!(out                            ,
                                            ind                            ,
                                            state_t                        ,
                                            state0_t                       ,
                                            state_s                        ,
                                            state0_s                       , 
                                            model_t::SEImodel              ,
                                            model_s                        ,
                                            ct::ButlerVolmerElyteToActmatCT,
                                            eq                             ,
                                            dt                             ,
                                            ldisc = Jutul.local_discretization(ct, ind)
                                            )

    electrolyte    = model_s.system
    activematerial = model_t.system
    
    n   = activematerial.params[:n_charge_carriers]
    vsa = activematerial.params[:volumetric_surface_area]
    
    ind_t = ct.target_cells[ind]
    ind_s = ct.source_cells[ind]

    phi_e = state_s.Phi[ind_s]
    c_e   = state_s.C[ind_s]

    vols  = state_t.Volume[ind_t]
    c_a   = state_t.Cs[ind_t]
    phi_a = state_t.Phi[ind_t]  
    seiU  = state_t.SEIvoltageDrop[ind_t]
    ocp   = state_t.Ocp[ind_t]
    R0    = state_t.ReactionRateConst[ind_t]
    T     = state_t.Temperature[ind_t]

    # overpotential include SEI voltage drop
    eta = phi_a - phi_e - ocp - seiU
    
    R = reaction_rate(eta           ,
                      c_a           ,
                      R0            ,
                      T             ,
                      c_e           ,
                      activematerial,
                      electrolyte)
    
    if eq isa SolidDiffusionBc

        rp  = activematerial.discretization[:rp] # particle radius
        vf  = state_t.VolumeFraction[ind_t]
        avf = activematerial.params.volume_fractions[1]
        
        v = vsa*R*(4*pi*rp^3)/(3*vf*avf)
        
        out[] = -v
        
    else
        
        cs = conserved_symbol(eq)
        @assert cs == :Charge
        v = 1.0*vols*vsa*R*n*FARADAY_CONSTANT

        out[] = v
        
    end
    
end

#################################################
# update the equations that are specific to SEI #
#################################################

function Jutul.update_cross_term_in_entity!(out                            ,
                                            ind                            ,
                                            state_t                        ,
                                            state0_t                       ,
                                            state_s                        ,
                                            state0_s                       , 
                                            model_t::SEImodel              ,
                                            model_s                        ,
                                            ct::ButlerVolmerElyteToActmatCT,
                                            eq::SEImassCons                ,
                                            dt                             ,
                                            ldisc = Jutul.local_discretization(ct, ind)
                                            )

    F = FARADAY_CONSTANT
    R = GAS_CONSTANT
    
    params = model_t.system.params

    s    = params[:SEIstoichiometricCoefficient]
    V    = params[:SEImolarVolume]
    De   = params[:SEIelectronicDiffusionCoefficient]
    ce0  = params[:SEIintersticialConcentration]
    Lref = params[:SEIlengthInitial]
    
    ind_t = ct.target_cells[ind]
    ind_s = ct.source_cells[ind]
    
    L0 = state0_t.SEIlength[ind_t]
    
    L     = state_t.SEIlength[ind_t]
    T     = state_t.Temperature[ind_t]
    phi_a = state_t.Phi[ind_t]
    Usei  = state_t.SEIvoltageDrop[ind_t]
    L     = state_t.SEIlength[ind_t]
    
    phi_e = state_s.Phi[ind_s]

    # compute SEI flux (called N)
    eta = phi_e - phi_a - Usei
    
    N = De*ce0/L*exp(-(F/(R*T))*eta)*(1 - (F/(2*R*T))*Usei)

    # Evolution equation for the SEI length
    out[] = (s/V)*(L - L0)/dt - N
    
end

function Jutul.update_cross_term_in_entity!(out                            ,
                                            ind                            ,
                                            state_t                        ,
                                            state0_t                       ,
                                            state_s                        ,
                                            state0_s                       , 
                                            model_t::SEImodel              ,
                                            model_s                        ,
                                            ct::ButlerVolmerElyteToActmatCT,
                                            eq::SEIvoltageDropEquation     ,
                                            dt                             ,
                                            ldisc = Jutul.local_discretization(ct, ind)
                                            )

    F = FARADAY_CONSTANT

    electrolyte    = model_s.system
    activematerial = model_t.system
    params         = activematerial.params
    
    k   = params[:SEIionicConductivity]
    
    ind_t = ct.target_cells[ind]
    ind_s = ct.source_cells[ind]

    phi_a = state_t.Phi[ind_t]  
    seiU  = state_t.SEIvoltageDrop[ind_t]
    ocp   = state_t.Ocp[ind_t]
    R0    = state_t.ReactionRateConst[ind_t]
    c_a   = state_t.Cs[ind_t]
    T     = state_t.Temperature[ind_t]
    L     = state_t.SEIlength[ind_t]
    
    phi_e = state_s.Phi[ind_s]
    c_e   = state_s.C[ind_s]

    # Overpotential definition  includes SEI voltage drop
    eta = phi_a - phi_e - ocp - seiU
    
    R = reaction_rate(eta           ,
                      c_a           ,
                      R0            ,
                      T             ,
                      c_e           ,
                      activematerial,
                      electrolyte)
    
    # Definition of the SEI voltage drop is implicit (because reaction rate R depends on seiU) and is given as follow
    out[] = seiU - F*R*L/k
    
end
