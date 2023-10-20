using BattMo, Plots



func = "1.8670.*SOC.^5 .- 5.0687.*SOC.^4 .+ 5.7087.*SOC.^3 .- 3.5125.*SOC.^2 .+ 1.7145.*SOC .+ 3.440"
SOC = range(start = 0.2,stop = 0.99,length = 10)
fun_ex = Meta.parse(func)

OCP = eval(fun_ex)

ocp = interpolation(SOC,OCP, degree = 7)

str = update_json_input(file_path = "test.json",
                        interpolation_object = ocp,
                        component_name = "NegativeElectrode",
                        x_name = "SOC" ,
                        y_name = "OCP",
                        new_file_path = "test2.json")


OCP = []
str = "f(SOC) = " * str
par = Meta.parse(str)
stop = false
ev2 = eval(par)

for i in collect(1:size(SOC)[1])
    local SOC = soc[i]
    if stop == false
        ev = eval(par)
        sub = f(SOC)
        push!(OCP,sub)
        global stop = true
    else
        sub = f(SOC)
        push!(OCP,sub)

    end
end

plot(SOC, OCP)

# fn1 = "test/battery/data/jsonfiles/p2d_40_jl_ud.json"
# init1 = JSONFile(fn1)

# states, reports, extra = run_battery(init1;use_p2d=true,info_level = -1, extra_timing = false);

# nam_ocp_ud = Array([state[:NAM][:Ocp] for state in states])
# pam_ocp_ud = Array([state[:PAM][:Ocp] for state in states])

# #fn2 = "test/battery/data/jsonfiles/p2d_40_jl.json"
# fn2 = "test2.json"
# init2 = JSONFile(fn2)
# states, reports, extra = run_battery(init2;use_p2d=true,info_level = -1, extra_timing = false);
# print(size(extra[:timesteps]))

# nam_ocp_pd = Array([state[:NAM][:Ocp] for state in states])
# pam_ocp_pd = Array([state[:PAM][:Ocp] for state in states])

# plt = plot([column[1] for column in nam_ocp_pd];
#            title     = "Discharge Voltage",
#            #size      = (1000, 800),
#            label     = "nam_ocp_ud",
#            xlabel    = "Time / s",
#            ylabel    = "OCP / V",
#            linewidth = 4,
#            xtickfont = font(pointsize = 15),
#            ytickfont = font(pointsize = 15))

# plot!(([column[1] for column in pam_ocp_pd]), label = "pam_ocp_pd", linewidth = 2)
# plot!(([column[1] for column in pam_ocp_ud]), label = "pam_ocp_ud", linewidth = 2)

# plot!(([column[1] for column in nam_ocp_ud]), label = "nam_ocp_ud", linewidth = 2)

# display(plt)




# y = [pam_ocp_pd,nam_ocp_pd,nam_ocp_ud ,pam_ocp_ud]
# print("x_pd =", size(x_pd))
# print("x_ud =", size(x_ud))
# print("y =", size(nam_ocp_pd))

# GLMakie.activate!()

# function makie_plots(x_pd, y; legends = [], title = [], xlabel = [], ylabel = [])
#     m = size(y, 1)
#     if isempty(legends)
#         legends = ["y$i" for i=1:m]
#     end
#     # standard colors from matplotlib
#     colors = ["#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd", "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf"];
#     fig = Figure()
#     ax = Axis(fig[1, 1])
#     for i = 1:m
#         lines!(ax, x_pd, y[i], label = legends[i], color = colors[(i-1)%10+1])
#     end
#     axislegend(ax)
#     if !isempty(title)
#         ax.title = title
#         # Bug? squeezes plots to width of title
#         #Label(fig[0, 1], title, textsize = 30) 
#     end
#     if !isempty(xlabel)
#         ax.xlabel = xlabel
#     end
#     if !isempty(ylabel)
#         ax.ylabel = ylabel
#     end
#     fig
# end

# n = 100; m = 3
# x = 1:n
# y = randn(n,m)
# #makie_plots(x, y)
# #makie_plots(x, y, legends = ["toto", "titi", "tata"])
# #makie_plots(x, y2, legends = ["toto", "titi", "tata"], title = "A Title")
# makie_plots(x, y, legends = ["toto", "titi", "tata"], title = "A Title", xlabel = "Time [s]", ylabel = "Volts [V]")


# fig = Figure()
# ax = Axis(fig[1, 1], ylabel = "OCP / V", xlabel = "Time / s", title = "OCP curve")
# lines!(ax, t, nam_ocp_pd)
# lines!(ax, t, pam_ocp_pd)
# lines!(ax, t, nam_ocp_ud)
# lines!(ax, t, pam_ocp_ud)
# display(fig)


# macro simple(ex, c, cmax,T)

    
#     Tref = 299.0
#     :(eval(Meta.parse($ex)))
# end

# function  func(ex,c,T,cmax)
    
#     @simple ex c T cmax 
# end
# mnc_111_ocp = "f(c,T,cmax,Tref) = (-4.656 + 0 * (c/cmax) + 88.669 * (c/cmax)^2 + 0 * (c/cmax)^3 - 401.119 * (c/cmax)^4 + 0 * (c/cmax)^5 + 342.909 * (c/cmax)^6 + 0 * (c/cmax)^7 - 462.471 * (c/cmax)^8 + 0 * (c/cmax)^9 + 433.434 * (c/cmax)^10)/(-1 + 0  * (c/cmax)+ 18.933 * (c/cmax)^2+ 0 * (c/cmax)^3- 79.532 * (c/cmax)^4+ 0 * (c/cmax)^5+ 37.311 * (c/cmax)^6+ 0 * (c/cmax)^7- 73.083 * (c/cmax)^8+ 0 * (c/cmax)^9+ 95.960 * (c/cmax)^10)+ (T - Tref) * ( -1e-3* ( 0.199521039- 0.928373822 * (c/cmax)+ 1.364550689000003 * (c/cmax)^2- 0.611544893999998 * (c/cmax)^3)/ (1- 5.661479886999997 * (c/cmax)+ 11.47636191 * (c/cmax)^2- 9.82431213599998 * (c/cmax)^3+ 3.048755063 * (c/cmax)^4))"
# c = 26829.8535645
# cmax = 30555
# T = 298.15
# Tref = 298.15
# graphite = "0.7222+ 0.1387*(c./cmax) + 0.0290*(c./cmax)^0.5 - 0.0172/(c./cmax) + 0.0019/(c./cmax)^1.5+ 0.2808 * exp(0.9 - 15.0*(c./cmax)) - 0.7984 * exp(0.4465*(c./cmax) - 0.4108)+ (T - Tref) * (1e-3 * ( 0.005269056+ 3.299265709 * (c./cmax)- 91.79325798 * (c./cmax)^2+ 1004.911008 * (c./cmax)^3- 5812.278127 * (c./cmax)^4+ 19329.75490 * (c./cmax)*5- 37147.89470 * (c./cmax)*6+ 38379.18127 * (c./cmax)*7- 16515.05308 * (c./cmax)*8 )/ ( 1- 48.09287227 * (c./cmax)+ 1017.234804 * (c./cmax)^2- 10481.80419 * (c./cmax)^3+ 59431.30000 * (c./cmax)^4- 195881.6488 * (c./cmax)*5+ 374577.3152 * (c./cmax)*6- 385821.1607 * (c./cmax)*7+ 165705.8597 * (c./cmax)*8 ))"
# f = eval(Meta.parse(mnc_111_ocp))
# f(c,T,cmax,Tref)
# print("")

# print(f(1,298,1,299))

# function func2()
#     c = 1.0
#     cmax = 2
#     T = 298.0
#     mnc_111_ocp = "(-4.656 + 0 * (c/cmax) + 88.669 * (c/cmax)^2 + 0 * (c/cmax)^3 - 401.119 * (c/cmax)^4 + 0 * (c/cmax)^5 + 342.909 * (c/cmax)^6 + 0 * (c/cmax)^7 - 462.471 * (c/cmax)^8 + 0 * (c/cmax)^9 + 433.434 * (c/cmax)^10)/(-1 + 0  * (c/cmax)+ 18.933 * (c/cmax)^2+ 0 * (c/cmax)^3- 79.532 * (c/cmax)^4+ 0 * (c/cmax)^5+ 37.311 * (c/cmax)^6+ 0 * (c/cmax)^7- 73.083 * (c/cmax)^8+ 0 * (c/cmax)^9+ 95.960 * (c/cmax)^10)+ (T - Tref) * ( -1e-3* ( 0.199521039- 0.928373822 * (c/cmax)+ 1.364550689000003 * (c/cmax)^2- 0.611544893999998 * (c/cmax)^3)/ (1- 5.661479886999997 * (c/cmax)+ 11.47636191 * (c/cmax)^2- 9.82431213599998 * (c/cmax)^3+ 3.048755063 * (c/cmax)^4))"
#     return func(mnc_111_ocp,c,T,cmax)
# end

# print(func2())


# macro evaluate_ocp_function(expression, c, T, cmax)
#     compute_ocp_from_function(string(expression), c, T, cmax)
# end

# function compute_ocp_from_function(expression, c, T, cmax)
#     """Compute OCP for a material as function of temperature and concentration"""
    
#     ex = Meta.parse(expression)
#     return eval(ex)

# end

# c = 1
# cmax = 2
# T = 298
# Tref = 299
# c =[1,2]

# @macroexpand @evaluate_ocp_function mnc_111_ocp , c, T, cmax



# # graphite_ocp = " 0.7222+ 0.1387*(c/cmax) + 0.0290*(c/cmax)^0.5 - 0.0172/(c/cmax) + 0.0019/(c/cmax)^1.5+ 0.2808 * exp(0.9 - 15.0*(c/cmax)) - 0.7984 * exp(0.4465*(c/cmax) - 0.4108)+ (T - Tref) * (1e-3 * ( 0.005269056+ 3.299265709 * (c/cmax)- 91.79325798 * (c/cmax)^2+ 1004.911008 * (c/cmax)^3- 5812.278127 * (c/cmax)^4+ 19329.75490 * (c/cmax)*5- 37147.89470 * (c/cmax)*6+ 38379.18127 * (c/cmax)*7- 16515.05308 * (c/cmax)*8 )/ ( 1- 48.09287227 * (c/cmax)+ 1017.234804 * (c/cmax)^2- 10481.80419 * (c/cmax)^3+ 59431.30000 * (c/cmax)^4- 195881.6488 * (c/cmax)*5+ 374577.3152 * (c/cmax)*6- 385821.1607 * (c/cmax)*7+ 165705.8597 * (c/cmax)*8 ))"

# # code = :(1.5*c+2.5*c^2)

# macro simple(expr, c, T, cmax)
#     # c = 1
#     # cmax = 2
#     # T = 298
#     Tref = 299
#     :(eval(Meta.parse($expr)))
# end

# function func(mnc_111_ocp, c, T, cmax)
#     ex = @macroexpand @simple mnc_111_ocp c T cmax
#     return ex
# end

# # for i in c

# print(func(mnc_111_ocp, 1, 298, 2))
# end

# c = 1
# cmax = 2
# T = 298
# Tref = 299

# function ev(ex,)

    
#     ex = eval(ex)
#     return ex
# end

# ex = Meta.parse(mnc_111_ocp)

# @macroexpand ex
# #print(eval(ex))

# dump(ex)

# ex = ev(ex)
# print(ex)