using CSV, DataFrames, Jutul

battmo_base = normpath(joinpath(pathof(BattMo) |> splitdir |> first, ".."))
exdata = joinpath(battmo_base, "examples", "example_data")
data_pe_ocp = CSV.read(joinpath("src/input/defaults/cell_parameters/sodium_ion/data", "U_p.csv"), DataFrame)

# data_pe_ocp = CSV.read(joinpath(battmo_base, "src/input/defaults/cell_parameters/sodium_ion/data/U_p.csv"), DataFrame)
data_ne_ocp = CSV.read(joinpath(exdata, "Chayambuka_ne_ocv_2.csv"), DataFrame)
# data_ne_ocp = CSV.read(joinpath(battmo_base, "src/input/defaults/cell_parameters/sodium_ion/data/U_n.csv"), DataFrame)
data_pe_D = CSV.read(joinpath(exdata, "Chayambuka_pe_D.csv"), DataFrame)
# data_pe_D = CSV.read(joinpath(battmo_base, "src/input/defaults/cell_parameters/sodium_ion/data/D_p.csv"), DataFrame)
data_ne_D = CSV.read(joinpath(exdata, "Chayambuka_ne_D.csv"), DataFrame)
# data_ne_D = CSV.read(joinpath(battmo_base, "src/input/defaults/cell_parameters/sodium_ion/data/D_n.csv"), DataFrame)
data_pe_k = CSV.read(joinpath(exdata, "Chayambuka_pe_k.csv"), DataFrame)
# data_pe_k = CSV.read(joinpath(battmo_base, "src/input/defaults/cell_parameters/sodium_ion/data/k_p.csv"), DataFrame)
data_ne_k = CSV.read(joinpath(exdata, "Chayambuka_ne_k.csv"), DataFrame)
# data_ne_k = CSV.read(joinpath(battmo_base, "src/input/defaults/cell_parameters/sodium_ion/data/k_n.csv"), DataFrame)
data_elyte_cond = CSV.read(joinpath(exdata, "Chayambuka_elyte_conductivity.csv"), DataFrame)
# data_elyte_cond = CSV.read(joinpath(battmo_base, "src/input/defaults/cell_parameters/sodium_ion/data/sigma_e.csv"), DataFrame)
data_elyte_diff = CSV.read(joinpath(exdata, "Chayambuka_elyte_D.csv"), DataFrame)
# data_elyte_diff = CSV.read(joinpath(battmo_base, "src/input/defaults/cell_parameters/sodium_ion/data/D_e.csv"), DataFrame)

pe_ocp = data_pe_ocp[:, 2]
pe_transfered_charge = data_pe_ocp[:, 1] # mAh/g

ne_ocp = data_ne_ocp[:, 2]
ne_transfered_charge = data_ne_ocp[:, 1] # mAh/g

cond_elyte = data_elyte_cond[:, 2] # mS/cm
c_elyte = data_elyte_cond[:, 1] # kmol/m^3
cond_elyte = cond_elyte .* 10^(-3) * 10^2
c_elyte = c_elyte .* 10^3

diff_elyte = data_elyte_diff[:, 2]
c_elyte_diff = data_elyte_diff[:, 1] # kmol/m^3
c_elyte_diff = c_elyte_diff .* 10^3


pe_D = data_pe_D[:, 2]
c_pe_D = data_pe_D[:, 1] # kmol/m^3
c_pe_D = c_pe_D .* 10^3

pe_k = data_pe_k[:, 2]
c_pe_k = data_pe_k[:, 1] # kmol/m^3
c_pe_k = c_pe_k .* 10^3

ne_D = data_ne_D[:, 2]
c_ne_D = data_ne_D[:, 1] # kmol/m^3
c_ne_D = c_ne_D .* 10^3

ne_k = data_ne_k[:, 2]
c_ne_k = data_ne_k[:, 1] # kmol/m^3
c_ne_k = c_ne_k .* 10^3

max_pe_charge = maximum(pe_transfered_charge)
min_pe_charge = minimum(pe_transfered_charge)
max_ne_charge = maximum(ne_transfered_charge)
min_ne_charge = minimum(ne_transfered_charge)

x_pe = (pe_transfered_charge .- min_pe_charge) ./ (max_pe_charge - min_pe_charge)
x_ne = (ne_transfered_charge .- min_ne_charge) ./ (max_ne_charge - min_ne_charge)

function calc_ne_ocp(c, T, refT, cmax)

	ocp = get_1d_interpolator(x_ne, ne_ocp)
	return ocp(c / cmax)
end

@eval Main calc_ne_ocp = $calc_ne_ocp

function calc_pe_ocp(c, T, refT, cmax)

	ocp = get_1d_interpolator(pe_transfered_charge, pe_ocp)
	return ocp(c / cmax)
end

@eval Main calc_pe_ocp = $calc_pe_ocp

function calc_elyte_cond(c, T)

	cond = get_1d_interpolator(c_elyte, cond_elyte)
	return cond(c)
end

@eval Main calc_elyte_cond = $calc_elyte_cond

function calc_elyte_diff(c, T)

	diff = get_1d_interpolator(c_elyte_diff, diff_elyte)
	return diff(c)
end

@eval Main calc_elyte_diff = $calc_elyte_diff

function calc_pe_D(c, T, refT, cmax)

	diff = get_1d_interpolator(c_pe_D, pe_D)
	return diff(c)
end

@eval Main calc_pe_D = $calc_pe_D

function calc_ne_D(c, T, refT, cmax)

	diff = get_1d_interpolator(c_ne_D, ne_D)
	return diff(c)
end

@eval Main calc_ne_D = $calc_ne_D

function calc_ne_k(c, T)

	diff = get_1d_interpolator(c_ne_k, ne_k)
	return diff(c)
end

@eval Main calc_ne_k = $calc_ne_k

function calc_pe_k(c, T)

	diff = get_1d_interpolator(c_pe_k, pe_k)
	return diff(c)
end

@eval Main calc_pe_k = $calc_pe_k