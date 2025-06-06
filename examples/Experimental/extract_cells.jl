using Jutul, BattMo, GLMakie, LinearAlgebra, JLD2

dosetup = true

if dosetup
    
    function getinput(name)
        return load_battmo_formatted_input(joinpath(pkgdir(BattMo), "examples", "Experimental", "jsoninputs", name))
    end

    # load geometry parameters
    inputparams_geometry = getinput("4680-geometry.json")
    # inputparams_geometry = getinput("geometry-1d.json")
    # inputparams_geometry = getinput("geometry-3d-demo.json")
    # load material parameters
    inputparams_material = getinput("lithium_ion_battery_nmc_graphite.json")
    # load control parameters
    inputparams_control = getinput("cc_discharge_control.json")

    inputparams = merge_input_params([inputparams_geometry, inputparams_material, inputparams_control])

    inputparams["Control"]["DRate"] = 0.1
    inputparams["Control"]["rampupTime"] = 3600*10

    output = get_simulation_input(deepcopy(inputparams))
    
	model = output[:model]
end

get_mesh(model) = model.domain.representation.representation

function get_cells(component; spmin = 0.01, spmax = 0.015)

    start_point = [0, 0, 0]
    direction = [1.2, 1, 0]
    direction = direction./norm(direction)
    
    grid = get_mesh(model[component])
    geo = tpfv_geometry(grid)

    u = geo.cell_centroids .- start_point

    sp = sum(u.*direction; dims = 1)
    v = u - sp.*direction

    v = v[1 : 2, :]

    n = [norm(col) for col in eachslice(v, dims = 2)]

    sp = vec(sp)

    c = findall((n .< 2e-3) .& (sp .> spmin) .& (sp .< spmax) .& (u[3, :] .< 0.03))

    sp = sp[c]
    
    compspmin = minimum(sp)
    compspmax = maximum(sp)

    # reorder c
    ind = sortperm(sp)
    c = c[ind]
    
    return grid, c, compspmin, compspmax
    
end

component = :NeCc
grid, c, compspmin, compsmpax = get_cells(component)
component = :PeCc
grid, c, compsp... = get_cells(component; spmin = compspmin, spmax = 0.02)

spmin = compspmin
spmax = compsp[2]

component = :NeCc
grid, c, = get_cells(component)
fig, ax = plot_mesh(grid; cells = c, color = :yellow)

components = [:PeCc, :NeAm, :PeAm, :Elyte]
colors = [:blue, :black, :red, :magenta]

for (i, component) in enumerate(components)
    let
        grid, c, = get_cells(component; spmin = spmin, spmax = spmax)
        plot_mesh!(ax, grid; cells = c, color = colors[i], alpha = 0.5)
    end
end

push!(components, :NeCc)

subcells = Dict()

for component in components
    let
        grid, c, = get_cells(component; spmin = spmin, spmax = spmax)
        subcells[component] = c
    end
end

# JLD2.save("subcells.jld2", Dict("subcells" => subcells))

# println(computeCellCapacity(output[:extra][:model])/ 3600) # in Ah
# model = output[:extra][:model][:PeAm]

# values = model.data_domain[:bcTrans]
# println("minimum : $(minimum(values))")
# fig, ax = hist(values)
# fig

# get_mesh(model) = model.domain.representation.representation
# 
# fig, ax = plot_mesh(get_mesh(model[:NeAm]); color = :black)
# plot_mesh!(ax, get_mesh(model[:PeAm]); color = :red)
# fig, ax = plot_mesh!(ax, get_mesh(model[:Elyte]); color = :green, alpha = 0.1)

# 1) NeAm  -> Elyte (Eq: charge_conservation)
#    ButlerVolmerActmatToElyteCT
# 2) NeAm  -> Elyte (Eq: mass_conservation)
#    ButlerVolmerActmatToElyteCT

# for ct in model.cross_terms
    # println(typeof(ct.cross_term))
# end

# 3) Elyte  -> NeAm (Eq: charge_conservation)
#    ButlerVolmerElyteToActmatCT
# 4) Elyte  -> NeAm (Eq: solid_diffusion_bc)
#    ButlerVolmerElyteToActmatCT
# 5) PeAm  -> Elyte (Eq: charge_conservation)
#    ButlerVolmerActmatToElyteCT
# 6) PeAm  -> Elyte (Eq: mass_conservation)
#    ButlerVolmerActmatToElyteCT
# 7) Elyte  -> PeAm (Eq: charge_conservation)
#    ButlerVolmerElyteToActmatCT
# 8) Elyte  -> PeAm (Eq: solid_diffusion_bc)
#    ButlerVolmerElyteToActmatCT
# 9) NeCc  -> NeAm (Eq: charge_conservation)
#    TPFAInterfaceFluxCT
# 10) NeAm  -> NeCc (Eq: charge_conservation)
#    TPFAInterfaceFluxCT
# 11) PeCc  -> PeAm (Eq: charge_conservation)
#    TPFAInterfaceFluxCT
# 12) PeAm  -> PeCc (Eq: charge_conservation)
#    TPFAInterfaceFluxCT
# 13) Control  -> PeCc (Eq: charge_conservation)
#    TPFAInterfaceFluxCT
# 14) PeCc  -> Control (Eq: charge_conservation)
#    AccumulatorInterfaceFluxCT
# 15) PeCc  -> Control (Eq: control)
#    AccumulatorInterfaceFluxCT


# states = output[:states]
# model = output[:extra][:model]
# plot_interactive(model, states, :Elyte; title = "Electrolyte ")
