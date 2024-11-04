using Jutul, BattMo, Plots
using MAT

fn = "/home/xavier/Downloads/battmo_formatted_input.json"
init = JSONFile(fn)

res = empty([1.0])

for ncycle in UnitRange(1, 10)
    local states, reports, extra
    @info "number of cycles : $(ncycle*10)" 
    init.object["Control"]["numberOfCycles"] = ncycle*10
    states, reports, extra = run_battery(init; info_level = 0)
    if !(reports[end][:ministeps][end][:success])
        break
    end
    push!(res, computeEnergyEfficiency(states))
end
