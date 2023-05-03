using Infiltrator

struct SourceAtCell
    cell
    src
    function SourceAtCell(cell, src)
        new(cell, src)
    end 
end

function getTrans(model1, model2, faces, cells, quantity)
    """ setup transmissibility for coupling between models at boundaries"""

    # @infiltrate
    
    T_all1 = model1["operators"]["T_all"][faces[:, 1]]
    T_all2 = model2["operators"]["T_all"][faces[:, 2]]

    s1  = model1[quantity][cells[:, 1]]
    s2  = model2[quantity][cells[:, 2]]
    
    T   = 1.0./((1.0./(T_all1.*s1))+(1.0./(T_all2.*s2)))

    return T
    
end

function getHalfTrans(model, faces, cells, quantity)
    """ recover half transmissibilities for boundary faces and  weight them by the coefficient sent as quantity for the given cells.
Here, the faces should belong the corresponding cells at the same index"""

    T_all = model["operators"]["T_all"]
    s = model[quantity][cells]
    T = T_all[faces].*s

    return T
    
end

function getHalfTrans(model, faces)
    """ recover the half transmissibilities for boundary faces"""
    
    T_all = model["operators"]["T_all"]
    T = T_all[faces]
    
    return T
    
end

function my_number_of_cells(model::MultiModel)
    
    cells = 0
    for smodel in model.models
        cells += number_of_cells(smodel.domain)
    end

    return cells
    
end

function convert_to_int_vector(x::Float64)
    vec = Int64.(Vector{Float64}([x]))
    return vec
end

function convert_to_int_vector(x::Matrix{Float64})
    vec = Int64.(Vector{Float64}(x[:,1]))
    return vec
end

function setup_model(exported; use_p2d = true, use_groups = false, kwarg...)

    include_cc = true

    model      = setup_battery_model(exported, use_p2d = use_p2d, include_cc = include_cc)
    parameters = setup_battery_parameters(exported, model)
    initState  = setup_battery_initial_state(exported, model)
    
    return model, initState, parameters
    
end


function setup_battery_model(exported; include_cc = true, use_p2d = true, use_groups = false)

    function setup_component(exported, sys, bcfaces = nothing)
        
        domain = exported_model_to_domain(exported, bcfaces = bcfaces)
        model = SimulationModel(domain, sys, context = DefaultContext())
        return model
        
    end

    exportNames = Dict(
        :NAM => "NegativeElectrode",
        :PAM => "PositiveElectrode",        
    )
    
    function setup_active_material(name)

        exportName = exportNames[name]

        exported_am = exported["model"][exportName]["ActiveMaterial"]

        am_params = Dict{Symbol, Any}()
        am_params[:n_charge_carriers]       = exported_am["Interface"]["n"]
        am_params[:maximum_concentration]   = exported_am["Interface"]["cmax"]
        am_params[:volumetric_surface_area] = exported_am["Interface"]["volumetricSurfaceArea"]

        if name == :NAM
            am_params[:ocp_func]                    = compute_ocp_graphite
            am_params[:reaction_rate_constant_func] = compute_reaction_rate_constant_graphite
            am_params[:diffusion_coef_func]         = compute_diffusion_coef_graphite
        elseif name == :PAM
            am_params[:ocp_func]                    = compute_ocp_nmc111
            am_params[:reaction_rate_constant_func] = compute_reaction_rate_constant_nmc111
            am_params[:diffusion_coef_func]         = compute_diffusion_coef_nmc111
        else
            error("not recongized")
        end
        
        if use_p2d
            rp = exported_am["SolidDiffusion"]["rp"]
            N = Int64(exported_am["SolidDiffusion"]["N"])
            sys_am = ActiveMaterial{P2Ddiscretization}(am_params, rp, N)
        else
            sys_am = ActiveMaterial{NoParticleDiffusion}(am_params)
        end
        
        if  include_cc
            model_am = setup_component(exported_am, sys_am)
        else
            bcfaces_am = convert_to_int_vector(["externalCouplingTerm"]["couplingfaces"])
            model_am   = setup_component(exported_am, sys_am, bcfaces_am)
            # We add also boundary parameters (if any)
            S = model_pam.parameters
            nbc = count_active_entities(model_pam.domain, BoundaryFaces())
            if nbc > 0
                bcvalue_zeros = zeros(nbc)
                # add parameters to the model
                S[:BoundaryPhi] = BoundaryPotential(:Phi)
                S[:BoundaryC]   = BoundaryPotential(:C)
                S[:BCCharge]    = BoundaryCurrent(srccells, :Charge)
                S[:BCMass]      = BoundaryCurrent(srccells, :Mass)
            end
        end

        return model_am
        
    end
    
    # Setup positive current collector if any
    
    if include_cc

        exported_cc = exported["model"]["NegativeElectrode"]["CurrentCollector"]
        sys_cc      = CurrentCollector()
        bcfaces     = convert_to_int_vector(exported_cc["externalCouplingTerm"]["couplingfaces"])
        
        model_cc =  setup_component(exported_cc, sys_cc, bcfaces)
        
    end

    # Setup NAM

    model_nam = setup_active_material(:NAM)

    ## Setup ELYTE
    
    model_elyte = setup_component(exported["model"]["Electrolyte"],
                                  TestElyte())

    # Setup PAM
    
    model_pam = setup_active_material(:PAM)

    # Setup negative current collector if any
    if include_cc
        model_pp = setup_component(exported["model"]["PositiveElectrode"]["CurrentCollector"],
                                   CurrentCollector())
    end

    # Setup control model

    sys_bpp    = CurrentAndVoltageSystem()
    domain_bpp = CurrentAndVoltageDomain()
    model_bpp  = SimulationModel(domain_bpp, sys_bpp, context = DefaultContext())
    
    if !include_cc
        groups = nothing
        model = MultiModel(
            (
                NAM   = model_nam, 
                ELYTE = model_elyte, 
                PAM   = model_pam, 
                BPP   = model_bpp
            ), 
            groups = groups)    
    else
        models = (
            CC    = model_cc, 
            NAM   = model_nam, 
            ELYTE = model_elyte, 
            PAM   = model_pam, 
            PP    = model_pp,
            BPP   = model_bpp
        )
        if use_groups
            groups = ones(Int64, length(models))
            # Should be BPP
            groups[end] = 2
            reduction = :schur_apply
        else
            groups    = nothing
            reduction = :reduction
        end
        model = MultiModel(models, groups = groups, reduction = reduction)

    end
    
    return model
    
end

function setup_battery_parameters(exported, model)

    parameters = Dict{Symbol, Any}()

    T0 = exported["model"]["initT"]
    
    # Negative current collector (if any)

    if haskey(model.models, :CC)
        use_cc = true
    else
        use_cc = false
    end

    if use_cc
        prm_cc = Dict{Symbol, Any}()
        exported_cc = exported["model"]["NegativeElectrode"]["CurrentCollector"]
        prm_cc[:Conductivity] = exported_cc["EffectiveElectricalConductivity"][1]
        parameters[:CC] = setup_parameters(model[:CC], prm_cc)
    end

    # Negative active material
    
    prm_nam = Dict{Symbol, Any}()
    exported_nam = exported["model"]["NegativeElectrode"]["ActiveMaterial"]
    prm_nam[:Conductivity] = exported_nam["EffectiveElectricalConductivity"][1]
    prm_nam[:Temperature] = T0
    
    if discretisation_type(model[:NAM]) == :P2Ddiscretization
        # nothing to do
    else
        @assert discretisation_type(model[:NAM]) == :NoParticleDiffusion
        prm_nam[:Diffusivity] = exported_nam["InterDiffusionCoefficient"]
    end

    parameters[:NAM] = setup_parameters(model[:NAM], prm_nam)

    # Electrolyte
    
    prm_elyte = Dict{Symbol, Any}()
    prm_elyte[:Temperature] = T0        

    parameters[:ELYTE] = setup_parameters(model[:ELYTE], prm_elyte)

    # Positive active material

    prm_pam = Dict{Symbol, Any}()
    exported_pam = exported["model"]["PositiveElectrode"]["ActiveMaterial"]
    prm_pam[:Conductivity] = exported_pam["EffectiveElectricalConductivity"][1]
    prm_pam[:Temperature] = T0
    
    if discretisation_type(model[:PAM]) == :P2Ddiscretization
        # nothing to do
    else
        @assert discretisation_type(model[:NAM]) == :NoParticleDiffusion
        prm_pam[:Diffusivity] = exported_nam["InterDiffusionCoefficient"]
    end

    parameters[:PAM] = setup_parameters(model[:PAM], prm_pam)

    # Positive current collector (if any)

    if haskey(model.models, :CC)
        use_pp = true
    else
        use_pp = false
    end

    if use_pp
        prm_pp = Dict{Symbol, Any}()
        exported_pp = exported["model"]["PositiveElectrode"]["CurrentCollector"]
        prm_pp[:Conductivity] = exported_pp["EffectiveElectricalConductivity"][1]
        
        parameters[:PP] = setup_parameters(model[:PP], prm_pp)
    end        

    parameters[:BPP] = setup_parameters(model[:BPP])

    return parameters
    
end

function setup_battery_initial_state(exported, model)

    state0 = exported["state0"]

    exportNames = Dict(
        :CC  => "NegativeElectrode",
        :NAM => "NegativeElectrode",
        :PAM => "PositiveElectrode",        
        :PP  => "PositiveElectrode",
    )


    function initialize_current_collector!(initState, name::Symbol)
        """ initialize values for the current collector"""
        
        if haskey(model.models, name)
            use_cc = true
        else
            use_cc = false
        end
        
        if use_cc
            init = Dict()
            init[:Phi] = state0[exportNames[name]]["CurrentCollector"]["phi"][1]
            initState[name] = init
        end
        
    end


    function initialize_active_material!(initState, name::Symbol)
        """ initialize values for the active material"""

        exportName = exportNames[name]
        
        ccnames = Dict(
            :NAM => :CC,
            :PAM => :PP,
        )

        if haskey(model.models, ccnames[name])
            use_cc = true
        else
            use_cc = false
        end

        # initialise NAM

        sys = model[name].system

        init = Dict()
        
        init[:Phi]   = state0[exportName]["ActiveMaterial"]["phi"][1]

        if use_cc
            c = state0[exportName]["ActiveMaterial"]["Interface"]["cElectrodeSurface"][1]
        else
            c = state0[exportName]["ActiveMaterial"]["c"][1]
        end

        if  discretisation_type(sys) == :P2Ddiscretization
            init[:Cp] = c
        else
            @assert discretisation_type(sys) == :NoParticleDiffusion
            init[:C] = c
        end
        
        initState[name] = init
        
    end

    function initialize_electrolyte!(initState)

        init = Dict()
        
        init[:Phi] = state0["Electrolyte"]["phi"][1]
        init[:C]   = state0["Electrolyte"]["c"][1]

        initState[:ELYTE] = init

    end

    function initialize_bpp!(initState)

        init = Dict(:Phi => 1.0, :Current => 1.0)
        
        initState[:BPP] = init
        
    end
    
    initState = Dict()

    initialize_current_collector!(initState, :CC)
    initialize_active_material!(initState, :NAM)
    initialize_electrolyte!(initState)
    initialize_active_material!(initState, :PAM)
    initialize_current_collector!(initState, :PP)
    initialize_bpp!(initState)

    
    initState = setup_state(model, initState)

    return initState
    
end


function setup_coupling!(model, exported_all)
    # setup coupling CC <-> NAM :charge_conservation
    
    skip_pp = size(exported_all["model"]["include_current_collectors"]) == (0,0)
    skip_cc = false
    
    if !skip_cc
        
        srange = Int64.(
            exported_all["model"]["NegativeElectrode"]["couplingTerm"]["couplingcells"][:, 1]
            )
        trange = Int64.(
            exported_all["model"]["NegativeElectrode"]["couplingTerm"]["couplingcells"][:, 2]
        )
        
        msource = exported_all["model"]["NegativeElectrode"]["CurrentCollector"]
        mtarget = exported_all["model"]["NegativeElectrode"]["ActiveMaterial"]
        couplingfaces = Int64.(exported_all["model"]["NegativeElectrode"]["couplingTerm"]["couplingfaces"])
        couplingcells = Int64.(exported_all["model"]["NegativeElectrode"]["couplingTerm"]["couplingcells"])
        trans = getTrans(msource, mtarget, couplingfaces, couplingcells, "EffectiveElectricalConductivity")

        ct = TPFAInterfaceFluxCT(trange, srange, trans)
        ct_pair = setup_cross_term(ct, target = :NAM, source = :CC, equation = :charge_conservation)
        add_cross_term!(model, ct_pair)
        
    end
    
    # setup coupling NAM <-> ELYTE charge

    srange = Int64.(exported_all["model"]["couplingTerms"][1]["couplingcells"][:, 1]) # negative electrode
    trange = Int64.(exported_all["model"]["couplingTerms"][1]["couplingcells"][:, 2]) # electrolyte (negative side)

    if discretisation_type(model[:NAM]) == :P2Ddiscretization

        ct = ButlerVolmerActmatToElyteCT(trange, srange)
        ct_pair = setup_cross_term(ct, target = :ELYTE, source = :NAM, equation = :charge_conservation)
        add_cross_term!(model, ct_pair)
        ct_pair = setup_cross_term(ct, target = :ELYTE, source = :NAM, equation = :mass_conservation)
        add_cross_term!(model, ct_pair)
        
        ct = ButlerVolmerElyteToActmatCT(srange, trange)
        ct_pair = setup_cross_term(ct, target = :NAM, source = :ELYTE, equation = :charge_conservation)
        add_cross_term!(model, ct_pair)
        ct_pair = setup_cross_term(ct, target = :NAM, source = :ELYTE, equation = :mass_conservation)
        add_cross_term!(model, ct_pair)
        
    else
        
        @assert discretisation_type(model[:NAM]) == :NoParticleDiffusion
        
        ct = ButlerVolmerInterfaceFluxCT(trange, srange)
        ct_pair = setup_cross_term(ct, target = :ELYTE, source = :NAM, equation = :charge_conservation)
        add_cross_term!(model, ct_pair)
        ct_pair = setup_cross_term(ct, target = :ELYTE, source = :NAM, equation = :mass_conservation)
        add_cross_term!(model, ct_pair)
        
    end

    # setup coupling ELYTE <-> PAM charge

    srange = Int64.(exported_all["model"]["couplingTerms"][2]["couplingcells"][:,1]) # postive electrode
    trange = Int64.(exported_all["model"]["couplingTerms"][2]["couplingcells"][:,2]) # electrolyte (positive side)
    
    if discretisation_type(model[:PAM]) == :P2Ddiscretization

        ct = ButlerVolmerActmatToElyteCT(trange, srange)
        ct_pair = setup_cross_term(ct, target = :ELYTE, source = :PAM, equation = :charge_conservation)
        add_cross_term!(model, ct_pair)
        ct_pair = setup_cross_term(ct, target = :ELYTE, source = :PAM, equation = :mass_conservation)
        add_cross_term!(model, ct_pair)
        
        ct = ButlerVolmerElyteToActmatCT(srange, trange)
        ct_pair = setup_cross_term(ct, target = :PAM, source = :ELYTE, equation = :charge_conservation)
        add_cross_term!(model, ct_pair)
        ct_pair = setup_cross_term(ct, target = :PAM, source = :ELYTE, equation = :mass_conservation)
        add_cross_term!(model, ct_pair)
        
    else
        
        @assert discretisation_type(model[:PAM]) == :NoParticleDiffusion    

        ct = ButlerVolmerInterfaceFluxCT(trange, srange)
        ct_pair = setup_cross_term(ct, target = :ELYTE, source = :PAM, equation = :charge_conservation)
        add_cross_term!(model, ct_pair)
        ct_pair = setup_cross_term(ct, target = :ELYTE, source = :PAM, equation = :mass_conservation)
        add_cross_term!(model, ct_pair)
        
    end

    
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

function currentFun(t::T, inputI::T) where T
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

function setup_sim(name; use_p2d = true, use_groups = false, general_ad = false)

    fn = string(dirname(pathof(BattMo)), "/../test/battery/data/", name, ".mat")
    exported = MAT.matread(fn)

    model, state0, parameters = setup_model(exported, use_p2d = use_p2d, use_groups = use_groups, general_ad = general_ad)
   
    setup_coupling!(model, exported)
    
    inputI = 0;
    minE   = 10
    steps  = size(exported["states"],1)
    
    for i = 1:steps
        
        inputI = max(inputI, exported["states"][i]["Control"]["I"])
        minE   = min(minE, exported["states"][i]["Control"]["E"])
        
    end
    
    @. state0[:BPP][:Phi] = minE*1.5
    cFun(time) = currentFun(time, inputI)
    forces_pp = nothing

    currents = setup_forces(model[:BPP], policy = SimpleCVPolicy(cFun, minE))

    forces = Dict(
        :CC => nothing,
        :NAM => nothing,
        :ELYTE => nothing,
        :PAM => nothing,
        :PP => forces_pp,
        :BPP => currents
    )
    
    sim = Simulator(model, state0 = state0, parameters = parameters, copy_state = true)
    
    return sim, forces, state0, parameters, exported, model
    
end

export run_battery

function run_battery(name;
                     use_p2d       = true,
                     extra_timing  = false,
                     max_step      = nothing,
                     linear_solver = :direct,
                     general_ad    = false,
                     use_groups    = false,
                     kwarg...)
    
    sim, forces, state0, parameters, exported, model = setup_sim(name, use_p2d = use_p2d, use_groups = use_groups, general_ad = general_ad)
    
    steps        = size(exported["states"], 1)
    alltimesteps = Vector{Float64}(undef, steps)
    time         = 0;
    end_step     = 0
    minE         = 3.2
    
    for i = 1 : steps
        alltimesteps[i] =  exported["states"][i]["time"] - time
        time = exported["states"][i]["time"]
        E = exported["states"][i]["Control"]["E"]
        if (E > minE + 0.001)
            end_step = i
        end
    end
    if !isnothing(max_step)
        end_step = min(max_step, end_step)
    end
    
    timesteps = alltimesteps[1 : end_step]
    
    cfg = simulator_config(sim; kwarg...)
    cfg[:linear_solver]              = battery_linsolve(model, linear_solver)
    cfg[:debug_level]                = 0
    #cfg[:max_timestep_cuts]         = 0
    cfg[:max_residual]               = 1e20
    cfg[:min_nonlinear_iterations]   = 1
    cfg[:extra_timing]               = extra_timing
    # cfg[:max_nonlinear_iterations] = 5
    cfg[:safe_mode]                  = false
    cfg[:error_on_incomplete]        = true
    if false
        cfg[:info_level]               = 5
        cfg[:max_nonlinear_iterations] = 1
        cfg[:max_timestep_cuts]        = 0
    end

    cfg[:tolerances][:PP][:default] = 1e-1
    cfg[:tolerances][:BPP][:default] = 1e-1
    # Run simulation
    
    states, report = simulate(sim, timesteps, forces = forces, config = cfg)
    stateref = exported["states"]

    extra = Dict(:model => model,
                 :state0 => state0,
                 :states_ref => stateref,
                 :parameters => parameters,
                 :exported => exported,
                 :timesteps => timesteps,
                 :config => cfg,
                 :forces => forces,
                 :simulator => sim)

    return (states = states, reports = report, extra = extra, exported = exported)
end

export inputRefToStates
function inputRefToStates(states, stateref)
statesref = deepcopy(states);
    for i in 1:size(states,1)
        staterefnew = statesref[i]   
        refstep=i
        sim_step=i

        fields = ["CurrentCollector","ActiveMaterial"]
        components = ["NegativeElectrode","PositiveElectrode"]
        newkeys = [:CC,:NAM,:PP,:PAM]
        ind =1
        for component = components
            for field in fields
                state = stateref[refstep][component]
                phi_ref = state[field]["phi"]
                newcomp = newkeys[ind]
                staterefnew[newcomp][:Phi] = phi_ref        
                if haskey(state[field],"c")
                    c = state[field]["c"]
                    staterefnew[newcomp][:C] = c
                end
                ind=ind + 1
            end
        end

        fields = ["Electrolyte"]
        newcomp = :ELYTE
        for field in fields

            state = stateref[refstep]
            phi_ref = state[field]["phi"]
            #j_ref = state[field]["j"]
            staterefnew[newcomp][:Phi] = phi_ref
            if haskey(state[field],"c")
                c = state[field]["c"]
                staterefnew[newcomp][:C] = c
            end
        end
        
        ##
        staterefnew[:BPP][:Phi][1] = stateref[refstep]["Control"]["E"]
    end
return statesref
end


function test_mrst_battery(name)
    states, grids, state0, stateref, parameters, exported, model, timesteps, cfg, report, sim = run_battery(name);
    steps = size(states, 1)
    E = Matrix{Float64}(undef,steps,2)
    for step in 1:steps
        phi = states[step][:BPP][:Phi][1]
        E[step,1] = phi
        phi_ref = stateref[step]["PositiveElectrode"]["CurrentCollector"]["E"]
        E[step,2] = phi_ref
    end
    
    
end
