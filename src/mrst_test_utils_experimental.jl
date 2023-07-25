
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


defaultjsonfilename = string(dirname(pathof(BattMo)), "/../test/battery/data/jsonfiles/p2d_40_jl.json")



#export inputRefToStates

