#export run_battery 
############################################################################################
#Run battery 
############################################################################################

function run_battery(init::InputFile,
    use_p2d::Bool=true,
    extra_timing::Bool=false,
    max_step::Int64=nothing,
    linear_solver=:direct, #Type?
    general_ad::Bool=false,
    use_groups::Bool=false,
    kwarg...)

    #Setup simulation
    sim, forces, state0, parameters, init, model = setup_sim(init, use_p2d=use_p2d, use_groups=use_groups, general_ad=general_ad)

    #Set up config and timesteps
    timesteps, cfg = prepare_simulate(init, linear_solver, model, sim, max_step, extra_timing)

    #Perform simulation
    states, reports = simulate(sim, timesteps, forces=forces, config=cfg)

    extra = Dict(:model => model,
        :state0 => state0,
        :parameters => parameters,
        :init => init,
        :timesteps => timesteps,
        :config => cfg,
        :forces => forces,
        :simulator => sim)

    return (states=states, reports=reports, extra=extra)
end

#Allows running run_battery with simple option for loading mat files
function run_battery(init::Symbol,
    use_p2d::Bool=true,
    extra_timing::Bool=false,
    max_step::Int64=nothing,
    linear_solver=:direct,
    general_ad::Bool=false,
    use_groups::Bool=false,
    kwarg...)

    path = ""
    suffix = ".mat"
    return run_battery(MatlabFile(path * init * suffix), use_p2d, extra_timing, max_step, linear_solver, general_ad, use_groups, kwarg)
end

#####################################################################################
#Prepare simulate 
#####################################################################################

function prepare_simulate(init::JSONFile,
    linear_solver,
    model,
    sim,
    max_step, #Dummy 
    extra_timing)

    total = init.object["TimeStepping"]["totalTime"]
    n = init.object["TimeStepping"]["N"]

    dt = total / n
    timesteps = rampupTimesteps(total, dt, 5)

    cfg = simulator_config(sim; kwarg...)
    cfg[:linear_solver] = battery_linsolve(model, linear_solver)
    cfg[:debug_level] = 0
    cfg[:max_residual] = 1e20
    cfg[:min_nonlinear_iterations] = 1
    cfg[:extra_timing] = extra_timing
    cfg[:safe_mode] = false
    cfg[:error_on_incomplete] = false
    cfg[:failure_cuts_timestep] = true

    if false
        cfg[:info_level] = 5
        cfg[:max_nonlinear_iterations] = 1
        cfg[:max_timestep_cuts] = 0
    end

    cfg[:tolerances][:PP][:default] = 1e-1
    cfg[:tolerances][:BPP][:default] = 1e-1
    return timesteps, cfg
end

function prepare_simulate(init::MatlabFile,
    linear_solver,
    model,
    sim,
    max_step,
    extra_timing)

    steps = size(init.object["schedule"]["step"]["val"], 1)
    alltimesteps = Vector{Float64}(undef, steps)
    time = 0
    end_step = 0
    minE = 3.2

    for i = 1:steps
        alltimesteps[i] = init.object["schedule"]["step"]["val"][i] #- time
        time = init.object["states"][i]["time"]
        E = init.object["states"][i]["Control"]["E"]
        if (E > minE + 0.001)
            end_step = i
        end
    end
    if !isnothing(max_step)
        end_step = min(max_step, end_step)
    end

    timesteps = alltimesteps

    cfg = simulator_config(sim; kwarg...)
    cfg[:linear_solver] = battery_linsolve(model, linear_solver)
    cfg[:debug_level] = 0
    #cfg[:max_timestep_cuts]         = 0
    cfg[:max_residual] = 1e20
    cfg[:min_nonlinear_iterations] = 1
    cfg[:extra_timing] = extra_timing
    # cfg[:max_nonlinear_iterations] = 5
    cfg[:safe_mode] = false
    cfg[:error_on_incomplete] = true
    if false
        cfg[:info_level] = 5
        cfg[:max_nonlinear_iterations] = 1
        cfg[:max_timestep_cuts] = 0
    end

    cfg[:tolerances][:PP][:default] = 1e-1
    cfg[:tolerances][:BPP][:default] = 1e-1
    return timesteps, cfg
end

####################################################################################
#Setup simulation
####################################################################################

#Replaces setup_sim_1d
function setup_sim(init::JSONFile;
    use_p2d=true, #Added to ensure same signature for the two methods
    use_groups=false,
    general_ad=false)

    model, state0, parameters = setup_model(init, use_groups=use_groups, general_ad=general_ad)

    setup_coupling!(init,model,parameters)

    minE = init.object["Control"]["lowerCutoffVoltage"]

    CRate = init.object["Control"]["CRate"]
    cap = computeCellCapacity(model)
    con = Constants()

    inputI = (cap / con.hour) * CRate

    @. state0[:BPP][:Phi] = minE * 1.5

    tup = Float64(init.object["TimeStepping"]["rampupTime"])
    cFun(time) = currentFun(time, inputI, tup)

    currents = setup_forces(model[:BPP], policy=SimpleCVPolicy(cFun, minE))
    forces = setup_forces(model, BPP=currents)

    sim = Simulator(model, state0=state0, parameters=parameters, copy_state=true)

    return sim, forces, state0, parameters, init, model

end

function setup_sim(init::MatlabFile;
    use_p2d::Bool=true,
    use_groups::Bool=false,
    general_ad::Bool=false)

    model, state0, parameters = setup_model(init, use_p2d=use_p2d, use_groups=use_groups, general_ad=general_ad)
    setup_coupling!(init,model)

    #########################################################
    #Setup assuming existence of stateref
    #########################################################
    inputI = 0
    minE = exported["model"]["Control"]["lowerCutoffVoltage"]
    steps = size(exported["schedule"]["step"]["val"], 1)

    for i = 1:steps

        inputI = max(inputI, exported["states"][i]["Control"]["I"])
        minE = min(minE, exported["states"][i]["Control"]["E"])

    end

    #############################################################
    #Setup when calculating minE and inputI
    #############################################################

    #CRate  = exported["model"]["Control"]["CRate"]
    #cap    = computeCellCapacity(model)
    #con    = Constants()

    #FIX!!!
    #inputI =1.0 # (cap/con.hour)*CRate

    #############################################################

    @. state0[:BPP][:Phi] = minE * 1.5
    cFun(time) = currentFun(time, inputI)
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

    sim = Simulator(model, state0=state0, parameters=parameters, copy_state=true)

    return sim, forces, state0, parameters, init, model

end

#######################################################################
#Setup coupling
#######################################################################

#Replaces setup_coupling_1d!
function setup_coupling!(init::JSONFile,
    model, #MultiModel?
    parameters)

    jsondict=init.object

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

function setup_coupling!(init::MatlabFile,
    model #MultiModel?
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

########################################################################
#Setup model
########################################################################

function setup_model(init::InputFile;
    use_p2d::Bool=true,
    use_groups::Bool=false,
    kwarg...)

    include_cc = true #!

    model = setup_battery_model(exported, use_p2d=use_p2d, include_cc=include_cc,use_groups=use_groups)
    parameters = setup_battery_parameters(exported, model)
    initState = setup_battery_initial_state(exported, model)

    return model, initState, parameters

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

function rampupTimesteps(time::Float64, dt::Float64, n::Int64=8)

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
    vec = Int64.(Vector{Float64}(x[:, 1]))
    return vec
end

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