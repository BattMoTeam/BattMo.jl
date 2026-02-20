# # An example using Matlab input

# ## We prepare the input.

using Jutul, BattMo, GLMakie

# We load the matlab input file
name = "p2d_40"
# name = "p2d_40_jl_ud_func"
# name = "p2d_40_no_cc"
# name = "p2d_40_cccv"
# name = "p2d_40_jl_chen2020"
# name = "3d_demo_case"

do_json = true

if do_json

    fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/", name, ".json")
    inputparams = readBattMoJsonInputFile(fn)
    config_kwargs = (info_level = 0, )
    function hook(simulator,
                  model,
                  state0,
                  forces,
                  timesteps,
                  cfg)
    end
    output = run_battery(inputparams;
                         hook = hook,
                         config_kwargs = config_kwargs,
                         extra_timing = false);

    states = output[:states]
    
    t = [state[:Control][:ControllerCV].time for state in states]
    E = [state[:Control][:Phi][1] for state in states]
    I = [state[:Control][:Current][1] for state in states]
    
else
    
    fn = string(dirname(pathof(BattMo)), "/../test/data/matlab_files/", name, ".mat")
    inputparams = readBattMoMatlabInputFile(fn)
    inputparams.dict["use_state_ref"] = true
    config_kwargs = (info_level = 0,)

function hook(simulator,
	model,
	state0,
	forces,
	timesteps,
	cfg)

	names = [:Electrolyte,
		:NegativeElectrodeActiveMaterial,
		:Control,
		:PositiveElectrodeActiveMaterial]

	if inputparams["model"]["include_current_collectors"]
		names = append!(names, [:PositiveElectrodeCurrentCollector, :NegativeElectrodeCurrentCollector])
	end

	for name in names
		cfg[:tolerances][name][:default] = 1e-8
	end

end
nothing # hide

# ## We run the simulation and retrieve the output
output = run_battery(inputparams;
	hook = hook,
	max_step = nothing);
states = output[:states]

t = [state[:Control][:Controller].time for state in states]
E = [state[:Control][:ElectricPotential][1] for state in states]
I = [state[:Control][:Current][1] for state in states]

nsteps = size(states, 1)
nothing # hide

# ## We retrieve the reference states computed in matlab.

statesref = inputparams["states"]
timeref   = t
Eref      = [state["Control"]["E"] for state in statesref[1:nsteps]]
Iref      = [state["Control"]["I"] for state in statesref[1:nsteps]]
nothing # hide

# ## We plot the results and compare the two simulations

f = Figure(size = (1000, 400))

ax = Axis(f[1, 1],
	title = "Voltage",
	xlabel = "Time / s",
	ylabel = "Voltage / V",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)

scatterlines!(ax,
	t,
	E;
	linewidth = 4,
	markersize = 10,
	marker = :cross,
	markercolor = :black,
	label = "Julia",
)


scatterlines!(ax,
	t,
	Eref;
	linewidth = 2,
	marker = :cross,
	markercolor = :black,
	markersize = 1,
	label = "Matlab")
axislegend()

ax = Axis(f[1, 2],
	title = "Current",
	xlabel = "Time / s",
	ylabel = "Current / A",
	xlabelsize = 25,
	ylabelsize = 25,
	xticklabelsize = 25,
	yticklabelsize = 25,
)

scatterlines!(ax,
	t,
	I;
	linewidth = 4,
	markersize = 10,
	marker = :cross,
	markercolor = :black,
	label = "Julia",
)

scatterlines!(ax,
	t,
	Iref;
	linewidth = 2,
	marker = :cross,
	markercolor = :black,
	markersize = 1,
	label = "Matlab")
axislegend()
nothing # hide

# We observe a perfect match between the Matlab and Julia simulations.

f # hide


