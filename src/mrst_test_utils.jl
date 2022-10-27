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
    #bcfaces = exported_all["model"]["NegativeElectrode"]["CurrentCollector"]["externalCouplingTerm"]["couplingcells"]
    bccells = N_all[bcfaces,1] + N_all[bcfaces,2]
    #T_hf   = -T_all[bcfaces]
    msource = exported  
    #T_hf = -getHalfTrans(msource, bcfaces, bccells, "EffectiveElectricalConductivity")
    T_hf = -getHalfTrans(msource, bcfaces)#, bccells, "EffectiveElectricalConductivity")
    bcvaluesrc = zeros(size(bccells))
    bcvaluephi = ones(size(bccells)).*0.0

    vf = []
    if haskey(exported, "volumeFraction")
        vf = exported["volumeFraction"][:, 1]
    end
    domain = exported_model_to_domain(exported, bc = bccells, b_T_hf = T_hf, vf=vf)
    G = exported["G"]
    plot_mesh = MRSTWrapMesh(G)
    model = SimulationModel(domain, sys, context = DefaultContext(), plot_mesh = plot_mesh)

    # State is dict with pressure in each cell
    phi0 = 1.0
    C0 = 1.
    T0 = 298.15
    I0 = 1.0
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

    S = model.parameters
    if count_active_entities(domain, BoundaryFaces()) > 0
        S[:BoundaryPhi] = BoundaryPotential(:Phi)
        S[:BoundaryC] = BoundaryPotential(:Phi)
        S[:BoundaryTemperature] = BoundaryPotential(:Temperature)

        S[:BCCharge] = BoundaryCurrent(srccells, :Charge)
        S[:BCMass] = BoundaryCurrent(srccells, :Mass)
        S[:BCEnergy] = BoundaryCurrent(srccells, :Charge)
        init_prm = Dict{Symbol, Any}(
            :BoundaryPhi            => bcvaluephi, 
            :BoundaryC              => bcvaluephi, 
            :BoundaryTemperature    => bcvaluephi,
            :BCCharge               => bcvaluesrc.*0,#0.0227702,
            :BCMass                 => bcvaluesrc,
            :BCEnergy               => bcvaluesrc,
            )
    else
        init_prm = Dict{Symbol, Any}()
    end
    init_prm[:Temperature] = T0

    init = Dict(
        :Phi                    => phi0,
        :Current                => I0,
        :C                      => C0,
        :ThermalConductivity    => λ
        )
    if model.system isa Electrolyte
        init[:Conductivity] = σ
        init[:Diffusivity] = D
    else
        init_prm[:Conductivity] = σ
        init_prm[:Diffusivity] = D
    end
    state0 = setup_state(model, init)
    parameters = setup_parameters(model, init_prm)

    return model, G, state0, parameters, init
end

##
function convert_to_int_vector(x::Float64)
    vec = Int64.(
        Vector{Float64}([x])
    )
    return vec
end
 function convert_to_int_vector(x::Matrix{Float64})
    vec = Int64.(   
    Vector{Float64}(x[:,1])
    )
    return vec
 end

function setup_model(exported_all; use_groups = false)
    skip_cc = size(exported_all["model"]["include_current_collectors"]) == (0,0)
    skip_cc = false
    if !skip_cc
        exported_cc = exported_all["model"]["NegativeElectrode"]["CurrentCollector"];

        sys_cc = CurrentCollector()
    
        bcfaces = convert_to_int_vector(exported_all["model"]["NegativeElectrode"]["CurrentCollector"]["externalCouplingTerm"]["couplingfaces"])
        srccells = []
        (model_cc, G_cc, state0_cc, parm_cc,init_cc) = make_system(exported_cc, sys_cc, bcfaces, srccells)
    end

    sys_nam = Grafite()
    exported_nam = exported_all["model"]["NegativeElectrode"]["ActiveMaterial"];
    
    if  skip_cc
        srccells = []
        bcfaces = convert_to_int_vector(exported_all["model"]["NegativeElectrode"]["ActiveMaterial"]["externalCouplingTerm"]["couplingfaces"])
        (model_nam, G_nam, state0_nam, parm_nam, init_nam) = 
            make_system(exported_nam, sys_nam, bcfaces, srccells)
    else
        srccells = []
        bcfaces=[]
        (model_nam, G_nam, state0_nam, parm_nam, init_nam) = 
            make_system(exported_nam, sys_nam, bcfaces, srccells)
    end
    t1, t2 = exported_all["model"]["Electrolyte"]["sp"]["t"]
    z1, z2 = exported_all["model"]["Electrolyte"]["sp"]["z"]
    tDivz_eff = (t1/z1 + t2/z2)

    sys_elyte = SimpleElyte(t = tDivz_eff, z = 1)
    exported_elyte = exported_all["model"]["Electrolyte"]
    bcfaces=[]
    srccells = []
    (model_elyte, G_elyte, state0_elyte, parm_elyte, init_elyte) = 
        make_system(exported_elyte, sys_elyte, bcfaces, srccells)


    sys_pam = NMC111()
    exported_pam = exported_all["model"]["PositiveElectrode"]["ActiveMaterial"];
    bcfaces=[]
    srccells = []
    (model_pam, G_pam, state0_pam, parm_pam, init_pam) = 
        make_system(exported_pam,sys_pam,bcfaces,srccells)   
   
    if !skip_cc    
        exported_pp = exported_all["model"]["PositiveElectrode"]["CurrentCollector"];
        sys_pp = CurrentCollector()
        bcfaces=[]
        srccells = []
        (model_pp, G_pp, state0_pp, parm_pp,init_pp) = 
        make_system(exported_pp,sys_pp, bcfaces, srccells)
    end
    sys_bpp = CurrentAndVoltageSystem()
    domain_bpp = CurrentAndVoltageDomain()
    model_bpp = SimulationModel(domain_bpp, sys_bpp, context = DefaultContext())
    parm_bpp = setup_parameters(model_bpp)
    # parm_bpp[:tolerances][:default] = 1e-8
    # Setup model
    
    if skip_cc
        groups = nothing
        model = MultiModel(
            (
                NAM = model_nam, 
                ELYTE = model_elyte, 
                PAM = model_pam, 
                BPP = model_bpp
            ), 
            groups = groups)    
    else
        models = (
            CC = model_cc, 
            NAM = model_nam, 
            ELYTE = model_elyte, 
            PAM = model_pam, 
            PP = model_pp,
            BPP = model_bpp
        )
        if use_groups
            groups = ones(Int64, length(models))
            # Should be BPP
            groups[end] = 2
            reduction = :schur_apply
        else
            groups = nothing
            reduction = :reduction
        end
        model = MultiModel(models, groups = groups, reduction = reduction)

    end    
    state0 = exported_all["state0"]
    if !skip_cc
        init_cc[:Phi] = state0["NegativeElectrode"]["CurrentCollector"]["phi"][1]           #*0
        init_pp[:Phi] = state0["PositiveElectrode"]["CurrentCollector"]["phi"][1]           #*0
    end
    init_nam[:Phi] = state0["NegativeElectrode"]["ActiveMaterial"]["phi"][1]  #*0
    init_elyte[:Phi] = state0["Electrolyte"]["phi"][1]
    init_pam[:Phi] = state0["PositiveElectrode"]["ActiveMaterial"]["phi"][1]  #*0

    if skip_cc
        init_nam[:C] = state0["NegativeElectrode"]["ActiveMaterial"]["Interface"]["cElectrodeSurface"]
        init_pam[:C] = state0["PositiveElectrode"]["ActiveMaterial"]["Interface"]["cElectrodeSurface"]
    else
        init_nam[:C] = state0["NegativeElectrode"]["ActiveMaterial"]["c"][1] 
        init_pam[:C] = state0["PositiveElectrode"]["ActiveMaterial"]["c"][1]
    end
    #init_elyte[:C] = state0["Electrolyte"]["cs"][1][1]
    if haskey(state0["Electrolyte"],"cs")
        init_elyte[:C] = state0["Electrolyte"]["cs"][1][1]# for compatibility to old
    else
        init_elyte[:C] = state0["Electrolyte"]["c"][1]
    end
    init_bpp = Dict(:Phi => 1.0, :Current => 1.0)
    if skip_cc
        init = Dict(     
            :NAM => init_nam,
            :ELYTE => init_elyte,
            :PAM => init_pam,
            :BPP => init_bpp
        )
    else
        init = Dict(
        :CC => init_cc,
        :NAM => init_nam,
        :ELYTE => init_elyte,
        :PAM => init_pam,
        :PP => init_pp,
        :BPP => init_bpp
    )
    end

    state0 = setup_state(model, init)
    if skip_cc
        parameters = Dict(
            :NAM => parm_nam,
            :ELYTE => parm_elyte,
            :PAM => parm_pam,
            :BPP => parm_bpp
        )
    else
        parameters = Dict(
            :CC => parm_cc,
            :NAM => parm_nam,
            :ELYTE => parm_elyte,
            :PAM => parm_pam,
            :PP => parm_pp,
            :BPP => parm_bpp
        )
    end
    if skip_cc
        grids = Dict(
            :NAM =>G_nam,
            :ELYTE => G_elyte,
            :PAM => G_pam
        )
    else
        grids = Dict(
         :CC => G_cc,
            :NAM =>G_nam,
            :ELYTE => G_elyte,
            :PAM => G_pam,
            :PP => G_pp
        )
    end

    return model, state0, parameters, grids
end

##

function setup_coupling!(model, exported_all)
    # setup coupling CC <-> NAM :charge_conservation
    skip_cc = size(exported_all["model"]["include_current_collectors"]) == (0,0)
    skip_cc = false
    if !skip_cc
        srange = Int64.(
            exported_all["model"]["NegativeElectrode"]["couplingTerm"]["couplingcells"][:,1]
            )
        trange = Int64.(
            exported_all["model"]["NegativeElectrode"]["couplingTerm"]["couplingcells"][:,2]
            )
        msource =   exported_all["model"]["NegativeElectrode"]["CurrentCollector"]
        mtarget =   exported_all["model"]["NegativeElectrode"]["ActiveMaterial"]
        couplingfaces = Int64.(exported_all["model"]["NegativeElectrode"]["couplingTerm"]["couplingfaces"])
        couplingcells = Int64.(exported_all["model"]["NegativeElectrode"]["couplingTerm"]["couplingcells"])
        trans = getTrans(msource, mtarget, couplingfaces, couplingcells,"EffectiveElectricalConductivity")

        ct = TPFAInterfaceFluxCT(trange, srange, trans)
        ct_pair = setup_cross_term(ct, target = :NAM, source = :CC, equation = :charge_conservation)
        add_cross_term!(model, ct_pair)
    end
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

    # setup coupling NAM <-> ELYTE mass (same cells as NAM <-> ELYTE)
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
    ct = ButlerVolmerInterfaceFluxCT(trange, srange)
    ct_pair = setup_cross_term(ct, target = :ELYTE, source = :PAM, equation = :mass_conservation)
    add_cross_term!(model, ct_pair)
    if  !skip_cc
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
        msource = exported_all["model"]["PositiveElectrode"]["CurrentCollector"]
        ct = exported_all["model"]["PositiveElectrode"]["couplingTerm"]
        couplingfaces = Int64.(ct["couplingfaces"])
        couplingcells = Int64.(ct["couplingcells"])
        trans = getTrans(msource, mtarget, couplingfaces, couplingcells, "EffectiveElectricalConductivity")
        ct = TPFAInterfaceFluxCT(trange, srange, trans)
        ct_pair = setup_cross_term(ct, target = :PAM, source = :PP, equation = :charge_conservation)
        add_cross_term!(model, ct_pair)
    end
    if skip_cc
        #setup coupling PP <-> BPP charge
        target = Dict( 
            :model => :PAM,
            :equation => :charge_conservation
            )

        trange = convert_to_int_vector(
                exported_all["model"]["PositiveElectrode"]["ActiveMaterial"]["externalCouplingTerm"]["couplingcells"]
            )
        srange = Int64.(ones(size(trange)))
        msource = exported_all["model"]["PositiveElectrode"]["ActiveMaterial"]
        couplingfaces = Int64.(msource["externalCouplingTerm"]["couplingfaces"])
        couplingcells = Int64.(msource["externalCouplingTerm"]["couplingcells"]) 
    else    
        #setup coupling PP <-> BPP charge
        target = Dict( 
            :model => :PP,
            :equation => :charge_conservation
            )

        trange = convert_to_int_vector(
                exported_all["model"]["PositiveElectrode"]["CurrentCollector"]["externalCouplingTerm"]["couplingcells"]
            )    
        srange = Int64.(ones(size(trange)))
        msource = exported_all["model"]["PositiveElectrode"]["CurrentCollector"]
        couplingfaces = Int64.(msource["externalCouplingTerm"]["couplingfaces"])
        couplingcells = Int64.(msource["externalCouplingTerm"]["couplingcells"])
    end
    source = Dict( 
        :model => :BPP,
        :equation => :charge_conservation
        )
    
    #effcond = exported_all["model"]["PositiveElectrode"]["CurrentCollector"]["EffectiveElectricalConductivity"]
    trans = getHalfTrans(msource, couplingfaces, couplingcells, "EffectiveElectricalConductivity")

    if skip_cc
        ct = TPFAInterfaceFluxCT(trange, srange, trans, symmetric = false)
        ct_pair = setup_cross_term(ct, target = :PAM, source = :BPP, equation = :charge_conservation)
        add_cross_term!(model, ct_pair)
    
        # Accmulation of charge
        ct = AccumulatorInterfaceFluxCT(1, trange, trans)
        ct_pair = setup_cross_term(ct, target = :BPP, source = :PAM, equation = :charge_conservation)
        add_cross_term!(model, ct_pair)
    else
        ct = TPFAInterfaceFluxCT(trange, srange, trans, symmetric = false)
        ct_pair = setup_cross_term(ct, target = :PP, source = :BPP, equation = :charge_conservation)
        add_cross_term!(model, ct_pair)

        # Accmulation of charge
        ct = AccumulatorInterfaceFluxCT(1, trange, trans)
        ct_pair = setup_cross_term(ct, target = :BPP, source = :PP, equation = :charge_conservation)
        add_cross_term!(model, ct_pair)
    end
    
end


##
function currentFun(t::T,inputI::T) where T
    #inputI = 9.4575
    tup = 0.1
    val::T = 0.0
    if  t <= tup
        val = sineup(0.0, inputI, 0.0, tup, t) 
    else
        val = inputI
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
                        solver = :gmres,
                        verbose = 0,
                        kwarg...)
    if method == :amg
        prec = amg_precond()   
    elseif method == :ilu0
        prec = ILUZeroPreconditioner()
    elseif method == :direct
        return LUSolver()
    elseif method == :cphi
        prec = BatteryCPhiPreconditioner()
    else
        return nothing
    end
    max_it = 200
    atol = 0.0

    lsolve = GenericKrylov(solver, verbose = verbose, preconditioner = prec, 
    relative_tolerance = rtol, absolute_tolerance = atol,
    max_iterations = max_it; kwarg...)
    return lsolve
end

function setup_sim(name; use_groups = false)
##
    #name="model1d_notemp"
    fn = string(dirname(pathof(BattMo)), "/../test/battery/data/", name, ".mat")
    exported_all = MAT.matread(fn)

    model, state0, parameters, grids = setup_model(exported_all, use_groups = use_groups)    
    setup_coupling!(model, exported_all)
    #inputI = 9.4575
    inputI = 0;
    minE = 10
    steps = size(exported_all["states"],1)
    for i = 1:steps
        inputI = max(inputI,exported_all["states"][i]["Control"]["I"])
        minE = min(minE,exported_all["states"][i]["Control"]["E"])
    end
    # Set initial voltage above the threshold for switching
    @. state0[:BPP][:Phi] = minE*1.5
    cFun(time) = currentFun(time, inputI)
    forces_pp = nothing 
    #forces_pp = (src = SourceAtCell(10,9.4575*0.0),)

    currents = setup_forces(model[:BPP], policy = SimpleCVPolicy(cFun, minE))
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

function test_battery(name; extra_timing = false, info_level = 0, max_step = nothing, linear_solver = :direct, use_groups = false)
    #timesteps = exported_all["schedule"]["step"]["val"][1:27]
    sim, forces, grids, state0, parameters, exported_all, model = setup_sim(name, use_groups = use_groups)
    steps = size(exported_all["states"],1)
    alltimesteps = Vector{Float64}(undef,steps)
    time = 0;
    end_step = 0
    minE=2.5
    for i = 1:steps
        alltimesteps[i] =  exported_all["states"][i]["time"]-time
        time = exported_all["states"][i]["time"]
        E = exported_all["states"][i]["Control"]["E"]
        if (E > minE+0.001)
            end_step = i
        end
    end
    if !isnothing(max_step)
        end_step = min(max_step, end_step)
    end
    timesteps = alltimesteps[1:end_step]
    cfg = simulator_config(sim, info_level = info_level)
    cfg[:linear_solver] = battery_linsolve(model, linear_solver)
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

    cfg[:tolerances][:PP][:default] = 1e-1
    cfg[:tolerances][:BPP][:default] = 1e-1
    # Run simulation
    states, report = simulate(sim, timesteps, forces = forces, config = cfg)
    stateref = exported_all["states"]

    extra = Dict(:model => model,
                 :grids => grids,
                 :state0 => state0,
                 :states_ref => stateref,
                 :parameters => parameters,
                 :exported => exported_all,
                 :timesteps => timesteps,
                 :config => cfg,
                 :forces => forces,
                 :simulator => sim)

    return (states = states, reports = report, extra = extra)
    # return states, grids, state0, stateref, parameters, exported_all, model, timesteps, cfg, report, sim
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
