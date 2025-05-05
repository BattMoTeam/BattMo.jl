export plot_3D_results

function plot_3D_results(results::NamedTuple; colormap = :curl)

	states = results[:states]
	solved_model = results[:extra][:model]


	plot_multimodel_interactive(solved_model, states; colormap = colormap)
end
