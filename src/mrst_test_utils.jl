######################
# Exported functions #
######################

export
    run_battery,
    computeCellCapacity,
    computeCellMaximumEnergy,
    computeCellEnergy,
    computeCellMass,
    computeCellSpecifications,
    computeEnergyEfficiency,
    computeDischargeEnergy,
    inputRefToStates,
    Constants


###############
# Run battery #
###############

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
    cfg = setup_config(sim, model, linear_solver, extra_timing; kwarg...)

    # Perform simulation
    states, reports = simulate(state0, sim, timesteps, forces=forces, config=cfg; kwarg ...)


    extra = Dict(:model => model,
                 :state0 => state0,
                 :parameters => parameters,
                 :init => init,
                 :timesteps => timesteps,
                 :config => cfg,
                 :forces => forces,
                 :simulator => sim)
    
    cellSpecifications = computeCellSpecifications(model)
    
    return (states             = states            ,
            cellSpecifications = cellSpecifications, 
            reports            = reports           ,
            extra              = extra             ,
            exported           = init)
    
end


################
# Setup config #
################

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
    
    cfg[:linear_solver]              = battery_linsolve(model, linear_solver)
    cfg[:debug_level]                = 0
    #cfg[:max_timestep_cuts]         = 0
    cfg[:max_residual]               = 1e20
    cfg[:min_nonlinear_iterations]   = 1
    cfg[:extra_timing]               = extra_timing
    # cfg[:max_nonlinear_iterations] = 5
    cfg[:safe_mode]                  = false
    cfg[:error_on_incomplete]        = false
    #Original matlab steps will be too large!
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

######################
# Setup timestepping #
######################

function setup_timesteps(init::JSONFile;
                         kwarg ...)
    """
        Method setting up the timesteps from a json file object. 
    """

    jsonstruct = init.object
    
    controlPolicy = jsonstruct["Control"]["controlPolicy"]
    
    if controlPolicy == "CCDischarge"

        DRate = jsonstruct["Control"]["DRate"]
        con   = Constants()
        totalTime = 1.1*con.hour/DRate

        if haskey(jsonstruct["TimeStepping"], "totalTime")
            @warn "totalTime value is given but not used"
        end

        if haskey(jsonstruct["TimeStepping"], "timeStepDuration")
            dt = jsonstruct["TimeStepping"]["timeStepDuration"]
            if haskey(jsonstruct["TimeStepping"], "numberOfTimeSteps")
                @warn "Number of time steps is given but not used"
            end
        else
            n = jsonstruct["TimeStepping"]["numberOfTimeSteps"]
            dt = totalTime / n
        end
        if haskey(jsonstruct["TimeStepping"], "useRampup") && jsonstruct["TimeStepping"]["useRampup"]
            nr = jsonstruct["TimeStepping"]["numberOfRampupSteps"]
        else
            nr = 1
        end
            
        timesteps = rampupTimesteps(totalTime, dt, nr)

    elseif controlPolicy == "CCCV"
        
        ncycles = jsonstruct["Control"]["numberOfCycles"]
        DRate = jsonstruct["Control"]["DRate"]
        CRate = jsonstruct["Control"]["CRate"]

        con   = Constants()
        
        totalTime = ncycles*1.5*(1*con.hour/CRate + 1*con.hour/DRate);
        
        if haskey(jsonstruct["TimeStepping"], "totalTime")
            @warn "totalTime value is given but not used"
        end

        if haskey(jsonstruct["TimeStepping"], "timeStepDuration")
            dt = jsonstruct["TimeStepping"]["timeStepDuration"]
            n  = Int64(floor(totalTime/dt))
            if haskey(jsonstruct["TimeStepping"], "numberOfTimeSteps")
                @warn "Number of time steps is given but not used"
            end
        else
            n  = jsonstruct["TimeStepping"]["numberOfTimeSteps"]
            dt = totalTime / n
        end

        timesteps = repeat([dt], n)

    else

        error("Control policy $controlPolicy not recognized")

    end
        
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

####################
# Setup simulation #
####################

function setup_sim(init::JSONFile;
                   use_groups::Bool = false,
                   general_ad::Bool = false,
                   kwarg ... )

    model, state0, parameters = setup_model(init, use_groups=use_groups, general_ad=general_ad; kwarg...)

    geom_case = init.object["Geometry"]["case"]
    if( geom_case == "1D")
        setup_coupling!(init, model, parameters)
    elseif (geom_case == "Grid")
        setup_coupling_grid!(init, model, parameters)
    else
        error()
    end

    setup_policy!(model[:Control].system.policy, init, parameters)
    
    minE = init.object["Control"]["lowerCutoffVoltage"]
    @. state0[:Control][:Phi] = minE * 1.5


    forces = setup_forces(model)

    sim = Simulator(model; state0=state0, parameters=parameters, copy_state=true)

    return sim, forces, state0, parameters, init, model

end

function setup_sim(init::MatlabFile;
                   use_p2d::Bool    = true,
                   use_groups::Bool = false,
                   general_ad::Bool = false,
                   kwarg ... )

    model, state0, parameters = setup_model(init, use_p2d=use_p2d, use_groups=use_groups, general_ad=general_ad)
    setup_coupling!(init, model)

    forces_pecc = nothing
    currents  = nothing

    forces = Dict(
        :NeCc => nothing,
        :NeAm => nothing,
        :Elyte => nothing,
        :PeAm => nothing,
        :PeCc => forces_pecc,
        :Control => currents
    )

    sim = Simulator(model; state0=state0, parameters=parameters, copy_state=true)

    return sim, forces, state0, parameters, init, model

end

##################
# Setup coupling #
##################

function setup_coupling!(init::JSONFile,
                         model::MultiModel,
                         parameters::Dict{Symbol,<:Any}
                         )
    
    jsondict   = init.object
    geomparams = setup_geomparams(init)
    include_cc = include_current_collectors(model)

    #################################
    # Setup coupling NeAm <-> Elyte #
    #################################
    
    Nnam = geomparams[:NeAm][:N]
    
    srange = collect(1 : Nnam) # negative electrode
    trange = collect(1 : Nnam) # electrolyte (negative side)

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
    
    Nnam = geomparams[:NeAm][:N]
    Nsep = geomparams[:SEP][:N]
    Npam = geomparams[:PeAm][:N]
    
    srange = collect(1 : Npam) # positive electrode
    trange = collect(Nnam + Nsep .+ (1 : Npam)) # electrolyte (positive side)
    
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

        Ncc  = geomparams[:NeCc][:N]

        srange = Ncc
        trange = 1
        
        msource = model[:NeCc]
        mtarget = model[:NeAm]
        
        psource = parameters[:NeCc]
        ptarget = parameters[:NeAm]

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
        ct_pair = setup_cross_term(ct, target = :NeAm, source = :NeCc, equation = :charge_conservation)
        add_cross_term!(model, ct_pair)
        
        ################################
        # setup coupling PeCc <-> PeAm #
        ################################
        
        Npam  = geomparams[:PeAm][:N]
        
        srange = 1
        trange = Npam
        
        msource = model[:PeCc]
        mtarget = model[:PeAm]
        
        psource = parameters[:PeCc]
        ptarget = parameters[:PeAm]

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
        ct_pair = setup_cross_term(ct, target = :PeAm, source = :PeCc, equation = :charge_conservation)
        
        add_cross_term!(model, ct_pair)

    end


    if include_cc
        
        ###################################
        # setup coupling PeCc <-> control #
        ###################################
        
        Nc = geomparams[:PeCc][:N]
        
        trange = Nc
        srange = Int64.(ones(size(trange)))

        msource       = model[:PeCc]
        mparameters   = parameters[:PeCc]
        # Here the indexing in BoundaryFaces in used
        couplingfaces = 2
        couplingcells = Nc
        trans = getHalfTrans(msource, couplingfaces, couplingcells, mparameters, :Conductivity)

        ct = TPFAInterfaceFluxCT(trange, srange, trans, symmetric = false)
        ct_pair = setup_cross_term(ct, target = :PeCc, source = :Control, equation = :charge_conservation)
        add_cross_term!(model, ct_pair)

        ct = AccumulatorInterfaceFluxCT(1, trange, trans)
        ct_pair = setup_cross_term(ct, target = :Control, source = :PeCc, equation = :charge_conservation)
        add_cross_term!(model, ct_pair)

    else
        
        ###################################
        # setup coupling PeAm <-> control #
        ###################################

        Nc = geomparams[:PeAm][:N]
        
        trange = Nc
        srange = Int64.(ones(size(trange)))

        msource       = model[:PeAm]
        mparameters   = parameters[:PeAm]
        
        # Here the indexing in BoundaryFaces in used
        couplingfaces = 2
        couplingcells = Nc
        trans = getHalfTrans(msource, couplingfaces, couplingcells, mparameters, :Conductivity)

        ct = TPFAInterfaceFluxCT(trange, srange, trans, symmetric = false)
        ct_pair = setup_cross_term(ct, target = :PeAm, source = :Control, equation = :charge_conservation)
        add_cross_term!(model, ct_pair)

        ct = AccumulatorInterfaceFluxCT(1, trange, trans)
        ct_pair = setup_cross_term(ct, target = :Control, source = :PeAm, equation = :charge_conservation)
        add_cross_term!(model, ct_pair)
        
    end
    
end


function setup_coupling_grid!(init::JSONFile,
    model::MultiModel,
    parameters::Dict{Symbol,<:Any}
    )

jsondict   = init.object
include_cc = init.object["include_current_collectors"]
geomparams = setup_geomparams_grid(init.object["Grids"],include_cc)
#include_cc = include_current_collectors(model)

#################################
# Setup coupling NeAm <-> Elyte #
#################################

Nnam = number_of_cells(geomparams[:NeAm])

srange = collect(1 : Nnam) # NB not givennegative electrode
trange = collect(geomparams[:couplings][:Elyte][:NeAm]) # electrolyte (negative side)

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

Nnam = number_of_cells(geomparams[:NeAm])
NSEP = number_of_cells(geomparams[:SEP])
Npam = number_of_cells(geomparams[:PeAm])


srange = collect(1 : Npam) #NB not givenositive electrode
trange = collect(geomparams[:couplings][:Elyte][:PeAm])

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

Ncc  = geomparams[:NeCc][:N]

srange = Ncc
trange = 1

msource = model[:NeCc]
mtarget = model[:NeAm]

psource = parameters[:NeCc]
ptarget = parameters[:NeAm]

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
ct_pair = setup_cross_term(ct, target = :NeAm, source = :NeCc, equation = :charge_conservation)
add_cross_term!(model, ct_pair)

################################
# setup coupling PeCc <-> PeAm #
################################

Npam  = geomparams[:PeAm][:N]

srange = 1
trange = Npam

msource = model[:PeCc]
mtarget = model[:PeAm]

psource = parameters[:PeCc]
ptarget = parameters[:PeAm]

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
ct_pair = setup_cross_term(ct, target = :PeAm, source = :PeCc, equation = :charge_conservation)

add_cross_term!(model, ct_pair)

end


if include_cc

###################################
# setup coupling PeCc <-> control #
###################################

Nc = geomparams[:PeCc][:N]

trange = Nc
srange = Int64.(ones(size(trange)))

msource       = model[:PeCc]
mparameters   = parameters[:PeCc]
# Here the indexing in BoundaryFaces in used
couplingfaces = 2
couplingcells = Nc
trans = getHalfTrans(msource, couplingfaces, couplingcells, mparameters, :Conductivity)

ct = TPFAInterfaceFluxCT(trange, srange, trans, symmetric = false)
ct_pair = setup_cross_term(ct, target = :PeCc, source = :Control, equation = :charge_conservation)
add_cross_term!(model, ct_pair)

ct = AccumulatorInterfaceFluxCT(1, trange, trans)
ct_pair = setup_cross_term(ct, target = :Control, source = :PeCc, equation = :charge_conservation)
add_cross_term!(model, ct_pair)

else

###################################
# setup coupling PeAm <-> control #
###################################
#NB hack
#Nc = geomparams[:PeAm][:N]
Npam = number_of_cells(geomparams[:PeAm])
trange = Npam
srange = Int64.(ones(size(trange)))

msource       = model[:PeAm]
mparameters   = parameters[:PeAm]

# Here the indexing in BoundaryFaces in used
## NB probably wrong
couplingfaces = 2
couplingcells = Npam
trans = getHalfTrans(msource, couplingfaces, couplingcells, mparameters, :Conductivity)

ct = TPFAInterfaceFluxCT(trange, srange, trans, symmetric = false)
ct_pair = setup_cross_term(ct, target = :PeAm, source = :Control, equation = :charge_conservation)
add_cross_term!(model, ct_pair)

ct = AccumulatorInterfaceFluxCT(1, trange, trans)
ct_pair = setup_cross_term(ct, target = :Control, source = :PeAm, equation = :charge_conservation)
add_cross_term!(model, ct_pair)

end

end



function setup_coupling!(init::MatlabFile,
                         model::MultiModel
                         )
    
    exported_all = init.object

    include_cc = include_current_collectors(model)
    
    #################################
    # setup coupling NeAm <-> Elyte #
    #################################

    srange = Int64.(exported_all["model"]["couplingTerms"][1]["couplingcells"][:, 1]) # negative electrode
    trange = Int64.(exported_all["model"]["couplingTerms"][1]["couplingcells"][:, 2]) # electrolyte (negative side)

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

    srange = Int64.(exported_all["model"]["couplingTerms"][2]["couplingcells"][:,1]) # postive electrode
    trange = Int64.(exported_all["model"]["couplingTerms"][2]["couplingcells"][:,2]) # electrolyte (positive side)
    
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
    
    if  include_cc
        
        ################################
        # setup coupling NeCc <-> NeAm #
        ################################
        
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
        ct_pair = setup_cross_term(ct, target = :NeAm, source = :NeCc, equation = :charge_conservation)
        add_cross_term!(model, ct_pair)
        
        #######################################
        # setup coupling PeCc <-> PeAm charge #
        #######################################
        
        target = Dict( 
            :model => :PeAm,
            :equation => :charge_conservation
            )
        source = Dict( 
            :model => :PeCc,
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
        ct_pair = setup_cross_term(ct, target = :PeAm, source = :PeCc, equation = :charge_conservation)
        add_cross_term!(model, ct_pair)

    end

    if include_cc
        
        ##########################################
        # setup coupling PeCc <-> Control charge #
        ##########################################

        trange = convert_to_int_vector(
                exported_all["model"]["PositiveElectrode"]["CurrentCollector"]["externalCouplingTerm"]["couplingcells"]
            )    
        srange = Int64.(ones(size(trange)))
        msource = exported_all["model"]["PositiveElectrode"]["CurrentCollector"]
        couplingfaces = Int64.(msource["externalCouplingTerm"]["couplingfaces"])
        couplingcells = Int64.(msource["externalCouplingTerm"]["couplingcells"])

        component = :PeCc
        
    else
        
        ##########################################
        # setup coupling PeAm <-> Control charge #
        ##########################################

        trange = convert_to_int_vector(
                exported_all["model"]["PositiveElectrode"]["Coating"]["externalCouplingTerm"]["couplingcells"]
            )
        srange = Int64.(ones(size(trange)))
        msource = exported_all["model"]["PositiveElectrode"]["Coating"]
        couplingfaces = Int64.(msource["externalCouplingTerm"]["couplingfaces"])
        couplingcells = Int64.(msource["externalCouplingTerm"]["couplingcells"]) 

        component = :PeAm
        
    end

    trans = getHalfTrans(msource, couplingfaces, couplingcells, "effectiveElectronicConductivity")

    ct = TPFAInterfaceFluxCT(trange, srange, trans, symmetric = false)
    ct_pair = setup_cross_term(ct, target = component, source = :Control, equation = :charge_conservation)
    add_cross_term!(model, ct_pair)

    # Accmulation of charge
    ct = AccumulatorInterfaceFluxCT(1, trange, trans)
    ct_pair = setup_cross_term(ct, target = :Control, source = component, equation = :charge_conservation)
    add_cross_term!(model, ct_pair)

    
end

########################################################################
# Setup model
########################################################################

function setup_model(init::InputFile;
                     use_p2d::Bool    = true,
                     use_groups::Bool = false,
                     kwarg...)

    model = setup_battery_model(init,
                                use_groups = use_groups,
                                use_p2d    = use_p2d;
                                kwarg... )
    parameters = setup_battery_parameters(init, model)
    initState  = setup_battery_initial_state(init, model)

    return model, initState, parameters

end

function include_current_collectors(init::MatlabFile)

    model = init.object["model"]

    if haskey(model, "include_current_collectors")
        if isempty(model["include_current_collectors"])
            include_cc = false
        elseif isa(model["include_current_collectors"], Bool) && model["include_current_collectors"] == false
            include_cc = false
        else
            include_cc = true
        end
    else
        include_cc = true
    end
    
    return include_cc
    
end


function include_current_collectors(init::JSONFile)

    jsondict = init.object

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



#######################
# Setup battery model #
#######################

function setup_battery_model(init::MatlabFile; 
                             use_groups::Bool = false,
                             use_p2d::Bool    = true,
                             general_ad::Bool = false,
                             kwarg...)

    include_cc = include_current_collectors(init)

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
        :NeAm => "NegativeElectrode",
        :PeAm => "PositiveElectrode",        
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

        funcname = inputparams_itf["computeOCPFunc"] # This matlab parameter must have been converted from function handle to string before call
        func = getfield(BattMo, Symbol(funcname))
        am_params[:ocp_func] = func

        if use_p2d
            rp = inputparams_sd["particleRadius"]
            N  = Int64(inputparams_sd["N"])
            D  = inputparams_sd["referenceDiffusionCoefficient"]
            sys_am = ActiveMaterialP2D(am_params, rp, N, D)
        else
            sys_am = ActiveMaterialNoParticleDiffusion(am_params)
        end
        
        if  !include_cc && name == :NeAm
            bcfaces  = convert_to_int_vector(inputparams_co["externalCouplingTerm"]["couplingfaces"])
            model_am = setup_component(inputparams_co, sys_am, bcfaces, general_ad)
        else
            model_am = setup_component(inputparams_co, sys_am, nothing, general_ad)
        end

        return model_am
        
    end
    
    ###########################################
    # Setup negative current collector if any #
    ###########################################
    
    if include_cc

        inputparams_necc = inputparams["NegativeElectrode"]["CurrentCollector"]

        necc_params = JutulStorage()
        necc_params[:density] = inputparams_necc["density"]
        
        sys_necc = CurrentCollector(necc_params)

        bcfaces = convert_to_int_vector(inputparams_necc["externalCouplingTerm"]["couplingfaces"])
        
        model_necc =  setup_component(inputparams_necc, sys_necc, bcfaces, general_ad)
        
    end

    ##############
    # Setup NeAm #
    ##############

    model_neam = setup_active_material(:NeAm, general_ad)

    ###############
    # Setup Elyte #
    ###############

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
                                  elyte, nothing, general_ad)

    ##############
    # Setup PeAm #
    ##############

    
    model_peam = setup_active_material(:PeAm, general_ad)

    if include_cc

        ###########################################
        # Setup positive current collector if any #
        ###########################################
        inputparams_pecc = inputparams["PositiveElectrode"]["CurrentCollector"]

        pecc_params = JutulStorage()
        pecc_params[:density] = inputparams_pecc["density"]
        
        sys_pecc = CurrentCollector(pecc_params)

        
        model_pecc =  setup_component(inputparams_pecc, sys_pecc, nothing, general_ad)
        
    end

    #######################
    # Setup control model #
    #######################

    controlPolicy = init.object["model"]["Control"]["controlPolicy"]
    
    if controlPolicy == "CCDischarge"
        
        minE   = init.object["model"]["Control"]["lowerCutoffVoltage"]
        inputI = init.object["model"]["Control"]["Imax"]

        cFun(time) = currentFun(time, inputI)
        
        policy = SimpleCVPolicy(cFun, minE)

    elseif controlPolicy == "CCCV"

        ctrl = init.object["model"]["Control"]
        
        policy = CyclingCVPolicy(ctrl["ImaxDischarge"]     ,
                                 ctrl["ImaxCharge"]        ,
                                 ctrl["lowerCutoffVoltage"],
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
    
    if !include_cc
        groups = nothing
        model = MultiModel(
            (
                NeAm    = model_neam, 
                Elyte   = model_elyte, 
                PeAm    = model_peam, 
                Control = model_control
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
    
    return model
    
end


function setup_battery_model(init::JSONFile; 
                             use_groups::Bool = false, 
                             general_ad::Bool = false,
                             kwarg...)
    
    include_cc = include_current_collectors(init)
    case_type = init.object["Geometry"]["case"]
    print(case_type)
    if case_type == "1D"                            
        geomparams = setup_geomparams(init)
    elseif case_type == "Grid"              
        geomparams = setup_geomparams_grid(init.object["Grids"],include_cc)
    else
        error()
    end

    jsondict = init.object

    


    """
    Generic helper function to setup a component (:NeAm, :NeCc, :PeAm, :PeCc)
    """
    function setup_component(geomparam::Dict, 
                             sys; 
                             addDirichlet::Bool = false, 
                             general_ad::Bool   = false,
                             facearea = 1.0)
        
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

        # We add Dirichlet on negative current collector. This is a bit hacky as we pass directly cell-number
        # Works only for 1D model
        
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

    """
    Helper function to setup  electrolyte (:Elyte)
    """
    function setup_component(geomparams::Dict, 
                             sys::Electrolyte;
                             general_ad::Bool = false,)

        # specific implementation for electrolyte
        # requires geometric parameters for :NeAm, :SEP, :PeAm
        facearea = geomparams[:SEP][:facearea]
        
        names = (:NeAm, :SEP, :PeAm)

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

    function setup_component(g::CartesianMesh,
                            sys;
                            general_ad::Bool=false,
                            addDirichlet::Bool = false,
                            facearea = 1.0)

        # specific implementation for electrolyte
        # requires geometric parameters for :NeAm, :SEP, :PeAm

        domain = DataDomain(g)

        domain[:face_weighted_volumes] = facearea*domain[:volumes]

        # opertors only use geometry not property
        k = ones(number_of_cells(g))
        T = compute_face_trans(domain, k)
        T_hf = compute_half_face_trans(domain, k)
        T_b = compute_boundary_trans(domain, k)

        domain[:trans, Faces()] = facearea * T
        domain[:halfTrans, HalfFaces()] = facearea * T_hf
        domain[:bcTrans, BoundaryFaces()] = facearea * T_b
        
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
        disc = (charge_flow=flow,)
        domain = DiscretizedDomain(domain, disc)

        model = SimulationModel(domain, sys, context=DefaultContext())

        return model

    end

    jsonNames = Dict(
        :NeAm => "NegativeElectrode",
        :PeAm => "PositiveElectrode",        
    )

    """
    Helper function to setup the active materials
    """
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

            return volumeFraction, volumeFractions, effectiveDensity
            
        end

        inputparams_am = jsondict[jsonName]["Coating"]["ActiveMaterial"]
        
        am_params = JutulStorage()
        vf, vfs, eff_dens = computeVolumeFraction(jsondict[jsonName]["Coating"])
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
        

        
        geomparam = geomparams[name]
       

        if !include_cc && name == :NeAm
            addDirichlet = true
        else
            addDirichlet = false
        end
        
        model_am = setup_component(geomparam              ,
                                   sys_am                 ;
                                   general_ad = general_ad,
                                   addDirichlet = addDirichlet)

        return model_am
        
    end
    
    ####################################
    # Setup negative current collector #
    ####################################
    
    if include_cc


        necc_params = JutulStorage()
        necc_params[:density] = jsondict["NegativeElectrode"]["CurrentCollector"]["density"]
        
        sys_necc = CurrentCollector(necc_params)
        model_necc = setup_component(geomparams[:NeCc]  ,
                                     sys_necc           ,
                                     addDirichlet = true,
                                     general_ad = general_ad)
    end

    ##############
    # Setup NeAm #
    ##############
    
    model_neam = setup_active_material(:NeAm, geomparams)

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
    if case_type == "1D"
        model_elyte = setup_component(geomparams, elyte, general_ad = general_ad)
    elseif case_type == "Grid"
        model_elyte = setup_component(geomparams[:Elyte], elyte,
                                      general_ad = general_ad,
                                      facearea = geomparams[:facearea])
    else
        error()
    end

    ##############
    # Setup PeAm #
    ##############
    
    model_peam = setup_active_material(:PeAm, geomparams)

    ###########################################
    # Setup negative current collector if any #
    ###########################################
    
    if include_cc
        pecc_params = JutulStorage()
        pecc_params[:density] = jsondict["PositiveElectrode"]["CurrentCollector"]["density"]
        
        sys_pecc = CurrentCollector(pecc_params)
        
        model_pecc = setup_component(geomparams[:PeCc], sys_pecc, 
                                    general_ad = general_ad,
                                    facearea = geomparams["facearea"])
    end

    #######################
    # Setup control model #
    #######################
    
    controlPolicy = jsondict["Control"]["controlPolicy"]
    
    if controlPolicy == "CCDischarge"
        
        minE   = jsondict["Control"]["lowerCutoffVoltage"]
        
        policy = SimpleCVPolicy(voltage = minE)

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
    if case_type == "1D"
        setup_volume_fractions!(model, geomparams)
    elseif case_type == "Grid"
        setup_volume_fractions_grid!(model, geomparams)
    else
        error()
    end
    
    return model
    
end

############################
# Setup battery parameters #
############################

function setup_battery_parameters(init::MatlabFile, 
                                  model::MultiModel
                                  )

    parameters = Dict{Symbol, Any}()

    exported=init.object

    T0 = exported["model"]["initT"]

    include_cc = include_current_collectors(model)

    if include_cc

        #####################
        # Current collector #
        #####################

        prm_necc = Dict{Symbol, Any}()
        exported_necc = exported["model"]["NegativeElectrode"]["CurrentCollector"]
        prm_necc[:Conductivity] = exported_necc["effectiveElectronicConductivity"][1]
        parameters[:NeCc] = setup_parameters(model[:NeCc], prm_necc)
    end

    ############################
    # Negative active material #
    ############################
    
    prm_neam = Dict{Symbol, Any}()
    exported_neam = exported["model"]["NegativeElectrode"]["Coating"]
    prm_neam[:Conductivity] = exported_neam["effectiveElectronicConductivity"][1]
    prm_neam[:Temperature] = T0
    
    if discretisation_type(model[:NeAm]) == :P2Ddiscretization
        # nothing to do
    else
        @assert discretisation_type(model[:NeAm]) == :NoParticleDiffusion
        prm_neam[:Diffusivity] = exported_neam["InterDiffusionCoefficient"]
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
    exported_peam = exported["model"]["PositiveElectrode"]["Coating"]
    prm_peam[:Conductivity] = exported_peam["effectiveElectronicConductivity"][1]
    prm_peam[:Temperature] = T0
    
    if discretisation_type(model[:PeAm]) == :P2Ddiscretization
        # nothing to do
    else
        @assert discretisation_type(model[:NeAm]) == :NoParticleDiffusion
        prm_peam[:Diffusivity] = exported_neam["InterDiffusionCoefficient"]
    end

    parameters[:PeAm] = setup_parameters(model[:PeAm], prm_peam)

    if include_cc

        #######################################
        # Positive current collector (if any) #
        #######################################
        
        prm_pecc = Dict{Symbol, Any}()
        exported_pecc = exported["model"]["PositiveElectrode"]["CurrentCollector"]
        prm_pecc[:Conductivity] = exported_pecc["effectiveElectronicConductivity"][1]
        
        parameters[:PeCc] = setup_parameters(model[:PeCc], prm_pecc)
    end        

    parameters[:Control] = setup_parameters(model[:Control])

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

    include_cc = include_current_collectors(model)

    if include_cc
        
        #######################################
        # Negative current collector (if any) #
        #######################################
        
        prm_necc = Dict{Symbol, Any}()
        jsonstruct_necc = jsonstruct["NegativeElectrode"]["CurrentCollector"]
        prm_necc[:Conductivity] = jsonstruct_necc["electronicConductivity"]
        parameters[:NeCc] = setup_parameters(model[:NeCc], prm_necc)
        
    end

    ############################
    # Negative active material #
    ############################
    
    prm_neam = Dict{Symbol, Any}()
    jsonstruct_neam = jsonstruct["NegativeElectrode"]["Coating"]["ActiveMaterial"]

    prm_neam[:Conductivity] = computeEffectiveConductivity(model[:NeAm], jsonstruct["NegativeElectrode"]["Coating"])
    prm_neam[:Temperature] = T0
    
    if discretisation_type(model[:NeAm]) == :P2Ddiscretization
        # nothing to do
    else
        @assert discretisation_type(model[:NeAm]) == :NoParticleDiffusion
        prm_neam[:Diffusivity] = jsonstruct_neam["InterDiffusionCoefficient"]
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
    jsonstruct_peam = jsonstruct["PositiveElectrode"]["Coating"]["ActiveMaterial"]

    prm_peam[:Conductivity] = computeEffectiveConductivity(model[:PeAm], jsonstruct["PositiveElectrode"]["Coating"])
    prm_peam[:Temperature] = T0
    
    
    if discretisation_type(model[:PeAm]) == :P2Ddiscretization
        # nothing to do
    else
        @assert discretisation_type(model[:NeAm]) == :NoParticleDiffusion
        prm_peam[:Diffusivity] = jsonstruct_peam["InterDiffusionCoefficient"]
    end

    parameters[:PeAm] = setup_parameters(model[:PeAm], prm_peam)

    if include_cc

        #######################################
        # Positive current collector (if any) #
        #######################################

        prm_pecc = Dict{Symbol, Any}()
        jsonstruct_pecc = jsonstruct["PositiveElectrode"]["CurrentCollector"]
        prm_pecc[:Conductivity] = jsonstruct_pecc["electronicConductivity"]
        
        parameters[:PeCc] = setup_parameters(model[:PeCc], prm_pecc)
    end        

    ###########
    # Control #
    ###########
    
    prm_control = Dict{Symbol, Any}()

    controlPolicy = jsonstruct["Control"]["controlPolicy"]
    
    if  controlPolicy == "CCDischarge"
        
        cap = computeCellCapacity(model)
        con = Constants()

        DRate = jsonstruct["Control"]["DRate"]
        prm_control[:ImaxDischarge] = (cap/con.hour)*DRate
        
        parameters[:Control] = setup_parameters(model[:Control], prm_control)
        
    elseif controlPolicy == "CCCV"

        cap = computeCellCapacity(model)
        con = Constants()

        DRate = jsonstruct["Control"]["DRate"]
        CRate = jsonstruct["Control"]["CRate"]
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

function setup_battery_initial_state(init::MatlabFile, 
                                     model::MultiModel
                                     )

    exported=init.object

    state0 = exported["initstate"]

    include_cc = include_current_collectors(model)

    if include_cc
        jsonNames = Dict(
            :NeCc  => "NegativeElectrode",
            :NeAm => "NegativeElectrode",
            :PeAm => "PositiveElectrode",        
            :PeCc  => "PositiveElectrode",
        )
    else
        jsonNames = Dict(
            :NeAm => "NegativeElectrode",
            :PeAm => "PositiveElectrode" 
        )
    end
    

    """ initialize values for the current collector"""
    function initialize_current_collector!(initState, name::Symbol)

        init = Dict()
        init[:Phi] = state0[jsonNames[name]]["CurrentCollector"]["phi"][1]
        initState[name] = init
        
    end

    """ initialize values for the active material"""
    function initialize_active_material!(initState, name::Symbol)

        jsonName = jsonNames[name]
        
        sys = model[name].system

        init = Dict()
        
        init[:Phi] = state0[jsonName]["Coating"]["phi"][1]
        c = state0[jsonName]["Coating"]["ActiveMaterial"]["Interface"]["cElectrodeSurface"][1]

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

        initState[:Elyte] = init

    end

    function initialize_control!(initState)

        init = Dict(:Phi => state0["Control"]["E"], :Current => 0*state0["Control"]["I"])
        
        initState[:Control] = init
        
    end
    
    initState = Dict()

    initialize_active_material!(initState, :NeAm)
    initialize_electrolyte!(initState)
    initialize_active_material!(initState, :PeAm)

    if include_cc
        initialize_current_collector!(initState, :NeCc)
        initialize_current_collector!(initState, :PeCc)
    end
    
    initialize_control!(initState)
    
    initState = setup_state(model, initState)

    return initState 
    
end


function setup_battery_initial_state(init::JSONFile,
                                     model::MultiModel)

                                     

    jsonstruct = init.object

    include_cc = include_current_collectors(model)

    T        = jsonstruct["initT"]
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
    init[:C]   = jsonstruct["Electrolyte"]["initialConcentration"]*ones(nc)
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
    init[:Phi]     = [1.0]
    init[:Current] = getInitCurrent(model[:Control])

    initState[:Control] = init

    initState = setup_state(model, initState)
    
    return initState
    
end

####################
# Current function #
####################

function currentFun(t::T, inputI::T, tup::T=0.1) where T
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

#function setup_volume_fractions!(model::MultiModel, geomparams::Dict{Symbol,<:Any})
function setup_volume_fractions!(model::MultiModel, geomparams)

    names = (:NeAm, :SEP, :PeAm)
    Nelyte = sum([geomparams[name][:N] for name in names])
    vfelyte = zeros(Nelyte)
    vfseparator  = zeros(Nelyte)
    
    names = (:NeAm, :PeAm)
    
    for name in names
        ammodel = model[name]
        vf = ammodel.system[:volume_fraction]
        Nam = geomparams[name][:N]
        ammodel.domain.representation[:volumeFraction] = vf*ones(Nam)
        if name == :NeAm
            nstart = 1
            nend   = Nam
        elseif name == :PeAm
            nstart = geomparams[:NeAm][:N] + geomparams[:SEP][:N] + 1
            nend   = Nelyte
        else
            error("name not recognized")
        end
        vfelyte[nstart : nend] .= 1 - vf
    end

    nstart = geomparams[:NeAm][:N] +  1
    nend   = nstart + geomparams[:SEP][:N]
    separator_porosity = model[:Elyte].system[:separator_porosity]
    
    vfelyte[nstart : nend]     .= separator_porosity*ones(nend - nstart + 1)
    vfseparator[nstart : nend] .= (1 -separator_porosity)*ones(nend - nstart + 1)
    
    model[:Elyte].domain.representation[:volumeFraction] = vfelyte
    model[:Elyte].domain.representation[:separator_volume_fraction] = vfseparator
    
end

function setup_volume_fractions_grid!(model::MultiModel, geomparams::Dict{Symbol,<:Any})

    names = (:NeAm, :SEP, :PeAm)
    Nelyte = number_of_cells(geomparams[:Elyte])
    NSEP = number_of_cells(geomparams[:SEP])
    vfelyte = zeros(Nelyte)
    vfseparator  = zeros(Nelyte)#Why this size?
    
    names = (:NeAm, :PeAm)
    println("--fractions--")
    println(geomparams)
    println(vfelyte)
    #println(elytecells)
    for name in names
        ncell = number_of_cells(geomparams[name])
        ammodel = model[name]
        vf = ammodel.system[:volume_fraction]
        ammodel.domain.representation[:volumeFraction] = vf*ones(ncell)
        println("---")
        println(name)
        println(geomparams[:couplings][:Elyte])
        elytecells = geomparams[:couplings][:Elyte][name]#cells
        vfelyte[elytecells] .= 1-vf 
    end

    begin
        separator_porosity = model[:Elyte].system[:separator_porosity]
        elytecells = geomparams[:couplings][:Elyte][:SEP]#.cells[:,1]
        #separatorcells = geomparams[:couplings][:Elyte][:separator].cells[:,2]
        vfelyte[elytecells]     .= separator_porosity*ones()
        #vfseparator[separatorcells] .= (1 -separator_porosity)*ones(nsep)
        # Assume all of separtor is coupled
        vfseparator[elytecells] .= (1 -separator_porosity)#*ones(nsep)
    end
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

####################
# Setup geomparams #
####################

function setup_geomparams(init::JSONFile)
    
    jsondict = init.object

    include_cc = include_current_collectors(init)

    if include_cc
        names = (:NeCc, :NeAm, :SEP, :PeAm, :PeCc)
    else
        names = (:NeAm, :SEP, :PeAm)
    end
    geomparams = Dict(name => Dict() for name in names)

    geomparams[:NeAm][:N]         = jsondict["NegativeElectrode"]["Coating"]["N"]
    geomparams[:NeAm][:thickness] = jsondict["NegativeElectrode"]["Coating"]["thickness"]
    geomparams[:SEP][:N]          = jsondict["Separator"]["N"]
    geomparams[:SEP][:thickness]  = jsondict["Separator"]["thickness"]
    geomparams[:PeAm][:N]         = jsondict["PositiveElectrode"]["Coating"]["N"]
    geomparams[:PeAm][:thickness] = jsondict["PositiveElectrode"]["Coating"]["thickness"]

    if include_cc
        geomparams[:NeCc][:N]         = jsondict["NegativeElectrode"]["CurrentCollector"]["N"]
        geomparams[:NeCc][:thickness] = jsondict["NegativeElectrode"]["CurrentCollector"]["thickness"]
        geomparams[:PeCc][:N]         = jsondict["PositiveElectrode"]["CurrentCollector"]["N"]
        geomparams[:PeCc][:thickness] = jsondict["PositiveElectrode"]["CurrentCollector"]["thickness"]
    end
    
    for name in names
        geomparams[name][:facearea] = jsondict["Geometry"]["faceArea"]
    end
    
    return geomparams
    
end

function setup_geomparams_grid(geometry::Dict, include_cc)

    #include_cc = false #include_current_collectors(init)

    if include_cc
        longnames = ["NegativeCurrentCollector", "NegativeElectrode", "Separator","PositiveElectrode","NegativeCurrentCollector"]
        names = (:NeCc, :NeAm, :SEP, :PeAm, :PeCc)
    else
        longnames = ["NegativeElectrode", "Separator","PositiveElectrode"]
        names = (:NeAm, :SEP, :PeAm)
    end
    geomparams =  Dict{Symbol, Any}()#Dict(name => Any() for name in names)
    for (ind,val) in enumerate(names)
        geomparams[val] = geometry[longnames[ind]]
    end    
    # geomparams[:NeAm]         = geometry["NegativeElectrode"]
    # geomparams[:SEP]          = geometry["Separator"]
    # geomparams[:PeAm]         = geometry["PositiveElectrode"]
    geomparams[:Elyte]         = geometry["Electrolyte"]
    # if include_cc
    #     geomparams[:NeCc] = ["NegativeCurrentCollector"]
    #     geomparams[:PeCc] = ["CurrentCollector"]
    # end
    
    #for name in names
    geomparams[:facearea] = geometry["faceArea"]
    #end
    geomparams[:couplings] = Dict{Symbol,Any}()
    geomparams[:couplings][:Elyte] = Dict{Symbol,Any}()#{Symbol,Dict{Symbol,Any}}()
    couplings = Dict{Symbol,Any}()
    for (ind,val) in enumerate(names)         
        couplings[val] =  geometry["Couplings"]["Electrolyte"][longnames[ind]];
    end
    geomparams[:couplings][:Elyte] = couplings
    return geomparams
    
end

##################################################################################
# Compute cell capacity 
##################################################################################

function computeElectrodeCapacity(model::MultiModel, name::Symbol)

    con = Constants()
    
    ammodel = model[name]
    sys = ammodel.system            
    F    = con.F
    n    = sys[:n_charge_carriers]
    cMax = sys[:maximum_concentration]
    vf   = sys[:volume_fraction]
    avf  = sys[:volume_fractions][1]
    
    if name == :NeAm
        thetaMax = sys[:theta100]
        thetaMin = sys[:theta0]
    elseif name == :PeAm
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

    
function computeCellCapacity(model::MultiModel)

    caps = [computeElectrodeCapacity(model, name) for name in (:NeAm, :PeAm)]

    return minimum(caps)
    
end

function computeCellEnergy(states)

    time = [state[:Control][:ControllerCV].time for state in states]
    E    = [state[:Control][:Phi][1] for state in states]
    I    = [state[:Control][:Current][1] for state in states]

    dt   = diff(time)
    
    Emid = (E[2 : end] + E[1 : end - 1])./2
    Imid = (I[2 : end] + I[1 : end - 1])./2

    energy = sum(Emid.*Imid.*dt)

    return energy
    
end


function computeCellMaximumEnergy(model::MultiModel; T = 298.15, capacities = missing)

    eldes = (:NeAm, :PeAm)
    
    if ismissing(capacities)
        capacities = NamedTuple([(name, computeElectrodeCapacity(model, name)) for name in eldes])
    end
    
    capacity = min(capacities.NeAm, capacities.PeAm)
    
    N = 1000

    energies = Dict()
    
    for elde in eldes

        cmax    = model[elde].system[:maximum_concentration]
        c0      = cmax*model[elde].system[:theta100]
        cT      = cmax*model[elde].system[:theta0]
        refT    = 298.15
        ocpfunc = model[elde].system[:ocp_func]

        smax = capacity/capacities[elde]
        s = smax*collect(range(0, 1, N + 1))
        
        c = (1 .- s).*c0 + s.*cT;

        f = Vector{Float64}(undef, N + 1)

        for i = 1 : N + 1
            if Jutul.haskey(model[elde].system.params, :ocp_funcexp)
                f[i] = ocpfunc(c[i], T, refT, cmax)
            elseif Jutul.haskey(model[elde].system.params, :ocp_funcdata)
                f[i] = ocpfunc(c[i]/cmax)
            else
                f[i] = ocpfunc(c[i], T, cmax)
            end

                
        end

       energies[elde] = (capacities[elde]*smax/N)*sum(f)
        
    end

    energy = energies[:PeAm] - energies[:NeAm]

    return energy
    
end

function computeCellMass(model::MultiModel)

    eldes = (:NeAm, :PeAm)

    mass = 0.0
    
    # Coating mass
    
    for elde in eldes
        effrho = model[elde].system[:effective_density]
        vols = model[elde].domain.representation[:face_weighted_volumes]
        mass = mass + sum(effrho.*vols)
    end
    
    # Electrolyte mass
    
    rho  = model[:Elyte].system[:electrolyte_density]
    vf   = model[:Elyte].domain.representation[:volumeFraction]
    vols = model[:Elyte].domain.representation[:face_weighted_volumes]
    
    mass = mass + sum(vf.*rho.*vols)

    # Separator mass
    
    rho  = model[:Elyte].system[:separator_density]
    vf   = model[:Elyte].domain.representation[:separator_volume_fraction]
    vols = model[:Elyte].domain.representation[:face_weighted_volumes]
    
    mass = mass + sum(vf.*rho.*vols)
    
    # Current Collector masses
    
    ccs = (:NeCc, :PeCc)

    for cc in ccs
        if haskey(model.models, cc)
            rho  = model[cc].system[:density]
            vols = model[cc].domain.representation[:face_weighted_volumes]        
            mass = mass + sum(rho.*vols)
        end
    end
        
    return mass
    
end


function computeCellSpecifications(init::JSONFile)
    
    model = setup_battery_model(init)
    return computeCellSpecifications(model)
    
end

function computeCellSpecifications(model::MultiModel; T = 298.15)

    capacities = (NeAm = computeElectrodeCapacity(model, :NeAm), PeAm =computeElectrodeCapacity(model, :PeAm))

    energy = computeCellMaximumEnergy(model; T = T, capacities = capacities)

    mass = computeCellMass(model)
    
    specs = Dict()

    specs["NegativeElectrodeCapacity"] = capacities.NeAm
    specs["PositiveElectrodeCapacity"] = capacities.PeAm
    specs["MaximumEnergy"]             = energy
    specs["Mass"]                      = mass
    
    return specs
    
end


###############
# Other utils #
###############

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

function computeDischargeEnergy(init::JSONFile)
    # setup a schedule with just discharge half cycle and very fine refinement

    jsondict = init.object

    ctrldict = jsondict["Control"]
    
    controlPolicy = ctrldict["controlPolicy"]

    timedict = jsondict["TimeStepping"]

    if controlPolicy == "CCCV"
        ctrldict["controlPolicy"]  = "CCDischarge"

        ctrldict["initialControl"] = "discharging"
        jsondict["SOC"] = 1.0

        rate = ctrldict["DRate"]
        timedict["timeStepDuration"] = 20 / rate

    elseif controlPolicy == "CCDischarge"
        ctrldict["initialControl"] = "discharging"
        jsondict["SOC"] = 1.0
        rate = ctrldict["DRate"]
        timedict["timeStepDuration"] = 20 / rate

    else

        error("controlPolicy not recognized.")
       
    end

    init2 = JSONFile(jsondict)

    (; states) = run_battery(init2; info_level=0)

    return (computeCellEnergy(states), states, init2)
    # return (missing, missing, init2)
    
end


function computeEnergyEfficiency(init::JSONFile)

    # setup a schedule with just one cycle and very fine refinement

    jsondict = init.object

    ctrldict = jsondict["Control"]
    
    controlPolicy = ctrldict["controlPolicy"]

    timedict = jsondict["TimeStepping"]
   
    if controlPolicy == "CCDischarge"

        ctrldict["controlPolicy"]  = "CCCV"
        ctrldict["CRate"]          = 1.0
        ctrldict["DRate"]          = 1.0
        ctrldict["dEdtLimit"]      = 1e-2
        ctrldict["dIdtLimit"]      = 1e-4
        ctrldict["numberOfCycles"] = 1
        ctrldict["initialControl"] = "charging"
        rate = ctrldict["DRate"]
        timedict["timeStepDuration"] = 20 / rate
        
        jsondict["SOC"] = 0.0

    elseif controlPolicy == "CCCV"

        ctrldict["initialControl"]    = "charging"
        ctrldict["dIdtLimit"]         = 1e-5
        ctrldict["dEdtLimit"]         = 1e-5
        ctrldict["numberOfCycles"]    = 1

        jsondict["SOC"] = 0.0

        rate = max(ctrldict["DRate"], ctrldict["CRate"])
        dt = 20/rate
        
        jsondict["TimeStepping"]["timeStepDuration"] = dt

        jsondict["SOC"]            = 0.0
        
    else

        error("controlPolicy not recognized.")
       
    end

    init2 = JSONFile(jsondict)

    (; states) = run_battery(init2; info_level=0)

    return (computeEnergyEfficiency(states), states, init2)
    
end

function computeEnergyEfficiency(states)
    
    time = [state[:Control][:ControllerCV].time for state in states]
    E    = [state[:Control][:Phi][1] for state in states]
    I    = [state[:Control][:Current][1] for state in states]

    Iref = copy(I)

    dt   = diff(time)
    
    Emid = (E[2 : end] + E[1 : end - 1])./2

     # discharge energy

    I[I .< 0] .= 0
    Imid = (I[2 : end] .+ I[1 : end - 1])./2
    
    energy_discharge = sum(Emid.*Imid.*dt)

    # charge energy

    I = copy(Iref)
    
    I[I .> 0] .= 0
    Imid = (I[2 : end] .+ I[1 : end - 1]) / 2
    
    energy_charge = -sum(Emid.*Imid.*dt)

    efficiency = energy_discharge/energy_charge

    return efficiency
    
end


function inputRefToStates(states, stateref)
    statesref = deepcopy(states)
    for i in 1:size(states,1)

        staterefnew = statesref[i]   
        refstep     = i
        fields      = ["CurrentCollector","ActiveMaterial"]
        components  = ["NegativeElectrode","PositiveElectrode"]
        newkeys     = [:NeCc, :NeAm, :PeCc, :PeAm]
       
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
        newcomp = :Elyte
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
        staterefnew[:Control][:Phi][1] = stateref[refstep]["Control"]["E"]
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
    # P = exported["G"]["operators"]["cellFluxOp"]["P"]
    # S = exported["G"]["operators"]["cellFluxOp"]["S"]
    P = []
    S = []
    T = exported["G"]["operators"]["T"].*1.0
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
        phi = states[step][:Control][:Phi][1]
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


