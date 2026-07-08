using BattMo

# Example: Loading cell parameters from a BPX-formatted JSON file
# This example demonstrates how to use the `from_bpx_file_path` argument
# of `load_cell_parameters` to load battery parameters from a BPX file.

# Define paths
bpX_file = joinpath(dirname(pathof(BattMo)), "../test/data/jsonfiles/nmc_pouch_cell_BPX.json")

println("========================================")
println("BPX File Loading Example")
println("========================================")
println("BPX file path: $bpX_file")
println()

# Step 1: Load cell parameters from the BPX file
println("Step 1: Loading cell parameters from BPX file...")
cell_parameters = load_cell_parameters(from_bpx_file_path = bpX_file)
println("Cell parameters loaded successfully.")
println("Cell nominal capacity: $(cell_parameters["cell_nominal_capacity"]) A·h")
println("Lower voltage cutoff: $(cell_parameters["cell_lower_voltage_cutoff"]) V")
println("Upper voltage cutoff: $(cell_parameters["cell_upper_voltage_cutoff"]) V")
println("Negative electrode minimum stoichiometry: $(cell_parameters["negative_electrode_minimum_stoichiometry"])")
println("Negative electrode maximum stoichiometry: $(cell_parameters["negative_electrode_maximum_stoichiometry"])")
println()

# Step 2: Set up a simple battery model and cycling protocol
println("Step 2: Setting up simulation...")
model = LithiumIonBattery()

rate = 1.0  # C-rate for discharge
discharge_duration = 3600  # 1 hour at 1C in seconds

# Define the negative electrode entropic coefficient as a function (BPX stores it as a string)
neg_entropic_coef_str = "(-0.1112 * x + 0.02914 + 0.3561 * exp(-((x - 0.08309) ^ 2) / 0.004616)) / 1000"
println("Negative electrode entropic coefficient formula: $neg_entropic_coef_str")

# Create a simple current cycling protocol (BPX uses flat keys, not nested)
current = rate * cell_parameters["cell_nominal_capacity"]
protocol_dict = Dict(
    "Protocol" => "InputCurrent",
    "Current" => current,
    "LowerVoltageLimit" => cell_parameters["cell_lower_voltage_cutoff"],
    "UpperVoltageLimit" => cell_parameters["cell_upper_voltage_cutoff"],
)

cycling_protocol = CyclingProtocol(protocol_dict)

# Create and run the simulation
println("Step 3: Running battery simulation...")
sim = Simulation(model, cell_parameters, cycling_protocol)
output = solve(sim; info_level = 1, include_initial_state = true)

# Step 4: Display results
println()
println("Step 4: Simulation Results")
println("========================================")
println("Simulation completed successfully.")
println("Total simulation time: $(round(output.time[end] / 3600, digits = 2)) hours")
println("Final voltage: $(round(output.time_series["Voltage"][end], digits = 4)) V")
println("Number of time steps: $(length(output.time_series["Voltage"]))")
println()

# Save the output to a JSON file for further analysis
output_file = joinpath(@__DIR__, "../test/data/jsonfiles/bpx_example_output.json")
output_data = Dict(
    "time" => output.time_series["Time"],
    "voltage" => output.time_series["Voltage"],
    "current" => output.time_series["Current"],
)
JSON.print(output_file, output_data, 2)
println("Output saved to: $output_file")
println()
println("========================================")
println("Example complete!")
println("========================================")
