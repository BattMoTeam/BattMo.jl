#=
Electro-Chemical component
A component with electric potential, concentration and temperature
The different potentials are independent (diagonal onsager matrix),
and conductivity, diffusivity is constant.
=#
# using Revise
# ENV["JULIA_STACKTRACE_MINIMAL"] = true
# using AbbreviatedStackTraces
using Jutul, BattMo
using MAT
# include("../../test/battery/mrstTestUtils.jl")
ENV["JULIA_DEBUG"] = 0;

##
#name="model1d_notemp"
name="model1D_50"
name="model1Dmod_50"
name="model1Dmod_500"
name="sector_7920"
name="model3D_492"
#name="model2D_1100" # give error
#name="model3D_3936"
#name="sector_1656"
#name="sector_55200" #To big for direct linear_solver
#name="spiral_16560"
#name="spiral_16560_org"
#name ="sector_1656_org"
fn = string(dirname(pathof(BattMo)), "/../test/battery/data/", name, ".mat")
exported_all = MAT.matread(fn)
model, state0, parameters, grids = BattMo.setup_model(exported_all);    
sim, forces, grids, state0, parameters, exported_all, model = BattMo.setup_sim(name);
states, grids, state0, stateref, parameters, exported_all, model, timesteps, cfg, report, sim = test_battery(name,info_level = 5, max_step = nothing);
steps = size(states, 1)
E = Matrix{Float64}(undef,steps,2)
for step in 1:steps
    phi = states[step][:BPP][:Phi][1]
    E[step,1] = phi
    phi_ref = stateref[step]["Control"]["E"]
    E[step,2] = phi_ref
end
timesteps = timesteps[1:steps]
using Plots
plot1 = Plots.plot(cumsum(timesteps),E; title = "E", size=(1000, 800))
# plot!(plot1,)
closeall()
display(plot1)

##
error()

function plot_phi()
    plot1 = Plots.plot([], []; title = "Phi", size=(1000, 800))

    p = plot!(plot1, legend = false)
    submodels = (:CC, :NAM, :ELYTE, :PAM, :PP)
    # submodels = (:NAM, :ELYTE, :PAM)
    # submodels = (:CC, :NAM)
    # submodels = (:ELYTE,)
    # submodels = (:PP, :PAM)

    var = :Phi
    steps = size(states, 1)
    for i in 1:steps
        for mod in submodels
            x = grids[mod]["cells"]["centroids"]
            plot!(plot1, x, states[i][mod][var], lw=2, color=RGBA(0.5, 0.5, 0.5, 0.5))
        end
    end
    return plot1
end
plot1 = plot_phi()
closeall()
display(plot1)

##

#for (i, dt) in enumerate(timesteps)
for i in 1:1   
    refstep=i
    sim_step=i

    p1 = Plots.plot(title="Phi", size=(1000, 800))
    p2 = Plots.plot(title="Flux", size=(1000, 800))
    p3 = Plots.plot(title="C", size=(1000, 800))

    fields = ["CurrentCollector","ElectrodeActiveComponent"]
    components = ["NegativeElectrode","PositiveElectrode"]
    #components = ["NegativeElectrode"]
    #components = ["PositiveElectrode"]
    #components = []
    for component = components
        for field in fields
            G = exported_all["model"][component][field]["G"]
            x = G["cells"]["centroids"]
            xf= G["faces"]["centroids"][end]
            xfi= G["faces"]["centroids"][2:end-1]

            state = stateref[refstep][component]
            phi_ref = state[field]["phi"]
            j_ref = state[field]["j"]

            Plots.plot!(p1,x,phi_ref;linecolor="red")
            Plots.plot!(p2,xfi,j_ref;linecolor="red")
            if haskey(state[field],"c")
                c = state[field]["c"]
                Plots.plot!(p3,x,c;linecolor="red")
            end
        end
    end

    fields = [] 
    fields = ["Electrolyte"]

    for field in fields
        G = exported_all["model"][field]["G"]
        x = G["cells"]["centroids"]
        xf= G["faces"]["centroids"][end]
        xfi= G["faces"]["centroids"][2:end-1]

        state = stateref[refstep]
        phi_ref = state[field]["phi"]
        j_ref = state[field]["j"]

        Plots.plot!(p1,x,phi_ref;linecolor="red")
        Plots.plot!(p2,xfi,j_ref;linecolor="red")
        if haskey(state[field],"cs")
            c = state[field]["cs"][1]
            Plots.plot!(p3,x,c;linecolor="red")
        end
    end

    ##


    mykeys = [:CC, :NAM] # :ELYTE]
    mykeys = [:PP, :PAM]
    #mykeys = [:ELYTE]
    mykeys =  keys(grids)
    for key in mykeys
        G = grids[key]
        x = G["cells"]["centroids"]
        xf= G["faces"]["centroids"][end]
        xfi= G["faces"]["centroids"][2:end-1]     
        p = plot(p1, p2, layout = (1, 2), legend = false)
        phi = states[sim_step][key][:Phi]
        Plots.plot!(
            p1, x, phi; markershape=:circle, linestyle=:dot, seriestype = :scatter
            )
        
        if haskey(states[sim_step][key], :TotalCurrent)
            j = states[sim_step][key][:TotalCurrent][1:2:end-1]
        else
#            j = -states[sim_step][key][:TPkGrad_Phi][1:2:end-1]
        end
        
        #Plots.plot!(p2, xfi, j; markershape=:circle,linestyle=:dot, seriestype = :scatter)
        if(haskey(states[sim_step][key], :C))
            cc = states[sim_step][key][:C]
            Plots.plot!(p3, x, cc; markershape=:circle, linestyle=:dot, seriestype = :scatter)
        end
    end

    display(plot!(p1, p2, p3,layout = (3, 1), legend = false))
end
error()
##
E = Matrix{Float64}(undef,27,2)
for step in 1:27
    phi = states[step][:PP][:Phi][10]
    E[step,1] = phi
    phi_ref = stateref[step]["PositiveElectrode"]["ElectrodeActiveComponent"]["phi"][10]
    E[step,2] = phi_ref
end

##
function print_diff_j(s, sref, n)
    k = :TotalCurrent
    if haskey(s[n], k)
        Δ = abs.(1 .+ (sref[n][k]) ./ s[n][k][2:2:end])
    else
        Δ = abs.(1 .+ (-sref[n][k]) ./ s[n][:TPkGrad_Phi][2:2:end])
    end
    println("k = $k, n = $n")
    println("rel.diff = $(maximum(Δ))")
end
##
EAC = "ElectrodeActiveComponent"
PE = "PositiveElectrode"
NE = "NegativeElectrode"

# Transelate bw states from matlab and julia
j2m = Dict{Symbol, String}(
    # :C                  => "cs",
    :T                  => "T",
    :Phi                => "phi", 
    :Conductivity       => "conductivity",
    :Diffusivity        => "D",
    :TotalCurrent       => "j",
    :ChargeCarrierFlux  => "LiFlux", # This is not correct - CC is more than Li
    :ELYTE              => "Electrolyte"
)
m2j = Dict(value => key for (key, value) in j2m)

rs = stateref[:, 1]
rs_elyte = [s[j2m[:ELYTE]] for s in rs];
rs_pam = [s[PE][EAC] for s in rs];

states_pam = [s[:PAM] for s in states];
states_elyte = [s[:ELYTE] for s in states];
##

states_comp = states_elyte
ref_states = get_ref_states(j2m, rs_elyte);
for (n, state) in enumerate(states_comp)
    print_diff_j(states_comp, ref_states, n)
end

plot(E)
##

i=4;plot([states[i][:ELYTE][:C], stateref[i]["Electrolyte"]["cs"][:,1]])
##
i=10;plot([states[i][:PAM][:C], stateref[i]["Electrolyte"]["cs"][:,1]])
i=10;plot([states[i][:NAM][:C], stateref[i]["NegativeElectrode"]["ElectrodeActiveComponent"]["c"][:,1]])
i=10;plot([states[i][:PAM][:C], stateref[i]["PositiveElectrode"]["ElectrodeActiveComponent"]["c"][:,1]])

i=10;plot([states[i][:CC][:Phi],stateref[i]["NegativeElectrode"]["CurrentCollector"]["phi"]])
i=10;plot([states[i][:NAM][:Phi],stateref[i]["NegativeElectrode"]["ElectrodeActiveComponent"]["phi"]])
i=10;plot([states[i][:ELYTE][:Phi], stateref[i]["Electrolyte"]["phi"]])

##
i=10;plot(grids[:CC]["cells"]["centroids"][:,2],[states[i][:CC][:Phi],stateref[i]["NegativeElectrode"]["CurrentCollector"]["phi"]],linestyle=:dot)
##
i=1;plot(grids[:NAM]["cells"]["centroids"][:,2],[states[i][:NAM][:Phi],stateref[i]["NegativeElectrode"]["ElectrodeActiveComponent"]["phi"]],linestyle=:dot)
##
i=1;plot(grids[:ELYTE]["cells"]["centroids"][:,2],[states[i][:ELYTE][:Phi], stateref[i]["Electrolyte"]["phi"]],linestyle=:dot)
##
i=10;plot(grids[:PAM]["cells"]["centroids"][:,2],[states[i][:PAM][:Phi],stateref[i]["PositiveElectrode"]["ElectrodeActiveComponent"]["phi"]],linestyle=:dot)
##
i=10;plot(grids[:PP]["cells"]["centroids"][:,2],[states[i][:PP][:Phi],stateref[i]["PositiveElectrode"]["CurrentCollector"]["phi"]],linestyle=:dot)
##
i=11;states[i][:BPP][:Phi],stateref[i]["PositiveElectrode"]["CurrentCollector"]["E"]
