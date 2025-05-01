# %%
using BattMo
using LinearAlgebra
#########################################
# Cell Mass calculations
#########################################

function compute_electrode_coating_mass(params::CellParameters, electrode::String)

	if !(electrode in ["PositiveElectrode", "NegativeElectrode"])
		error("Electrode must be either PositiveElectrode or NegativeElectrode, not $electrode. Check for typos")
	end

	effective_density = params[electrode]["ElectrodeCoating"]["EffectiveDensity"]
	area = params["Cell"]["ElectrodeGeometricSurfaceArea"]
	thickness = params[electrode]["ElectrodeCoating"]["Thickness"]

	return effective_density * area * thickness
end



function compute_electrode_theoretical_density(params::CellParameters, electrode::String)

	if !(electrode in ["PositiveElectrode", "NegativeElectrode"])
		error("Electrode must be either PositiveElectrode or NegativeElectrode, not $electrode. Check for typos")
	end

	component_mass_fractions = [params[electrode]["ActiveMaterial"]["MassFraction"],
		params[electrode]["ConductiveAdditive"]["MassFraction"],
		params[electrode]["Binder"]["MassFraction"]]
	component_densities = [params[electrode]["ActiveMaterial"]["Density"],
		params[electrode]["ConductiveAdditive"]["Density"],
		params[electrode]["Binder"]["Density"]]

	return 1 / sum(component_mass_fractions ./ component_densities)
end



function compute_separator_mass(params::CellParameters)
	area = params["Cell"]["ElectrodeGeometricSurfaceArea"]
	density = params["Separator"]["Density"]
	thickness = params["Separator"]["Thickness"]
	porosity = params["Separator"]["Porosity"]
	return thickness * area * (1 - porosity) * density
end



function compute_current_collector_mass(params::CellParameters, electrode::String)

	if !(electrode in ["PositiveElectrode", "NegativeElectrode"])
		error("Electrode must be either PositiveElectrode or NegativeElectrode, not $electrode. Check for typos")
	end

	area = params["Cell"]["ElectrodeGeometricSurfaceArea"]
	thickness = params[electrode]["CurrentCollector"]["Thickness"]
	density = params[electrode]["CurrentCollector"]["Density"]
	return area * thickness * density
end


"""

"""
function compute_electrolyte_mass(params::CellParameters)

	electrolyte_density = params["Electrolyte"]["Density"]
	cell_area = params["Cell"]["ElectrodeGeometricSurfaceArea"]

	#separator (sep)
	sep_porosity = params["Separator"]["Porosity"]
	sep_volume = cell_area * params["Separator"]["Thickness"]

	#positive electrode (pe)
	pe_theoretical_density = compute_electrode_theoretical_density(params, "PositiveElectrode")
	pe_effective_density = params["PositiveElectrode"]["ElectrodeCoating"]["EffectiveDensity"]
	pe_volume = cell_area * params["PositiveElectrode"]["ElectrodeCoating"]["Thickness"]
	pe_porosity = 1.0 - (pe_effective_density / pe_theoretical_density)

	#negative electrode (ne)
	ne_theoretical_density = compute_electrode_theoretical_density(params, "NegativeElectrode")
	ne_effective_density = params["NegativeElectrode"]["ElectrodeCoating"]["EffectiveDensity"]
	ne_volume = cell_area * params["NegativeElectrode"]["ElectrodeCoating"]["Thickness"]
	ne_porosity = 1.0 - (ne_effective_density / ne_theoretical_density)

	component_volumes = [pe_volume, ne_volume, sep_volume]
	component_porosities = [pe_porosity, ne_porosity, sep_porosity]

	return electrolyte_density * dot(component_volumes, component_porosities)
end

function compute_cell_mass(params::CellParameters; print_breakdown::Bool = false)
	m_positive_e = compute_electrode_coating_mass(params, "PositiveElectrode")
	m_negative_e = compute_electrode_coating_mass(params, "NegativeElectrode")
	m_separator = compute_separator_mass(params)
	m_positive_e_cc = compute_current_collector_mass(params, "PositiveElectrode")
	m_negative_e_cc = compute_current_collector_mass(params, "NegativeElectrode")
	m_electrolyte = compute_electrolyte_mass(params)
	total_cell_mass = m_positive_e + m_negative_e + m_separator + m_positive_e_cc + m_negative_e_cc + m_electrolyte

	if print_breakdown
		print("""
		Positive Electrode                   Mass = $m_positive_e,     % = $(100*m_positive_e/total_cell_mass) \n
		Negative Electrode                   Mass = $m_negative_e,     % = $(100*m_negative_e/total_cell_mass) \n
		Positive Electrode Current Collector Mass = $m_positive_e_cc,  % = $(100*m_positive_e_cc/total_cell_mass) \n
		Negative Electrode Current Collector Mass = $m_negative_e_cc,  % = $(100*m_negative_e_cc/total_cell_mass) \n
		Electrolyte                          Mass = $m_electrolyte,    % = $(100*m_electrolyte/total_cell_mass) \n
		Separator                            Mass = $m_separator,      % = $(100*m_separator/total_cell_mass) \n
		""")
	end
	return total_cell_mass
end



#########################################
# Cell XXXX calculations
#########################################


function compute_electrode_volume_fraction(params::CellParameters, electrode::String)

	if !(electrode in ["PositiveElectrode", "NegativeElectrode"])
		error("Electrode must be either PositiveElectrode or NegativeElectrode, not $electrode. Check for typos")
	end

	effective_density = params[electrode]["ElectrodeCoating"]["EffectiveDensity"]
	theoretical_density = compute_electrode_theoretical_density(params, electrode)
	return effective_density / theoretical_density
end

"""
Computes the Areal mass loading of active material on current collector (kg/m^2)
"""
function compute_electrode_mass_loading(params::CellParameters, electrode::String)

	if !(electrode in ["PositiveElectrode", "NegativeElectrode"])
		error("Electrode must be either PositiveElectrode or NegativeElectrode, not $electrode. Check for typos.")
	end

	electrode_mass = compute_electrode_coating_mass(params, electrode)
	active_material_mass = electrode_mass * params[electrode]["ActiveMaterial"]["MassFraction"]
	electrode_area = params["Cell"]["ElectrodeGeometricSurfaceArea"]
	return active_material_mass / electrode_area
end

function compute_electrode_maximum_capacity(params::CellParameters, electrode::String)

	if !(electrode in ["PositiveElectrode", "NegativeElectrode"])
		error("Electrode must be either PositiveElectrode or NegativeElectrode, not $electrode. Check for typos.")
	end

	electrode_mass = compute_electrode_coating_mass(params, electrode)
	mass_fraction = params[electrode]["ActiveMaterial"]["MassFraction"]
	max_concentration = params[electrode]["ActiveMaterial"]["MaximumConcentration"]
	density = params[electrode]["ActiveMaterial"]["Density"]
	stoichiometry_100 = params[electrode]["ActiveMaterial"]["StoichiometricCoefficientAtSOC100"]
	stoichiometry_0 = params[electrode]["ActiveMaterial"]["StoichiometricCoefficientAtSOC0"]

	stoichiometric_range = abs(stoichiometry_100 - stoichiometry_0)
	active_material_mass = electrode_mass * mass_fraction
	faraday_constant_Ah = 96500.0 / 3600.0

	return stoichiometric_range * (max_concentration / density) * active_material_mass * faraday_constant_Ah
end

function compute_np_ratio(params::CellParameters)
	pe_maximum_capacity = compute_electrode_maximum_capacity(params, "PositiveElectrode")
	ne_maximum_capacity = compute_electrode_maximum_capacity(params, "NegativeElectrode")
	return ne_maximum_capacity / pe_maximum_capacity
end

function compute_cell_theoretical_capacity(params::CellParameters)
	pe_maximum_capacity = compute_electrode_maximum_capacity(params, "PositiveElectrode")
	ne_maximum_capacity = compute_electrode_maximum_capacity(params, "NegativeElectrode")
	return min(pe_maximum_capacity, ne_maximum_capacity)
end

# %%
#########################################
# Testing
#########################################


parameter_sets_directory = "./test/data/jsonfiles/"

cell_parameters = load_cell_parameters(; from_file_path = parameter_sets_directory * "cell_parameters/Chen2020.json")
cell_parameters["PositiveElectrode"]["ElectrodeCoating"]["Thickness"] |> println

cycling_protocol = load_cycling_protocol(; from_file_path = parameter_sets_directory * "cycling_protocols/CCCV.json")
cycling_protocol["Protocol"] |> println

simulation_settings = read_simulation_settings(parameter_sets_directory * "model_settings/model_settings_P2D.json")
simulation_settings["ModelGeometry"] |> println