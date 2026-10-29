#######################################################################################################################
# Protocol conversion
#
# All cycling protocols are run by the control protocol of the external circuit model (see
# models/external_circuit/protocol.jl). This script converts each cycling protocol to the json control step structure
# described by the control step schema (see get_schema_control_steps):
#	- "Generic": the control steps are given directly
#	- "Experiment": experiment strings, see experiment_strings.jl
#	- "CC": constant current, possibly cycling between charge and discharge
#	- "CCCV": cycles of constant current discharge, rest, constant current charge and constant voltage hold
#	- "Function": the current is given by a function of time and voltage
#	- "InputCurrentSeries": the current is interpolated from a time series, with voltage limits
#######################################################################################################################

export cycling_protocol_to_control_steps


"""
	cycling_protocol_to_control_steps(cycling_protocol)

Convert a cycling protocol to a list of control steps following the control step schema.
"""
function cycling_protocol_to_control_steps(cycling_protocol)

    protocol = cycling_protocol["Protocol"]

    if protocol == "Generic"
        return cycling_protocol["ControlSteps"]
    elseif protocol == "Experiment"
        return experiment_to_control_steps(cycling_protocol["Experiment"])
    elseif protocol == "CC"
        return cc_to_control_steps(cycling_protocol)
    elseif protocol == "CCCV"
        return cccv_to_control_steps(cycling_protocol)
    elseif protocol == "Function"
        return function_to_control_steps(cycling_protocol)
    elseif protocol == "InputCurrentSeries"
        return input_current_series_to_control_steps(cycling_protocol)
    else
        error("Protocol $protocol not recognized.")
    end

end


# Relative tolerance of the voltage limits of the CC and CCCV protocols
const CC_VOLTAGE_TOLERANCE = 1.0e-4


function voltage_limit_termination(voltage, comparison)
    return Dict{String, Any}("Quantity" => "Voltage", "Value" => voltage, "Comparison" => comparison, "Tolerance" => CC_VOLTAGE_TOLERANCE)
end

function cc_discharge_step(cycling_protocol)
    return Dict{String, Any}(
        "ControlType" => "Current",
        "CRate" => cycling_protocol["DRate"],
        "Direction" => "discharging",
        "Termination" => voltage_limit_termination(cycling_protocol["LowerVoltageLimit"], "below"),
    )
end

function cc_charge_step(cycling_protocol)
    return Dict{String, Any}(
        "ControlType" => "Current",
        "CRate" => cycling_protocol["CRate"],
        "Direction" => "charging",
        "Termination" => voltage_limit_termination(cycling_protocol["UpperVoltageLimit"], "above"),
    )
end


"""
Constant current protocol. Without cycles, the cell is charged or discharged until the voltage limit is reached.
With cycles, the cell alternates between charge and discharge, starting with the initial control. A cycle consists of
the initial control followed by the opposite one.
"""
function cc_to_control_steps(cycling_protocol)

    number_of_cycles = cycling_protocol["TotalNumberOfCycles"]
    initial_control = cycling_protocol["InitialControl"]

    if number_of_cycles == 0
        step = initial_control == "discharging" ? cc_discharge_step(cycling_protocol) : cc_charge_step(cycling_protocol)
        return [step]
    end

    if initial_control == "discharging"
        cycle_steps = [cc_discharge_step(cycling_protocol), cc_charge_step(cycling_protocol)]
    else
        cycle_steps = [cc_charge_step(cycling_protocol), cc_discharge_step(cycling_protocol)]
    end

    return [Dict{String, Any}("ControlType" => "Cycle", "NumberOfCycles" => number_of_cycles, "ControlSteps" => cycle_steps)]
end


"""
Constant current constant voltage protocol. The discharge part consists of a constant current discharge until the lower
voltage limit followed by a rest until the voltage change rate is below the limit. The charge part consists of a
constant current charge until the upper voltage limit followed by a constant voltage hold until the current change rate
is below the limit. A cycle consists of the part of the initial control followed by the opposite one.
"""
function cccv_to_control_steps(cycling_protocol)

    discharge_steps = [
        cc_discharge_step(cycling_protocol),
        Dict{String, Any}(
            "ControlType" => "Rest",
            "Termination" => Dict{String, Any}("Quantity" => "VoltageChange", "Value" => cycling_protocol["VoltageChangeLimit"], "Comparison" => "absolute value below"),
        ),
    ]

    charge_steps = [
        cc_charge_step(cycling_protocol),
        Dict{String, Any}(
            "ControlType" => "Voltage",
            "Value" => cycling_protocol["UpperVoltageLimit"],
            "Termination" => Dict{String, Any}("Quantity" => "CurrentChange", "Value" => cycling_protocol["CurrentChangeLimit"], "Comparison" => "absolute value below"),
        ),
    ]

    if cycling_protocol["InitialControl"] == "discharging"
        cycle_steps = [discharge_steps; charge_steps]
    else
        cycle_steps = [charge_steps; discharge_steps]
    end

    return [Dict{String, Any}("ControlType" => "Cycle", "NumberOfCycles" => cycling_protocol["TotalNumberOfCycles"], "ControlSteps" => cycle_steps)]
end


"""
The current is given by a user function of time and voltage, until the end of the simulation.
"""
function function_to_control_steps(cycling_protocol)

    step = Dict{String, Any}("ControlType" => "CurrentFunction", "FunctionName" => cycling_protocol["FunctionName"])

    if haskey(cycling_protocol, "FilePath")
        step["FilePath"] = cycling_protocol["FilePath"]
    end

    return [step]
end


"""
The current is interpolated from the time series, until the end of the simulation. The voltage limits are enforced by
switching to voltage control.
"""
function input_current_series_to_control_steps(cycling_protocol)

    step = Dict{String, Any}(
        "ControlType" => "CurrentSeries",
        "Times" => cycling_protocol["Times"],
        "Currents" => cycling_protocol["Currents"],
        "LowerVoltageLimit" => cycling_protocol["LowerVoltageLimit"],
        "UpperVoltageLimit" => cycling_protocol["UpperVoltageLimit"],
    )

    return [step]
end
