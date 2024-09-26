##########################
# Variable for SEI model #
##########################

struct normalizedSEIlength      <: ScalarVariable end
struct normalizedSEIvoltageDrop <: ScalarVariable end
struct SEIlength                <: ScalarVariable end
struct SEIvoltageDrop           <: ScalarVariable end
struct SEIflux                  <: ScalarVariable end

###########################
# Equations for SEI model #
###########################

struct SEImassCons <: JutulEquation end
Jutul.local_discretization(::SEImassCons, i) = nothing

struct SEIvoltageDropEquation <: JutulEquation end
Jutul.local_discretization(::SEIvoltageDropEquation, i) = nothing

#############################
# setup sei active material #
#############################

function select_primary_variables!(S,
                                   system::ActiveMaterialP2D{:sei, D, T},
                                   model::SimulationModel
                                   ) where {D, T}
    
    S[:Phi]                      = Phi()
    S[:Cp]                       = Cp()
    S[:Cs]                       = Cs()
    S[:normalizedSEIvoltageDrop] = normalizedSEIvoltageDrop()
    S[:normalizedSEIlength]      = normalizedSEIlength()
    
end



function select_secondary_variables!(S,
                                     system::ActiveMaterialP2D{:sei, D, T},
                                     model::SimulationModel
                                     ) where {D, T}
    
    S[:Charge]            = Charge()
    S[:Ocp]               = Ocp()
    S[:ReactionRateConst] = ReactionRateConst()
    S[:SolidDiffFlux]     = SolidDiffFlux()
    S[:SEIflux]           = SEIflux()
    
end

##############################
# update secondary variables #
##############################

@jutul_secondary(
    function update_vocp!(SEIflux,
                          tv::SEIflux,
                          model:: SimulationModel{<:Any, ActiveMaterialP2D{:sei, D, T}, <:Any, <:Any},
                          Cs,
                          ix
                          ) where {D, T}
        
        for cell in ix
            @inbounds SEIflux[cell] = Cs[cell]
        end
        
    end
)

#########################################
# update equations specific to SEI case #
#########################################

function update_equation_in_entity!(eq_buf,
                                    self_cell,
                                    state,
                                    state0,
                                    eq::SEImassCons,
                                    model,
                                    dt,
                                    ldisc = nothing)
    params = model.system.params

    s = params[:SEIstoichiometryCoefficient]
    V = params[:SEImolarVolume]

    N  = state.SEIflux[self_cell]
    L  = state.Length[self_cell]
    L0 = state0.Length[self_cell]

    eq_buf[] = s/V*(L - L0)/dt - N
    
end

function update_equation_in_entity!(eq_buf,
                                    self_cell,
                                    state,
                                    state0,
                                    eq::SEIvoltageDropEquation,
                                    model,
                                    dt,
                                    ldisc = nothing)
    
    params = model.system.params

    F = FARADAY_CONSTANT
    k = params[:SEIionicConductivity]
    V = params[:SEImolarVolume]

    N  = state.SEIflux[self_cell]
    L  = state.Length[self_cell]
    L0 = state0.Length[self_cell]

    eq_buf[] = s/V*(L - L0)/dt - N
    
end


