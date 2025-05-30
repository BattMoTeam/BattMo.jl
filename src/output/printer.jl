export print_output_variables_overview

function print_output_variables_overview()
	meta_data = get_output_variables_meta_data()

	# Group variables by case
	case_groups = Dict{String, Vector{NamedTuple}}()

	for (name, info) in meta_data
		case = get(info, "case", "uncategorized")
		if !haskey(case_groups, case)
			case_groups[case] = NamedTuple[]
		end
		push!(case_groups[case], (
			name = name,
			isdefault = get(info, "isdefault", false),
			unit = get(info, "unit", "N/A"),
		))
	end

	function print_table(case_name::String, vars::Vector{NamedTuple})
		println("\nCase: $(uppercase(case_name))")
		println("="^50)
		println(rpad("Variable", 35), "Unit")
		println("-"^50)
		for v in sort(vars, by = x -> x.name)
			default_str = v.isdefault ? "Yes" : "No"
			println(rpad(v.name, 35), v.unit)
		end
		println("="^50)
	end

	for case in ["time_series", "metrics", "states"]
		if haskey(case_groups, case)
			print_table(case, case_groups[case])
		end
	end
end
