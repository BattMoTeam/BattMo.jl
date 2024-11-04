using Jutul

export
    run_battery,
    setup_simulation,
    setup_model


###############
# Run battery #
###############

"""
    run_battery(inputparams::AbstractInputParams; hook = nothing)

Simulate a battery for a given input (JSON file, Dict, etc.)
"""
function run_battery(inputparams::AbstractInputParams;
                     hook = nothing,
                     kwargs...)
    """
        Run battery wrapper method. Call setup_simulation function and run the simulation with the setup that is returned. A hook function can be given to modify the setup after the call to setup_simulation
    """
    
    #Setup simulation
    output = setup_simulation(inputparams; kwargs...)

    simulator = output[:simulator]
    model     = output[:model]
    state0    = output[:state0]
    forces    = output[:forces]
    timesteps = output[:timesteps]
    cfg       = output[:cfg]

    if !isnothing(hook)
        hook(simulator,
             model,
             state0,
             forces,
             timesteps,
             cfg)
    end
    
    # Perform simulation
    states, reports = simulate(state0, simulator, timesteps; forces = forces, config = cfg)

    extra = output
    extra[:timesteps] = timesteps

    if isa(inputparams, MatlabInputParams)
        cellSpecifications = nothing
    else
        cellSpecifications = computeCellSpecifications(model)
    end
    
    return (states             = states            ,
            cellSpecifications = cellSpecifications, 
            reports            = reports           ,
            inputparams        = inputparams,
            extra              = extra)
    
end


####################
# Setup simulation #
####################

function setup_simulation(inputparams::AbstractInputParams;
                          use_p2d::Bool                     = true,
                          extra_timing::Bool                = false,
                          max_step::Union{Integer, Nothing} = nothing,
                          linear_solver::Symbol             = :direct,
                          general_ad::Bool                  = false,
                          use_groups::Bool                  = false,
                          model_kwargs::NamedTuple          = NamedTuple(),
                          config_kwargs::NamedTuple         = NamedTuple())

    model, parameters = setup_model(inputparams;
                                    use_groups=use_groups,
                                    general_ad=general_ad,
                                    model_kwargs...)

    state0 = setup_initial_state(inputparams, model)

    forces = setup_forces(model)

    simulator = Simulator(model; state0=state0, parameters=parameters, copy_state=true)

    timesteps = setup_timesteps(inputparams; max_step = max_step)
    
    cfg = setup_config(simulator,
                       model,
                       linear_solver,
                       extra_timing;
                       config_kwargs...)
    
    output = Dict(:simulator   => simulator,
                  :forces      => forces,
                  :state0      => state0,
                  :parameters  => parameters,
                  :inputparams => inputparams,
                  :model       => model,
                  :timesteps   => timesteps,
                  :cfg         => cfg)
    
    return output

end


###############
# Setup model #
###############

function setup_model(inputparams::AbstractInputParams;
                     use_p2d::Bool    = true,
                     use_groups::Bool = false,
                     kwargs...)

    # setup the submodels and also return a coupling structure which is used to setup later the cross-terms
    model, couplings = setup_submodels(inputparams,
                                       use_groups = use_groups,
                                       use_p2d    = use_p2d;
                                       kwargs... )

    # setup the parameters (for each model, some parameters are declared, which gives the possibility to compute
    # sensitivities)
    parameters = setup_battery_parameters(inputparams, model)

    # setup the cross terms which couples the submodels.
    setup_coupling_cross_terms!(inputparams, model, parameters, couplings)

    setup_initial_control_policy!(model[:Control].system.policy, inputparams, parameters)
    
    return model, parameters

end


function setup_submodels(inputparams::InputParams; 
                         use_groups::Bool = false, 
                         general_ad::Bool = false,
                         kwargs...)

    include_cc = include_current_collectors(inputparams)
    
    jsondict = inputparams.dict

    grids, couplings = setup_grids_and_couplings(inputparams)

    stringNames = Dict(
        :NeAm => "NegativeElectrode",
        :PeAm => "PositiveElectrode",        
    )

    """
    Helper function to setup the active materials
    """
    function setup_active_material(name::Symbol)

        stringName = stringNames[name]

        function computeVolumeFraction(codict)
            # We compute the volume fraction form the coating data

            am = "ActiveMaterial"
            bd = "Binder"
            ad = "ConductingAdditive"

            compnames = [am, bd, ad]

            specificVolumes = zeros(length(compnames))
            for icomp in eachindex(compnames)
                compname = compnames[icomp]
                rho = codict[compname]["density"]
                mf  = codict[compname]["massFraction"]
                specificVolumes[icomp] = mf/rho
            end

            sumSpecificVolumes = sum(specificVolumes)
            volumeFractions =[sv/sumSpecificVolumes for sv in specificVolumes]
            
            effectiveDensity = codict["effectiveDensity"]
            volumeFraction = sumSpecificVolumes*effectiveDensity

            return volumeFraction, volumeFractions, effectiveDensity
            
        end

        inputparams_am = jsondict[stringName]["Coating"]["ActiveMaterial"]
        
        am_params = JutulStorage()
        vf, vfs, eff_dens = computeVolumeFraction(jsondict[stringName]["Coating"])
        am_params[:volume_fraction]         = vf
        am_params[:volume_fractions]        = vfs
        am_params[:effective_density]       = eff_dens
        am_params[:n_charge_carriers]       = inputparams_am["Interface"]["numberOfElectronsTransferred"]
        am_params[:maximum_concentration]   = inputparams_am["Interface"]["saturationConcentration"]
        am_params[:volumetric_surface_area] = inputparams_am["Interface"]["volumetricSurfaceArea"]
        am_params[:theta0]                  = inputparams_am["Interface"]["guestStoichiometry0"]
        am_params[:theta100]                = inputparams_am["Interface"]["guestStoichiometry100"]

        k0  = inputparams_am["Interface"]["reactionRateConstant"]
        Eak = inputparams_am["Interface"]["activationEnergyOfReaction"]

        am_params[:reaction_rate_constant_func] = (c, T) -> compute_reaction_rate_constant(c, T, k0, Eak)

        if haskey(inputparams_am["Interface"]["openCircuitPotential"], "function")

            am_params[:ocp_funcexp] = true
            ocp_exp = inputparams_am["Interface"]["openCircuitPotential"]["function"]
            exp = setup_ocp_evaluation_expression_from_string(ocp_exp)
            am_params[:ocp_func] = @RuntimeGeneratedFunction(exp)
            
        elseif haskey(inputparams_am["Interface"]["openCircuitPotential"], "functionname")
            
            funcname = inputparams_am["Interface"]["openCircuitPotential"]["functionname"]
            am_params[:ocp_func] = getfield(BattMo, Symbol(funcname))
            
        else
            am_params[:ocp_funcdata] = true
            data_x = inputparams_am["Interface"]["openCircuitPotential"]["data_x"]
            data_y = inputparams_am["Interface"]["openCircuitPotential"]["data_y"]

            interpolation_object = get_1d_interpolator(data_x,data_y,cap_endpoints =false)
            am_params[:ocp_func] = interpolation_object
        end
        
        use_p2d = true
        if use_p2d
            rp = inputparams_am["SolidDiffusion"]["particleRadius"]
            N  = Int64(inputparams_am["SolidDiffusion"]["N"])
            D  = inputparams_am["SolidDiffusion"]["referenceDiffusionCoefficient"]
            sys_am = ActiveMaterialP2D(am_params, rp, N, D)
        else
            sys_am = ActiveMaterialNoParticleDiffusion(am_params)
        end
        
        grid     = grids[stringName]
        coupling = couplings[stringName]

        boundary = nothing
        if !include_cc && name == :NeAm
            addDirichlet = true
            boundary = coupling["External"]
        else
            addDirichlet = false
            boundary = nothing
        end
        
        model_am = setup_component(grid,
                                   sys_am;
                                   general_ad = general_ad,
                                   dirichletBoundary = boundary)

        return model_am
        
    end
    
    ####################################
    # Setup negative current collector #
    ####################################

    if include_cc

        grid     = grids["NegativeCurrentCollector"]
        coupling = couplings["NegativeCurrentCollector"]
        
        boundary = coupling["External"]
        necc_params = JutulStorage()
        necc_params[:density] = jsondict["NegativeElectrode"]["CurrentCollector"]["density"]
        
        sys_necc = CurrentCollector(necc_params)
        model_necc = setup_component(grid,
                                     sys_necc           ,
                                     dirichletBoundary = boundary,
                                     general_ad = general_ad)
    end

    ##############
    # Setup NeAm #
    ##############
    
    model_neam = setup_active_material(:NeAm)

    ###############
    # Setup Elyte #
    ###############
    
    params = JutulStorage();
    inputparams_elyte = jsondict["Electrolyte"]
    
    params[:transference]        = inputparams_elyte["species"]["transferenceNumber"]
    params[:charge]              = inputparams_elyte["species"]["chargeNumber"]
    params[:separator_porosity]  = jsondict["Separator"]["porosity"]
    params[:bruggeman]           = inputparams_elyte["bruggemanCoefficient"]
    params[:electrolyte_density] = jsondict["Separator"]["porosity"]
    params[:separator_density]   = inputparams_elyte["density"]
    
    # setup diffusion coefficient function
    if haskey(inputparams_elyte["diffusionCoefficient"], "function")

        exp = setup_diffusivity_evaluation_expression_from_string(inputparams_elyte["diffusionCoefficient"]["function"])
        params[:diffusivity_func] = @RuntimeGeneratedFunction(exp)
        
    elseif haskey(inputparams_elyte["diffusionCoefficient"], "functionname")

        funcname = inputparams_elyte["diffusionCoefficient"]["functionname"]
        params[:diffusivity_func] = getfield(BattMo, Symbol(funcname))

    else
        data_x = inputparams_elyte["diffusionCoefficient"]["data_x"]
        data_y = inputparams_elyte["diffusionCoefficient"]["data_y"]

        interpolation = get_1d_interpolator(data_x,data_y,cap_endpoints =false)
        params[:diffusivity_data] = true
        params[:diffusivity_func] = interpolation
        
    end

    # setup conductivity function
    if haskey(inputparams_elyte["ionicConductivity"],"function")

        exp = setup_conductivity_evaluation_expression_from_string(inputparams_elyte["ionicConductivity"]["function"])
        params[:conductivity_func] = @RuntimeGeneratedFunction(exp)
        
    elseif haskey(inputparams_elyte["ionicConductivity"], "functionname")
        
        funcname = inputparams_elyte["ionicConductivity"]["functionname"]
        params[:conductivity_func] = getfield(BattMo, Symbol(funcname))

    else
        data_x = inputparams_elyte["ionicConductivity"]["data_x"]
        data_y = inputparams_elyte["ionicConductivity"]["data_y"]

        interpolation = get_1d_interpolator(data_x,data_y,cap_endpoints = false)
        params[:conductivity_data] = true
        params[:conductivity_func] = interpolation
        
    end

    elyte = Electrolyte(params)
    
    model_elyte = setup_component(grids["Electrolyte"], elyte, general_ad = general_ad)

    ##############
    # Setup PeAm #
    ##############
    
    model_peam = setup_active_material(:PeAm)

    ###########################################
    # Setup negative current collector if any #
    ###########################################
    
    if include_cc

        grid = grids["PositiveCurrentCollector"]
        pecc_params = JutulStorage()
        pecc_params[:density] = jsondict["PositiveElectrode"]["CurrentCollector"]["density"]
        
        sys_pecc = CurrentCollector(pecc_params)
        
        model_pecc = setup_component(grid, sys_pecc, 
                                     general_ad = general_ad)
    end

    #######################
    # Setup control model #
    #######################
    
    controlPolicy = jsondict["Control"]["controlPolicy"]
    
    if controlPolicy == "CCDischarge"
        
        minE   = jsondict["Control"]["lowerCutoffVoltage"]
        
        policy = SimpleCVPolicy()

    elseif controlPolicy == "CCCV"

        ctrl = jsondict["Control"]

        policy = CyclingCVPolicy(ctrl["lowerCutoffVoltage"],
                                 ctrl["upperCutoffVoltage"],
                                 ctrl["dIdtLimit"]         ,
                                 ctrl["dEdtLimit"]         ,
                                 ctrl["initialControl"]    ,
                                 ctrl["numberOfCycles"])

    else

        error("controlPolicy not recognized.")
        
    end
    
    sys_control    = CurrentAndVoltageSystem(policy)
    domain_control = CurrentAndVoltageDomain()
    model_control  = SimulationModel(domain_control, sys_control, context = DefaultContext())

    #####################
    # Setup multi-model #
    #####################

    if !include_cc
        groups = nothing
        model = MultiModel(
            (
                NeAm    = model_neam, 
                Elyte   = model_elyte, 
                PeAm    = model_peam, 
                Control = model_control,
            ),
            Val(:Battery);
            groups = groups)    
    else
        models = (
            NeCc    = model_necc, 
            NeAm    = model_neam, 
            Elyte   = model_elyte, 
            PeAm    = model_peam, 
            PeCc    = model_pecc,
            Control = model_control
        )
        if use_groups
            groups = ones(Int64, length(models))
            # Should be Control
            groups[end] = 2
            reduction = :schur_apply
        else
            groups    = nothing
            reduction = :reduction
        end
        model = MultiModel(models,
                           Val(:Battery);
                           groups = groups, reduction = reduction)

    end

    setup_volume_fractions!(model, grids, couplings["Electrolyte"])

    output = (model      = model,
              couplings  = couplings)
    
    return output
    
end

#################################################################
# Setup grids and coupling for the given geometrical parameters #
#################################################################

function setup_grids_and_couplings(inputparams::InputParams)


    case_type = inputparams["Geometry"]["case"]

    if case_type == "1D"

        grids, couplings = one_dimensional_grid(inputparams)
        
    elseif case_type == "3D-demo"
        
        grids, couplings = pouch_grid(inputparams)
        
    else
        
        error("geometry case type not recognized")
        
    end       
    
    return grids, couplings
    
end

function setup_component(grid::Jutul.FiniteVolumeMesh,
                         sys;
                         general_ad::Bool=false,
                         dirichletBoundary = nothing)

    domain = DataDomain(grid)

    # opertors only use geometry not property
    k = ones(number_of_cells(grid))
    
    T    = compute_face_trans(domain, k)
    T_hf = compute_half_face_trans(domain, k)
    T_b  = compute_boundary_trans(domain, k)
    
    domain[:trans, Faces()]           = T
    domain[:halfTrans, HalfFaces()]   = T_hf
    domain[:bcTrans, BoundaryFaces()] = T_b
    
    if !isnothing(dirichletBoundary)

        bfaces = dirichletBoundary["boundaryfaces"]
        nb = size(bfaces,1)
        domain.entities[BoundaryDirichletFaces()] =  nb

        bcDirFace = dirichletBoundary["boundaryfaces"] # in BoundaryFaces indexing
        bcDirCell = dirichletBoundary["cells"]
        
        bcDirInd  = Vector{Int64}(1:nb)
        domain[:bcDirHalfTrans, BoundaryDirichletFaces()] = domain[:bcTrans][bcDirFace]
        domain[:bcDirCells, BoundaryDirichletFaces()]     = bcDirCell 
        domain[:bcDirInds, BoundaryDirichletFaces()]      = bcDirInd 
        
    end
    
    if general_ad
        flow = PotentialFlow(grid)
    else
        flow = TwoPointPotentialFlowHardCoded(grid)
    end
    disc = (charge_flow=flow,)
    domain = DiscretizedDomain(domain, disc)

    model = SimulationModel(domain, sys, context=DefaultContext())

    return model

end

############################
# Setup battery parameters #
############################

function setup_battery_parameters(inputparams::InputParams, 
                                  model::MultiModel
                                  )

    function computeEffectiveConductivity(comodel, coinputparams)

        # Compute effective conductivity for the coating

        # First we compute the intrinsic conductivity as volume weight average of the subcomponents
        am = "ActiveMaterial"
        bd = "Binder"
        ad = "ConductingAdditive"
        
        compnames = [am, bd, ad]

        vfs = comodel.system.params[:volume_fractions]
        kappa = 0
        for icomp in eachindex(compnames)
            compname = compnames[icomp]
            vf = vfs[icomp]
            kappa += vf*coinputparams[compname]["electronicConductivity"]
        end

        vf = comodel.system.params[:volume_fraction]
        bg = coinputparams["bruggemanCoefficient"]

        kappaeff = (vf^bg)*kappa

        return kappaeff
        
    end

    parameters = Dict{Symbol, Any}()

    T0 = inputparams["initT"]

    include_cc = include_current_collectors(model)

    if include_cc
        
        #######################################
        # Negative current collector (if any) #
        #######################################
        
        prm_necc = Dict{Symbol, Any}()
        inputparams_necc = inputparams["NegativeElectrode"]["CurrentCollector"]
        prm_necc[:Conductivity] = inputparams_necc["electronicConductivity"]
        parameters[:NeCc] = setup_parameters(model[:NeCc], prm_necc)
        
    end

    ############################
    # Negative active material #
    ############################
    
    prm_neam = Dict{Symbol, Any}()
    inputparams_neam = inputparams["NegativeElectrode"]["Coating"]["ActiveMaterial"]

    prm_neam[:Conductivity] = computeEffectiveConductivity(model[:NeAm], inputparams["NegativeElectrode"]["Coating"])
    prm_neam[:Temperature] = T0
    
    if discretisation_type(model[:NeAm]) == :P2Ddiscretization
        # nothing to do
    else
        @assert discretisation_type(model[:NeAm]) == :NoParticleDiffusion
        prm_neam[:Diffusivity] = inputparams_neam["InterDiffusionCoefficient"]
    end

    parameters[:NeAm] = setup_parameters(model[:NeAm], prm_neam)

    ###############
    # Electrolyte #
    ###############
    
    prm_elyte = Dict{Symbol, Any}()
    prm_elyte[:Temperature] = T0 
    

    parameters[:Elyte] = setup_parameters(model[:Elyte], prm_elyte)

    ############################
    # Positive active material #
    ############################

    prm_peam = Dict{Symbol, Any}()
    inputparams_peam = inputparams["PositiveElectrode"]["Coating"]["ActiveMaterial"]

    prm_peam[:Conductivity] = computeEffectiveConductivity(model[:PeAm], inputparams["PositiveElectrode"]["Coating"])
    prm_peam[:Temperature] = T0
    
    
    if discretisation_type(model[:PeAm]) == :P2Ddiscretization
        # nothing to do
    else
        @assert discretisation_type(model[:NeAm]) == :NoParticleDiffusion
        prm_peam[:Diffusivity] = inputparams_peam["InterDiffusionCoefficient"]
    end

    parameters[:PeAm] = setup_parameters(model[:PeAm], prm_peam)

    if include_cc

        #######################################
        # Positive current collector (if any) #
        #######################################

        prm_pecc = Dict{Symbol, Any}()
        inputparams_pecc = inputparams["PositiveElectrode"]["CurrentCollector"]
        prm_pecc[:Conductivity] = inputparams_pecc["electronicConductivity"]
        
        parameters[:PeCc] = setup_parameters(model[:PeCc], prm_pecc)
    end        

    ###########
    # Control #
    ###########
    
    prm_control = Dict{Symbol, Any}()

    controlPolicy = inputparams["Control"]["controlPolicy"]
    
    if  controlPolicy == "CCDischarge"
        
        cap = computeCellCapacity(model)
        con = Constants()

        DRate = inputparams["Control"]["DRate"]
        prm_control[:ImaxDischarge] = (cap/con.hour)*DRate
        
        parameters[:Control] = setup_parameters(model[:Control], prm_control)
        
    elseif controlPolicy == "CCCV"

        cap = computeCellCapacity(model)
        con = Constants()

        DRate = inputparams["Control"]["DRate"]
        CRate = inputparams["Control"]["CRate"]
        prm_control[:ImaxDischarge] = (cap/con.hour)*DRate        
        prm_control[:ImaxCharge]    = (cap/con.hour)*CRate
        
        parameters[:Control] = setup_parameters(model[:Control], prm_control)
        
    else
        error("control policy $controlPolicy not recognized")
    end

    return parameters
    
end

#######################
# Setup initial state #
#######################


function setup_initial_state(inputparams::InputParams,
                             model::MultiModel)

    include_cc = include_current_collectors(model)

    T        = inputparams["initT"]
    SOC_init = inputparams["SOC"]

    function setup_init_am(name, model)
        
        theta0   = model[name].system[:theta0]
        theta100 = model[name].system[:theta100]
        cmax     = model[name].system[:maximum_concentration]
        N        = model[name].system.discretization[:N]
        refT = 298.15
        
        theta = SOC_init*(theta100 - theta0) + theta0;
        c     = theta*cmax
        SOC = SOC_init
        nc    = count_entities(model[name].data_domain, Cells())
        init = Dict()
        init[:Cs]  = c*ones(nc)
        init[:Cp]  = c*ones(N, nc)

        if Jutul.haskey(model[name].system.params, :ocp_funcexp)
            OCP = model[name].system[:ocp_func](c, T, refT, cmax)
        elseif Jutul.haskey(model[name].system.params, :ocp_funcdata)
            
            OCP = model[name].system[:ocp_func](theta)

        else
            OCP = model[name].system[:ocp_func](c, T, cmax)
        end

        return (init, nc, OCP)
        
    end

    function setup_current_collector(name, phi, model)
        nc = count_entities(model[name].data_domain, Cells())
        init = Dict();
        init[:Phi] = phi*ones(nc)
        return init
    end
    
    initState = Dict()

    # Setup initial state in negative active material
    
    init, nc, negOCP = setup_init_am(:NeAm, model)
    init[:Phi] = zeros(nc)
    initState[:NeAm] = init
    
    # Setup initial state in electrolyte
    
    nc = count_entities(model[:Elyte].data_domain, Cells())
    
    init = Dict()
    init[:C]   = inputparams["Electrolyte"]["initialConcentration"]*ones(nc)
    init[:Phi] = - negOCP*ones(nc) 

    initState[:Elyte] = init

    # Setup initial state in positive active material
    
    init, nc, posOCP = setup_init_am(:PeAm, model)
    init[:Phi] = (posOCP - negOCP)*ones(nc)
    
    initState[:PeAm] = init

    if include_cc
        # Setup negative current collector
        initState[:NeCc] = setup_current_collector(:NeCc, 0, model)
        # Setup positive current collector
        initState[:PeCc] = setup_current_collector(:PeCc, posOCP - negOCP, model)
    end
    
    init = Dict()
    init[:Phi]     = posOCP - negOCP
    init[:Current] = getInitCurrent(model[:Control])

    initState[:Control] = init

    initState = setup_state(model, initState)

    return initState
    
end

##################
# Setup coupling #
##################

function setup_coupling_cross_terms!(inputparams::InputParams,
                         model::MultiModel,
                         parameters::Dict{Symbol,<:Any},
                         couplings)

    include_cc = inputparams["include_current_collectors"]


    stringNames = Dict(:NeCc  => "NegativeCurrentCollector",
                       :NeAm => "NegativeElectrode",
                       :PeAm => "PositiveElectrode",        
                       :PeCc  => "PositiveCurrentCollector")

    #################################
    # Setup coupling NeAm <-> Elyte #
    #################################

    srange = collect(couplings["NegativeElectrode"]["Electrolyte"]["cells"]) 
    trange = collect(couplings["Electrolyte"]["NegativeElectrode"]["cells"]) # electrolyte (negative side)

    if discretisation_type(model[:NeAm]) == :P2Ddiscretization

        ct = ButlerVolmerActmatToElyteCT(trange, srange)
        ct_pair = setup_cross_term(ct, target = :Elyte, source = :NeAm, equation = :charge_conservation)
        add_cross_term!(model, ct_pair)
        ct_pair = setup_cross_term(ct, target = :Elyte, source = :NeAm, equation = :mass_conservation)
        add_cross_term!(model, ct_pair)

        ct = ButlerVolmerElyteToActmatCT(srange, trange)
        ct_pair = setup_cross_term(ct, target = :NeAm, source = :Elyte, equation = :charge_conservation)
        add_cross_term!(model, ct_pair)
        ct_pair = setup_cross_term(ct, target = :NeAm, source = :Elyte, equation = :solid_diffusion_bc)
        add_cross_term!(model, ct_pair)

    else

        @assert discretisation_type(model[:NeAm]) == :NoParticleDiffusion

        ct = ButlerVolmerInterfaceFluxCT(trange, srange)
        ct_pair = setup_cross_term(ct, target = :Elyte, source = :NeAm, equation = :charge_conservation)
        add_cross_term!(model, ct_pair)
        ct_pair = setup_cross_term(ct, target = :Elyte, source = :NeAm, equation = :mass_conservation)
        add_cross_term!(model, ct_pair)

    end
    
    #################################
    # setup coupling Elyte <-> PeAm #
    #################################

    srange = collect(couplings["PositiveElectrode"]["Electrolyte"]["cells"])
    trange = collect(couplings["Electrolyte"]["PositiveElectrode"]["cells"])

    if discretisation_type(model[:PeAm]) == :P2Ddiscretization

        ct = ButlerVolmerActmatToElyteCT(trange, srange)
        ct_pair = setup_cross_term(ct, target = :Elyte, source = :PeAm, equation = :charge_conservation)
        add_cross_term!(model, ct_pair)
        ct_pair = setup_cross_term(ct, target = :Elyte, source = :PeAm, equation = :mass_conservation)
        add_cross_term!(model, ct_pair)

        ct = ButlerVolmerElyteToActmatCT(srange, trange)
        ct_pair = setup_cross_term(ct, target = :PeAm, source = :Elyte, equation = :charge_conservation)
        add_cross_term!(model, ct_pair)
        ct_pair = setup_cross_term(ct, target = :PeAm, source = :Elyte, equation = :solid_diffusion_bc)
        add_cross_term!(model, ct_pair)

    else

        @assert discretisation_type(model[:PeAm]) == :NoParticleDiffusion    

        ct = ButlerVolmerInterfaceFluxCT(trange, srange)
        ct_pair = setup_cross_term(ct, target = :Elyte, source = :PeAm, equation = :charge_conservation)
        add_cross_term!(model, ct_pair)
        ct_pair = setup_cross_term(ct, target = :Elyte, source = :PeAm, equation = :mass_conservation)
        add_cross_term!(model, ct_pair)

    end

    if include_cc 

        ################################
        # Setup coupling NeCc <-> NeAm #
        ################################

        #Ncc  = geomparams[:NeCc][:N]

        srange_cells = collect(couplings["NegativeCurrentCollector"]["NegativeElectrode"]["cells"])
        trange_cells = collect(couplings["NegativeElectrode"]["NegativeCurrentCollector"]["cells"])

        srange_faces = collect(couplings["NegativeCurrentCollector"]["NegativeElectrode"]["faces"])
        trange_faces = collect(couplings["NegativeElectrode"]["NegativeCurrentCollector"]["faces"])

        msource = model[:NeCc]
        mtarget = model[:NeAm]

        psource = parameters[:NeCc]
        ptarget = parameters[:NeAm]

        # Here, the indexing in BoundaryFaces is used
        couplingfaces = Array{Int64}(undef, size(srange_faces,1), 2)
        couplingfaces[:, 1] = srange_faces
        couplingfaces[:, 2] = trange_faces

        couplingcells = Array{Int64}(undef, size(srange_faces,1), 2)
        couplingcells[:, 1] = srange_cells
        couplingcells[:, 2] = trange_cells

        trans = getTrans(msource, mtarget,
                         couplingfaces,
                         couplingcells,
                         psource, ptarget,
                         :Conductivity)
        @assert size(trans,1) == size(srange_cells,1)
        ct = TPFAInterfaceFluxCT(trange_cells, srange_cells, trans)
        ct_pair = setup_cross_term(ct, target = :NeAm, source = :NeCc, equation = :charge_conservation)
        add_cross_term!(model, ct_pair)

        ################################
        # setup coupling PeCc <-> PeAm #
        ################################

        #Npam  = geomparams[:PeAm][:N]

        srange_cells = collect(couplings["PositiveCurrentCollector"]["PositiveElectrode"]["cells"])
        trange_cells = collect(couplings["PositiveElectrode"]["PositiveCurrentCollector"]["cells"])

        srange_faces = collect(couplings["PositiveCurrentCollector"]["PositiveElectrode"]["faces"])
        trange_faces = collect(couplings["PositiveElectrode"]["PositiveCurrentCollector"]["faces"])

        msource = model[:PeCc]
        mtarget = model[:PeAm]

        psource = parameters[:PeCc]
        ptarget = parameters[:PeAm]

        # Here, the indexing in BoundaryFaces is used
        couplingfaces = Array{Int64}(undef, size(srange_faces,1), 2)
        couplingfaces[:, 1] = srange_faces
        couplingfaces[:, 2] = trange_faces


        couplingcells = Array{Int64}(undef, size(srange_faces,1), 2)
        couplingcells[:, 1] = srange_cells
        couplingcells[:, 2] = trange_cells

        trans = getTrans(msource, mtarget,
                         couplingfaces,
                         couplingcells,
                         psource, ptarget,
                         :Conductivity)
        @assert size(trans,1) == size(srange_cells,1)  
        ct = TPFAInterfaceFluxCT(trange_cells, srange_cells, trans)
        ct_pair = setup_cross_term(ct, target = :PeAm, source = :PeCc, equation = :charge_conservation)

        add_cross_term!(model, ct_pair)

    end

    ########################################
    # setup coupling PeCc/NeAm <-> control #
    ########################################

    if include_cc
        controlComp = :PeCc
    else
        controlComp = :PeAm
    end

    stringControlComp = stringNames[controlComp]
    
    trange = couplings[stringControlComp]["External"]["cells"]
    srange = Int64.(ones(size(trange)))

    msource     = model[controlComp]
    mparameters = parameters[controlComp]
    
    # Here the indexing in BoundaryFaces in used
    couplingfaces = couplings[stringControlComp]["External"]["boundaryfaces"]
    couplingcells = trange 
    trans = getHalfTrans(msource, couplingfaces, couplingcells, mparameters, :Conductivity)

    ct = TPFAInterfaceFluxCT(trange, srange, trans, symmetric = false)
    ct_pair = setup_cross_term(ct, target = controlComp, source = :Control, equation = :charge_conservation)
    add_cross_term!(model, ct_pair)

    ct = AccumulatorInterfaceFluxCT(1, trange, trans)
    ct_pair = setup_cross_term(ct, target = :Control, source = controlComp, equation = :charge_conservation)
    add_cross_term!(model, ct_pair)


end

######################
# Setup timestepping #
######################

function setup_timesteps(inputparams::InputParams;
                         kwargs ...)
    """
        Method setting up the timesteps from a json file object. 
    """

    controlPolicy = inputparams["Control"]["controlPolicy"]
    
    if controlPolicy == "CCDischarge"

        DRate = inputparams["Control"]["DRate"]
        con   = Constants()
        totalTime = 1.1*con.hour/DRate

        if haskey(inputparams["TimeStepping"], "totalTime")
            @warn "totalTime value is given but not used"
        end

        if haskey(inputparams["TimeStepping"], "timeStepDuration")
            dt = inputparams["TimeStepping"]["timeStepDuration"]
            if haskey(inputparams["TimeStepping"], "numberOfTimeSteps")
                @warn "Number of time steps is given but not used"
            end
        else
            n = inputparams["TimeStepping"]["numberOfTimeSteps"]
            dt = totalTime / n
        end
        if haskey(inputparams["TimeStepping"], "useRampup") && inputparams["TimeStepping"]["useRampup"]
            nr = inputparams["TimeStepping"]["numberOfRampupSteps"]
        else
            nr = 1
        end
            
        timesteps = rampupTimesteps(totalTime, dt, nr)

    elseif controlPolicy == "CCCV"
        
        ncycles = inputparams["Control"]["numberOfCycles"]
        DRate = inputparams["Control"]["DRate"]
        CRate = inputparams["Control"]["CRate"]

        con   = Constants()
        
        totalTime = ncycles*1.5*(1*con.hour/CRate + 1*con.hour/DRate);
        
        if haskey(inputparams["TimeStepping"], "totalTime")
            @warn "totalTime value is given but not used"
        end

        if haskey(inputparams["TimeStepping"], "timeStepDuration")
            dt = inputparams["TimeStepping"]["timeStepDuration"]
            n  = Int64(floor(totalTime/dt))
            if haskey(inputparams["TimeStepping"], "numberOfTimeSteps")
                @warn "Number of time steps is given but not used"
            end
        else
            n  = inputparams["TimeStepping"]["numberOfTimeSteps"]
            dt = totalTime / n
        end

        timesteps = repeat([dt], n)

    else

        error("Control policy $controlPolicy not recognized")

    end
        
    return timesteps
end

######################################
# Setup solver configuration options #
######################################

"""
    setup_config(sim::Jutul.JutulSimulator,
                      model::MultiModel        ,
                      linear_solver::Symbol    ,
                      extra_timing::Bool;
                      kwargs...)

Sets up the config object used during simulation. In this current version this
setup is the same for json and mat files. The specific setup values should
probably be given as inputs in future versions of BattMo.jl
"""
function setup_config(sim::Jutul.JutulSimulator,
                      model::MultiModel        ,
                      linear_solver::Symbol    ,
                      extra_timing::Bool;
                      kwargs...)

    cfg = simulator_config(sim; kwargs...)
    
    cfg[:linear_solver]              = battery_linsolve(model, linear_solver)
    cfg[:debug_level]                = 0
    cfg[:max_timestep_cuts]          = 10
    cfg[:max_residual]               = 1e20
    cfg[:min_nonlinear_iterations]   = 1
    cfg[:extra_timing]               = extra_timing
    # cfg[:max_nonlinear_iterations] = 5
    cfg[:safe_mode]                  = false
    cfg[:error_on_incomplete]        = false
    cfg[:failure_cuts_timestep]      = true

    for key in Jutul.submodels_symbols(model)
        cfg[:tolerances][key][:default]  = 1e-5
    end
    
    if model[:Control].system.policy isa CyclingCVPolicy

        cfg[:tolerances][:global_convergence_check_function] = (model, storage) -> check_constraints(model, storage)

        function post_hook(done, report, sim, dt, forces, max_iter, cfg)

            s = Jutul.get_simulator_storage(sim)
            m = Jutul.get_simulator_model(sim)

            if s.state.Control.ControllerCV.numberOfCycles >= m[:Control].system.policy.numberOfCycles
                report[:stopnow] = true
            else
                report[:stopnow] = false
            end
            
            return (done, report)
            
        end

        cfg[:post_ministep_hook] = post_hook

    end
    
    return cfg
    
end


####################
# Current function #
####################

function currentFun(t::T, inputI::T, tup::T = 0.1) where T
    val::T = 0.0
    if  t <= tup
        val = sineup(0.0, inputI, 0.0, tup, t) 
    else
        val = inputI
    end
    return val
end

#########################
# Setup volume fraction # 
#########################

function setup_volume_fractions!(model::MultiModel, grids, coupling)

    Nelyte      = number_of_cells(grids["Electrolyte"])
    vfelyte     = zeros(Nelyte)
    vfseparator = zeros(Nelyte)

    names = [:NeAm, :PeAm]
    stringNames = Dict(:NeAm => "NegativeElectrode",
                       :PeAm => "PositiveElectrode" )

    for name in names
        stringName = stringNames[name]
        ncell = number_of_cells(grids[stringName])
        ammodel = model[name]
        vf = ammodel.system[:volume_fraction]
        ammodel.domain.representation[:volumeFraction] = vf*ones(ncell)
        elytecells = coupling[stringName]["cells"]
        vfelyte[elytecells] .= 1 - vf 
    end

    separator_porosity = model[:Elyte].system[:separator_porosity]
    elytecells         = coupling["Separator"]["cells"]

    vfelyte[elytecells]     .= separator_porosity*ones()
    vfseparator[elytecells] .= (1 -separator_porosity)
    
    model[:Elyte].domain.representation[:volumeFraction] = vfelyte
    model[:Elyte].domain.representation[:separator_volume_fraction] = vfseparator
    
end

######################
# Transmissibilities #
######################

function getTrans(model1::Dict{String,<:Any},
                  model2::Dict{String, Any}, 
                  faces, 
                  cells, 
                  quantity::String)
    """ setup transmissibility for coupling between models at boundaries"""

    T_all1 = model1["G"]["operators"]["T_all"][faces[:, 1]]
    T_all2 = model2["G"]["operators"]["T_all"][faces[:, 2]]


    function getcellvalues(values, cellinds)

        if length(values) == 1
            values = values*ones(length(cellinds))
        else
            values = values[cellinds]
        end
        return values
        
    end
    
    s1  = getcellvalues(model1[quantity], cells[:, 1])
    s2  = getcellvalues(model2[quantity], cells[:, 2])
    
    T   = 1.0./((1.0./(T_all1.*s1))+(1.0./(T_all2.*s2)))

    return T
    
end

function getTrans(model1::Jutul.SimulationModel, 
                  model2::Jutul.SimulationModel, 
                  bcfaces, 
                  bccells, 
                  parameters1, 
                  parameters2, 
                  quantity)
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

function getHalfTrans(model::Jutul.SimulationModel, 
                      bcfaces, 
                      bccells, 
                      parameters, 
                      quantity)
    """ recover half transmissibilities for boundary faces and  weight them by the coefficient sent as quantity for the corresponding given cells. Intermediate 1d version. Note the indexing in BoundaryFaces is used"""

    d = physical_representation(model)
    bcTrans = d[:bcTrans][bcfaces]
    s       = parameters[quantity][bccells]
    
    T   = bcTrans.*s

    return T
end

function getHalfTrans(model::Dict{String, Any}, 
                      faces, 
                      cells, 
                      quantity::String)
    """ recover half transmissibilities for boundary faces and  weight them by the coefficient sent as quantity for the given cells.
    Here, the faces should belong the corresponding cells at the same index"""

    T_all = model["G"]["operators"]["T_all"]
    s = model[quantity]
    if length(s) == 1
        s = s*ones(length(cells))
    else
        s = s[cells]
    end
    
    T = T_all[faces].*s

    return T
    
end

function getHalfTrans(model::Dict{String,<:Any}, 
                      faces)
    """ recover the half transmissibilities for boundary faces"""
    
    T_all = model["G"]["operators"]["T_all"]
    T = T_all[faces]
    
    return T
    
end


#############
# Utilities #
#############

function include_current_collectors(inputparams::InputParams)

    jsondict = inputparams.dict

    if haskey(jsondict, "include_current_collectors") && !jsondict["include_current_collectors"]
        include_cc = false
    else
        include_cc = true
    end
    
    return include_cc
    
end

function include_current_collectors(model)
    
    if haskey(model.models, :NeCc)
        include_cc = true
        @assert haskey(model.models, :PeCc)
    else
        include_cc = false
        @assert !haskey(model.models, :PeCc)
    end

    return include_cc
    
end

function rampupTimesteps(time::Real, dt::Real, n::Integer=8)

    ind = collect(range(n, 1, step = -1))
    dt_init = [dt / 2^k for k in ind]
    cs_time = cumsum(dt_init)
    if any(cs_time .> time)
        dt_init = dt_init[cs_time.<time]
    end
    dt_left = time .- sum(dt_init)

    # Even steps
    dt_rem = dt * ones(floor(Int64, dt_left / dt))
    # Final ministep if present
    dt_final = time - sum(dt_init) - sum(dt_rem)
    # Less than to account for rounding errors leading to a very small
    # negative time-step.
    if dt_final <= 0
        dt_final = []
    end
    # Combined timesteps
    dT = [dt_init; dt_rem; dt_final]

    return dT
end


struct SourceAtCell
    cell
    src
    function SourceAtCell(cell, src)
        new(cell, src)
    end
end

function convert_to_int_vector(x::Float64)
    vec = Int64.(Vector{Float64}([x]))
    return vec
end

function convert_to_int_vector(x::Matrix{Float64})
    vec = Int64.(Vector{Float64}(x[:, 1]))
    return vec
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


