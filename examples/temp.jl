pe_ocp(x) = (116.1647 - 940.2551 * (x)^2 + 3101.9987 * (x)^4 - 5292.6225 * (x)^6 + 4040.4367 * (x)^8) / (27.9167 - 228.18310 * (x)^2 + 769.0709 * (x)^4 - 1353.4191 * (x)^6 + 1063.2453 * (x)^8)

x = range(0, 1, 50)

y = [pe_ocp(i) for i in x]


fig = Figure()
ax = Axis(fig[1, 1], title = "OCP", xlabel = "Time / s", ylabel = "OCP / -")
lines!(ax, x, y, label = "Negative")
axislegend(position = :lb)
fig