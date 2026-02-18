# # Validation of Arrhenius temperature dependence implementation in BattMo.jl

# This notebook validates the Arrhenius temperature dependence implemented in BattMo.jl for two key battery properties:

# - the reaction rate constant k,
# - the solid‑phase diffusion coefficient D,

# for both the negative and positive electrodes.
# BattMo applies an Arrhenius law of the form:
# ln⁡Y = ln⁡A −(Ea/R*1/T), 
# meaning that ln⁡(Y) should vary linearly with 1/T, with slope:
# slope=−Ea/R.
# To verify this, we:

# Run battery simulations at several temperatures (0–40 °C).
# Extract k and D at the first output time.
# Fit ln⁡(Y) vs. 1/T to obtain the observed slope.
# Compare this slope to the theoretical value from the activation energies in the parameter set.
# Plot data, fitted lines, and theoretical lines for clear visual validation.

# Successful validation is seen when the fitted slope matches −Ea/R, confirming correct Arrhenius scaling in BattMo.

using BattMo
using GLMakie
using Statistics


# ### Load model with Arrhenius temperature dependence

params = load_cell_parameters(; from_default_set = "chen_2020")
protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
model_settings = load_model_settings(; from_default_set = "p2d")

model_settings["TemperatureDependence"] = "Arrhenius"
model = LithiumIonBattery(; model_settings)

temps_C = 0:10:40   # 0,10,20,30,40 °C

# ### Activation energies from parameter set
Ea_ne_R = params["NegativeElectrode"]["ActiveMaterial"]["ActivationEnergyOfReaction"]
Ea_ne_D = params["NegativeElectrode"]["ActiveMaterial"]["ActivationEnergyOfDiffusion"]
Ea_pe_R = params["PositiveElectrode"]["ActiveMaterial"]["ActivationEnergyOfReaction"]
Ea_pe_D = params["PositiveElectrode"]["ActiveMaterial"]["ActivationEnergyOfDiffusion"]


# ### Run simulations and extract values

T = Float64[]       # K
kvals_ne = Float64[]   # reaction rate
Dvals_ne = Float64[]   # diffusion
kvals_pe = Float64[]   # reaction rate
Dvals_pe = Float64[]   # diffusion

for TC in temps_C
	p = deepcopy(protocol)
	p["InitialTemperature"] = TC + 273.15
	out = solve(Simulation(model, params, p))

	# Pick first time point
	k_ne = out.states["NegativeElectrodeActiveMaterialReactionRateConstant"][1, :]
	d_ne = out.states["NegativeElectrodeActiveMaterialDiffusionCoefficient"][1, :]
	k_pe = out.states["PositiveElectrodeActiveMaterialReactionRateConstant"][1, :]
	d_pe = out.states["PositiveElectrodeActiveMaterialDiffusionCoefficient"][1, :]

	push!(kvals_ne, mean(filter(!isnan, collect(k_ne))))
	push!(Dvals_ne, mean(filter(!isnan, collect(d_ne))))
	push!(kvals_pe, mean(filter(!isnan, collect(k_pe))))
	push!(Dvals_pe, mean(filter(!isnan, collect(d_pe))))

	@show TC, mean(filter(!isnan, collect(k_ne)))

	push!(T, TC + 273.15)
end


# ### Fit ln(k) and ln(D) vs 1/T

function linfit(x, y)
	x̄ = mean(x)
	ȳ = mean(y)
	b = sum((x .- x̄) .* (y .- ȳ)) / sum((x .- x̄) .^ 2)
	a = ȳ - b*x̄
	return a, b
end


R = Constants().R
x = 1 ./ T

a_k_ne, b_k_ne = linfit(x, log.(kvals_ne))
a_D_ne, b_D_ne = linfit(x, log.(Dvals_ne))
a_k_pe, b_k_pe = linfit(x, log.(kvals_pe))
a_D_pe, b_D_pe = linfit(x, log.(Dvals_pe))

slope_fit_k_ne = b_k_ne
slope_fit_D_ne = b_D_ne
slope_fit_k_pe = b_k_pe
slope_fit_D_pe = b_D_pe

slope_theory_k_ne = -Ea_ne_R / R
slope_theory_D_ne = -Ea_ne_D / R
slope_theory_k_pe = -Ea_pe_R / R
slope_theory_D_pe = -Ea_pe_D / R


# ### Plot the simulation data, fitted lines, and theoretical lines

fig1 = Figure(size = (1200, 900))
ax1 = Axis(fig1[1, 1], title = "Arrhenius Validation: NE reaction rate constant k",
	xlabel = "1/T (1/K)", ylabel = "ln(k)")

scatter!(ax1, x, log.(kvals_ne), color = :blue, label = "Simulation data")
xs = range(minimum(x), maximum(x), length = 100)
lines!(ax1, xs, a_k_ne .+ b_k_ne .* xs, color = :blue, label = "Fit slope = $(round(slope_fit_k_ne, digits=4))")
lines!(ax1, xs, (a_k_ne + b_k_ne*mean(x)) .- slope_theory_k_ne*(mean(x) .- xs),
	color = :black, linestyle = :dash, label = "Theory slope = $(round(slope_theory_k_ne, digits=4))")

axislegend(ax1, position = :rb)


ax2 = Axis(fig1[1, 2], title = "Arrhenius Validation: PE reaction rate constant k",
	xlabel = "1/T (1/K)", ylabel = "ln(k)")

scatter!(ax2, x, log.(kvals_pe), color = :blue, label = "Simulation data")
xs = range(minimum(x), maximum(x), length = 100)
lines!(ax2, xs, a_k_pe .+ b_k_pe .* xs, color = :blue, label = "Fit slope = $(round(slope_fit_k_pe, digits=4))")
lines!(ax2, xs, (a_k_pe + b_k_pe*mean(x)) .- slope_theory_k_pe*(mean(x) .- xs),
	color = :black, linestyle = :dash, label = "Theory slope = $(round(slope_theory_k_pe, digits=4))")

axislegend(ax2, position = :rb)


ax3 = Axis(fig1[2, 1], title = "Arrhenius Validation: NE diffusion coefficient D",
	xlabel = "1/T (1/K)", ylabel = "ln(D)")

scatter!(ax3, x, log.(Dvals_ne), color = :red, label = "Simulation data")
lines!(ax3, xs, a_D_ne .+ b_D_ne .* xs, color = :red, label = "Fit slope = $(round(slope_fit_D_ne, digits=4))")
lines!(ax3, xs, (a_D_ne + b_D_ne*mean(x)) .- slope_theory_D_ne*(mean(x) .- xs),
	color = :black, linestyle = :dash, label = "Theory slope = $(round(slope_theory_D_ne, digits=4))")

axislegend(ax3, position = :rb)


ax4 = Axis(fig1[2, 2], title = "Arrhenius Validation: PE diffusion coefficient D",
	xlabel = "1/T (1/K)", ylabel = "ln(D)")

scatter!(ax4, x, log.(Dvals_pe), color = :red, label = "Simulation data")
lines!(ax4, xs, a_D_pe .+ b_D_pe .* xs, color = :red, label = "Fit slope = $(round(slope_fit_D_pe, digits=4))")
lines!(ax4, xs, (a_D_pe + b_D_pe*mean(x)) .- slope_theory_D_pe*(mean(x) .- xs),
	color = :black, linestyle = :dash, label = "Theory slope = $(round(slope_theory_D_pe, digits=4))")

axislegend(ax4, position = :rb)
display(fig1)
