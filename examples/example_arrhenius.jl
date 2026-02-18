using BattMo
using GLMakie

cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
model_settings = load_model_settings(; from_default_set = "p2d")

model_settings["TemperatureDependence"] = "Arrhenius"

Ea_D_ne = cell_parameters["NegativeElectrode"]["ActiveMaterial"]["ActivationEnergyOfDiffusion"]
Ea_D_pe = cell_parameters["PositiveElectrode"]["ActiveMaterial"]["ActivationEnergyOfDiffusion"]
Ea_R_ne = cell_parameters["NegativeElectrode"]["ActiveMaterial"]["ActivationEnergyOfReaction"]
Ea_R_pe = cell_parameters["PositiveElectrode"]["ActiveMaterial"]["ActivationEnergyOfReaction"]


con = Constants()

R = con.R
F = con.F

cell_parameters_R = deepcopy(cell_parameters)
cell_parameters_F = deepcopy(cell_parameters)
# cell_parameters_R["NegativeElectrode"]["ActiveMaterial"]["DiffusionCoefficient"] = "3.3e-14*exp(-$Ea_D_ne/($R)*(1/T-1/refT))"
# cell_parameters_F["NegativeElectrode"]["ActiveMaterial"]["DiffusionCoefficient"] = "3.3e-14*exp(-$Ea_D_ne/($F)*(1/T-1/refT))"

# cell_parameters_R["PositiveElectrode"]["ActiveMaterial"]["DiffusionCoefficient"] = "4.0e-15*exp(-$Ea_D_pe/($R)*(1/T-1/refT))"
# cell_parameters_F["PositiveElectrode"]["ActiveMaterial"]["DiffusionCoefficient"] = "4.0e-15*exp(-$Ea_D_pe/($F)*(1/T-1/refT))"

# cell_parameters_R["NegativeElectrode"]["ActiveMaterial"]["ReactionRateConstant"] = "6.716e-12*exp(-$Ea_R_ne/($R)*(1/T-1/refT))"
# cell_parameters_F["NegativeElectrode"]["ActiveMaterial"]["ReactionRateConstant"] = "6.716e-12*exp(-$Ea_R_ne/($F)*(1/T-1/refT))"

# cell_parameters_R["PositiveElectrode"]["ActiveMaterial"]["ReactionRateConstant"] = "3.545e-11*exp(-$Ea_R_pe/($R)*(1/T-1/refT))"
# cell_parameters_F["PositiveElectrode"]["ActiveMaterial"]["ReactionRateConstant"] = "3.545e-11*exp(-$Ea_R_pe/($F)*(1/T-1/refT))"

########################################

# model_settings["TemperatureDependence"] = "Arrhenius"

model_setup = LithiumIonBattery(; model_settings)

kelvin = 274.15

cycling_protocol_10 = deepcopy(cycling_protocol)
cycling_protocol_25 = deepcopy(cycling_protocol)
cycling_protocol_10["InitialTemperature"] = 10 + kelvin
cycling_protocol_25["InitialTemperature"] = 25 + kelvin

@show typeof(cell_parameters_R["NegativeElectrode"]["ActiveMaterial"]["ReactionRateConstant"])
@show cell_parameters_R["NegativeElectrode"]["ActiveMaterial"]["ReactionRateConstant"]

solve_R = true
solve_F = false

if solve_R == true
	sim_R_10 = Simulation(model_setup, cell_parameters_R, cycling_protocol_10)
	sim_R_25 = Simulation(model_setup, cell_parameters_R, cycling_protocol_25)
end

if solve_F == true
	sim_F_10 = Simulation(model_setup, cell_parameters_F, cycling_protocol_10)
	sim_F_25 = Simulation(model_setup, cell_parameters_F, cycling_protocol_25)
end


if solve_R == true
	output_R_10 = solve(sim_R_10)
	output_R_25 = solve(sim_R_25)

	t_R_10 = output_R_10.time_series["Time"]
	E_R_10 = output_R_10.time_series["Voltage"]

	r_R_10 = output_R_10.states["NegativeElectrodeActiveMaterialReactionRateConstant"]
	D_R_10 = output_R_10.states["NegativeElectrodeActiveMaterialDiffusionCoefficient"]

	t_R_25 = output_R_25.time_series["Time"]
	E_R_25 = output_R_25.time_series["Voltage"]
	r_R_25 = output_R_25.states["NegativeElectrodeActiveMaterialReactionRateConstant"]
	D_R_25 = output_R_25.states["NegativeElectrodeActiveMaterialDiffusionCoefficient"]

	@info "The voltage at 10°C with R is: $(E_R_10[10]) V"
	@info "The voltage at 25°C with R is: $(E_R_25[10]) V"

	@info "The r at 10°C with R is: $(r_R_10[10])"
	@info "The r at 25°C with R is: $(r_R_25[10])"

	@info "The D at 10°C with R is: $(D_R_10[10])"
	@info "The D at 25°C with R is: $(D_R_25[10])"
end

if solve_F == true
	output_F_10 = solve(sim_F_10)
	output_F_25 = solve(sim_F_25)

	t_F_10 = output_F_10.time_series["Time"]
	E_F_10 = output_F_10.time_series["Voltage"]
	r_F_10 = output_F_10.states["NegativeElectrodeActiveMaterialReactionRateConstant"]
	D_F_10 = output_F_10.states["NegativeElectrodeActiveMaterialDiffusionCoefficient"]


	t_F_25 = output_F_25.time_series["Time"]
	E_F_25 = output_F_25.time_series["Voltage"]
	r_F_25 = output_F_25.states["NegativeElectrodeActiveMaterialReactionRateConstant"]
	D_F_25 = output_F_25.states["NegativeElectrodeActiveMaterialDiffusionCoefficient"]

	@info "The voltage at 10°C with F is: $(E_F_10[10]) V"
	# @info "The voltage at 25°C with F is: $(E_F_25[10]) V"


	@info "The r at 10°C with F is: $(r_F_10[10])"
	# @info "The r at 25°C with F is: $(r_F_25[10])"


	@info "The D at 10°C with F is: $(D_F_10[10])"
	# @info "The D at 25°C with F is: $(D_F_25[10])"
end


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

if solve_R == true
	scatterlines!(ax,
		t_R_10,
		E_R_10;
		linewidth = 4,
		markersize = 1,

		# marker = :cross,
		# markercolor = :black,
		label = "R_10K",
	)

	scatterlines!(ax,
		t_R_25,
		E_R_25;
		linewidth = 2,
		# marker = :cross,
		# markercolor = :black,
		markersize = 1,
		label = "R_25K")
end

if solve_F == true
	scatterlines!(ax,
		t_F_10,
		E_F_10;
		linewidth = 2,
		# marker = :cross,
		# markercolor = :black,
		markersize = 1,
		label = "F_10K")

	scatterlines!(ax,
		t_F_25,
		E_F_25;
		linewidth = 2,
		# marker = :cross,
		# markercolor = :black,
		markersize = 1,
		label = "F_25K")
end
axislegend()
display(f)
