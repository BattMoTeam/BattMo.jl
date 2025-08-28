using BattMo
using Jutul
using CSV
using DataFrames
using GLMakie

# Testing the getExpData function
exp_data = getExpData("all", "discharge")
println("Number of entries: ", length(exp_data))
@show exp_data[1]["rawRate"] 
@show exp_data[2]["rawRate"]
@show exp_data[3]["rawRate"]
@show exp_data[4]["rawRate"] # Show first entry for verification

""" setup the simulation for the MJ1 cell
"""
function runMJ1()

    cell_parameters = load_cell_parameters(; from_file_path = joinpath(@__DIR__,"mj1_tab1.json"))
    
    #cell_parameters = load_cell_parameters(; from_default_set = "Xu2015")
    println("successfully loaded cell parameters and cycling protocol")
    cycling_protocol = load_cycling_protocol(; from_file_path = joinpath(@__DIR__,"custom_discharge2.json"))

    #simulation_settings = load_simulation_settings(; from_file_path = joinpath(@__DIR__,"simple.json"))
    #simulation_settings = load_simulation_settings(; from_default_set = "P4D_pouch")
    simulation_settings = load_simulation_settings(; from_default_set = "P2D") # Ensure the model framework is set to P4D Pouch
    
    #model_settings = load_model_settings(;from_default_set = "P4D_pouch")
    model_settings = load_model_settings(;from_default_set = "P2D") 

    model_setup = LithiumIonBattery(; model_settings)

    sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings);
    print(sim.is_valid)
    #output0 = solve(sim;accept_invalid = true)
    return cycling_protocol, cell_parameters, model_setup, simulation_settings

end


cycling_protocol, cell_parameters,model_setup, simulation_settings = runMJ1()

sim = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)

cell_parameters_calibrated, V_eq, t_eq = equilibriumCalibration(sim)

cell_parameters_calibrated2,history  = highRateCalibration(exp_data,cycling_protocol,cell_parameters_calibrated,model_setup,simulation_settings; scaling = :log)
#cell_parameters_calibrated2 = highRateCalibration(exp_data,cycling_protocol,cell_parameters_calibrated,model_setup,simulation_settings)

println("Calibration done:")

CRates = [exp_data[i]["rawRate"] for i in 1:length(exp_data)]
outputs_base = []
outputs_calibrated = []

for i in 1:length(exp_data)
    
    I = exp_data[i]["I"]

    println("Running simulation for I = ", I)
    
	simuc = Simulation(model_setup, cell_parameters, cycling_protocol; simulation_settings)
    output = get_simulation_input(simuc)
    model = output[:model]
    simuc.cycling_protocol["DRate"] = I * 3600 / computeCellCapacity(model) 

    # Solve the simulation with the base parameters
    println("Running simulation for I = ", I)

	output = solve(simuc, info_level = -1; accept_invalid = true)

    # Store the output for the base case
    if i == 1
        output0 = output
    end

    # Store the output for the calibrated case
	push!(outputs_base, (I = I, output = output))
    
    simc = Simulation(model_setup, cell_parameters_calibrated2, cycling_protocol; simulation_settings)
    #println(simc.cell_parameters)
    outputc = get_simulation_input(simc)
    modelc = outputc[:model]
    simc.cycling_protocol["DRate"] =  I * 3600 / computeCellCapacity(modelc)
	output_c = solve(simc, info_level = -1;accept_invalid = true)

    println("calibrated simulation done for I = ", I, "\n")

    ocp_ne = modelc[:NeAm].system.params[:ocp_func]
    ocp_pe = modelc[:PeAm].system.params[:ocp_func]

    Vne = sum(modelc[:NeAm].domain.representation[:volumes])
    Vpe = sum(modelc[:PeAm].domain.representation[:volumes])

    eps_ne = modelc[:NeAm].system.params[:volume_fraction]
    eps_pe = modelc[:PeAm].system.params[:volume_fraction]

    a_ne = modelc[:NeAm].system.params[:volume_fractions][1]
    a_pe = modelc[:PeAm].system.params[:volume_fractions][1]

    cpe = simc.cell_parameters["PositiveElectrode"]["ActiveMaterial"]["MaximumConcentration"]
    cne = simc.cell_parameters["NegativeElectrode"]["ActiveMaterial"]["MaximumConcentration"]
    
    mpe = cpe * Vpe * a_pe * eps_pe 
    mne = cne * Vne * a_ne * eps_ne 

    @info "mpe = $mpe, mne = $mne"


    push!(outputs_calibrated, (I = I, output = output_c))
end

colors = Makie.wong_colors()

for (i, CRate) in enumerate(CRates)
    local fig = Figure(size = (800, 500))
    local ax = Axis(fig[1, 1],
        ylabel = "Voltage / V",
        xlabel = "Time / s",
        title = "Discharge curve at $(round(CRate, digits = 2))C"
    )

    if i == 1
      lines!(ax, t_eq, V_eq, linestyle = :dash, label = "Equilibrium", color = colors[4])
    
    end

    # Experimental curve
    t_exp = vec(exp_data[i]["time"])
    V_exp = vec(exp_data[i]["E"])
    lines!(ax, t_exp, V_exp, linestyle = :dot, label = "Experimental", color = colors[1])

    # Simulated curve (calibrated)
    t_sim, V_sim = get_tV(outputs_calibrated[i].output)
    lines!(ax, t_sim, V_sim, linestyle = :dash, label = "Simulated (calibrated)", color = colors[2])

    # Simulated curve (base)
    t_b, V_b = get_tV(outputs_base[i].output)
    lines!(ax, t_b, V_b, linestyle = :dash, label = "Simulated (base)", color = colors[3])

    axislegend(ax, position = :rb)
    display(fig)

    # Save figure as PNG
    save_path = joinpath(@__DIR__, "discharge_curve_$(round(CRate, digits=2))C.png")
    save(save_path, fig)
    println("Saved plot for $(round(CRate, digits=2))C at $save_path")
    
end


