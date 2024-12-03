h     = inputparams["ThermalModel"]["externalHeatTransferCoefficient"]
alpha = inputparams["ThermalModel"]["conductivity"]
Text  = inputparams["ThermalModel"]["externalTemperature"]

# For comparison, the value should be set to the same as in example_thermal
source = 1e8

M = [1 h;
     (1 + h/alpha) -h]

b = [h*Text, -source + h*(-source/(2*alpha) - Text)]

x =M\b

A = x[1]
B = x[2]

temp(x) = -1/(2*alpha) * source * x^2 - A/alpha*x + B

x = collect(0 : 0.01 : 1)
y = [temp(xx) for xx in x]


f = Figure(size = (1000, 400))

ax = Axis(f[1, 1],
          xlabelsize = 25,
          ylabelsize = 25,
          xticklabelsize = 25,
          yticklabelsize = 25)

scatterlines!(ax,
              x,
              y;
              linewidth = 4,
              markersize = 10,
              marker = :cross, 
              markercolor = :green,
              )

display(GLMakie.Screen(), f)






