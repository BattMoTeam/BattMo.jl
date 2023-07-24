
function getTrans(model1, model2, faces, cells, quantity)
    """ setup transmissibility for coupling between models at boundaries"""

    T_all1 = model1["operators"]["T_all"][faces[:, 1]]
    T_all2 = model2["operators"]["T_all"][faces[:, 2]]

    s1  = model1[quantity][cells[:, 1]]
    s2  = model2[quantity][cells[:, 2]]
    
    T   = 1.0./((1.0./(T_all1.*s1))+(1.0./(T_all2.*s2)))

    return T
    
end

function getTrans_1d(model1, model2, bcfaces, bccells, parameters1, parameters2, quantity)
    """ setup transmissibility for coupling between models at boundaries. Intermediate 1d version"""

    d1 = physical_representation(model1)
    d2 = physical_representation(model2)

    bcTrans1 = d1[:bcTrans][bcfaces[:, 1]]
    bcTrans2 = d2[:bcTrans][bcfaces[:, 2]]
    cells1   = bccells[:, 1]
    cells2   = bccells[:, 2]

    s1  = parameters1[quantity][cells1]
    s2  = parameters2[quantity][cells2]
    
    T   = 1.0./((1.0./(bcTrans1.*s1))+(1.0./(bcTrans2.*s2)))

    return T
    
end

function getHalfTrans_1d(model, bcfaces, bccells, parameters, quantity)
    """ recover half transmissibilities for boundary faces and  weight them by the coefficient sent as quantity for the corresponding given cells. Intermediate 1d version. Note the indexing in BoundaryFaces is used"""

    d = physical_representation(model)
    bcTrans = d[:bcTrans][bcfaces]
    s       = parameters[quantity][bccells]
    
    T   = bcTrans.*s

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


function setup_model(exported; use_p2d = true, use_groups = false, kwarg...)

    include_cc = true

    model      = setup_battery_model(exported, use_p2d = use_p2d, include_cc = include_cc)
    parameters = setup_battery_parameters(exported, model)
    initState  = setup_battery_initial_state(exported, model)
    
    return model, initState, parameters
    
end

function setup_model_1d(jsondict; use_groups = false, kwarg...)

    include_cc = true
    
    model      = setup_battery_model_1d(jsondict, include_cc = include_cc; kwarg...)
    parameters = setup_battery_parameters_1d(jsondict, model)
    initState  = setup_battery_initial_state_1d(jsondict, model)
    
    return model, initState, parameters
    
end

function setup_geomparams(jsondict)
    
    names = (:CC, :NAM, :SEP, :PAM, :PP)
    geomparams = Dict(name => Dict() for name in names)

    geomparams[:CC][:N]          = jsondict["NegativeElectrode"]["CurrentCollector"]["N"]
    geomparams[:CC][:thickness]  = jsondict["NegativeElectrode"]["CurrentCollector"]["thickness"]
    geomparams[:NAM][:N]         = jsondict["NegativeElectrode"]["ActiveMaterial"]["N"]
    geomparams[:NAM][:thickness] = jsondict["NegativeElectrode"]["ActiveMaterial"]["thickness"]
    geomparams[:SEP][:N]         = jsondict["Electrolyte"]["Separator"]["N"]
    geomparams[:SEP][:thickness] = jsondict["Electrolyte"]["Separator"]["thickness"]
    geomparams[:PAM][:N]         = jsondict["PositiveElectrode"]["ActiveMaterial"]["N"]
    geomparams[:PAM][:thickness] = jsondict["PositiveElectrode"]["ActiveMaterial"]["thickness"]
    geomparams[:PP][:N]          = jsondict["PositiveElectrode"]["CurrentCollector"]["N"]
    geomparams[:PP][:thickness]  = jsondict["PositiveElectrode"]["CurrentCollector"]["thickness"]

    for name in names
        geomparams[name][:facearea] = jsondict["Geometry"]["faceArea"]
    end
    
    return geomparams
    
end


function setup_battery_model_1d(jsondict; include_cc = true, use_groups = false, general_ad = false)
    
    geomparams = setup_geomparams(jsondict)

    function setup_component(geomparam::Dict, sys; addDirichlet = false, general_ad = false)

        facearea = geomparam[:facearea]
        
        g = CartesianMesh(Tuple(geomparam[:N]), Tuple(geomparam[:thickness]))
        domain = DataDomain(g)

        domain[:face_weighted_volumes] = facearea*domain[:volumes]
        
        k = ones(geomparam[:N])

        T    = compute_face_trans(domain, k)
        T_hf = compute_half_face_trans(domain, k)
        T_b  = compute_boundary_trans(domain, k)

        domain[:trans, Faces()]           = facearea*T
        domain[:halfTrans, HalfFaces()]   = facearea*T_hf
        domain[:bcTrans, BoundaryFaces()] = facearea*T_b

        # We add Dirichlet on negative current collector. This is hacky
        if addDirichlet

            domain.entities[BoundaryDirichletFaces()] = 1

            bcDirFace = 1 # in BoundaryFaces indexing
            bcDirCell = 1
            bcDirInd  = 1
            domain[:bcDirHalfTrans, BoundaryDirichletFaces()] = facearea*domain[:bcTrans][bcDirFace]
            domain[:bcDirCells, BoundaryDirichletFaces()]     = facearea*bcDirCell # 
            domain[:bcDirInds, BoundaryDirichletFaces()]      = facearea*bcDirInd #
            
        end
        
        if general_ad
            flow = PotentialFlow(g)
        else
            flow = TwoPointPotentialFlowHardCoded(g)
        end
        disc = (charge_flow = flow,)
        domain = DiscretizedDomain(domain, disc)
        
        model = SimulationModel(domain, sys, context = DefaultContext())
        return model
        
    end

    function setup_component(geomparams::Dict, sys::Electrolyte, bcfaces = nothing; general_ad = false)
        # specific implementation for electrolyte
        # requires geometric parameters for :NAM, :SEP, :PAM

        facearea = geomparams[:SEP][:facearea]
        
        names = (:NAM, :SEP, :PAM)

        deltas = Vector{Float64}()
        for name in names
            dx = geomparams[name][:thickness]/geomparams[name][:N]
            dx = dx*ones(geomparams[name][:N])
            deltas = vcat(deltas, dx)
        end

        N = sum([geomparams[name][:N] for name in names])
        deltas = (deltas,)
        g = CartesianMesh((N,), deltas)
        
        domain = DataDomain(g)

        domain[:face_weighted_volumes] = facearea*domain[:volumes]

        k = ones(N)
        T    = compute_face_trans(domain, k)
        T_hf = compute_half_face_trans(domain, k)
        T_b  = compute_boundary_trans(domain, k)

        domain[:trans, Faces()]           = facearea*T
        domain[:halfTrans, HalfFaces()]   = facearea*T_hf
        domain[:bcTrans, BoundaryFaces()] = facearea*T_b
        
        if general_ad
            flow = PotentialFlow(g)
        else
            flow = TwoPointPotentialFlowHardCoded(g)
        end
        disc = (charge_flow = flow,)
        domain = DiscretizedDomain(domain, disc)
        
        model = SimulationModel(domain, sys, context = DefaultContext())

        return model
        
    end

    jsonNames = Dict(
        :NAM => "NegativeElectrode",
        :PAM => "PositiveElectrode",        
    )

    
    function setup_active_material(name::Symbol, geomparams::Dict)

        jsonName = jsonNames[name]

        inputparams_am = jsondict[jsonName]["ActiveMaterial"]

        am_params = JutulStorage()
        am_params[:volumeFraction]          = inputparams_am["Interface"]["volumeFraction"]
        am_params[:n_charge_carriers]       = inputparams_am["Interface"]["n"]
        am_params[:maximum_concentration]   = inputparams_am["Interface"]["cmax"]
        am_params[:volumetric_surface_area] = inputparams_am["Interface"]["volumetricSurfaceArea"]
        am_params[:theta0]                  = inputparams_am["Interface"]["theta0"]
        am_params[:theta100]                = inputparams_am["Interface"]["theta100"]

        k0  = inputparams_am["Interface"]["k0"]
        Eak = inputparams_am["Interface"]["Eak"]
        am_params[:reaction_rate_constant_func] = (c, T) -> compute_reaction_rate_constant(c, T, k0, Eak)
        
        funcname = inputparams_am["Interface"]["OCP"]["functionname"]
        am_params[:ocp_func] = getfield(BattMo, Symbol(funcname))
        
        use_p2d = true
        if use_p2d
            rp = inputparams_am["SolidDiffusion"]["rp"]
            N  = Int64(inputparams_am["SolidDiffusion"]["N"])
            D  = inputparams_am["SolidDiffusion"]["D0"]
            sys_am = ActiveMaterialP2D(am_params, rp, N, D)
        else
            sys_am = ActiveMaterialNoParticleDiffusion(am_params)
        end
        
        geomparam = geomparams[name]
        model_am = setup_component(geomparam, sys_am, general_ad = general_ad)

        return model_am
        
    end
    
    # Setup negative current collector
    
    if include_cc
        sys_cc = CurrentCollector()
        model_cc =  setup_component(geomparams[:CC], sys_cc, addDirichlet = true, general_ad = general_ad)
    end

    # Setup NAM
    model_nam = setup_active_material(:NAM, geomparams)

    ## Setup ELYTE

    params = JutulStorage();
    inputparams_elyte = jsondict["Electrolyte"]
    
    params[:transference]       = inputparams_elyte["sp"]["t"]
    params[:charge]             = inputparams_elyte["sp"]["z"]
    params[:separator_porosity] = inputparams_elyte["Separator"]["porosity"]
    params[:bruggeman]          = inputparams_elyte["BruggemanCoefficient"]
    
    # setup diffusion coefficient function
    funcname = inputparams_elyte["DiffusionCoefficient"]["functionname"]
    func = getfield(BattMo, Symbol(funcname))
    params[:diffusivity] = func

    # setup diffusion coefficient function
    funcname = inputparams_elyte["Conductivity"]["functionname"]
    func = getfield(BattMo, Symbol(funcname))
    params[:conductivity] = func
    
    elyte = Electrolyte(params)
    model_elyte = setup_component(geomparams, elyte, general_ad = general_ad)

    # Setup PAM
    model_pam = setup_active_material(:PAM, geomparams)

    # Setup negative current collector if any
    if include_cc
        sys_pp = CurrentCollector()
        model_pp = setup_component(geomparams[:PP], sys_pp, general_ad = general_ad)
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

    setup_volume_fractions_1d!(model, geomparams)
    
    return model
    
end

function setup_volume_fractions_1d!(model, geomparams)

    names = (:NAM, :SEP, :PAM)
    Nelyte = sum([geomparams[name][:N] for name in names])
    vfelyte = zeros(Nelyte)
    
    names = (:NAM, :PAM)
    
    for name in names
        ammodel = model[name]
        vf = ammodel.system[:volumeFraction]
        Nam = geomparams[name][:N]
        ammodel.domain.representation[:volumeFraction] = vf*ones(Nam)
        if name == :NAM
            nstart = 1
            nend   = Nam
        elseif name == :PAM
            nstart = geomparams[:NAM][:N] + geomparams[:SEP][:N] + 1
            nend   = Nelyte
        else
            error("name not recognized")
        end
        vfelyte[nstart : nend] .= 1 - vf
    end

    nstart = geomparams[:NAM][:N] +  1
    nend   = nstart + geomparams[:SEP][:N]
    separator_porosity = model[:ELYTE].system[:separator_porosity]
    vfelyte[nstart : nend] .= separator_porosity*ones(nend - nstart + 1)
    
    model[:ELYTE].domain.representation[:volumeFraction] = vfelyte

end


function setup_battery_model(exported; include_cc = true, use_p2d = true, use_groups = false)

    function setup_component(exported, sys, bcfaces = nothing)
        
        domain = exported_model_to_domain(exported, bcfaces = bcfaces)
        G = MRSTWrapMesh(exported["G"])
        data_domain = DataDomain(G)
        for (k, v) in domain.entities
            data_domain.entities[k] = v
        end
        model = SimulationModel(domain, sys, context = DefaultContext(), data_domain = data_domain)
        return model
        
    end

    jsonNames = Dict(
        :NAM => "NegativeElectrode",
        :PAM => "PositiveElectrode",        
    )

    inputparams = exported["model"]
    
    function setup_active_material(name)
        jsonName = jsonNames[name]

        inputparams_am = inputparams[jsonName]["ActiveMaterial"]

        am_params = JutulStorage()
        am_params[:n_charge_carriers]       = inputparams_am["Interface"]["n"]
        am_params[:maximum_concentration]   = inputparams_am["Interface"]["cmax"]
        am_params[:volumetric_surface_area] = inputparams_am["Interface"]["volumetricSurfaceArea"]
        am_params[:volume_fraction]         = inputparams_am["Interface"]["volumeFraction"]
        
        k0  = inputparams_am["Interface"]["k0"]
        Eak = inputparams_am["Interface"]["Eak"]
        am_params[:reaction_rate_constant_func] = (c, T) -> compute_reaction_rate_constant(c, T, k0, Eak)
        
        if name == :NAM
            am_params[:ocp_func] = compute_ocp_graphite
        elseif name == :PAM
            am_params[:ocp_func] = compute_ocp_nmc111
        else
            error("not recongized")
        end
        T_prm = typeof(am_params)
        if use_p2d
            rp = inputparams_am["SolidDiffusion"]["rp"]
            N  = Int64(inputparams_am["SolidDiffusion"]["N"])
            D  = inputparams_am["SolidDiffusion"]["D0"]
            sys_am = ActiveMaterialP2D(am_params, rp, N, D)
        else
            sys_am = ActiveMaterialNoParticleDiffusion(am_params)
        end
        
        if  include_cc
            model_am = setup_component(inputparams_am, sys_am)
        else
            bcfaces_am = convert_to_int_vector(["externalCouplingTerm"]["couplingfaces"])
            model_am   = setup_component(inputparams_am, sys_am, bcfaces_am)
            # We add also boundary parameters (if any)
            S = model_am.parameters
            nbc = count_active_entities(model_am.domain, BoundaryDirichletFaces())
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

        inputparams_cc = inputparams["NegativeElectrode"]["CurrentCollector"]
        sys_cc      = CurrentCollector()
        bcfaces     = convert_to_int_vector(inputparams_cc["externalCouplingTerm"]["couplingfaces"])
        
        model_cc =  setup_component(inputparams_cc, sys_cc, bcfaces)
        
    end

    # Setup NAM

    model_nam = setup_active_material(:NAM)

    ## Setup ELYTE
    params = JutulStorage();
    inputparams_elyte = inputparams["Electrolyte"]
    params[:transference] = inputparams_elyte["sp"]["t"]
    params[:charge]       = inputparams_elyte["sp"]["z"]
    params[:bruggeman]    = inputparams_elyte["BruggemanCoefficient"]
    
    # setup diffusion coefficient function, hard coded for the moment because function name is not passed throught model
    # TODO : add general code
    funcname = "computeDiffusionCoefficient_default"
    func = getfield(BattMo, Symbol(funcname))
    params[:diffusivity] = func

    # setup diffusion coefficient function
    # TODO : add general code
    funcname = "computeElectrolyteConductivity_default"
    func = getfield(BattMo, Symbol(funcname))
    params[:conductivity] = func
    
    elyte = Electrolyte(params)
    model_elyte = setup_component(inputparams["Electrolyte"],
                                  elyte)

    # Setup PAM
    
    model_pam = setup_active_material(:PAM)

    # Setup negative current collector if any
    if include_cc
        model_pp = setup_component(inputparams["PositiveElectrode"]["CurrentCollector"],
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

function setup_battery_parameters_1d(jsonstruct, model)

    parameters = Dict{Symbol, Any}()

    T0 = jsonstruct["initT"]
    
    # Negative current collector (if any)

    if haskey(model.models, :CC)
        use_cc = true
    else
        use_cc = false
    end

    if use_cc
        prm_cc = Dict{Symbol, Any}()
        jsonstruct_cc = jsonstruct["NegativeElectrode"]["CurrentCollector"]
        prm_cc[:Conductivity] = jsonstruct_cc["EffectiveElectricalConductivity"]
        parameters[:CC] = setup_parameters(model[:CC], prm_cc)
    end

    # Negative active material
    
    prm_nam = Dict{Symbol, Any}()
    jsonstruct_nam = jsonstruct["NegativeElectrode"]["ActiveMaterial"]

    kappa = jsonstruct_nam["electricalConductivity"]
    vf    = jsonstruct_nam["Interface"]["volumeFraction"]
    prm_nam[:Conductivity] = vf*kappa
    prm_nam[:Temperature] = T0
    
    if discretisation_type(model[:NAM]) == :P2Ddiscretization
        # nothing to do
    else
        @assert discretisation_type(model[:NAM]) == :NoParticleDiffusion
        prm_nam[:Diffusivity] = jsonstruct_nam["InterDiffusionCoefficient"]
    end

    parameters[:NAM] = setup_parameters(model[:NAM], prm_nam)

    # Electrolyte
    
    prm_elyte = Dict{Symbol, Any}()
    prm_elyte[:Temperature] = T0        

    parameters[:ELYTE] = setup_parameters(model[:ELYTE], prm_elyte)

    # Positive active material

    prm_pam = Dict{Symbol, Any}()
    jsonstruct_pam = jsonstruct["PositiveElectrode"]["ActiveMaterial"]
    kappa = jsonstruct_pam["electricalConductivity"]
    vf    = jsonstruct_pam["Interface"]["volumeFraction"]
    prm_pam[:Conductivity] = vf*kappa
    prm_pam[:Temperature] = T0
    
    if discretisation_type(model[:PAM]) == :P2Ddiscretization
        # nothing to do
    else
        @assert discretisation_type(model[:NAM]) == :NoParticleDiffusion
        prm_pam[:Diffusivity] = jsonstruct_nam["InterDiffusionCoefficient"]
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
        jsonstruct_pp = jsonstruct["PositiveElectrode"]["CurrentCollector"]
        prm_pp[:Conductivity] = jsonstruct_pp["EffectiveElectricalConductivity"][1]
        
        parameters[:PP] = setup_parameters(model[:PP], prm_pp)
    end        

    parameters[:BPP] = setup_parameters(model[:BPP])

    return parameters
    
end

function setup_battery_initial_state_1d(jsonstruct, model)

    if haskey(model.models, :CC)
        use_cc = true
    else
        use_cc = false
    end

    T   = jsonstruct["initT"]
    SOC = jsonstruct["SOC"]

    function setup_init_am(name, model)
        
        theta0   = model[name].system[:theta0]
        theta100 = model[name].system[:theta100]
        cmax     = model[name].system[:maximum_concentration]
        N        = model[name].system.discretization[:N]
        
        theta = SOC*(theta100 - theta0) + theta0;
        c     = theta*cmax
        nc    = count_entities(model[name].data_domain, Cells())
        init = Dict()
        init[:Cs]  = c*ones(nc)
        init[:Cp]  = c*ones(nc, N)

        OCP = model[name].system[:ocp_func](c, T, cmax)
        return (init, nc, OCP)
        
    end

    function setup_cc(name, phi, model)
        nc = count_entities(model[name].data_domain, Cells())
        init = Dict();
        init[:Phi] = phi*ones(nc)
        return init
    end
    
    initState = Dict()

    # Setup initial state in negative active material
    
    init, nc, negOCP = setup_init_am(:NAM, model)
    init[:Phi] = zeros(nc)
    initState[:NAM] = init
    
    # Setup initial state in electrolyte
    
    nc = count_entities(model[:ELYTE].data_domain, Cells())
    
    init = Dict()
    init[:C]   = 1000*ones(nc)
    init[:Phi] = - negOCP*ones(nc) 

    initState[:ELYTE] = init

    # Setup initial state in positive active material
    
    init, nc, posOCP = setup_init_am(:PAM, model)
    init[:Phi] = (posOCP - negOCP)*ones(nc)
    
    initState[:PAM] = init

    # Setup negative current collector

    initState[:CC] = setup_cc(:CC, 0, model)
    
    # Setup positive current collector

    initState[:PP] = setup_cc(:PP, posOCP - negOCP, model)

    init = Dict()
    init[:Phi]     = [1.0]
    init[:Current] = [1.0]
        
    initState[:BPP] = init

    initState = setup_state(model, initState)
    
    return initState
    
end


function setup_battery_initial_state(exported, model)

    state0 = exported["state0"]

    jsonNames = Dict(
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
            init[:Phi] = state0[jsonNames[name]]["CurrentCollector"]["phi"][1]
            initState[name] = init
        end
        
    end


    function initialize_active_material!(initState, name::Symbol)
        """ initialize values for the active material"""

        jsonName = jsonNames[name]
        
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
        
        init[:Phi]   = state0[jsonName]["ActiveMaterial"]["phi"][1]

        if use_cc
            c = state0[jsonName]["ActiveMaterial"]["Interface"]["cElectrodeSurface"][1]
        else
            c = state0[jsonName]["ActiveMaterial"]["c"][1]
        end

        if  discretisation_type(sys) == :P2Ddiscretization
            init[:Cp] = c
            init[:Cs] = c
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

function setup_coupling_1d!(model, parameters, jsondict)

    geomparams = setup_geomparams(jsondict)
    
    # setup coupling CC <-> NAM :charge_conservation
    
    skip_cc = false # we consider only case with current collector (for simplicity, for the moment)
    
    if !skip_cc

        Ncc  = geomparams[:CC][:N]

        srange = Ncc
        trange = 1
        
        msource = model[:CC]
        mtarget = model[:NAM]
        
        psource = parameters[:CC]
        ptarget = parameters[:NAM]

        # Here, the indexing in BoundaryFaces is used
        couplingfaces = Array{Int64}(undef, 1, 2)
        couplingfaces[1, 1] = 2
        couplingfaces[1, 2] = 1
        
        couplingcells = Array{Int64}(undef, 1, 2)
        couplingcells[1, 1] = Ncc
        couplingcells[1, 2] = 1
        
        trans = getTrans_1d(msource, mtarget,
                            couplingfaces,
                            couplingcells,
                            psource, ptarget,
                            :Conductivity)

        ct = TPFAInterfaceFluxCT(trange, srange, trans)
        ct_pair = setup_cross_term(ct, target = :NAM, source = :CC, equation = :charge_conservation)
        add_cross_term!(model, ct_pair)
        
    end
    
    # setup coupling NAM <-> ELYTE charge

    Nnam = geomparams[:NAM][:N]
    
    srange = collect(1 : Nnam) # negative electrode
    trange = collect(1 : Nnam) # electrolyte (negative side)

    if discretisation_type(model[:NAM]) == :P2Ddiscretization

        ct = ButlerVolmerActmatToElyteCT(trange, srange)
        ct_pair = setup_cross_term(ct, target = :ELYTE, source = :NAM, equation = :charge_conservation)
        add_cross_term!(model, ct_pair)
        ct_pair = setup_cross_term(ct, target = :ELYTE, source = :NAM, equation = :mass_conservation)
        add_cross_term!(model, ct_pair)
        
        ct = ButlerVolmerElyteToActmatCT(srange, trange)
        ct_pair = setup_cross_term(ct, target = :NAM, source = :ELYTE, equation = :charge_conservation)
        add_cross_term!(model, ct_pair)
        ct_pair = setup_cross_term(ct, target = :NAM, source = :ELYTE, equation = :solid_diffusion_bc)
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

    Nnam = geomparams[:NAM][:N]
    Nsep = geomparams[:SEP][:N]
    Npam = geomparams[:PAM][:N]
    
    srange = collect(1 : Npam) # positive electrode
    trange = collect(Nnam + Nsep .+ (1 : Npam)) # electrolyte (positive side)
    
    if discretisation_type(model[:PAM]) == :P2Ddiscretization

        ct = ButlerVolmerActmatToElyteCT(trange, srange)
        ct_pair = setup_cross_term(ct, target = :ELYTE, source = :PAM, equation = :charge_conservation)
        add_cross_term!(model, ct_pair)
        ct_pair = setup_cross_term(ct, target = :ELYTE, source = :PAM, equation = :mass_conservation)
        add_cross_term!(model, ct_pair)
        
        ct = ButlerVolmerElyteToActmatCT(srange, trange)
        ct_pair = setup_cross_term(ct, target = :PAM, source = :ELYTE, equation = :charge_conservation)
        add_cross_term!(model, ct_pair)
        ct_pair = setup_cross_term(ct, target = :PAM, source = :ELYTE, equation = :solid_diffusion_bc)
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
        
        Npam  = geomparams[:PAM][:N]
        
        srange = 1
        trange = Npam
        
        msource = model[:PP]
        mtarget = model[:PAM]
        
        psource = parameters[:PP]
        ptarget = parameters[:PAM]

        # Here, the indexing in BoundaryFaces is used
        couplingfaces = Array{Int64}(undef, 1, 2)
        couplingfaces[1, 1] = 1
        couplingfaces[1, 2] = 2
        
        couplingcells = Array{Int64}(undef, 1, 2)
        couplingcells[1, 1] = 1
        couplingcells[1, 2] = Npam
        
        
        trans = getTrans_1d(msource, mtarget,
                            couplingfaces,
                            couplingcells,
                            psource, ptarget,
                            :Conductivity)

        ct = TPFAInterfaceFluxCT(trange, srange, trans)
        ct_pair = setup_cross_term(ct,
                                   target = :PAM,
                                   source = :PP,
                                   equation = :charge_conservation)
        
        add_cross_term!(model, ct_pair)
        
        # setup coupling with control
        
        Npp  = geomparams[:PP][:N]
        
        trange = Npp
        srange = Int64.(ones(size(trange)))

        msource       = model[:PP]
        mparameters   = parameters[:PP]
        # Here the indexing in BoundaryFaces in used
        couplingfaces = 2
        couplingcells = Npp
        trans = getHalfTrans_1d(msource, couplingfaces, couplingcells, mparameters, :Conductivity)

        ct = TPFAInterfaceFluxCT(trange, srange, trans, symmetric = false)
        ct_pair = setup_cross_term(ct, target = :PP, source = :BPP, equation = :charge_conservation)
        add_cross_term!(model, ct_pair)

        # Accmulation of charge
        ct = AccumulatorInterfaceFluxCT(1, trange, trans)
        ct_pair = setup_cross_term(ct, target = :BPP, source = :PP, equation = :charge_conservation)
        add_cross_term!(model, ct_pair)
       
    end
    
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
        ct_pair = setup_cross_term(ct, target = :NAM, source = :ELYTE, equation = :solid_diffusion_bc)
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
        ct_pair = setup_cross_term(ct, target = :PAM, source = :ELYTE, equation = :solid_diffusion_bc)
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


function currentFun(t::T, inputI::T, tup::T) where T
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


function computeCellCapacity(model)

    con = Constants()
    
    function computeHalfCellCapacity(name)

        ammodel = model[name]
        sys = ammodel["ActiveMaterial"]["SolidDiffusion"]
            
        F    = con.F
        n    = sys[:n_charge_carriers]
        cMax = sys[:maximum_concentration]
        vf   = sys[:volumeFraction]
        
        if name == :NAM
            thetaMax = sys[:theta100]
            thetaMin = sys[:theta0]
        elseif name == :PAM
            thetaMax = sys[:theta0]
            thetaMin = sys[:theta100]
        else
            error("name not recognized")
        end

        vols = ammodel.domain.representation[:face_weighted_volumes]
        vol = sum(vf*vols)
        
        cap_usable = (thetaMax - thetaMin)*cMax*vol*n*F
        
        return cap_usable
        
    end

    caps = [computeHalfCellCapacity(name) for name in (:NAM, :PAM)]

    return minimum(caps)
    
end

function setup_sim_1d(jsondict; use_groups = false, general_ad = false)

    model, state0, parameters = setup_model_1d(jsondict, use_groups = use_groups, general_ad = general_ad)
   
    setup_coupling_1d!(model, parameters, jsondict)

    minE = jsondict["Control"]["lowerCutoffVoltage"]

    CRate  = jsondict["Control"]["CRate"]
    cap    = computeCellCapacity(model)
    con    = Constants()
    
    inputI = (cap/con.hour)*CRate

    @. state0[:BPP][:Phi] = minE*1.5
    
    tup = Float64(jsondict["TimeStepping"]["rampupTime"])
    cFun(time) = currentFun(time, inputI, tup)
    
    currents = setup_forces(model[:BPP], policy = SimpleCVPolicy(cFun, minE))
    forces = setup_forces(model, BPP = currents) 
    
    sim = Simulator(model, state0 = state0, parameters = parameters, copy_state = true)
    
    return sim, forces, state0, parameters, model
    
end

function setup_sim(exported; use_p2d = true, use_groups = false, general_ad = false)

    #fn = string(dirname(pathof(BattMo)), "/../test/battery/data/", name, ".mat")
    #exported = MAT.matread(fn)

    model, state0, parameters = setup_model(exported, use_p2d = use_p2d, use_groups = use_groups, general_ad = general_ad)
    setup_coupling!(model, exported)
    
    inputI = 0;
    minE   = exported["model"]["Control"]["lowerCutoffVoltage"]
    steps  = size(exported["schedule"]["step"]["val"],1)
    
    #for i = 1:steps
        
    #    inputI = max(inputI, exported["states"][i]["Control"]["I"])
    #    minE   = min(minE, exported["states"][i]["Control"]["E"])
        
    #end
    CRate  = exported["model"]["Control"]["CRate"]
    #cap    = computeCellCapacity(model)
    #con    = Constants()
    
    #FIX!!!
    inputI =1.0 # (cap/con.hour)*CRate
    
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




defaultjsonfilename = string(dirname(pathof(BattMo)), "/../test/battery/data/jsonfiles/p2d_40_jl.json")



export inputRefToStates
function inputRefToStates(states, stateref)
    statesref = deepcopy(states);
    for i in 1:size(states,1)
        staterefnew = statesref[i]   
        refstep = i
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
