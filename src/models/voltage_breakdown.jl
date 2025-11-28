##################################################################################
# Functions to calculate individual losses leading to the total cell voltage
#
# The method used: 
#   - Power-loss post_processing method
# Reference:
#   - Michael R. Gerhardt et al 2021
#   - https://doi.org/10.1149/1945-7111/abf061


function compute_ohmic_electrode_overpotential(local_current_density, effective_electronic_conductivity, cell_current, weights)

	ohmic_integral = sum((local_current_density .^ 2 ./ effective_electronic_conductivity) .* weights)

	overpotential = ohmic_integral / cell_current

	return overpotential
end
