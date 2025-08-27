export
	computeCellCapacity,
	computeCellMaximumEnergy,
	computeCellEnergy,
	computeCellMass,
	computeCellSpecifications,
	computeEnergyEfficiency,
	computeDischargeEnergy


function computeElectrodeCapacity(multimodel::MultiModel, name::Symbol)
	ammodel = multimodel[name]
	return computeElectrodeCapacity(ammodel, name)
end

function computeElectrodeCapacity(ammodel::SimulationModel, name)
	con = Constants()

	sys = ammodel.system
	F = con.F
	n = sys[:n_charge_carriers]
	cMax = sys[:maximum_concentration]
	vf = sys[:volume_fraction]
	avf = sys[:volume_fractions][1]

	if name == :NeAm
		thetaMax = sys[:theta100]
		thetaMin = sys[:theta0]
	elseif name == :PeAm
		thetaMax = sys[:theta0]
		thetaMin = sys[:theta100]
	else
		error("Electrode name $name not recognized")
	end

	vols = ammodel.domain.representation[:volumes]
	vol = sum(avf * vf * vols)
	cap_usable = (thetaMax - thetaMin) * cMax * vol * n * F

	return cap_usable

end

function computeCellCapacity(model::MultiModel)

	caps = [computeElectrodeCapacity(model, name) for name in (:NeAm, :PeAm)]

	return minimum(caps)

end

function computeCellEnergy(states)
	# Only take discharge curves
	time = [state[:Control][:Controller].time for state in states if state[:Control][:Current][1] > 0]
	E    = [state[:Control][:Voltage][1] for state in states if state[:Control][:Current][1] > 0]
	I    = [state[:Control][:Current][1] for state in states if state[:Control][:Current][1] > 0]

	dt = diff(time)

	Emid = (E[2:end] + E[1:end-1]) ./ 2
	Imid = (I[2:end] + I[1:end-1]) ./ 2

	energy = sum(Emid .* Imid .* dt)

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
		c0      = cmax * model[elde].system[:theta100]
		cT      = cmax * model[elde].system[:theta0]
		refT    = 298.15
		ocpfunc = model[elde].system[:ocp_func]

		smax = capacity / capacities[elde]
		s = smax * collect(range(0, 1, N + 1))

		c = (1 .- s) .* c0 + s .* cT

		f = Vector{Float64}(undef, N + 1)

		for i ∈ 1:N+1
			if haskey(model[elde].system.params, :ocp_funcexp)
				f[i] = ocpfunc(c[i], T, refT, cmax)
			elseif haskey(model[elde].system.params, :ocp_funcdata)
				f[i] = ocpfunc(c[i] / cmax)
			else
				f[i] = ocpfunc(c[i], T, refT, cmax)
			end


		end

		energies[elde] = (capacities[elde] * smax / N) * sum(f)

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
		vols = model[elde].domain.representation[:volumes]
		mass = mass + sum(effrho .* vols)
	end

	# Electrolyte mass

	rho  = model[:Elyte].system[:electrolyte_density]
	vf   = model[:Elyte].domain.representation[:volumeFraction]
	vols = model[:Elyte].domain.representation[:volumes]

	mass = mass + sum(vf .* rho .* vols)

	# Separator mass

	rho  = model[:Elyte].system[:separator_density]
	vf   = model[:Elyte].domain.representation[:separator_volume_fraction]
	vols = model[:Elyte].domain.representation[:volumes]

	mass = mass + sum(vf .* rho .* vols)

	# Current Collector masses

	ccs = (:NeCc, :PeCc)

	for cc in ccs
		if haskey(model.models, cc)
			rho  = model[cc].system[:density]
			vols = model[cc].domain.representation[:volumes]
			mass = mass + sum(rho .* vols)
		end
	end

	return mass

end


function computeCellSpecifications(inputparams::InputParamsOld)

	model = setup_submodels(inputparams)
	return computeCellSpecifications(model)

end

function computeCellSpecifications(model::MultiModel; T = 298.15)

	capacities = (NeAm = computeElectrodeCapacity(model, :NeAm), PeAm = computeElectrodeCapacity(model, :PeAm))

	energy = computeCellMaximumEnergy(model; T = T, capacities = capacities)

	mass = computeCellMass(model)

	specs = Dict()

	specs["NegativeElectrodeCapacity"] = capacities.NeAm
	specs["PositiveElectrodeCapacity"] = capacities.PeAm
	specs["MaximumEnergy"]             = energy
	specs["Mass"]                      = mass

	return specs

end


function computeEnergyEfficiency(inputparams::InputParamsOld)

	# setup a schedule with just one cycle and very fine refinement

	jsondict = inputparams.data

	ctrldict = jsondict["Control"]

	controlPolicy = ctrldict["controlPolicy"]

	timedict = jsondict["TimeStepping"]

	if controlPolicy == "CCDischarge"

		ctrldict["controlPolicy"] = "CCCV"
		ctrldict["CRate"] = 1.0
		ctrldict["DRate"] = 1.0
		ctrldict["dEdtLimit"] = 1e-2
		ctrldict["dIdtLimit"] = 1e-4
		ctrldict["numberOfCycles"] = 1
		ctrldict["initialControl"] = "charging"
		rate = ctrldict["DRate"]
		timedict["timeStepDuration"] = 20 / rate

		jsondict["SOC"] = 0.0

	elseif controlPolicy == "CCCV"

		ctrldict["initialControl"] = "charging"
		ctrldict["dIdtLimit"]      = 1e-5
		ctrldict["dEdtLimit"]      = 1e-5
		ctrldict["numberOfCycles"] = 1

		jsondict["SOC"] = 0.0

		rate = max(ctrldict["DRate"], ctrldict["CRate"])
		dt = 20 / rate

		jsondict["TimeStepping"]["timeStepDuration"] = dt

		jsondict["SOC"] = 0.0

	else

		error("Control policy $controlPolicy not recognized.")

	end

	inputparams2 = InputParamsOld(jsondict)

	(; states) = run_battery(inputparams2; info_level = 0)

	return (computeEnergyEfficiency(states), states, inputparams2)

end

function computeEnergyEfficiency(states; cycle_number = nothing)

	t = [state[:Control][:Controller].time for state in states]
	E = [state[:Control][:Voltage][1] for state in states]
	I = [state[:Control][:Current][1] for state in states]

	if !isnothing(cycle_number)
		cycle_array = [state[:Control][:Controller].numberOfCycles for state in states]
		total_number_of_cycles = states[end][:Control][:Controller].numberOfCycles

		cycle_index = findall(x -> x == cycle_number, cycle_array)

		I = I[cycle_index]
		t = t[cycle_index]
		E = E[cycle_index]
	end

	Iref = copy(I)

	dt = diff(t)

	Emid = (E[2:end] + E[1:end-1]) ./ 2

	# discharge energy

	I[I.<0] .= 0
	Imid = (I[2:end] .+ I[1:end-1]) ./ 2

	energy_discharge = sum(Emid .* Imid .* dt)

	# charge energy

	I = copy(Iref)

	I[I.>0] .= 0
	Imid = (I[2:end] .+ I[1:end-1]) / 2

	energy_charge = -sum(Emid .* Imid .* dt)

	efficiency = energy_discharge / energy_charge

	return efficiency * 100 # %

end
function computeDischargeEnergy(inputparams::InputParamsOld)
	# setup a schedule with just discharge half cycle and very fine refinement

	jsondict = inputparams.data

	ctrldict = jsondict["Control"]

	controlPolicy = ctrldict["controlPolicy"]

	timedict = jsondict["TimeStepping"]

	if controlPolicy == "CCCV"
		ctrldict["controlPolicy"] = "CCDischarge"

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

		error("Control policy $controlPolicy not recognized.")

	end

	inputparams2 = InputParamsOld(jsondict)

	(; states) = run_battery(inputparams2; info_level = 0)

	return (computeCellEnergy(states), states, inputparams2)
	# return (missing, missing, inputparams2)

end
