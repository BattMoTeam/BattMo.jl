
"""
	print_overview(output::SimulationOutput)

Print a categorized summary of the output variables available in a simulation result.

# Description
Groups variables by type (`time_series`, `metrics`, `states`) and prints their names and units if present in the output.

# Arguments
- `output`: A simulation output as a `NamedTuple`, typically from a `Simulation.run()` call.

# Example
```julia
print_overview(output)
```
"""
function print_overview(output::SimulationOutput)
	meta_data = get_output_variables_meta_data()

	var_map = Dict(
		:NegativeElectrodeActiveMaterialSurfaceConcentration => [:NegativeElectrodeActiveMaterial, :SurfaceConcentration],
		:PositiveElectrodeActiveMaterialSurfaceConcentration => [:PositiveElectrodeActiveMaterial, :SurfaceConcentration],
		:NegativeElectrodeActiveMaterialConcentration        => [:NegativeElectrodeActiveMaterial, :ParticleConcentration],
		:PositiveElectrodeActiveMaterialConcentration        => [:PositiveElectrodeActiveMaterial, :ParticleConcentration],
		:NegativeElectrodeActiveMaterialDiffusionCoefficient => [:NegativeElectrodeActiveMaterial, :DiffusionCoefficient],
		:PositiveElectrodeActiveMaterialDiffusionCoefficient => [:PositiveElectrodeActiveMaterial, :DiffusionCoefficient],
		:NegativeElectrodeActiveMaterialReactionRateConstant => [:NegativeElectrodeActiveMaterial, :ReactionRateConstant],
		:PositiveElectrodeActiveMaterialReactionRateConstant => [:PositiveElectrodeActiveMaterial, :ReactionRateConstant],
		:ElectrolyteConcentration                            => [:Electrolyte, :ElectrolyteConcentration],
		:NegativeElectrodeActiveMaterialPotential            => [:NegativeElectrodeActiveMaterial, :ElectricPotential],
		:NegativeElectrodeCurrentCollectorPotential          => [:NegativeElectrodeCurrentCollector, :ElectricPotential],
		:ElectrolytePotential                                => [:Electrolyte, :ElectricPotential],
		:PositiveElectrodeActiveMaterialPotential            => [:PositiveElectrodeActiveMaterial, :ElectricPotential],
		:PositiveElectrodeCurrentCollectorPotential          => [:PositiveElectrodeCurrentCollector, :ElectricPotential],
		:NegativeElectrodeActiveMaterialTemperature          => [:NegativeElectrodeActiveMaterial, :Temperature],
		:PositiveElectrodeActiveMaterialTemperature          => [:PositiveElectrodeActiveMaterial, :Temperature],
		:NegativeElectrodeActiveMaterialOpenCircuitPotential => [:NegativeElectrodeActiveMaterial, :OpenCircuitPotential],
		:PositiveElectrodeActiveMaterialOpenCircuitPotential => [:PositiveElectrodeActiveMaterial, :OpenCircuitPotential],
		:NegativeElectrodeActiveMaterialCharge               => [:NegativeElectrodeActiveMaterial, :Charge],
		:NegativeElectrodeCurrentCollectorCharge             => [:NegativeElectrodeCurrentCollector, :Charge],
		:ElectrolyteCharge                                   => [:Electrolyte, :Charge],
		:PositiveElectrodeActiveMaterialCharge               => [:PositiveElectrodeActiveMaterial, :Charge],
		:PositiveElectrodeCurrentCollectorCharge             => [:PositiveElectrodeCurrentCollector, :Charge],
		:ElectrolyteMass                                     => [:Electrolyte, :Mass],
		:ElectrolyteDiffusivity                              => [:Electrolyte, :Diffusivity],
		:ElectrolyteConductivity                             => [:Electrolyte, :Conductivity],
		:SEIThickness                                        => [:NegativeElectrodeActiveMaterial, :SEIlength],
		:NormalizedSEIThickness                              => [:NegativeElectrodeActiveMaterial, :normalizedSEIlength],
		:SEIVoltageDrop                                      => [:NegativeElectrodeActiveMaterial, :SEIvoltageDrop],
		:NormalizedSEIVoltageDrop                            => [:NegativeElectrodeActiveMaterial, :normalizedSEIvoltageDrop],
	)

	# Group variables by case
	case_groups = Dict{String, Vector{NamedTuple}}()
	state = output.jutul_output[:states][3]

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
				shape = get(info, "shape", "N/A"),
			))
		end
	end

	function print_table(case_name::String, vars::Vector{NamedTuple})
		println("\nCase: $(uppercase(case_name))")
		println("="^160)
		println(rpad("Variable", 65), rpad("Unit", 30), "Shape")
		println("-"^160)
		for v in sort(vars, by = x -> x.name)
			println(rpad(string(v.name), 65), rpad(v.unit, 30), v.shape)
		end
		println("="^160)
	end

	for case in ["time_series", "metrics", "states"]
		if haskey(case_groups, case)
			print_table(case, case_groups[case])
		end
	end
end

