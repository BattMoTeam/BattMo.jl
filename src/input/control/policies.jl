
struct ConstantCurrent <: AbstractPolicy
	all::AbstractDict
end

struct ConstantCurrentConstantVoltage <: AbstractPolicy
	all::AbstractDict
end

function calculate_total_time(cycling_protocol)
	number_of_cycles = cycling_protocol["TotalNumberOfCycles"]
	d_rate = haskey(cycling_protocol, "DRate") ? cycling_protocol["DRate"] : nothing
	c_rate = haskey(cycling_protocol, "CRate") ? cycling_protocol["CRate"] : nothing

	con = Constants()
	if number_of_cycles == 0

		if !isnothing(d_rate)
			total_time = 1.1 * con.hour / d_rate
		elseif !isnothing(c_rate)
			total_time = 1.1 * con.hour / c_rate
		end

	else
		total_time = number_of_cycles * 2.5 * (1 * con.hour / c_rate + 1 * con.hour / d_rate)
	end
	return total_time

end

function setup_generic_protocol(cycling_protocol::ConstantCurrent, input)
	total_time = calculate_total_time(cycling_protocol)

	experiment_dict = Dict{String, Any}(
		"InitialStateOfCharge" => cycling_protocol["InitialStateOfCharge"],
		"TotalTime" => total_time,
	)

	experiment_list = []
	if cycling_protocol["InitialControl"] == "charging"
		push!(experiment_list, "Charge at $(cycling_protocol["CRate"]) C until $(cycling_protocol["UpperVoltageLimit"]) V")
	elseif cycling_protocol["InitialControl"] == "discharging"
		push!(experiment_list, "Discharge at $(cycling_protocol["DRate"]) C until $(cycling_protocol["LowerVoltageLimit"]) V")
	else
		error("Initial control $(cycling_protocol["InitialControl"]) not recognized.")
	end

	if cycling_protocol["TotalNumberOfCycles"] > 0
		if cycling_protocol["InitialControl"] == "charging"
			push!(experiment_list, "Discharge at $(cycling_protocol["DRate"]) C until $(cycling_protocol["LowerVoltageLimit"]) V")
		elseif cycling_protocol["InitialControl"] == "discharging"
			push!(experiment_list, "Charge at $(cycling_protocol["CRate"]) C until $(cycling_protocol["UpperVoltageLimit"]) V")
		else
			error("Initial control $(cycling_protocol["InitialControl"]) not recognized.")
		end
		push!(experiment_list, "Increase cycle count")
		push!(experiment_list, "Repeat $(cycling_protocol["TotalNumberOfCycles"]-1) times")
	end

	if haskey(cycling_protocol, "InitialTemperature")
		experiment_dict["InitialTemperature"] = cycling_protocol["InitialTemperature"]
	end

	experiment_dict["Experiment"] = experiment_list

	experiment = Experiment(experiment_dict)

	return setup_generic_protocol(experiment, input)
end


function setup_generic_protocol(cycling_protocol::ConstantCurrentConstantVoltage, input)
	total_time = calculate_total_time(cycling_protocol)

	experiment_dict = Dict{String, Any}(
		"InitialStateOfCharge" => cycling_protocol["InitialStateOfCharge"],
		"TotalTime" => total_time,
	)

	experiment_list = []
	if cycling_protocol["InitialControl"] == "charging"
		push!(experiment_list, "Charge at $(cycling_protocol["CRate"]) C until $(cycling_protocol["UpperVoltageLimit"]) V")
		push!(experiment_list, "Hold at $(cycling_protocol["UpperVoltageLimit"]) V until $(cycling_protocol["CurrentChangeLimit"]) A/s")
	elseif cycling_protocol["InitialControl"] == "discharging"
		push!(experiment_list, "Discharge at $(cycling_protocol["DRate"]) C until $(cycling_protocol["LowerVoltageLimit"]) V")
		push!(experiment_list, "Rest until $(cycling_protocol["VoltageChangeLimit"]) V/s")

	else
		error("Initial control $(cycling_protocol["InitialControl"]) not recognized.")
	end

	if cycling_protocol["TotalNumberOfCycles"] > 0
		if cycling_protocol["InitialControl"] == "charging"
			push!(experiment_list, "Discharge at $(cycling_protocol["DRate"]) C until $(cycling_protocol["LowerVoltageLimit"]) V")
			push!(experiment_list, "Rest until $(cycling_protocol["VoltageChangeLimit"]) V/s")

		elseif cycling_protocol["InitialControl"] == "discharging"
			push!(experiment_list, "Charge at $(cycling_protocol["CRate"]) C until $(cycling_protocol["UpperVoltageLimit"]) V")
			push!(experiment_list, "Hold at $(cycling_protocol["UpperVoltageLimit"]) V until $(cycling_protocol["CurrentChangeLimit"]) A/s")

		else
			error("Initial control $(cycling_protocol["InitialControl"]) not recognized.")
		end
		push!(experiment_list, "Increase cycle count")
		push!(experiment_list, "Repeat $(cycling_protocol["TotalNumberOfCycles"]-1) times")
	end

	if haskey(cycling_protocol, "InitialTemperature")
		experiment_dict["InitialTemperature"] = cycling_protocol["InitialTemperature"]
	end

	experiment_dict["Experiment"] = experiment_list

	experiment = Experiment(experiment_dict)

	return setup_generic_protocol(experiment, input)
end
