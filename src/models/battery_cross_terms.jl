
Jutul.symmetry(::TPFAInterfaceFluxCT) = Jutul.CTSkewSymmetry()

Jutul.cross_term_entities(ct::TPFAInterfaceFluxCT, eq::Jutul.JutulEquation, model) = ct.target_cells
Jutul.cross_term_entities_source(ct::TPFAInterfaceFluxCT, eq::Jutul.JutulEquation, model) = ct.source_cells

function Jutul.update_cross_term_in_entity!(out                                  ,
                                            ind                                  ,
                                            state_t                              ,
                                            state0_t                             ,
                                            state_s                              ,
                                            state0_s                             , 
                                            model_t                              ,
                                            model_s                              ,
                                            ct::TPFAInterfaceFluxCT              ,
                                            eq                                   ,
                                            dt                                   ,
                                            ldisc = Jutul.local_discretization(ct, ind))

    trans = ct.trans[ind]
    ind_t = ct.target_cells[ind]
    ind_s = ct.source_cells[ind]
    phi_t = state_t.Phi[ind_t]
    phi_s = state_s.Phi[ind_s]
    
    out[] = trans*(phi_t - phi_s)
    
end

function Jutul.update_cross_term_in_entity!(out                           ,
                                            ind                           ,
                                            state_t                       ,
                                            state0_t                      ,
                                            state_s                       ,
                                            state0_s                      , 
                                            model_t                       ,
                                            model_s                       ,
                                            ct::AccumulatorInterfaceFluxCT,
                                            eq                            ,
                                            dt                            ,
                                            ldisc = Jutul.local_discretization(ct, ind))
    trans = ct.trans
    ind_t = ct.target_cell
    phi_t = state_t.Phi[ind_t]
    phi_s = state_s.Phi
    v = 0
    for (i, ind_s) in enumerate(ct.source_cells)
        v += trans[i]*(phi_t - phi_s[ind_s])
    end

    out[] = v
end

Jutul.cross_term_entities(ct::AccumulatorInterfaceFluxCT, eq::Jutul.JutulEquation, model) = [ct.target_cell]

function regularized_sqrt(x::T, th::Float64) where {T<:Any}
    x, th = promote(x, th)
    y = zero(T)
    if x <= th
        y = x/th*sqrt(th)
    else
        y = x^0.5
    end
    return y
end

function butler_volmer_equation(j0, alpha, n, eta, T)
    
    res = j0 * (
        exp(  alpha * n * FARADAY_CONSTANT * eta / (GAS_CONSTANT * T ) ) - 
        exp( -(1-alpha) * n * FARADAY_CONSTANT * eta / ( GAS_CONSTANT * T ) ) 
    )
    
    return res
    
end

function reaction_rate(phi_a         ,
                       c_a           ,
                       R0            ,
                       ocp           ,
                       T             ,
                       phi_e         ,
                       c_e           ,
                       activematerial,
                       electrolyte
                       )

    n    = activematerial.params[:n_charge_carriers]
    cmax = activematerial.params[:maximum_concentration]
    vsa  = activematerial.params[:volumetric_surface_area]

    eta = (phi_a - phi_e - ocp)
    th  = 1e-3*cmax
    j0  = R0*regularized_sqrt(c_e*(cmax - c_a)*c_a, th)*n*FARADAY_CONSTANT
    R   = vsa*butler_volmer_equation(j0, 0.5, n, eta, T)

    return R/(n*FARADAY_CONSTANT)
    
end



##########################
# cross-term for 2pd model
##########################


Jutul.cross_term_entities(ct::ButlerVolmerActmatToElyteCT, eq::Jutul.JutulEquation, model) = ct.target_cells
Jutul.cross_term_entities_source(ct::ButlerVolmerActmatToElyteCT, eq::Jutul.JutulEquation, model) = ct.source_cells


function Jutul.update_cross_term_in_entity!(out                            ,
                                            ind                            ,
                                            state_t                        ,
                                            state0_t                       ,
                                            state_s                        ,
                                            state0_s                       , 
                                            model_t                        ,
                                            model_s                        ,
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
    ocp   = state_s.Ocp[ind_s]
    R0    = state_s.ReactionRateConst[ind_s]
    c_e   = state_t.C[ind_t]
    c_a   = state_s.Cs[ind_s]
    T     = state_s.Temperature[ind_s]

    R = reaction_rate(phi_a         ,
                      c_a           ,
                      R0            ,
                      ocp           ,
                      T             ,
                      phi_e         ,
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


Jutul.cross_term_entities(ct::ButlerVolmerElyteToActmatCT, eq::Jutul.JutulEquation, model) = ct.target_cells

Jutul.cross_term_entities_source(ct::ButlerVolmerElyteToActmatCT, eq::Jutul.JutulEquation, model) = ct.source_cells


function Jutul.update_cross_term_in_entity!(out                            ,
                                            ind                            ,
                                            state_t                        ,
                                            state0_t                       ,
                                            state_s                        ,
                                            state0_s                       , 
                                            model_t                        ,
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
    ocp   = state_t.Ocp[ind_t]
    R0    = state_t.ReactionRateConst[ind_t]
    c_e   = state_s.C[ind_s]
    c_a   = state_t.Cs[ind_t]
    T     = state_t.Temperature[ind_t]

    R = reaction_rate(phi_a         ,
                      c_a           ,
                      R0            ,
                      ocp           ,
                      T             ,
                      phi_e         ,
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


##############
# cross-terms for no particle diffusion model
###############

function source_electric_material(vols,
                                  T,
                                  phi_a,
                                  c_a,
                                  R0,
                                  ocp,
                                  phi_e,
                                  c_e,
                                  activematerial,
                                  electrolyte
                                  )

    n = activematerial.params[:n_charge_carriers]
    R = reaction_rate(phi_a,
                      c_a,
                      R0,
                      ocp,
                      T,
                      phi_e,
                      c_e,
                      activematerial,
                      electrolyte
                      )
    
    eS = 1.0 * vols * R * n * FARADAY_CONSTANT
    eM = 1.0 * vols * R 

    return (eS, eM)
    
end


Jutul.cross_term_entities(ct::ButlerVolmerInterfaceFluxCT, eq::Jutul.JutulEquation, model) = ct.target_cells
Jutul.cross_term_entities_source(ct::ButlerVolmerInterfaceFluxCT, eq::Jutul.JutulEquation, model) = ct.source_cells

Jutul.symmetry(::ButlerVolmerInterfaceFluxCT) = Jutul.CTSkewSymmetry()

function Jutul.update_cross_term_in_entity!(out,
                                            ind,
                                            state_t,
                                            state0_t,
                                            state_s,
                                            state0_s, 
                                            model_t,
                                            model_s,
                                            ct::ButlerVolmerInterfaceFluxCT,
                                            eq,
                                            dt,
                                            ldisc = Jutul.local_discretization(ct, ind))

    activematerial = model_s.system
    electrolyte = model_t.system

    ind_t = ct.target_cells[ind]
    ind_s = ct.source_cells[ind]

    vols  = model_s.domain.representation.volumes[ind_s]

    phi_e = state_t.Phi[ind_t]
    phi_a = state_s.Phi[ind_s]  
    ocp   = state_s.Ocp[ind_s]
    R     = state_s.ReactionRateConst[ind_s]
    c_e   = state_t.C[ind_t]
    c_a   = state_s.C[ind_s]
    T     = state_s.Temperature[ind_s]

    eS, eM = source_electric_material(vols,
                                      T,
                                      phi_a,
                                      c_a,
                                      R,
                                      ocp,
                                      phi_e,
                                      c_e,
                                      activematerial,
                                      electrolyte
                                      )
    
    cs = conserved_symbol(eq)
    if cs == :Mass
        v = eM
    else
        @assert cs == :Charge
        v = eS
    end
    
    out[] = -v
    
end



