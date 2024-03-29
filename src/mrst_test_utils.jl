############################################################################################
#Exported functions:
############################################################################################

export run_battery, inputRefToStates, computeCellCapacity, Constants

############################################################################################
#Run battery 
############################################################################################

function run_battery(init::InputFile;   
                    use_p2d::Bool                     = true,
                    extra_timing::Bool                = false,
                    max_step::Union{Integer, Nothing} = nothing,
                    linear_solver::Symbol             = :direct,
                    general_ad::Bool                  = false,
                    use_groups::Bool                  = false,
                    kwarg...)
    """
        Run battery wrapper method. Can use inputs from either Matlab or Json files and performs
        simulation using a simple discharge CV policy
    """

    #Setup simulation
    sim, forces, state0, parameters, init, model = setup_sim(init, use_p2d=use_p2d, use_groups=use_groups, general_ad=general_ad)

    #Set up config and timesteps
    timesteps = setup_timesteps(init; max_step = max_step)
    cfg = setup_config(sim,model,linear_solver,extra_timing; kwarg...)

    #Perform simulation
    states, reports = simulate(state0, sim, timesteps, forces=forces, config=cfg; kwarg ...)

    extra = Dict(:model => model,
                 :state0 => state0,
                 :parameters => parameters,
                 :init => init,
                 :timesteps => timesteps,
                 :config => cfg,
                 :forces => forces,
                 :simulator => sim)

    return (states=states, reports=reports, extra=extra,exported=init)
    
end

#Allows running run_battery with simple option for loading mat files
function run_battery(init::String;
                     use_p2d::Bool         = true,
                     extra_timing::Bool    = false,
                     max_step              = nothing,
                     linear_solver::Symbol = :direct,
                     general_ad::Bool      = false,
                     use_groups::Bool      = false,
                     kwarg...)
    """
        Simplifies reading pre-generated .mat files from the data repository inside BattMo.jl
    """

    #Path to mat files
    path = string(dirname(pathof(BattMo)), "/../test/battery/data/")
    suffix = ".mat"

    return run_battery(MatlabFile(path * init * suffix); 
                       use_p2d       = use_p2d, 
                       extra_timing  = extra_timing, 
                       max_step      = max_step, 
                       linear_solver = linear_solver, 
                       general_ad    = general_ad, 
                       use_groups    = use_groups,
                       kwarg...)
end

#####################################################################################
#Setup config
#####################################################################################

function setup_config(sim::Jutul.JutulSimulator,
                      model::MultiModel,
                      linear_solver::Symbol,
                      extra_timing::Bool;
                      kwarg...)
    """
        Sets up the config object used during simulation. In this current version this
        setup is the same for json and mat files. The specific setup values should
        probably be given as inputs in future versions of BattMo.jl
    """

    cfg = simulator_config(sim; kwarg...)
    cfg[:linear_solver] = battery_linsolve(model, linear_solver)
    cfg[:debug_level] = 0
    #cfg[:max_timestep_cuts]         = 0
    cfg[:max_residual] = 1e20
    cfg[:min_nonlinear_iterations] = 1
    cfg[:extra_timing] = extra_timing
    # cfg[:max_nonlinear_iterations] = 5
    cfg[:safe_mode] = false
    cfg[:error_on_incomplete] = false
    #Original matlab steps will be too large!
    cfg[:failure_cuts_timestep]=true

    # if false
    #     cfg[:info_level] = 5
    #     cfg[:max_nonlinear_iterations] = 1
    #     cfg[:max_timestep_cuts] = 0
    # end

    cfg[:tolerances][:PP][:default]  = 1e-1
    cfg[:tolerances][:BPP][:default] = 1e-1

    return cfg
    
end

#####################################################################################
#Setup timestepping
#####################################################################################

function setup_timesteps(init::JSONFile;
                         kwarg ...)
    """
        Method setting up the timesteps from a json file object. 
    """

    total = init.object["TimeStepping"]["totalTime"]
    n     = init.object["TimeStepping"]["numberOfTimeSteps"]

    dt = total / n
    timesteps = rampupTimesteps(total, dt, 5)

    return timesteps
end

function setup_timesteps(init::MatlabFile;
                         max_step::Union{Integer,Nothing} = nothing,
                         kwarg...)
    """
        Method setting up the timesteps from a mat file object. If use_state_ref is true
        the simulation will use the same timesteps as the pre-run matlab simulation.
    """

    if init.use_state_ref
        steps = size(init.object["states"], 1)
        alltimesteps = Vector{Float64}(undef, steps)
        time = 0
        end_step = 0

        #Alternative to minE=3.2
        minE = init.object["model"]["Control"]["lowerCutoffVoltage"]

        for i = 1 : steps
            alltimesteps[i] =  init.object["states"][i]["time"] - time
            time = init.object["states"][i]["time"]
            E = init.object["states"][i]["Control"]["E"]
            if (E > minE + 0.001)
                end_step = i
            end
        end
        if !isnothing(max_step)
            end_step = min(max_step, end_step)
        end
        timesteps = alltimesteps[1:end_step]
    else
        timesteps=init.object["schedule"]["step"]["val"][:]

    end

    return timesteps
end

####################################################################################
#Setup simulation
####################################################################################

#Replaces setup_sim_1d
function setup_sim(init::JSONFile;
                   use_groups::Bool = false,
                   general_ad::Bool = false,
                   kwarg ... )

    model, state0, parameters= setup_model(init, use_groups=use_groups, general_ad=general_ad; kwarg...)

    setup_coupling!(init,model,parameters)

    minE = init.object["Control"]["lowerCutoffVoltage"]

    CRate = init.object["Control"]["CRate"]
    cap = computeCellCapacity(model)
    con = Constants()

    inputI = (cap / con.hour) * CRate

    @. state0[:BPP][:Phi] = minE * 1.5

    tup = Float64(init.object["Control"]["rampupTime"])
    cFun(time) = currentFun(time, inputI, tup)

    currents = setup_forces(model[:BPP], policy=SimpleCVPolicy(cFun, minE))
    forces = setup_forces(model, BPP=currents)

    sim = Simulator(model; state0=state0, parameters=parameters, copy_state=true)

    return sim, forces, state0, parameters, init, model

end

function setup_sim(init::MatlabFile;
                   use_p2d::Bool    = true,
                   use_groups::Bool = false,
                   general_ad::Bool = false,
                   kwarg ... )

    model, state0, parameters = setup_model(init, use_p2d=use_p2d, use_groups=use_groups, general_ad=general_ad)
    setup_coupling!(init,model)

    #quantities from matlab
    minE=init.object["model"]["Control"]["lowerCutoffVoltage"]
    inputI=init.object["model"]["Control"]["Imax"]

    #@. state0[:BPP][:Phi] = state0[:PAM][:Phi][end] #minE * 1.5

    # if isempty(init.object["model"]["Control"]["tup"])
    #     cFun(time) = currentFun(time, inputI)
    # else
    #     cFun(time) = currentFun(time, inputI,init.object["model"]["Control"]["tup"])
    # end
    cFun(time) = currentFun(time,inputI)
    forces_pp = nothing

    currents = setup_forces(model[:BPP], policy=SimpleCVPolicy(cFun, minE))

    forces = Dict(
        :CC => nothing,
        :NAM => nothing,
        :ELYTE => nothing,
        :PAM => nothing,
        :PP => forces_pp,
        :BPP => currents
    )

    sim = Simulator(model; state0=state0, parameters=parameters, copy_state=true)

    return sim, forces, state0, parameters, init, model

end

#######################################################################
#Setup coupling
#######################################################################

#Replaces setup_coupling_1d!
function setup_coupling!(init::JSONFile,
                         model::MultiModel,
                         parameters::Dict{Symbol,<:Any}
                         )
    
    jsondict = init.object

    geomparams = setup_geomparams(init)
    
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
        
        trans = getTrans(msource, mtarget,
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
        
        
        trans = getTrans(msource, mtarget,
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
        trans = getHalfTrans(msource, couplingfaces, couplingcells, mparameters, :Conductivity)

        ct = TPFAInterfaceFluxCT(trange, srange, trans, symmetric = false)
        ct_pair = setup_cross_term(ct, target = :PP, source = :BPP, equation = :charge_conservation)
        add_cross_term!(model, ct_pair)

        # Accmulation of charge
        ct = AccumulatorInterfaceFluxCT(1, trange, trans)
        ct_pair = setup_cross_term(ct, target = :BPP, source = :PP, equation = :charge_conservation)
        add_cross_term!(model, ct_pair)
       
    end
    
end

function setup_coupling!(init::MatlabFile,
                         model::MultiModel
                         )
    
    # setup coupling CC <-> NAM :charge_conservation
    
    exported_all=init.object
    skip_pp = size(exported_all["model"]["include_current_collectors"]) == (0,0) #! unused
    skip_cc = false
    
    if !skip_cc
        
        srange = Int64.(
            exported_all["model"]["NegativeElectrode"]["couplingTerm"]["couplingcells"][:, 1]
            )
        trange = Int64.(
            exported_all["model"]["NegativeElectrode"]["couplingTerm"]["couplingcells"][:, 2]
        )
        
        msource = exported_all["model"]["NegativeElectrode"]["CurrentCollector"]
        mtarget = exported_all["model"]["NegativeElectrode"]["Coating"]
        couplingfaces = Int64.(exported_all["model"]["NegativeElectrode"]["couplingTerm"]["couplingfaces"])
        couplingcells = Int64.(exported_all["model"]["NegativeElectrode"]["couplingTerm"]["couplingcells"])
        trans = getTrans(msource, mtarget, couplingfaces, couplingcells, "effectiveElectronicConductivity")

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
        trans = getTrans(msource, mtarget, couplingfaces, couplingcells, "effectiveElectronicConductivity")
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
    
    #effcond = exported_all["model"]["PositiveElectrode"]["CurrentCollector"]["effectiveElectronicConductivity"]
    trans = getHalfTrans(msource, couplingfaces, couplingcells, "effectiveElectronicConductivity")

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

########################################################################
#Setup model
########################################################################

function setup_model(init::InputFile;
                     use_p2d::Bool    = true,
                     use_groups::Bool = false,
                     kwarg...)

    include_cc = true #!

    model      = setup_battery_model(init, include_cc=include_cc,use_groups=use_groups,use_p2d=use_p2d; kwarg ... )
    parameters = setup_battery_parameters(init, model)
    initState  = setup_battery_initial_state(init, model)

    return model, initState, parameters

end

###################################################################################
#Setup battery model
##################################################################################

function setup_battery_model(init::MatlabFile; 
                             include_cc::Bool = true, 
                             use_groups::Bool = false,
                             use_p2d::Bool    = true,
                             general_ad::Bool = false,
                             kwarg...)


    function setup_component(obj::Dict, 
                             sys, 
                             bcfaces = nothing,
                             general_ad::Bool = false)
        
        domain = exported_model_to_domain(obj, bcfaces = bcfaces, general_ad=general_ad)
        G = MRSTWrapMesh(obj["G"])
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

    inputparams = init.object["model"]
    
    function setup_active_material(name::Symbol, general_ad::Bool)
        jsonName = jsonNames[name]

        inputparams_co  = inputparams[jsonName]["Coating"]
        inputparams_itf = inputparams[jsonName]["Coating"]["ActiveMaterial"]["Interface"]
        inputparams_sd  = inputparams[jsonName]["Coating"]["ActiveMaterial"]["SolidDiffusion"]
        
        am_params = JutulStorage()
        am_params[:n_charge_carriers]       = inputparams_itf["numberOfElectronsTransferred"]
        am_params[:maximum_concentration]   = inputparams_itf["saturationConcentration"]
        am_params[:volumetric_surface_area] = inputparams_itf["volumetricSurfaceArea"]
        am_params[:volume_fraction]         = inputparams_co["volumeFraction"]
        am_params[:volume_fractions]        = inputparams_co["volumeFractions"]
        
        k0  = inputparams_itf["reactionRateConstant"]
        Eak = inputparams_itf["activationEnergyOfReaction"]
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
            rp = inputparams_sd["particleRadius"]
            N  = Int64(inputparams_sd["N"])
            D  = inputparams_sd["referenceDiffusionCoefficient"]
            sys_am = ActiveMaterialP2D(am_params, rp, N, D)
        else
            sys_am = ActiveMaterialNoParticleDiffusion(am_params)
        end
        
        if  include_cc
            model_am = setup_component(inputparams_co, sys_am, nothing, general_ad)
        else
            bcfaces_am = convert_to_int_vector(inputparams_co["externalCouplingTerm"]["couplingfaces"])
            model_am   = setup_component(inputparams_co, sys_am, bcfaces_am,general_ad)
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
        
        model_cc =  setup_component(inputparams_cc, sys_cc, bcfaces, general_ad)
        
    end

    # Setup NAM

    model_nam = setup_active_material(:NAM,general_ad)

    ## Setup ELYTE
    params = JutulStorage();
    inputparams_elyte = inputparams["Electrolyte"]
    params[:transference] = inputparams_elyte["species"]["transferenceNumber"]
    params[:charge]       = inputparams_elyte["species"]["chargeNumber"]
    params[:bruggeman]    = inputparams_elyte["bruggemanCoefficient"]
    
    # setup diffusion coefficient function, hard coded for the moment because function name is not passed throught model
    # TODO : add general code
    funcname = "computeDiffusionCoefficient_default"
    func = getfield(BattMo, Symbol(funcname))
    params[:diffusivity_func] = func

    # setup diffusion coefficient function
    # TODO : add general code
    funcname = "computeElectrolyteConductivity_default"
    func = getfield(BattMo, Symbol(funcname))
    params[:conductivity_func] = func
    
    elyte = Electrolyte(params)
    model_elyte = setup_component(inputparams["Electrolyte"],
                                  elyte,nothing,general_ad)

    # Setup PAM
    
    model_pam = setup_active_material(:PAM,general_ad)

    # Setup negative current collector if any
    if include_cc
        model_pp = setup_component(inputparams["PositiveElectrode"]["CurrentCollector"],
                                   CurrentCollector(),nothing,general_ad)
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

function setup_battery_model(init::JSONFile; 
                             include_cc::Bool = true, 
                             use_groups::Bool = false, 
                             general_ad::Bool = false,
                             kwarg...)
    
    geomparams = setup_geomparams(init)

    jsondict = init.object

    function setup_component(geomparam::Dict, 
                             sys; 
                             addDirichlet::Bool = false, 
                             general_ad::Bool = false)

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
            domain[:bcDirCells, BoundaryDirichletFaces()]     = bcDirCell # 
            domain[:bcDirInds, BoundaryDirichletFaces()]      = bcDirInd #
            
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

    function setup_component(geomparams::Dict, 
                             sys::Electrolyte, 
                             bcfaces = nothing; 
                             general_ad::Bool = false)

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

    
    function setup_active_material(name::Symbol, 
                                   geomparams::Dict{Symbol, <:Any})

        jsonName = jsonNames[name]

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

            return volumeFraction, volumeFractions
            
        end

        inputparams_am = jsondict[jsonName]["Coating"]["ActiveMaterial"]
        
        am_params = JutulStorage()
        vf, vfs = computeVolumeFraction(jsondict[jsonName]["Coating"])
        am_params[:volume_fraction]          = vf
        am_params[:volume_fractions]         = vfs
        am_params[:n_charge_carriers]       = inputparams_am["Interface"]["numberOfElectronsTransferred"]
        am_params[:maximum_concentration]   = inputparams_am["Interface"]["saturationConcentration"]
        am_params[:volumetric_surface_area] = inputparams_am["Interface"]["volumetricSurfaceArea"]
        am_params[:theta0]                  = inputparams_am["Interface"]["guestStoichiometry0"]
        am_params[:theta100]                = inputparams_am["Interface"]["guestStoichiometry100"]

        k0  = inputparams_am["Interface"]["reactionRateConstant"]
        Eak = inputparams_am["Interface"]["activationEnergyOfReaction"]

        ###### MERGE ######
        # am_params[:reaction_rate_constant_func] = (c, T) -> compute_reaction_rate_constant(c, T, k0, Eak)
        
        # funcname = inputparams_am["Interface"]["openCircuitPotential"]["functionname"]
        # am_params[:ocp_func] = getfield(BattMo, Symbol(funcname))
        
        am_params[:reaction_rate_constant_func] = (c, T) -> compute_reaction_rate_constant(c, T, k0, Eak)

        input_symbols = ""
        if haskey(inputparams_am["Interface"]["openCircuitPotential"],"function")
            am_params[:ocp_args] = inputparams_am["Interface"]["openCircuitPotential"]["argumentlist"]
          
            for i in collect(1:size(am_params[:ocp_args])[1])
                if i == size(am_params[:ocp_args])[1]
                    input_symbols *= am_params[:ocp_args][i]    
                else
                    input_symbols *= am_params[:ocp_args][i] * ","
                end
            end
            am_params[:ocp_eq] = jsonName * "_ocp_curve($input_symbols) = " * inputparams_am["Interface"]["openCircuitPotential"]["function"]
            am_params[:ocp_func] = getfield(BattMo, Symbol("compute_function_from_string"))
            am_params[:ocp_comp] = Base.invokelatest(am_params[:ocp_func],am_params[:ocp_eq])
            
        else
            funcname = inputparams_am["Interface"]["openCircuitPotential"]["functionname"]
            am_params[:ocp_func] = getfield(BattMo, Symbol(funcname))
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
    
    params[:transference]       = inputparams_elyte["species"]["transferenceNumber"]
    params[:charge]             = inputparams_elyte["species"]["chargeNumber"]
    params[:separator_porosity] = jsondict["Separator"]["porosity"]
    params[:bruggeman]          = inputparams_elyte["bruggemanCoefficient"]
    
    # setup diffusion coefficient function


    ##### MERGE #####

    input_symbols_diffusivity = ""
    if haskey(inputparams_elyte["diffusionCoefficient"],"function")
        params[:diffusivity_args] = inputparams_elyte["diffusionCoefficient"]["argumentlist"]
        
        for i in collect(1:size(params[:diffusivity_args])[1])
            if i == size(params[:diffusivity_args])[1]
                input_symbols_diffusivity *= params[:diffusivity_args][i]    
            else
                input_symbols_diffusivity *= params[:diffusivity_args][i] * ","
            end
        end
        params[:diffusivity_eq] = "elyte_diffusion_curve($input_symbols_diffusivity) = " * inputparams_elyte["diffusionCoefficient"]["function"]
        params[:diffusivity_func] = getfield(BattMo, Symbol("compute_function_from_string"))
        params[:diffusivity_comp] = Base.invokelatest(params[:diffusivity_func],params[:diffusivity_eq])

        
    else
        funcname = inputparams_elyte["diffusionCoefficient"]["functionname"]
        params[:diffusivity_func] = getfield(BattMo, Symbol(funcname))
    end

    # setup conductivity function

    input_symbols_conductivity = ""
    if haskey(inputparams_elyte["ionicConductivity"],"function")
        params[:conductivity_args] = inputparams_elyte["ionicConductivity"]["argumentlist"]
        
        for i in collect(1:size(params[:conductivity_args])[1])
            if i == size(params[:conductivity_args])[1]
                input_symbols_conductivity *= params[:conductivity_args][i]    
            else
                input_symbols_conductivity *= params[:conductivity_args][i] * ","
            end
        end
        params[:conductivity_eq] = "elyte_conduct_curve($input_symbols_conductivity) = " * inputparams_elyte["ionicConductivity"]["function"]
        params[:conductivity_func] = getfield(BattMo, Symbol("compute_function_from_string"))
        params[:conductivity_comp] = Base.invokelatest(params[:conductivity_func],params[:conductivity_eq])
        
    else
        funcname = inputparams_elyte["ionicConductivity"]["functionname"]
        params[:conductivity_func] = getfield(BattMo, Symbol(funcname))
    end

    
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

    setup_volume_fractions!(model, geomparams)
    
    return model
    
end

###################################################################################
# Setup battery parameters
###################################################################################

function setup_battery_parameters(init::MatlabFile, 
                                  model::MultiModel
                                  )

    parameters = Dict{Symbol, Any}() #NB

    exported=init.object

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
        prm_cc[:Conductivity] = exported_cc["effectiveElectronicConductivity"][1]
        parameters[:CC] = setup_parameters(model[:CC], prm_cc)
    end

    # Negative active material
    
    prm_nam = Dict{Symbol, Any}()
    exported_nam = exported["model"]["NegativeElectrode"]["Coating"]
    prm_nam[:Conductivity] = exported_nam["effectiveElectronicConductivity"][1]
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
    exported_pam = exported["model"]["PositiveElectrode"]["Coating"]
    prm_pam[:Conductivity] = exported_pam["effectiveElectronicConductivity"][1]
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
        prm_pp[:Conductivity] = exported_pp["effectiveElectronicConductivity"][1]
        
        parameters[:PP] = setup_parameters(model[:PP], prm_pp)
    end        

    parameters[:BPP] = setup_parameters(model[:BPP])

    return parameters
    
end

function setup_battery_parameters(init::JSONFile, 
                                  model::MultiModel
                                  )

    function computeEffectiveConductivity(comodel, cojsonstruct)
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
            kappa += vf*cojsonstruct[compname]["electronicConductivity"]
        end

        vf = comodel.system.params[:volume_fraction]
        bg = cojsonstruct["bruggemanCoefficient"]

        kappaeff = (vf^bg)*kappa

        return kappaeff
        
    end

    parameters = Dict{Symbol, Any}()

    jsonstruct=init.object

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
        prm_cc[:Conductivity] = jsonstruct_cc["electronicConductivity"]
        parameters[:CC] = setup_parameters(model[:CC], prm_cc)
    end

    # Negative active material
    
    prm_nam = Dict{Symbol, Any}()
    jsonstruct_nam = jsonstruct["NegativeElectrode"]["Coating"]["ActiveMaterial"]

    prm_nam[:Conductivity] = computeEffectiveConductivity(model[:NAM], jsonstruct["NegativeElectrode"]["Coating"])
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
    jsonstruct_pam = jsonstruct["PositiveElectrode"]["Coating"]["ActiveMaterial"]

    prm_pam[:Conductivity] = computeEffectiveConductivity(model[:PAM], jsonstruct["PositiveElectrode"]["Coating"])
    prm_pam[:Temperature] = T0
    
    
    if discretisation_type(model[:PAM]) == :P2Ddiscretization
        # nothing to do
    else
        @assert discretisation_type(model[:NAM]) == :NoParticleDiffusion
        prm_pam[:Diffusivity] = jsonstruct_pam["InterDiffusionCoefficient"]
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
        prm_pp[:Conductivity] = jsonstruct_pp["electronicConductivity"]
        
        parameters[:PP] = setup_parameters(model[:PP], prm_pp)
    end        

    parameters[:BPP] = setup_parameters(model[:BPP])

    return parameters
    
end

###################################################################################
# Setup initial state
###################################################################################

function setup_battery_initial_state(init::MatlabFile, 
                                     model::MultiModel
                                     )

    exported=init.object

    state0 = exported["initstate"]

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
        
        init[:Phi] = state0[jsonName]["Coating"]["phi"][1]

        if use_cc
            c = state0[jsonName]["Coating"]["ActiveMaterial"]["Interface"]["cElectrodeSurface"][1]
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

        init = Dict(:Phi => state0["Control"]["E"], :Current => 0*state0["Control"]["I"])
        
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


function extract_input_symbols(ex::Expr, symbols::Vector{Symbol})

    args = ex.args
    func_definition = args[1]
    input_symbols = func_definition.args[2:end]

    return input_symbols 
end

function set_symbol_values(symbols, c, refT, T, cmax, SOC)
    symbol_values = Dict{Symbol, Any}()
    
    for symbol in symbols
     
        if symbol == :c
            symbol_values[symbol] = c
        elseif symbol == :T
            symbol_values[symbol] = T
        elseif symbol == :refT
            symbol_values[symbol] = refT
        elseif symbol == :cmax
            symbol_values[symbol] = cmax
        elseif symbol == :SOC
            symbol_values[symbol] = SOC
        else
            error("Symbol $symbol not supported by BattMo OCP computation")
        end
    end
    return symbol_values
end


function setup_battery_initial_state(init::JSONFile,
                                     model::MultiModel)

    jsonstruct=init.object

    if haskey(model.models, :CC)
        use_cc = true
    else
        use_cc = false
    end

    T   = jsonstruct["initT"]
    SOC_init = jsonstruct["SOC"]


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
        init[:Cp]  = c*ones(nc, N)

        symbol_eq = ""
        if Jutul.haskey(model[name].system.params, :ocp_eq)
            ocp_eq = model[name].system[:ocp_eq]
            ocp_args = model[name].system[:ocp_args]
            
            symbols = Symbol[]
            for i in collect(1:size(ocp_args)[1])
                
                sym = Symbol(ocp_args[i])
                push!(symbols, sym)   
            end

            ocp_form = model[name].system[:ocp_comp]

            symbol_values = set_symbol_values(symbols,c,refT,T,cmax,SOC)
        
            function_arguments = [symbol_values[symbol] for symbol in symbols if haskey(symbol_values, symbol)]
            OCP = Base.invokelatest(ocp_form,function_arguments...)

        else
            OCP = model[name].system[:ocp_func](c, T, cmax)

        end

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
    init[:C]   = jsonstruct["Electrolyte"]["initialConcentration"]*ones(nc)
    init[:Phi] = - negOCP*ones(nc) 

    initState[:ELYTE] = init

    # Setup initial state in positive active material
    
    init, nc, posOCP= setup_init_am(:PAM, model)
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


##################################################################################
#Current function
##################################################################################
# function currentFun(t::T, inputI::T) where T
#     #inputI = 9.4575
#     tup = 0.1
#     val::T = 0.0
#     if  t <= tup
#         val = sineup(0.0, inputI, 0.0, tup, t) 
#     else
#         val = inputI
#     end
#     return val
# end


function currentFun(t::T, inputI::T, tup::T=0.1) where T
    val::T = 0.0
    if  t <= tup
        val = sineup(0.0, inputI, 0.0, tup, t) 
    else
        val = inputI
    end
    return val
end

##################################################################################
#Setup volume fraction 
##################################################################################

function setup_volume_fractions!(model::MultiModel, geomparams::Dict{Symbol,<:Any})

    names = (:NAM, :SEP, :PAM)
    Nelyte = sum([geomparams[name][:N] for name in names])
    vfelyte = zeros(Nelyte)
    
    names = (:NAM, :PAM)
    
    for name in names
        ammodel = model[name]
        vf = ammodel.system[:volume_fraction]
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

##################################################################################
#Transmissibilities
##################################################################################

function getTrans(model1::Dict{String,<:Any},
                  model2::Dict{String, Any}, 
                  faces, 
                  cells, 
                  quantity::String)
    """ setup transmissibility for coupling between models at boundaries"""

    T_all1 = model1["operators"]["T_all"][faces[:, 1]]
    T_all2 = model2["operators"]["T_all"][faces[:, 2]]


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

    T_all = model["operators"]["T_all"]
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
    
    T_all = model["operators"]["T_all"]
    T = T_all[faces]
    
    return T
    
end

##################################################################################
#Setup geomparams
##################################################################################

function setup_geomparams(init::JSONFile)
    
    jsondict = init.object

    names = (:CC, :NAM, :SEP, :PAM, :PP)
    geomparams = Dict(name => Dict() for name in names)

    geomparams[:CC][:N]          = jsondict["NegativeElectrode"]["CurrentCollector"]["N"]
    geomparams[:CC][:thickness]  = jsondict["NegativeElectrode"]["CurrentCollector"]["thickness"]
    geomparams[:NAM][:N]         = jsondict["NegativeElectrode"]["Coating"]["N"]
    geomparams[:NAM][:thickness] = jsondict["NegativeElectrode"]["Coating"]["thickness"]
    geomparams[:SEP][:N]         = jsondict["Separator"]["N"]
    geomparams[:SEP][:thickness] = jsondict["Separator"]["thickness"]
    geomparams[:PAM][:N]         = jsondict["PositiveElectrode"]["Coating"]["N"]
    geomparams[:PAM][:thickness] = jsondict["PositiveElectrode"]["Coating"]["thickness"]
    geomparams[:PP][:N]          = jsondict["PositiveElectrode"]["CurrentCollector"]["N"]
    geomparams[:PP][:thickness]  = jsondict["PositiveElectrode"]["CurrentCollector"]["thickness"]

    for name in names
        geomparams[name][:facearea] = jsondict["Geometry"]["faceArea"]
    end
    
    return geomparams
    
end

##################################################################################
# Compute cell capacity 
##################################################################################

function computeCellCapacity(model::MultiModel)

    con = Constants()

    function computeHalfCellCapacity(name::Symbol)

        ammodel = model[name]
        sys = ammodel.system            
        F    = con.F
        n    = sys[:n_charge_carriers]
        cMax = sys[:maximum_concentration]
        vf   = sys[:volume_fraction]
        avf  = sys[:volume_fractions][1]
        
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
        vol = sum(avf*vf*vols)
        
        cap_usable = (thetaMax - thetaMin)*cMax*vol*n*F
        
        return cap_usable
        
    end

    caps = [computeHalfCellCapacity(name) for name in (:NAM, :PAM)]

    return minimum(caps)
    
end

###################################################################################
#Other utils
###################################################################################

struct Constants
    F
    R
    hour
    function Constants()
        new(96485.3329,
            8.31446261815324,
            3600)
    end
end

struct SourceAtCell
    cell
    src
    function SourceAtCell(cell, src)
        new(cell, src)
    end
end

function rampupTimesteps(time::Real, dt::Real, n::Integer=8)

    ind = [8; collect(range(n, 1, step=-1))]
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

function convert_to_int_vector(x::Float64)
    vec = Int64.(Vector{Float64}([x]))
    return vec
end

function convert_to_int_vector(x::Matrix{Float64})
    vec = Int64.(Vector{Float64}(x[:, 1]))
    return vec
end

function inputRefToStates(states, stateref)
    statesref = deepcopy(states);
    for i in 1:size(states,1)

        staterefnew = statesref[i]   
        refstep     = i
        fields      = ["CurrentCollector","ActiveMaterial"]
        components  = ["NegativeElectrode","PositiveElectrode"]
        newkeys     = [:CC, :NAM, :PP, :PAM]
       
        ind = 1
        for component = components
            for field in fields
                state = stateref[refstep][component]
                phi_ref = state[field]["phi"]
                newcomp = newkeys[ind]
                staterefnew[newcomp][:Phi] = phi_ref        
                if haskey(state[field], "c")
                    c = state[field]["c"]
                    staterefnew[newcomp][:C] = c
                end
                ind = ind + 1
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

function exported_model_to_domain(exported;
                                  bcfaces    = nothing, 
                                  general_ad = false)

    """ Returns domain"""

    N = exported["G"]["faces"]["neighbors"]
    N = Int64.(N)

    if !isnothing(bcfaces)
        isboundary = (N[bcfaces, 1].==0) .| (N[bcfaces, 2].==0)
        @assert all(isboundary)
    
        bc_cells = N[bcfaces, 1] + N[bcfaces, 2]
        bc_hfT = getHalfTrans(exported, bcfaces)
    else
        bc_hfT = []
        bc_cells = []
    end
    
    vf = []
    if haskey(exported, "volumeFraction")
        if length(exported["volumeFraction"]) == 1
            vf = exported["volumeFraction"]
        else
            vf = exported["volumeFraction"][:, 1]
        end
    end
    
    internal_faces = (N[:, 2] .> 0) .& (N[:, 1] .> 0)
    N = copy(N[internal_faces, :]')
    
    face_areas   = vec(exported["G"]["faces"]["areas"][internal_faces])
    face_normals = exported["G"]["faces"]["normals"][internal_faces, :]./face_areas
    face_normals = copy(face_normals')
    if length(exported["G"]["cells"]["volumes"])==1
        volumes    = exported["G"]["cells"]["volumes"]
        volumes    = Vector{Float64}(undef, 1)
        volumes[1] = exported["G"]["cells"]["volumes"]
    else
        volumes = vec(exported["G"]["cells"]["volumes"])
    end
    # P = exported["operators"]["cellFluxOp"]["P"]
    # S = exported["operators"]["cellFluxOp"]["S"]
    P = []
    S = []
    T = exported["operators"]["T"].*1.0
    G = MinimalECTPFAGrid(volumes, N, vec(T);
                          bc_cells = bc_cells,
                          bc_hfT   = bc_hfT,
                          P        = P,
                          S        = S,
                          vf       = vf)

    nc = length(volumes)
    if general_ad
        flow = PotentialFlow(G)
    else
        flow = TwoPointPotentialFlowHardCoded(G)
    end
    disc = (charge_flow = flow,)
    domain = DiscretizedDomain(G, disc)

    return domain
    
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


