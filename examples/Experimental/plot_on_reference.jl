#fn = string(dirname(pathof(BattMo)), "/../test/battery/data/", name, ".mat")
#fn = "/home/hnil/Documents/JULIA_NEW/BattMo/test/battery/data/model1D_50.mat"
#fn = "/data2/hnil/JULIA/Jutul.jl/data/models/model1D_50.mat"
#fn="/data/hnil/BITBUCKET/mrst-bitbucket/projects/project-batman/project-batman/Examples/gellyrole/model1D_50_notemp_.mat"
#exported_all = MAT.matread(fn)
for i in 5

	refstep = i
	sim_step = i

	p1 = Plots.plot(title = "Voltage", size = (1000, 800))
	p2 = Plots.plot(title = "Flux", size = (1000, 800))
	p3 = Plots.plot(title = "C", size = (1000, 800))

	# fields = ["CurrentCollector","ActiveMaterial"]
	# fields = ["CurrentCollector"]
	fields = ["ActiveMaterial"]
	# components = ["NegativeElectrode"]#,"PositiveElectrode"]
	components = ["NegativeElectrode"]
	# components = ["PositiveElectrode"]
	components = []
	for component ∈ components
		for field in fields
			G = exported_all["model"][component][field]["G"]
			x = G["cells"]["centroids"]
			xf = G["faces"]["centroids"][end]
			xfi = G["faces"]["centroids"][2:end-1]

			state = stateref[refstep][component]
			phi_ref = state[field]["phi"]
			#            j_ref = state[field]["j"]

			Plots.plot!(p1, x, phi_ref; linecolor = "red")
			#           Plots.plot!(p2,xfi,j_ref;linecolor="red")
			if haskey(state[field], "c")
				c = state[field]["c"]
				Plots.plot!(p3, x, c; linecolor = "red")
			end
		end
	end

	fields = []
	# fields = ["Electrolyte"]

	for field in fields
		G = exported_all["model"][field]["G"]
		x = G["cells"]["centroids"]
		xf = G["faces"]["centroids"][end]
		xfi = G["faces"]["centroids"][2:end-1]

		state = stateref[refstep]
		phi_ref = state[field]["phi"]
		#j_ref = state[field]["j"]

		Plots.plot!(p1, x, phi_ref; linecolor = "red")
		#Plots.plot!(p2,xfi,j_ref;linecolor="red")
		if haskey(state[field], "c")
			c = state[field]["c"]
			Plots.plot!(p3, x, c; linecolor = "red")
		end
	end

	##


	# mykeys = [:NeCc, :NeAm, :Elyte, :PeAm, :PeCc]
	# mykeys = [:PeCc, :PeAm]
	# mykeys = [:NeAm]
	# mykeys = [:Elyte]
	mykeys = [:PeAm]
	# mykeys = [:NeCc]
	#mykeys =  keys(grids)
	for key in mykeys
		G = grids[key]
		x = G["cells"]["centroids"]
		xf = G["faces"]["centroids"][end]
		xfi = G["faces"]["centroids"][2:end-1]
		p = plot(p1, p2, layout = (1, 2), legend = false)
		phi = states[sim_step][key][:Voltage]
		Plots.plot!(
			p1, x, phi; markershape = :circle, linestyle = :dot, seriestype = :scatter,
		)

		if haskey(states[sim_step][key], :TotalCurrent)
			j = states[sim_step][key][:TotalCurrent][1:2:end-1]
		else
			#            j = -states[sim_step][key][:TPkGrad_Voltage][1:2:end-1]
		end

		#Plots.plot!(p2, xfi, j; markershape=:circle,linestyle=:dot, seriestype = :scatter)
		if (haskey(states[sim_step][key], :Concentration))
			cc = states[sim_step][key][:Concentration]
			Plots.plot!(p3, x, cc; markershape = :circle, linestyle = :dot, seriestype = :scatter)
		end

		if (haskey(states[sim_step][key], :SurfaceConcentration))
			cc = states[sim_step][key][:SurfaceConcentration]
			Plots.plot!(p3, x, cc; markershape = :circle, linestyle = :dot, seriestype = :scatter)
		end

	end

	display(plot!(p1, p2, p3, layout = (3, 1), legend = false))
end
