struct SourceAtCell
    cell
    src
    function SourceAtCell(cell,src)
        new(cell,src)
    end 
end

function getTrans(model1, model2, faces, cells, quantity)
    T_all1 = model1["operators"]["T_all"][faces[:,1]]
    T_all2 = model2["operators"]["T_all"][faces[:,2]]
    s1 =   model1[quantity][cells[:,1]]
    s2 =   model2[quantity][cells[:,2]]
    T = 1.0./((1.0./(T_all1.*s1))+(1.0./(T_all2.*s2)))
    return T
    #N_all = Int64.(exported["G"]["faces"]["neighbors"])
end
function getHalfTrans(model , faces, cells, quantity)
    T_all = model["operators"]["T_all"]
    s = model[quantity][cells]
    T = T_all[faces].*s
    return T
    #N_all = Int64.(exported["G"]["faces"]["neighbors"])
end
##
function getHalfTrans(model , faces)
    T_all = model["operators"]["T_all"]
    #s = model[quantity][cells]
    T = T_all[faces]#.*s
    return T
end
function my_number_of_cells(model::MultiModel)
    cells = 0
    for smodel in model.models
        cells += number_of_cells(smodel.domain)
    end
    return cells
end

##
function make_system(exported,sys,bcfaces,srccells)
    #T_all = exported["operators"]["T_all"]
    N_all = Int64.(exported["G"]["faces"]["neighbors"])
    isboundary = (N_all[bcfaces,1].==0) .| (N_all[bcfaces,2].==0)
    @assert all(isboundary)
    #bcfaces = exported_all["model"]["NegativeElectrode"]["CurrentCollector"]["couplingTerm"]["couplingcells"]
    bccells = N_all[bcfaces,1] + N_all[bcfaces,2]
    #T_hf   = -T_all[bcfaces]
    msource = exported  
    #T_hf = -getHalfTrans(msource, bcfaces, bccells, "EffectiveElectricalConductivity")
    T_hf = -getHalfTrans(msource, bcfaces)#, bccells, "EffectiveElectricalConductivity")
    bcvaluesrc = ones(size(srccells))
    bcvaluephi = ones(size(bccells)).*0.0

    vf = []
    if haskey(exported, "volumeFraction")
        vf = exported["volumeFraction"][:, 1]
    end
    domain = exported_model_to_domain(exported, bc = bccells, b_T_hf = T_hf, vf=vf)
    G = exported["G"]    
    model = SimulationModel(domain, sys, context = DefaultContext())
    parameters = setup_parameters(model)
    parameters[:boundary_currents] = (:BCCharge, :BCMass)

    # State is dict with pressure in each cell
    phi0 = 1.0
    C0 = 1.
    T0 = 298.15
    #D = -0.7e-10 # ???
    # D = - exported_all["model"]["NegativeElectrode"]["ElectrodeActiveComponent"]["InterDiffusionCoefficient"]
    if haskey(exported,"InterDiffusionCoefficient")
        D = - exported["InterDiffusionCoefficient"]
    else
        D =  -0.0
    end
    if isa(exported["EffectiveElectricalConductivity"], Matrix)
        σ = exported["EffectiveElectricalConductivity"][1]
    else
        σ = 1.0
    end
    λ = exported["thermalConductivity"][1]

    S = model.secondary_variables
    S[:BoundaryPhi] = BoundaryPotential{Phi}()
    S[:BoundaryC] = BoundaryPotential{Phi}()
    S[:BoundaryT] = BoundaryPotential{T}()

    S[:BCCharge] = BoundaryCurrent{Charge}(srccells)
    S[:BCMass] = BoundaryCurrent{Mass}(srccells)
    S[:BCEnergy] = BoundaryCurrent{Energy}(srccells)

    init = Dict(
        :Phi                    => phi0,
        :C                      => C0,
        :T                      => T0,
        :Conductivity           => σ,
        :Diffusivity            => D,
        :ThermalConductivity    => λ,
        :BoundaryPhi            => bcvaluephi, 
        :BoundaryC              => bcvaluephi, 
        :BoundaryT              => bcvaluephi,
        :BCCharge               => bcvaluesrc.*0,#0.0227702,
        :BCMass                 => bcvaluesrc,
        :BCEnergy               => bcvaluesrc,
        )

    state0 = setup_state(model, init)
    return model, G, state0, parameters, init
end

##
function convertToIntVector(x::Float64)
    vec = Int64.(
        Vector{Float64}([x])
    )
    return vec
end
 function convertToIntVector(x::Matrix{Float64})
    vec = Int64.(   
    Vector{Float64}(x[:,1])
    )
    return vec
 end

function setup_model(exported_all)
    exported_cc = exported_all["model"]["NegativeElectrode"]["CurrentCollector"];

    sys_cc = CurrentCollector()
    
    bcfaces = convertToIntVector(exported_all["model"]["NegativeElectrode"]["CurrentCollector"]["couplingTerm"]["couplingfaces"])
    srccells = []
    (model_cc, G_cc, state0_cc, parm_cc,init_cc) = make_system(exported_cc, sys_cc, bcfaces, srccells)
    
    sys_nam = Grafite()
    exported_nam = exported_all["model"]["NegativeElectrode"]["ElectrodeActiveComponent"];
    bcfaces=[]
    srccells = []
    (model_nam, G_nam, state0_nam, parm_nam, init_nam) = 
        make_system(exported_nam, sys_nam, bcfaces, srccells)

    sys_elyte = SimpleElyte()
    exported_elyte = exported_all["model"]["Electrolyte"]
    bcfaces=[]
    srccells = []
    (model_elyte, G_elyte, state0_elyte, parm_elyte, init_elyte) = 
        make_system(exported_elyte, sys_elyte, bcfaces, srccells)


    sys_pam = NMC111()
    exported_pam = exported_all["model"]["PositiveElectrode"]["ElectrodeActiveComponent"];
    bcfaces=[]
    srccells = []
    (model_pam, G_pam, state0_pam, parm_pam, init_pam) = 
        make_system(exported_pam,sys_pam,bcfaces,srccells)   
   
    exported_pp = exported_all["model"]["PositiveElectrode"]["CurrentCollector"];
    sys_pp = CurrentCollector()
    bcfaces=[]
    srccells = []
    (model_pp, G_pp, state0_pp, parm_pp,init_pp) = 
    make_system(exported_pp,sys_pp, bcfaces, srccells)

    sys_bpp = CurrentAndVoltageSystem()
    domain_bpp = CurrentAndVoltageDomain()
    model_bpp = SimulationModel(domain_bpp, sys_bpp, context = DefaultContext())
    parm_bpp = setup_parameters(model_bpp)
    # parm_bpp[:tolerances][:default] = 1e-8
    # Setup model
    

    groups = nothing
    model = MultiModel(
        (
            CC = model_cc, 
            NAM = model_nam, 
            ELYTE = model_elyte, 
            PAM = model_pam, 
            PP = model_pp,
            BPP = model_bpp
        ), 
        groups = groups)    

    state0 = exported_all["state0"]

    init_cc[:Phi] = state0["NegativeElectrode"]["CurrentCollector"]["phi"][1]           #*0
    init_pp[:Phi] = state0["PositiveElectrode"]["CurrentCollector"]["phi"][1]           #*0
    init_nam[:Phi] = state0["NegativeElectrode"]["ElectrodeActiveComponent"]["phi"][1]  #*0
    init_elyte[:Phi] = state0["Electrolyte"]["phi"][1]
    init_pam[:Phi] = state0["PositiveElectrode"]["ElectrodeActiveComponent"]["phi"][1]  #*0
    init_nam[:C] = state0["NegativeElectrode"]["ElectrodeActiveComponent"]["c"][1] 
    init_pam[:C] = state0["PositiveElectrode"]["ElectrodeActiveComponent"]["c"][1]
    #init_elyte[:C] = state0["Electrolyte"]["cs"][1][1]
    if haskey(state0["Electrolyte"],"cs")
        init_elyte[:C] = state0["Electrolyte"]["cs"][1][1]# for compatibility to old
    else
        init_elyte[:C] = state0["Electrolyte"]["c"][1]
    end
    init_bpp = Dict(:Phi => 1.0)

    init = Dict(
        :CC => init_cc,
        :NAM => init_nam,
        :ELYTE => init_elyte,
        :PAM => init_pam,
        :PP => init_pp,
        :BPP => init_bpp
    )

    state0 = setup_state(model, init)
    parameters = Dict(
        :CC => parm_cc,
        :NAM => parm_nam,
        :ELYTE => parm_elyte,
        :PAM => parm_pam,
        :PP => parm_pp,
        :BPP => parm_bpp
    )

    t1, t2 = exported_all["model"]["Electrolyte"]["sp"]["t"]
    z1, z2 = exported_all["model"]["Electrolyte"]["sp"]["z"]
    tDivz_eff = (t1/z1 + t2/z2)
    parameters[:ELYTE][:t] = tDivz_eff
    parameters[:ELYTE][:z] = 1
    grids = Dict(
        :CC => G_cc,
        :NAM =>G_nam,
        :ELYTE => G_elyte,
        :PAM => G_pam,
        :PP => G_pp
        )

    return model, state0, parameters, grids
end

##

function setup_coupling!(model, exported_all)
    # setup coupling CC <-> NAM :charge_conservation
    srange = Int64.(
        exported_all["model"]["NegativeElectrode"]["couplingTerm"]["couplingcells"][:,1]
        )
    trange = Int64.(
        exported_all["model"]["NegativeElectrode"]["couplingTerm"]["couplingcells"][:,2]
        )
    msource =   exported_all["model"]["NegativeElectrode"]["CurrentCollector"]
    mtarget =   exported_all["model"]["NegativeElectrode"]["ElectrodeActiveComponent"]
    couplingfaces = Int64.(exported_all["model"]["NegativeElectrode"]["couplingTerm"]["couplingfaces"])
    couplingcells = Int64.(exported_all["model"]["NegativeElectrode"]["couplingTerm"]["couplingcells"])
    trans = getTrans(msource, mtarget, couplingfaces, couplingcells,"EffectiveElectricalConductivity")

    ct = TPFAInterfaceFluxCT(trange, srange, trans)
    ct_pair = setup_cross_term(ct, target = :NAM, source = :CC, equation = :charge_conservation)
    add_cross_term!(model, ct_pair)
   
    properties = Dict(:trans => trans) #NB    
    intersection = ( srange, trange, Cells(), Cells())
    crosstermtype = InjectiveCrossTerm
    issym = true
    # coupling = MultiModelCoupling(source, target, intersection; crosstype = crosstermtype, properties = properties, issym = issym)
    # push!(model.couplings, coupling)

    # setup coupling NAM <-> ELYTE charge
    target = Dict( 
        :model => :ELYTE,
        :equation => :charge_conservation
    )
    source = Dict( 
        :model => :NAM, 
        :equation => :charge_conservation
        )

    srange=Int64.(exported_all["model"]["couplingTerms"][1]["couplingcells"][:,1])
    trange=Int64.(exported_all["model"]["couplingTerms"][1]["couplingcells"][:,2])
    ct = ButlerVolmerInterfaceFluxCT(trange, srange)
    ct_pair = setup_cross_term(ct, target = :ELYTE, source = :NAM, equation = :charge_conservation)
    add_cross_term!(model, ct_pair)

    # crosstermtype = InjectiveCrossTerm
    # issym = true
    # coupling = MultiModelCoupling(source, target, intersection; crosstype = crosstermtype, issym = issym)
    # push!(model.couplings, coupling)

    # setup coupling NAM <-> ELYTE mass
    srange=Int64.(exported_all["model"]["couplingTerms"][1]["couplingcells"][:,1])
    trange=Int64.(exported_all["model"]["couplingTerms"][1]["couplingcells"][:,2])
    ct = ButlerVolmerInterfaceFluxCT(trange, srange)
    ct_pair = setup_cross_term(ct, target = :ELYTE, source = :NAM, equation = :mass_conservation)
    add_cross_term!(model, ct_pair)

    # setup coupling ELYTE <-> PAM charge
    target = Dict( 
        :model => :ELYTE,
        :equation => :charge_conservation
        )
    source = Dict( 
        :model => :PAM,
        :equation => :charge_conservation
        )
    srange=Int64.(exported_all["model"]["couplingTerms"][2]["couplingcells"][:,1])
    trange=Int64.(exported_all["model"]["couplingTerms"][2]["couplingcells"][:,2])
    ct = ButlerVolmerInterfaceFluxCT(trange, srange)
    ct_pair = setup_cross_term(ct, target = :ELYTE, source = :PAM, equation = :charge_conservation)
    add_cross_term!(model, ct_pair)

    # setup coupling PAM <-> ELYTE mass
    target = Dict( 
        :model => :ELYTE,
        :equation => :mass_conservation
        )
    source = Dict( 
        :model => :PAM,
        :equation => :mass_conservation
        )
    srange=Int64.(exported_all["model"]["couplingTerms"][2]["couplingcells"][:,1])
    trange=Int64.(exported_all["model"]["couplingTerms"][2]["couplingcells"][:,2])
    ct = ButlerVolmerInterfaceFluxCT(trange, srange)
    ct_pair = setup_cross_term(ct, target = :ELYTE, source = :PAM, equation = :mass_conservation)
    add_cross_term!(model, ct_pair)

    # setup coupling PP <-> PAM charge
    target = Dict( 
        :model => :PAM,
        :equation => :charge_conservation
        )
    source = Dict( 
        :model => :PP,
        :equation => :charge_conservation
        )
    srange = Int64.(
        exported_all["model"]["PositiveElectrode"]["couplingTerm"]["couplingcells"][:,1]
        )
    trange = Int64.(
        exported_all["model"]["PositiveElectrode"]["couplingTerm"]["couplingcells"][:,2]
        )
    msource =   exported_all["model"]["PositiveElectrode"]["CurrentCollector"]
    mtarget =   exported_all["model"]["PositiveElectrode"]["ElectrodeActiveComponent"]
    couplingfaces = Int64.(exported_all["model"]["PositiveElectrode"]["couplingTerm"]["couplingfaces"])
    couplingcells = Int64.(exported_all["model"]["PositiveElectrode"]["couplingTerm"]["couplingcells"])
    trans = getTrans(msource, mtarget, couplingfaces, couplingcells, "EffectiveElectricalConductivity")
    ct = TPFAInterfaceFluxCT(trange, srange, trans)
    ct_pair = setup_cross_term(ct, target = :PAM, source = :PP, equation = :charge_conservation)
    add_cross_term!(model, ct_pair)

    #setup coupling PP <-> PAM charge
    target = Dict( 
        :model => :PP,
        :equation => :charge_conservation
        )
    source = Dict( 
        :model => :BPP,
        :equation => :charge_conservation
        )
    trange = convertToIntVector(
            exported_all["model"]["PositiveElectrode"]["CurrentCollector"]["couplingTerm"]["couplingcells"]
        )    
    srange = Int64.(ones(size(trange)))
    msource =   exported_all["model"]["PositiveElectrode"]["CurrentCollector"]
    couplingfaces = Int64.(exported_all["model"]["PositiveElectrode"]["CurrentCollector"]["couplingTerm"]["couplingfaces"])
    couplingcells = Int64.(exported_all["model"]["PositiveElectrode"]["CurrentCollector"]["couplingTerm"]["couplingcells"])
    #effcond = exported_all["model"]["PositiveElectrode"]["CurrentCollector"]["EffectiveElectricalConductivity"]
    trans = getHalfTrans(msource, couplingfaces, couplingcells, "EffectiveElectricalConductivity")

    ct = TPFAInterfaceFluxCT(trange, srange, trans, symmetric = false)
    ct_pair = setup_cross_term(ct, target = :PP, source = :BPP, equation = :charge_conservation)
    add_cross_term!(model, ct_pair)

    # Accmulation of charge
    ct = AccumulatorInterfaceFluxCT(1, trange, trans)
    ct_pair = setup_cross_term(ct, target = :BPP, source = :PP, equation = :charge_conservation)
    add_cross_term!(model, ct_pair)
end


##
function currentFun(t::T,inputI::T) where {T<:Any}
    #inputI = 9.4575
    tup = 0.1
    val::T = 0.0
    if ( t<= tup)
        val = sineup(0.0, inputI, 0.0, tup, t) 
    else
        val = inputI;
    end
    return val
end
function amg_precond(; max_levels = 10, max_coarse = 10, type = :smoothed_aggregation)
    gs_its = 1
    cyc = AlgebraicMultigrid.V()
    if type == :smoothed_aggregation
        m = smoothed_aggregation
    else
        m = ruge_stuben
    end
    gs = GaussSeidel(ForwardSweep(), gs_its)
    return AMGPreconditioner(m, max_levels = max_levels, max_coarse = max_coarse, presmoother = gs, postsmoother = gs, cycle = cyc)
end

function battery_linsolve(model, method = :ilu0;
    rtol = 0.005,
    verbose = 0,
    provider = Krylov,
    solver = Krylov.bicgstab,
    update_interval = :ministep,
    amg_type = :smoothed_aggregation,
    max_coarse = nothing,
    partial_update = update_interval == :once,
    kwarg...)
    ncells = my_number_of_cells(model)
   

    if method == :amg
        if isnothing(max_coarse)
            max_coarse = Int64(ceil(0.05*ncells))
            max_coarse = min(1000, max_coarse)
        end
        prec = amg_precond(max_coarse = max_coarse, type = amg_type)   
    elseif method == :ilu0
        prec = ILUZeroPreconditioner()
    else
        return nothing
    end
    max_it = 200
    atol = 0.0#1e-12
    # v = -1
    # v = 0
    # v = 1
    # if true
    #     krylov = Krylov.bicgstab
    #     # krylov = Krylov.gmres
    #     pv = Krylov
    # else
    #     krylov = IterativeSolvers.gmres!
    #     krylov = IterativeSolvers.bicgstabl!
    #     pv = IterativeSolvers
    # end
    # nl_reltol = 1e-3
    # relaxed_reltol = 0.25
    # nonlinear_relative_tolerance = nl_reltol,
    # relaxed_relative_tolerance = relaxed_reltol,

    lsolve = GenericKrylov(solver, provider = provider, verbose = verbose, preconditioner = prec, 
    relative_tolerance = rtol, absolute_tolerance = atol,
    max_iterations = max_it; kwarg...)
    return lsolve
end

function setup_sim(name)
##
    #name="model1d_notemp"
    fn = string(dirname(pathof(BattMo)), "/../test/battery/data/", name, ".mat")
    exported_all = MAT.matread(fn)

    model, state0, parameters, grids = setup_model(exported_all)    
    setup_coupling!(model, exported_all)
    #inputI = 9.4575
    inputI = 0;
    minE = 10
    steps = size(exported_all["states"],1)
    for i = 1:steps
        inputI = max(inputI,exported_all["states"][i]["PositiveElectrode"]["CurrentCollector"]["I"])
        minE = min(minE,exported_all["states"][i]["PositiveElectrode"]["CurrentCollector"]["E"])
    end

    cFun(time) = currentFun(time, inputI)
    forces_pp = nothing 
    #forces_pp = (src = SourceAtCell(10,9.4575*0.0),)
    currents = Dict( :current => cFun)
    forces = Dict(
        :CC => nothing,
        :NAM => nothing,
        :ELYTE => nothing,
        :PAM => nothing,
        :PP => forces_pp,
        :BPP => currents
    )
    for (k, p) in parameters
        #p[:tolerances][:default] = 1e-10
        # p[:tolerances][:default] = 1e-3
    end
    #parameters[:ELYTE][:tolerances][:charge_conservation]=1e-9
    #parameters[:PAM][:tolerances][:charge_conservation]=1e-6
    #parameters[:PP][:tolerances][:charge_conservation]=1e-3
    #parameters[:BPP][:tolerances][:charge_conservation]=1e-8
    # parameters[:BPP][:tolerances][:charge_conservation]=1e-2
    # parameters[:PP][:tolerances][:charge_conservation]=1e-2
    sim = Simulator(model, state0 = state0, parameters = parameters, copy_state = true)
    return sim, forces, grids, state0, parameters, exported_all, model
end

export test_battery

function test_battery(name; extra_timing = false, info_level = 0, max_step = nothing)   
    #timesteps = exported_all["schedule"]["step"]["val"][1:27]
    sim, forces, grids, state0, parameters, exported_all, model = setup_sim(name)
    steps = size(exported_all["states"],1)
    alltimesteps = Vector{Float64}(undef,steps)
    time = 0;
    end_step = 0
    minE=2.5
    for i = 1:steps
        alltimesteps[i] =  exported_all["states"][i]["time"]-time
        time = exported_all["states"][i]["time"]
        E = exported_all["states"][i]["PositiveElectrode"]["CurrentCollector"]["E"]
        if (E > minE+0.001)
            end_step = i
        end
    end
    if !isnothing(max_step)
        end_step = min(max_step, end_step)
    end
    #end_step=33
    linear_solver = nothing
    #slinear_solver = battery_linsolve(model,:ilu0; verbose = 1)
    timesteps = alltimesteps[1:end_step]
    cfg = simulator_config(sim, info_level = info_level)
    cfg[:linear_solver] = linear_solver
    cfg[:debug_level] = 0
    #cfg[:max_timestep_cuts] = 0
    cfg[:max_residual] = 1e20
    cfg[:min_nonlinear_iterations] = 1
    cfg[:extra_timing] = extra_timing
    cfg[:max_nonlinear_iterations] = 5
    cfg[:safe_mode] = false
    cfg[:error_on_incomplete] = true
    if false
        cfg[:info_level] = 5
        cfg[:max_nonlinear_iterations] = 1
        cfg[:max_timestep_cuts] = 0
    end

    t = cfg[:tolerances]
    # t[:NAM] = (default = 1e-3)
    # t[:NAM] = (default = 1e-3)

##

    states, report = simulate(sim, timesteps, forces = forces, config = cfg)
    stateref = exported_all["states"]

    return states, grids, state0, stateref, parameters, exported_all, model, timesteps, cfg, report, sim
end
function test_mrst_battery(name)
    states, grids, state0, stateref, parameters, exported_all, model, timesteps, cfg, report, sim = test_battery(name);
    steps = size(states, 1)
    E = Matrix{Float64}(undef,steps,2)
    for step in 1:steps
        phi = states[step][:BPP][:Phi][1]
        E[step,1] = phi
        phi_ref = stateref[step]["PositiveElectrode"]["CurrentCollector"]["E"]
        E[step,2] = phi_ref
    end
    
    
end
