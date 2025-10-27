using CSV
using DataFrames
using Statistics
using GLMakie
using Jutul


# Read the electrode properties into a DataFrame
df_electrodes = CSV.read(joinpath(@__DIR__,"./data/ank_2023_electrode_properties.txt"), DataFrame)

# Read the psuedo ocv curves into a DataFrame
df_ocv = CSV.read(joinpath(@__DIR__,"./data/ank_2023_cell_pOCV_data.txt"), DataFrame)
# Fix comma decimals in numeric columns
for col in ["time/s", "Ewe/V", "I/mA", "Ece/V", "Ewe-Ece/V", "Capacity/mA.h"]
	df_ocv[!, col] = parse.(Float64, replace.(df_ocv[!, col], ',' => '.'))
end

# Calculate average properties
averages = Dict(
	"NegativeElectrodeCoatingThickness" => mean(df_electrodes[!, "Thickness anode"])/2,
	"PositiveElectrodeCoatingThickness" => mean(df_electrodes[!, "Thickness cathode"])/2,
	"NegativeElectrodeCoatingMass" => mean(df_electrodes[!, "Mass anode"])/2,
	"PositiveElectrodeCoatingMass" => mean(df_electrodes[!, "Mass cathode"])/2,
	"NegativeElectrodeCoatingEffectiveDensity" => mean(df_electrodes[!, "Density anode"])*1000, # convert from g/cm3 to kg/m3
	"PositiveElectrodeCoatingEffectiveDensity" => mean(df_electrodes[!, "Density cathode"])*1000, # convert from g/cm3 to kg/m3
)

# separate charge and discharge data
df_charge = filter(row -> row["I/mA"] .> 0, df_ocv)
df_discharge = filter(row -> row["I/mA"] .< 0, df_ocv)

# calculate stoichiometric coefficient from Capacity
Q_charge = df_charge[!, "Capacity/mA.h"]
Q_discharge = df_discharge[!, "Capacity/mA.h"]
stoich_charge = (Q_charge ) ./ (maximum(Q_charge) .- minimum(Q_charge))
stoich_discharge = (Q_discharge ) ./ (minimum(Q_discharge) .- maximum(Q_discharge))
stoich = stoich_charge

# calculate OCP vs stoichiometric coefficient
discharge_ne_ocp_interp = get_1d_interpolator(stoich_discharge, df_discharge[!, "Ece/V"])
discharge_pe_ocp_interp = get_1d_interpolator(stoich_discharge, df_discharge[!, "Ewe/V"])

discharge_ne_ocp = discharge_ne_ocp_interp.(stoich_charge)
discharge_pe_ocp = discharge_pe_ocp_interp.(stoich_charge)

ne_ocp = (discharge_ne_ocp .+ df_charge[!, "Ece/V"]) ./ 2
pe_ocp = (discharge_pe_ocp .+ df_charge[!, "Ewe/V"]) ./ 2

# write average OCP curves to csv
df_ocp_avg = DataFrame(StoichiometricCoefficient = stoich,
	NegativeElectrodeOCP = ne_ocp,
	PositiveElectrodeOCP = pe_ocp,
)


ne_ocp_interp = get_1d_interpolator(df_ocp_avg[!, "StoichiometricCoefficient"], df_ocp_avg[!, "NegativeElectrodeOCP"])
pe_ocp_interp = get_1d_interpolator(df_ocp_avg[!, "StoichiometricCoefficient"], df_ocp_avg[!, "PositiveElectrodeOCP"])

function negative_electrode_ocp(c, T, refT, cmax)
	return ne_ocp_interp(c / cmax)
end

function positive_electrode_ocp(c, T, refT, cmax)
	return pe_ocp_interp(c / cmax)
end

function electrolyte_diffusion_coefficient(c, T)
	# Expression from Nyman 2008

	D = 8.794e-11*(c/1000) .^ 2 - 3.972e-10*(c/1000) + 4.862e-10;
	return D
end

function electrolyte_conductivity(c, T)
	# Expression from Nyman 2008

	# NOTE : We have added a non-zero value to avoid singularity in the equation
	creg = 0.1;
	conductivity = 0.1297 .* (c ./ 1000) .^ 3 - 2.51 .* (c ./ 1000) .^ 1.5 + 3.329 .* (c ./ 1000) + creg;

	return conductivity
end
