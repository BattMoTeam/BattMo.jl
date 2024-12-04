using Jutul, BattMo, GLMakie

name = "p2d_40_cccv"
fn = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/", name, ".json")
inputparams = readBattMoJsonInputFile(fn)

config_kwargs = (info_level = 0, )
# Run base case and plot the results against BattMo-MRST reference
output = run_battery(inputparams; config_kwargs = config_kwargs);

states = output[:states]

################
# plot results #
################

t = [state[:Control][:ControllerCV].time for state in states]
E = [state[:Control][:Phi][1] for state in states]
I = [state[:Control][:Current][1] for state in states]

f = Figure(size = (1000, 400))

ax = Axis(f[1, 1],
          title     = "Voltage",
          xlabel    = "Time / s",
          ylabel    = "Voltage / V",
          xlabelsize = 25,
          ylabelsize = 25,
          xticklabelsize = 25,
          yticklabelsize = 25
          )

scatterlines!(ax, t, E;
              linewidth = 4,
              markersize = 10,
              marker = :cross, 
              markercolor = :black)

ax = Axis(f[1, 2],
          title     = "Current",
          xlabel    = "Time / s",
          ylabel    = "Current / A",
          xlabelsize = 25,
          ylabelsize = 25,
          xticklabelsize = 25,
          yticklabelsize = 25)

scatterlines!(ax, t, I;
              linewidth = 4,
              markersize = 10,
              marker = :cross, 
              markercolor = :black)


#####################
# compute Reaction  #
#####################

model      = output[:extra][:model]
parameters = output[:extra][:parameters]

Rs = []

# we do it only for the negative electrode

for state in states
    local R
    R = computeR(state, :NeAm, model, parameters)
    global Rs = push!(Rs, R)
end    

#####################################
# plot R for some position in space #
#####################################

f = Figure(size = (1000, 400))

ax = Axis(f[1, 1],
          title     = "Reaction Rate",
          xlabel    = "Time / s",
          ylabel    = "R / unit",
          xlabelsize = 25,
          ylabelsize = 25,
          xticklabelsize = 25,
          yticklabelsize = 25
          )


R = [locR[1] for locR in Rs]

scatterlines!(ax, t, R;
              linewidth = 4,
              markersize = 10,
              label = "back cell",
              marker = :cross, 
              markercolor = :black)

R = [locR[length(Rs[1])] for locR in Rs]

scatterlines!(ax, t, R;
              linewidth = 4,
              markersize = 10,
              label = "front cell",
              marker = :cross, 
              markercolor = :black)

axislegend(ax)
