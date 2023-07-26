

import BattMo
import JSON
import Jutul
JSON.lower(c::BattMo.ControllerCV)=Dict(:policy => c.policy,
                                        :time => c.time,
                                        :control_time => c.control_time,
                                        :target => c.target,
                                        :target_is_voltage => c.target_is_voltage,
                                        :mode => c.mode)
JSON.lower(policy::BattMo.SimpleCVPolicy{<:Real})=Dict(:current_function => policy.current_function, :voltage => policy.voltage)
JSON.lower(policy::BattMo.NoPolicy)=typeof(policy)
JSON.lower(config::Jutul.JutulConfig)=Dict(:name => name,
                                           :values => values,
                                           :options => options)

JSON.lower(sim::Jutul.JutulSimulator)=typeof(sim)
JSON.lower(obj::Nothing)=""
JSON.lower(ptr::Ptr)=typeof(ptr)
JSON.lower(relax::Jutul.NonLinearRelaxation)=typeof(relax)
JSON.lower(mapp::Jutul.AbstractGlobalMap)=typeof(mapp)
JSON.lower(mapp::Jutul.TrivialGlobalMap)=typeof(mapp)
JSON.lower(formulation::Jutul.JutulFormulation)=typeof(formulation)
JSON.lower(entity::Jutul.JutulEntity)=typeof(entity)

#Default to ensure all objects can be read into json
#JSON.lower(obj::Any)=typeof(obj)
#Not a good idea! We should instead pay attention to abstract objects
#we do not want to send to matlab  


function jsondict(dict)
    println(dict)
end

function setup_wrapper(exported)

    init=BattMo.MatlabFile("From Matlab", exported)
    states, reports, extra, exported = BattMo.run_battery(init);
    # for (s,el) in pairs(extra)
    #     println(string(s)*" ",typeof(el))
    #     if !isnothing(el)
    #         for (s2,el2) in pairs(el)
    #             println(string(s2)*" ",typeof(el2))
    #             # if !isnothing(el2)
    #             #     for (s3,el3) in pairs(el2)
    #             #         println(string(s3)*" ",typeof(el3))
    #             #     end
    #             # end
    #         end
    #     end
    # end
    # timesteps = extra[:timesteps]
    
    # time = cumsum(timesteps)
    # E    = [state[:BPP][:Phi][1] for state in states]

    # plt = plot(time, E;
    #        title     = "Discharge Voltage",
    #        size      = (1000, 800),
    #        label     = "BattMo.jl",
    #        xlabel    = "Time / s",
    #        ylabel    = "Voltage / V",
    #        linewidth = 4,
    #        xtickfont = font(pointsize = 15),
    #        ytickfont = font(pointsize = 15)
    # )
    #display(plt)
    
    a=JSON.json(extra)
    println(typeof(states))
    println(typeof(reports))
    println(typeof(extra))

    ret=Dict("states" => states, "reports" => reports, "extra" => extra, "exported" => exported)
    return ret
end

