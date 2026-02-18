```@meta
EditURL = "../../../examples/validation_notebooks/arrhenius.jl"
```

# Validation of Arrhenius temperature dependence implementation in BattMo.jl

This notebook validates the Arrhenius temperature dependence implemented in BattMo.jl
for the reaction rate constant k and the solid‑phase diffusion coefficient D,
for both the negative and positive electrodes.

BattMo applies an Arrhenius law of the (shifted) form:
ln Y(T) = ln Y(T_ref) - (Ea/R) * (1/T - 1/T_ref)
so that ln Y varies linearly with (1/T - 1/T_ref) with slope = -Ea/R and intercept ln Y(T_ref).

Steps:
- Run simulations at multiple temperatures (0–40 °C) + one at T_ref
- Extract k and D at the first output time
- Fit ln(Y) vs (1/T - 1/T_ref)
- Compare fitted slope to theoretical -Ea/R
- Plot data, fitted lines, and theory lines (anchored at ln Y_ref)

````@example arrhenius
using BattMo
using GLMakie
using Statistics
````

### Load model with Arrhenius temperature dependence

````@example arrhenius
params = load_cell_parameters(; from_default_set = "chen_2020")
protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
model_settings = load_model_settings(; from_default_set = "p2d")

model_settings["TemperatureDependence"] = "Arrhenius"
model = LithiumIonBattery(; model_settings)

temps_C = 0:10:40   # 0,10,20,30,40 °C

T_ref = 298.15
````

### Activation energies from parameter set (assumed in J/mol)

````@example arrhenius
Ea_ne_R = params["NegativeElectrode"]["ActiveMaterial"]["ActivationEnergyOfReaction"]
Ea_ne_D = params["NegativeElectrode"]["ActiveMaterial"]["ActivationEnergyOfDiffusion"]
Ea_pe_R = params["PositiveElectrode"]["ActiveMaterial"]["ActivationEnergyOfReaction"]
Ea_pe_D = params["PositiveElectrode"]["ActiveMaterial"]["ActivationEnergyOfDiffusion"]
````

### Run simulations and extract values

````@example arrhenius
T        = Float64[]     # K
kvals_ne = Float64[]     # reaction rate (NE)
Dvals_ne = Float64[]     # diffusion (NE)
kvals_pe = Float64[]     # reaction rate (PE)
Dvals_pe = Float64[]     # diffusion (PE)

for TC in temps_C
	p = deepcopy(protocol)
	p["InitialTemperature"] = TC + 273.15
	out = solve(Simulation(model, params, p));

	k_ne = out.states["NegativeElectrodeActiveMaterialReactionRateConstant"][1, :]
	d_ne = out.states["NegativeElectrodeActiveMaterialDiffusionCoefficient"][1, :]
	k_pe = out.states["PositiveElectrodeActiveMaterialReactionRateConstant"][1, :]
	d_pe = out.states["PositiveElectrodeActiveMaterialDiffusionCoefficient"][1, :]

	push!(kvals_ne, mean(filter(!isnan, collect(k_ne))))
	push!(Dvals_ne, mean(filter(!isnan, collect(d_ne))))
	push!(kvals_pe, mean(filter(!isnan, collect(k_pe))))
	push!(Dvals_pe, mean(filter(!isnan, collect(d_pe))))

	push!(T, TC + 273.15)
end
````

Also run once at the reference temperature to anchor the theoretical lines at ln(Y_ref)

````@example arrhenius
p_ref = deepcopy(protocol)
p_ref["InitialTemperature"] = T_ref
out_ref = solve(Simulation(model, params, p_ref));

k_ne_ref = out_ref.states["NegativeElectrodeActiveMaterialReactionRateConstant"][1, :]
d_ne_ref = out_ref.states["NegativeElectrodeActiveMaterialDiffusionCoefficient"][1, :]
k_pe_ref = out_ref.states["PositiveElectrodeActiveMaterialReactionRateConstant"][1, :]
d_pe_ref = out_ref.states["PositiveElectrodeActiveMaterialDiffusionCoefficient"][1, :]

k_ne_ref_val = mean(filter(!isnan, collect(k_ne_ref)))
d_ne_ref_val = mean(filter(!isnan, collect(d_ne_ref)))
k_pe_ref_val = mean(filter(!isnan, collect(k_pe_ref)))
d_pe_ref_val = mean(filter(!isnan, collect(d_pe_ref)))
````

### Fit ln(k) and ln(D) vs (1/T - 1/T_ref)

````@example arrhenius
function linfit(x, y)
	x̄ = mean(x)
	ȳ = mean(y)
	b = sum((x .- x̄) .* (y .- ȳ)) / sum((x .- x̄) .^ 2)
	a = ȳ - b*x̄
	return a, b
end

R = Constants().R
x_ref = (1.0 ./ T) .- (1.0 / T_ref)

a_k_ne, b_k_ne = linfit(x_ref, log.(kvals_ne))
a_D_ne, b_D_ne = linfit(x_ref, log.(Dvals_ne))
a_k_pe, b_k_pe = linfit(x_ref, log.(kvals_pe))
a_D_pe, b_D_pe = linfit(x_ref, log.(Dvals_pe))

slope_fit_k_ne = b_k_ne
slope_fit_D_ne = b_D_ne
slope_fit_k_pe = b_k_pe
slope_fit_D_pe = b_D_pe
````

Theoretical slopes: -Ea/R

````@example arrhenius
slope_theory_k_ne = -Ea_ne_R / R
slope_theory_D_ne = -Ea_ne_D / R
slope_theory_k_pe = -Ea_pe_R / R
slope_theory_D_pe = -Ea_pe_D / R

ln_k_ne_ref = log(k_ne_ref_val)
ln_D_ne_ref = log(d_ne_ref_val)
ln_k_pe_ref = log(k_pe_ref_val)
ln_D_pe_ref = log(d_pe_ref_val)
````

### Plot the simulation data, fitted lines, and theoretical lines (shifted-x)

````@example arrhenius
fig1 = Figure(size = (1200, 900))
````

We plot against x_ref = (1/T - 1/T_ref)

````@example arrhenius
xs = range(minimum(x_ref), maximum(x_ref), length = 100)
````

--- NE Reaction ---

````@example arrhenius
ax1 = Axis(fig1[1, 1],
	title = "Arrhenius Validation (with T_ref): NE reaction rate constant k",
	xlabel = "1/T - 1/T_ref (1/K)", ylabel = "ln(k)")
scatter!(ax1, x_ref, log.(kvals_ne), color = :blue, label = "Simulation data")
````

Fitted line in shifted-x form: ln(k) ≈ a + b*x_ref

````@example arrhenius
lines!(ax1, xs, a_k_ne .+ b_k_ne .* xs, color = :blue,
	label = "Fit slope = $(round(slope_fit_k_ne, digits=4))")
````

Theory line passing through ln(k_ref) at x=0 with slope -Ea/R

````@example arrhenius
lines!(ax1, xs, ln_k_ne_ref .+ slope_theory_k_ne .* xs,
	color = :black, linestyle = :dash,
	label = "Theory slope = $(round(slope_theory_k_ne, digits=4))")
axislegend(ax1, position = :rb)
````

--- PE Reaction ---

````@example arrhenius
ax2 = Axis(fig1[1, 2],
	title = "Arrhenius Validation (with T_ref): PE reaction rate constant k",
	xlabel = "1/T - 1/T_ref (1/K)", ylabel = "ln(k)")
scatter!(ax2, x_ref, log.(copy(kvals_pe)), color = :blue, label = "Simulation data")
lines!(ax2, xs, a_k_pe .+ b_k_pe .* xs, color = :blue,
	label = "Fit slope = $(round(slope_fit_k_pe, digits=4))")
lines!(ax2, xs, ln_k_pe_ref .+ slope_theory_k_pe .* xs,
	color = :black, linestyle = :dash,
	label = "Theory slope = $(round(slope_theory_k_pe, digits=4))")
axislegend(ax2, position = :rb)
````

--- NE Diffusion ---

````@example arrhenius
ax3 = Axis(fig1[2, 1],
	title = "Arrhenius Validation (with T_ref): NE diffusion coefficient D",
	xlabel = "1/T - 1/T_ref (1/K)", ylabel = "ln(D)")
scatter!(ax3, x_ref, log.(Dvals_ne), color = :red, label = "Simulation data")
lines!(ax3, xs, a_D_ne .+ b_D_ne .* xs, color = :red,
	label = "Fit slope = $(round(slope_fit_D_ne, digits=4))")
lines!(ax3, xs, ln_D_ne_ref .+ slope_theory_D_ne .* xs,
	color = :black, linestyle = :dash,
	label = "Theory slope = $(round(slope_theory_D_ne, digits=4))")
axislegend(ax3, position = :rb)
````

--- PE Diffusion ---

````@example arrhenius
ax4 = Axis(fig1[2, 2],
	title = "Arrhenius Validation (with T_ref): PE diffusion coefficient D",
	xlabel = "1/T - 1/T_ref (1/K)", ylabel = "ln(D)")
scatter!(ax4, x_ref, log.(Dvals_pe), color = :red, label = "Simulation data")
lines!(ax4, xs, a_D_pe .+ b_D_pe .* xs, color = :red,
	label = "Fit slope = $(round(slope_fit_D_pe, digits=4))")
lines!(ax4, xs, ln_D_pe_ref .+ slope_theory_D_pe .* xs,
	color = :black, linestyle = :dash,
	label = "Theory slope = $(round(slope_theory_D_pe, digits=4))")
axislegend(ax4, position = :rb)

display(fig1)
````

From te results, we can see that the log(k) and log(D) values from the simulations have a linear relationship with (1/T - 1/T_ref) and that the fitted lines closely follow the theoretical lines, which are anchored at the reference temperature point.
We can also see that the fitted slopes (from the simulation data) closely match the theoretical slopes (-Ea/R), validating the Arrhenius temperature dependence implementation.

## Example on GitHub
If you would like to run this example yourself, it can be downloaded from the BattMo.jl GitHub repository [as a script](https://github.com/BattMoTeam/BattMo.jl/blob/main/validations/arrhenius.jl).

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

