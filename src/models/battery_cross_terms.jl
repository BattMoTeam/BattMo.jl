# interface flux between current conductors
# 1e7 should be the harmonic mean of hftrans/conductivity


Jutul.symmetry(::TPFAInterfaceFluxCT) = Jutul.CTSkewSymmetry()

Jutul.cross_term_entities(ct::TPFAInterfaceFluxCT, eq, model) = ct.target_cells
Jutul.cross_term_entities_source(ct::TPFAInterfaceFluxCT, eq, model) = ct.source_cells

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
    t_c   = ct.target_cells[ind]
    t_s   = ct.source_cells[ind]
    phi_t = state_t.Phi[t_c]
    phi_s = state_s.Phi[t_s]
    out[] = -trans*(phi_t - phi_s)
    
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
    t_c = ct.target_cell
    phi_t = state_t.Phi[t_c]
    phi_s = state_s.Phi
    v = 0
    for (i, s_c) in enumerate(ct.source_cells)
        v -= trans[i]*(phi_t - phi_s[s_c])
    end

    out[] = v
end

Jutul.cross_term_entities(ct::AccumulatorInterfaceFluxCT, eq, model) = [ct.target_cell]

function regularized_sqrt(x::T, th::Float64) where {T<:Any}
    #x,th = promote(xi,thi)
    y::T = 0.0
    #ind = (x <= th)
    if !(x <= th)
        y = x^0.5
    else
        y = x/th*sqrt(th)
    end
    return y   
end

function butler_volmer_equation(j0, alpha, n, eta, T)
    
    res = j0 * (
        exp(  alpha * n * FARADAY_CONST * eta / (GAS_CONSTANT * T ) ) - 
        exp( -(1-alpha) * n * FARADAY_CONST * eta / ( GAS_CONSTANT * T ) ) 
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

    n    = n_charge_carriers(activematerial)
    cmax = maximum_concentration(activematerial) 
    vsa  = volumetric_surface_area(activematerial)

    eta = (phi_a - phi_e - ocp);
    th  = 1e-3*cmax;
    j0  = R0*regularized_sqrt(c_e*(cmax - c_a)*c_a, th)*n*FARADAY_CONST;
    R   = vsa*butler_volmer_equation(j0, 0.5, n, eta, T);

    return R./(n*FARADAY_CONST);
    
end

# function sourceElectricMaterial!(
#     eS, eM, vols, T,
#     phi_a, c_a, R0,  ocp,
#     phi_e, c_e, activematerial, electrolyte
#     )

#     n = n_charge_carriers(activematerial)
#     for (i, val) in enumerate(phi_a)
#         # ! Hack, as we get error in ForwardDiff without .value
#         # ! This will cause errors if T is not just constant
#         temp = T[i].value
#         R = reaction_rate(
#             phi_a[i], c_a[i], R0[i], ocp[i], temp,
#             phi_e[i], c_e[i], activematerial, electrolyte
#             )
    
#         eS[i] = -1.0 * vols[i] * R * n * FARADAY_CONST
#         eM[i] = +1.0 * vols[i] * R 
#     end
#     return (eS, eM)
# end

function source_electric_material(vols          ,
                                  T             ,
                                  phi_a         ,
                                  c_a           ,
                                  R0            ,
                                  ocp           ,
                                  phi_e         ,
                                  c_e           ,
                                  activematerial,
                                  electrolyte)

    n = n_charge_carriers(activematerial)
    # for (i, val) in enumerate(phi_a)
    # ! Hack, as we get error in ForwardDiff without .value
    # ! This will cause errors if T is not just constant
    R = reaction_rate(phi_a         ,
                      c_a           ,
                      R0            ,
                      ocp           ,
                      T             ,
                      phi_e         ,
                      c_e           ,
                      activematerial,
                      electrolyte)
    
    eS = -1.0 * vols * R * n * FARADAY_CONST
    eM = +1.0 * vols * R 
    # end
    return (eS, eM)
    
end

Jutul.cross_term_entities(ct::ButlerVolmerCT, eq, model) = ct.target_cells

Jutul.cross_term_entities_source(ct::ButlerVolmerCT, eq, model) = ct.source_cells


function Jutul.update_cross_term_in_entity!(out                            ,
                                            ind                            ,
                                            state_t                        ,
                                            state0_t                       ,
                                            state_s                        ,
                                            state0_s                       , 
                                            model_t                        ,
                                            model_s                        ,
                                            ct::ButlerVolmerCT,
                                            eq                             ,
                                            dt                             ,
                                            ldisc = Jutul.local_discretization(ct, ind)
                                            )

    activematerial = model_s.system
    electrolyte    = model_t.system

    t_c = ct.target_cells[ind]
    s_c = ct.source_cells[ind]

    phi_e = state_t.Phi[t_c]
    phi_a = state_s.Phi[s_c]  
    ocp   = state_s.Ocp[s_c]
    R     = state_s.ReactionRateConst[s_c]
    c_e   = state_t.C[t_c]
    c_a   = state_s.Cs[s_c]
    vols  = model_s.domain.grid.volumes[s_c]
    T     = state_s.Temperature[s_c]

    eS, eM = source_electric_material(vols          ,
                                      T             ,
                                      phi_a         ,
                                      c_a           ,
                                      R             ,
                                      ocp           ,
                                      phi_e         ,
                                      c_e           ,
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
