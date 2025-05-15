#%%
using BattMo, GLMakie

cell_parameters = load_cell_parameters(; from_default_set = "Chen2020_calibrated")

#%%
# PLOT OCV

fig_temp = Figure()
ax = Axis(fig_temp[1,1], title = "OCP Positive Electrode", xlabel = "x", ylabel = "OCP")


x = collect(0.0:0.001:1.0)
ocv_string = replace(cell_parameters["NegativeElectrode"]["ActiveMaterial"]["OpenCircuitPotential"], "(c/cmax)" => "x")
ocv = eval(Meta.parse("x -> " *  ocv_string))

# new_ocv_string = ocv_string * " + exp(-400*(x)) - exp(400*(x-1.0))"
# new_ocv = eval(Meta.parse("x -> " *  new_ocv_string))

lines!(ax, x,  ocv, label="Original")
# lines!(ax, x,  new_ocv, label="Asymptotic")

axislegend(ax)
fig_temp