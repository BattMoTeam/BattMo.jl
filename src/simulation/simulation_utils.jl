

struct SourceAtCell
	cell::Any
	src::Any
	function SourceAtCell(cell, src)
		new(cell, src)
	end
end



function amg_precond(; max_levels = 10, max_coarse = 10, type = :smoothed_aggregation)

	gs_its = 1
	cyc = AlgebraicMultigrid.V()
	if type == :smoothed_aggregation
		m = smoothed_aggregation
	else
		m = ruge_stuben
	end
	gs = GaussSeidel(ForwardSweep(), gs_its)

	return AMGPreconditioner(m, max_levels = max_levels, max_coarse = max_coarse, presmoother = gs, postsmoother = gs, cycle = cyc)

end