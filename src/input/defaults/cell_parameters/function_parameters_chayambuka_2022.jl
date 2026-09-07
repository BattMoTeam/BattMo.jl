using DelimitedFiles: readdlm
using Jutul: get_1d_interpolator

battmo_base = normpath(joinpath(pathof(BattMo) |> splitdir |> first, ".."))
defaultdata = joinpath(
    battmo_base, "src", "input", "defaults", "cell_parameters", "data", "sodium_ion"
)

"""Read a two-column Chayambuka data table, which is headerless by default."""
function read_chayambuka_data(file_name::AbstractString; header::Bool = false)
    file_path = joinpath(defaultdata, file_name)
    data = if header
        first(readdlm(file_path, ',', Float64; header = true))
    else
        readdlm(file_path, ',', Float64)
    end
    size(data, 2) == 2 || error("Expected two columns in Chayambuka data file: $file_name")
    return data
end

data_pe_ocp = read_chayambuka_data("chayambuka_pe_ocp.csv"; header = true)
data_ne_ocp = read_chayambuka_data("chayambuka_ne_ocp.csv")
data_pe_D = read_chayambuka_data("chayambuka_pe_D.csv")
data_ne_D = read_chayambuka_data("chayambuka_ne_D.csv")
data_pe_k = read_chayambuka_data("chayambuka_pe_k.csv")
data_ne_k = read_chayambuka_data("chayambuka_ne_k.csv")
data_elyte_cond = read_chayambuka_data("chayambuka_elyte_sigma.csv")
data_elyte_diff = read_chayambuka_data("chayambuka_elyte_D.csv")

pe_ocp = data_pe_ocp[:, 2]
x_pe = data_pe_ocp[:, 1] # stoich -

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

max_ne_charge = maximum(ne_transfered_charge)
min_ne_charge = minimum(ne_transfered_charge)

x_ne = (ne_transfered_charge .- min_ne_charge) ./ (max_ne_charge - min_ne_charge)

function calc_ne_ocp(c, T, refT, cmax)

    ocp = get_1d_interpolator(x_ne, ne_ocp)
    return ocp(c / cmax)
end


function calc_pe_ocp(c, T, refT, cmax)

    ocp = get_1d_interpolator(x_pe, pe_ocp)
    return ocp(c / cmax)
end


function calc_elyte_cond(c, T)

    cond = get_1d_interpolator(c_elyte, cond_elyte)
    return cond(c)
end


function calc_elyte_diff(c, T)

    diff = get_1d_interpolator(c_elyte_diff, diff_elyte)
    return diff(c)
end


function calc_pe_D(c, T, refT, cmax)

    diff = get_1d_interpolator(c_pe_D, pe_D)
    return diff(c)
end

function calc_ne_D(c, T, refT, cmax)

    diff = get_1d_interpolator(c_ne_D, ne_D)
    return diff(c)
end


function calc_ne_k(c, T, refT, cmax)

    diff = get_1d_interpolator(c_ne_k, ne_k)
    return diff(c)
end


function calc_pe_k(c, T, refT, cmax)

    diff = get_1d_interpolator(c_pe_k, pe_k)
    return diff(c)
end
