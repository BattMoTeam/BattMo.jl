using BattMo
using GLMakie

# ## Parameters

rate = 1.0           # Rate for both discharge and charge
initial_soc = 1.0    # Starting state of charge
upper_cutoff = 4.1   # Upper voltage limit V
lower_cutoff = 3.5   # Lower voltage limit V

# ## Helpers: trapz and RMSE
trapz(x, y) = sum((y[1:(end - 1)] .+ y[2:end]) .* diff(x)) / 2
rmse(x, y0, y1) = sqrt(trapz(x, (y1 .- y0) .^ 2) / (x[end] - x[1]))

# Setup cell model and parameters
model = LithiumIonBattery()
cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")

# Step 0: full discharge--charge cycle as reference
HOUR = 3600.0
discharge_duration = HOUR / rate
charge_duration = HOUR / rate
t_total = discharge_duration + charge_duration

N = 11
t_discharge = collect(range(0.0, discharge_duration, N))
t_charge = collect(range(discharge_duration, t_total, N))
t_ref = vcat(t_discharge, t_charge[2:end])  # drop duplicate join point
I_app = rate * cell_parameters["Cell"]["NominalCapacity"]
I_tmp = vcat(fill(I_app, N), fill(-I_app, N - 1))

ref_protocol = CyclingProtocol(
    Dict(
        "Protocol" => "InputCurrentSeries",
        "Times" => t_ref,
        "Currents" => I_tmp,
        "LowerVoltageLimit" => lower_cutoff,
        "UpperVoltageLimit" => upper_cutoff,
        "InitialStateOfCharge" => initial_soc,
    )
)

sim_ref = Simulation(model, cell_parameters, ref_protocol)
output_ref = solve(sim_ref; info_level = 0, include_initial_state = true)
@assert maximum(abs.(output_ref.time_series["Time"] .- t_ref)) < 1.0e-14

# Step 1: discharge only using the current from the reference simulation
I_discharge = output_ref.time_series["Current"][1:N]

discharge_protocol = CyclingProtocol(
    Dict(
        "Protocol" => "InputCurrentSeries",
        "Times" => t_discharge,
        "Currents" => I_discharge,
        "LowerVoltageLimit" => lower_cutoff,
        "UpperVoltageLimit" => upper_cutoff,
        "InitialStateOfCharge" => initial_soc
    )
)

sim_discharge = Simulation(
    model, cell_parameters, discharge_protocol;
    output_all_secondary_variables = true,
)
output_discharge = solve(sim_discharge; info_level = 0, include_initial_state = true)
@assert maximum(abs.(output_discharge.time_series["Time"] .- t_discharge)) < 1.0e-14

# Step 2: charge using the discharge end state as initial state
I_charge = output_ref.time_series["Current"][N:end]
end_state = output_discharge.jutul_output.states[end]
@assert abs(end_state[:Control][:Controller].time - output_ref.time_series["Time"][N]) < 1.0e-14

charge_protocol = CyclingProtocol(
    Dict(
        "Protocol" => "InputCurrentSeries",
        "Times" => t_charge .- t_charge[1],
        "Currents" => I_charge,
        "LowerVoltageLimit" => 0.0,
        "UpperVoltageLimit" => upper_cutoff,
        "InitialStateOfCharge" => initial_soc
    )
)

sim_charge = Simulation(
    model, cell_parameters, charge_protocol;
    initial_state = end_state
)
output_charge = solve(sim_charge; info_level = 0, include_initial_state = true)
@assert maximum(abs.(output_charge.time_series["Time"] .- (t_charge .- t_charge[1]))) < 1.0e-14

# RMSE
E_discharge = output_discharge.time_series["Voltage"]
E_charge = output_charge.time_series["Voltage"]
E_ref = output_ref.time_series["Voltage"]
E_merge = vcat(E_discharge, E_charge[2:end])  # drop duplicate join point
rmse_total = rmse(t_ref, E_ref, E_merge)
milli = 1.0e-3
println("RMSE total: $(round(rmse_total / milli; digits = 6)) mV")

# Plot
fig = Figure()
ax = Axis(fig[1, 1], title = "Lower Cutoff = $(lower_cutoff) V", xlabel = "Time  /  h", ylabel = "Voltage  /  V")
lines!(ax, t_ref / HOUR, E_ref; label = "Reference", color = :blue)
lines!(ax, t_discharge / HOUR, E_discharge; label = "Discharge", color = :orange, linestyle = :dash)
lines!(ax, t_charge / HOUR, E_charge; label = "Charge", color = :red, linestyle = :dash)
scatter!(ax, t_discharge[end] / HOUR, E_discharge[end]; label = "Discharge end", color = :black, marker = :circle, markersize = 10)
ylims!(ax, lower_cutoff - 0.1, upper_cutoff + 0.1)
axislegend(ax; position = :rb)

ax = Axis(fig[2, 1], xlabel = "Time  /  h", ylabel = "Voltage Error  /  mV")
lines!(ax, t_ref / HOUR, (E_ref .- E_merge) ./ milli; label = "Error", color = :red)

display(GLMakie.Screen(), fig)
