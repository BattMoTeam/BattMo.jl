export print_output_overview, print_output_variable_info


"""
	print_output_overview(output::NamedTuple)

Print a categorized summary of the output variables available in a simulation result.

# Description
Groups variables by type (`time_series`, `metrics`, `states`) and prints their names and units if present in the output.

# Arguments
- `output`: A simulation output as a `NamedTuple`, typically from a `Simulation.run()` call.

# Example
```julia
print_output_overview(output)
```
"""
function print_output_overview(output::NamedTuple)
	meta_data = get_output_variables_meta_data()

	var_map = Dict(
		:NeAmSurfaceConcentration => [:NeAm, :SurfaceConcentration],
		:PeAmSurfaceConcentration => [:PeAm, :SurfaceConcentration],
		:NeAmConcentration        => [:NeAm, :ParticleConcentration],
		:PeAmConcentration        => [:PeAm, :ParticleConcentration],
		:ElectrolyteConcentration => [:Elyte, :Concentration],
		:NeAmPotential            => [:NeAm, :Voltage],
		:ElectrolytePotential     => [:Elyte, :Voltage],
		:PeAmPotential            => [:PeAm, :Voltage],
		:NeAmTemperature          => [:NeAm, :Temperature],
		:PeAmTemperature          => [:PeAm, :Temperature],
		:NeAmOpenCircuitPotential => [:NeAm, :OpenCircuitPotential],
		:PeAmOpenCircuitPotential => [:PeAm, :OpenCircuitPotential],
		:NeAmCharge               => [:NeAm, :Charge],
		:ElectrolyteCharge        => [:Elyte, :Charge],
		:PeAmCharge               => [:PeAm, :Charge],
		:ElectrolyteMass          => [:Elyte, :Mass],
		:ElectrolyteDiffusivity   => [:Elyte, :Diffusivity],
		:ElectrolyteConductivity  => [:Elyte, :Conductivity],
		:SEIThickness             => [:NeAm, :SEIlength],
		:NormalizedSEIThickness   => [:NeAm, :normalizedSEIlength],
		:SEIVoltageDrop           => [:NeAm, :SEIvoltageDrop],
		:NormalizedSEIVoltageDrop => [:NeAm, :normalizedSEIvoltageDrop],
	)

	# Group variables by case
	case_groups = Dict{String, Vector{NamedTuple}}()
	state = output[:states][3]

	for (name, info) in meta_data
		case = get(info, "case", "uncategorized")
		has_data = false

		if case == "states"
			symname = Symbol(name)
			if haskey(var_map, symname)
				path = var_map[symname]
				has_data = try
					value = state[path[1]][path[2]]
					true
				catch
					false
				end

			else
				has_data = true
			end
		else
			# Always include time_series and metrics
			has_data = true
		end

		if has_data
			if !haskey(case_groups, case)
				case_groups[case] = NamedTuple[]
			end
			push!(case_groups[case], (
				name = name,
				isdefault = get(info, "isdefault", false),
				unit = get(info, "unit", "N/A"),
			))
		end
	end

	function print_table(case_name::String, vars::Vector{NamedTuple})
		println("\nCase: $(uppercase(case_name))")
		println("="^50)
		println(rpad("Variable", 35), "Unit")
		println("-"^50)
		for v in sort(vars, by = x -> x.name)
			println(rpad(string(v.name), 35), v.unit)
		end
		println("="^50)
	end

	for case in ["time_series", "metrics", "states"]
		if haskey(case_groups, case)
			print_table(case, case_groups[case])
		end
	end
end



"""
	print_output_variable_info(from_name::String)

Print detailed metadata for output variables that match the given name.

# Description
Performs a case-insensitive search for variable names containing `from_name` and prints information such as description, type, unit, and documentation links.

# Arguments
- `from_name`: Partial or full name of the variable to search for.

# Example
```julia
print_output_variable_info("voltage")
```
"""
function print_output_variable_info(from_name::String)
	# Get the metadata dictionary
	meta_data = get_output_variables_meta_data()
	output_fmt = detect_output_format()

	# Soft match: find keys containing `from_name` (case-insensitive)
	matches = collect(filter(key -> occursin(lowercase(from_name), lowercase(key)), keys(meta_data)))

	if isempty(matches)
		println("❌ No variables found matching: ", from_name)
	else
		for actual_key in matches
			param_info = meta_data[actual_key]

			println("="^80)
			println("ℹ️  Variable Information")
			println("="^80)

			# Name
			println("🔹 Name:         	", actual_key)

			# Description
			if haskey(param_info, "description")
				description = param_info["description"]
				println("🔹 Description:		", description)
			end

			# Type
			if haskey(param_info, "type")
				types = param_info["type"]
				types_str = isa(types, AbstractArray) ? join(types, ", ") : string(types)
				println("🔹 Type:         	", types_str)
			end

			# Shape
			if haskey(param_info, "shape")
				types = param_info["shape"]
				types_str = isa(types, AbstractArray) ? join(types, ", ") : string(types)
				println("🔹 Shape:         	", types_str)
			end

			# Unit
			if haskey(param_info, "unit")
				println("🔹 Unit:         	", param_info["unit"])
			end

			# Options
			if haskey(param_info, "options")
				options = param_info["options"]
				options_str = isa(options, AbstractArray) ? join(options, ", ") : string(options)
				println("🔹 Options:      	", options_str)
			end

			# Validation bounds
			if haskey(param_info, "min_value")
				min_value = param_info["min_value"]
				println("🔹 Minimum value:      	", min_value)
			end
			if haskey(param_info, "max_value")
				max_value = param_info["max_value"]
				println("🔹 Maximum value:      	", max_value)
			end

			# Documentation
			doc_url = get(param_info, "documentation", nothing)
			if isnothing(doc_url) || doc_url == "-"
				link = "-"
			elseif doc_url isa String
				link = format_link("visit", doc_url, 50, output_fmt)
				println("🔹 Documentation:	", link)
			end




			# Ontology
			context_type_iri = get(param_info, "context_type_iri", nothing)
			if isnothing(context_type_iri) || context_type_iri == "-"
				iri = "-"
			elseif context_type_iri isa String
				iri = format_link("visit", context_type_iri, 50, output_fmt)
				println("🔹 Ontology link:	", iri)
			end




			println()  # Extra spacing between entries
		end
	end
end
