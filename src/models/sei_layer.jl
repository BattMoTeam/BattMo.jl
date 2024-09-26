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

struct SEImassCons <: JutulEquation end
Jutul.local_discretization(::SEImassCons, i) = nothing

struct SEIvoltageDropEquation <: JutulEquation end
Jutul.local_discretization(::SEIvoltageDropEquation, i) = nothing

# The equations are both of cross-term type

struct SEImassConsCT{T} <: Jutul.AdditiveCrossTerm
    target_cells::T
    source_cells::T
end

struct SEIvoltageDropEquationCT{T} <: Jutul.AdditiveCrossTerm
    target_cells::T
    source_cells::T
end

# Create a type for the model with SEI layer. It will be used to specialize the function
SeiModel = SimulationModel{O, BattMo.ActiveMaterialP2D{:sei, D, T}, F, C} where {O <: JutulDomain,
                                                                                 D<: BattMo.SolidDiffusionDiscretization,
                                                                                 T<: BattMo.ActiveMaterialParameters,
                                                                                 F<: Jutul.JutulFormulation,
                                                                                 C<: Jutul.JutulContext}

###################################
# Declare variables for sei model #
###################################

function select_primary_variables!(S,
                                   system,
                                   model::SeiModel
                                   )
    
    S[:Phi]                      = Phi()
    S[:Cp]                       = Cp()
    S[:Cs]                       = Cs()
    S[:normalizedSEIlength]      = normalizedSEIlength()
    S[:normalizedSEIvoltageDrop] = normalizedSEIvoltageDrop()
    
end



function select_secondary_variables!(S,
                                     system,
                                     model::SeiModel
                                     )
    
    S[:Charge]            = Charge()
    S[:Ocp]               = Ocp()
    S[:ReactionRateConst] = ReactionRateConst()
    S[:SolidDiffFlux]     = SolidDiffFlux()
    S[:SEIlength]         = SEIlength()
    S[:SEIvoltageDrop]    = SEIvoltageDrop()
    
end

##############################
# update secondary variables #
##############################

@jutul_secondary(
    function update_vocp!(SEIlength,
                          tv::SEIlength,
                          model::SeiModel,
                          normalizedSEIlength,
                          ix
                          ) where {D, T}

        scaling = model.system.params[:sei_length_scaling]
        
        for cell in ix
            @inbounds SEIlength[cell] = scaling*normalizedSEIlength[cell]
        end
        
    end
)

@jutul_secondary(
    function update_vocp!(SEIvoltageDrop,
                          tv::SEIvoltageDrop,
                          model::SeiModel,
                          normalizedSEIvoltageDrop,
                          ix
                          ) where {D, T}

        scaling = model.system.params[:sei_voltage_drop_scaling]
        
        for cell in ix
            @inbounds SEIvoltageDrop[cell] = scaling*normalizedSEIvoltageDrop[cell]
        end
        
    end
)


############################
# Setup of the cross-terms #
############################

Jutul.cross_term_entities(ct::SEImassConsCT, eq::Jutul.JutulEquation, model)        = ct.target_cells
Jutul.cross_term_entities_source(ct::SEImassConsCT, eq::Jutul.JutulEquation, model) = ct.source_cells


Jutul.cross_term_entities(ct::SEIvoltageDropEquationCT, eq::Jutul.JutulEquation, model)        = ct.target_cells
Jutul.cross_term_entities_source(ct::SEIvoltageDropEquationCT, eq::Jutul.JutulEquation, model) = ct.source_cells


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
                                            model_s::SeiModel              ,
                                            ct::ButlerVolmerActmatToElyteCT,
                                            eq                             ,
                                            dt                             ,
                                            ldisc = Jutul.local_discretization(ct, ind)
                                            )

    activematerial = model_s.system
    electrolyte    = model_t.system
    
    n = activematerial.params[:n_charge_carriers]
    
    ind_t = ct.target_cells[ind]
    ind_s = ct.source_cells[ind]

    vols  = state_t.Volume[ind_t]

    phi_e = state_t.Phi[ind_t]
    phi_a = state_s.Phi[ind_s]  
    seiU  = state_s.SEIvoltageDrop[ind_s]
    ocp   = state_s.Ocp[ind_s]
    R0    = state_s.ReactionRateConst[ind_s]
    c_e   = state_t.C[ind_t]
    c_a   = state_s.Cs[ind_s]
    T     = state_s.Temperature[ind_s]

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
        v = 1.0*vols*R
    else
        @assert cs == :Charge
        v = 1.0*vols*R*n*FARADAY_CONSTANT
    end
    out[] = -v
    
end


Jutul.cross_term_entities(ct::ButlerVolmerElyteToActmatCT, eq::Jutul.JutulEquation, model)        = ct.target_cells
Jutul.cross_term_entities_source(ct::ButlerVolmerElyteToActmatCT, eq::Jutul.JutulEquation, model) = ct.source_cells

function Jutul.update_cross_term_in_entity!(out                            ,
                                            ind                            ,
                                            state_t                        ,
                                            state0_t                       ,
                                            state_s                        ,
                                            state0_s                       , 
                                            model_t::SeiModel              ,
                                            model_s                        ,
                                            ct::ButlerVolmerElyteToActmatCT,
                                            eq                             ,
                                            dt                             ,
                                            ldisc = Jutul.local_discretization(ct, ind)
                                            )

    electrolyte    = model_s.system
    activematerial = model_t.system
    
    n = activematerial.params[:n_charge_carriers]

    ind_t = ct.target_cells[ind]
    ind_s = ct.source_cells[ind]

    vols  = state_t.Volume[ind_t]

    phi_e = state_s.Phi[ind_s]
    phi_a = state_t.Phi[ind_t]  
    seiU  = state_t.SEIvoltageDrop[ind_s]
    ocp   = state_t.Ocp[ind_t]
    R0    = state_t.ReactionRateConst[ind_t]
    c_e   = state_s.C[ind_s]
    c_a   = state_t.Cs[ind_t]
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
        
        v = R*(4*pi*rp^3)/(3*vf*avf)
        
        out[] = -v
        
    else
        
        cs = conserved_symbol(eq)
        @assert cs == :Charge
        v = 1.0*vols*R*n*FARADAY_CONSTANT

        out[] = v
        
    end
    
end


############################
# update equations for SEI #
############################



function Jutul.update_cross_term_in_entity!(out                            ,
                                            ind                            ,
                                            state_t                        ,
                                            state0_t                       ,
                                            state_s                        ,
                                            state0_s                       , 
                                            model_t::SeiModel              ,
                                            model_s                        ,
                                            ct::SEImassConsCT              ,
                                            eq                             ,
                                            dt                             ,
                                            ldisc = Jutul.local_discretization(ct, ind)
                                            )

    F = FARADAY_CONSTANT
    R = GAS_CONSTANT
    
    params = model_t.system.params

    s   = params[:SEIstoichiometryCoefficient]
    V   = params[:SEImolarVolume]
    De  = params[:SEIelectronicDiffusionCoefficient]
    ce0 = params[:SEIintersticialConcentration]

    ind_t = ct.target_cells[ind]
    ind_s = ct.source_cells[ind]
    
    L0 = state0_t.Length[ind_t]

    L     = state_t.Length[ind_t]
    T     = state_t.temperature[ind_t]
    phi_a = state_t.phiElectrode[ind_t]
    Usei  = state_t.SEIvoltageDrop[ind_t]
    L     = state_t.SEIlength[ind_t]
    
    phi_e = state_s.phiElectrolyte[ind_s]

    # compute SEI flux (called N)
    eta = phiElectrode - phiElectrolyte - Usei
    
    N = De*ce0/L*exp(-(F/(R*T))*eta)*(1 - (F/(2*R*T))*Usei)

    # Evolution equation for the SEI length
    out[] = (s/V)*(L - L0)/dt - N
    
end

function Jutul.update_cross_term_in_entity!(out                       ,
                                            ind                       ,
                                            state_t                   ,
                                            state0_t                  ,
                                            state_s                   ,
                                            state0_s                  , 
                                            model_t::SeiModel         ,
                                            model_s                   ,
                                            ct::SEIvoltageDropEquation,
                                            eq                        ,
                                            dt                        ,
                                            ldisc = Jutul.local_discretization(ct, ind)
                                            )

    F = FARADAY_CONSTANT

    params = model_t.system.params
    
    k   = params[:SEIionicConductivity]
    
    ind_t = ct.target_cells[ind]
    ind_s = ct.source_cells[ind]

    vols  = state_t.Volume[ind_t]
    phi_a = state_t.Phi[ind_t]  
    seiU  = state_t.SEIvoltageDrop[ind_s]
    ocp   = state_t.Ocp[ind_t]
    R0    = state_t.ReactionRateConst[ind_t]
    c_a   = state_t.Cs[ind_t]
    T     = state_t.Temperature[ind_t]
    L     = state_t.Length[ind_t]
    
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
