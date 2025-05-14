using BattMo, GLMakie

## Setup the model

# We use chen data
cell_parameters  = load_cell_parameters(; from_default_set = "Chen2020_calibrated")

cycling_protocol = load_cycling_protocol(; from_default_set = "CCDischarge")

model = LithiumIonBattery()

battmo_formatted_input = convert_parameter_sets_to_battmo_input(model.model_settings, cell_parameters, cycling_protocol, BattMo.get_default_simulation_settings(model))

output = setup_simulation(deepcopy(battmo_formatted_input))

## Plot the OCPs for both electrodes

eldes = [:PeAm, :NeAm]
names = ["old positive", "negative"]

set_theme!(linewidth = 4)

fig = Figure(size = (1000, 400), fontsize = 20)
ax = Axis(fig[1, 1], title = "half-OCP", xlabel = "stoichiometry/-", ylabel = "Voltage/V")

let
    for (ielde, elde) in enumerate(eldes)
        submodel = output[:model].models[elde]
        cmax = submodel.system.params[:maximum_concentration]
        refT = 298.15
        cs = (0:0.01:1)*cmax
        ocp = [submodel.system.params.ocp_func(c, refT, refT, cmax) for c in cs]
        lines!(ax, cs/cmax, ocp, label = names[ielde])
    end
end

## We change the OCP function of the positive electrode by adding an exponential term
ocp = battmo_formatted_input["PositiveElectrode"]["Coating"]["ActiveMaterial"]["Interface"]["openCircuitPotential"]
# The pre-factor in the exponential is pretty high so that we do not touch the rest of the function
ocp["function"] = "-2*exp(-200*(1 - c/cmax))" * ocp["function"]

## We reinstantiate the model and add the OCP plot to the figure

output = setup_simulation(deepcopy(battmo_formatted_input))

elde = :PeAm
submodel = output[:model].models[elde]
cmax = submodel.system.params[:maximum_concentration]
refT = 298.15
cs = (0:0.01:1)*cmax
ocp = [submodel.system.params.ocp_func(c, refT, refT, cmax) for c in cs]
lines!(ax, cs/cmax, ocp, label = "new positive ")

fig[1, 2] = Legend(fig, ax, "Electrode")
fig


thicknesses = []
