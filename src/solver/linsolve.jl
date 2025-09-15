
##NB genneral version
# function modify_equation!(lsys, maps, tfac, context)
#     # slow genneral version
#     (mass_index, charge_index, mass_cons_map, charge_cons_map) = maps
#     for i in 1:length(mass_cons_map)
#         ## decouple mass end charge conservation based on the property
#         # that charge and mass transport is propotioinal due to change 
#         #storage.LinearizedSystem.jac[mass_cons_map[i],:] += storage.LinearizedSystem.jac[charge_cons_map[i],:] 
#         #storage.LinearizedSystem.r[mass_cons_map[i],:] += storage.LinearizedSystem.r[charge_cons_map[i],:] 
#         if true #needed for separate saturation solve
#         @.    lsys.jac[mass_cons_map[i],:] .-= tfac.*lsys.jac[charge_cons_map[i],:] 
#             #lsys.r[mass_cons_map[i]] .-= tfac.*lsys.r[charge_cons_map[i]]
#             lsys.r[mass_cons_map[i]] -= tfac*lsys.r[charge_cons_map[i]]
#         end 
#     end
# end
function matrix_maps(lsys, mass_cons_map, charge_cons_map, context::DefaultContext)
	## make pair
	ncol = size(lsys.jac, 1)
	mass_index = zeros(Int, 0)
	charge_index = zeros(Int, 0)
	mass_charge_ind = zeros(Int, ncol)
	mass_charge_ind[mass_cons_map] = charge_cons_map
	#vals = nonzeros(lsys.jac)
	rows = rowvals(lsys.jac)
	#NB could probably be more efficent vectorized
	for j in 1:size(lsys.jac, 2)
		zrange = nzrange(lsys.jac, j)
		loc_rows = rows[zrange]
		for i in zrange
			row = rows[i]
			charge_row = mass_charge_ind[row]
			if charge_row != 0
				charge_ind = indexin(charge_row, loc_rows)
				if !(charge_ind[1] == nothing)
					charge_val_index = zrange[charge_ind[1]]
					push!(charge_index, charge_val_index)
					push!(mass_index, i)
				end
			end
		end
	end
	return (mass_index, charge_index)
end

function matrix_maps(lsys, mass_cons_map, charge_cons_map, context::ParallelCSRContext)
	## make pair
	At = lsys.jac.At
	#ncol = size(At,2)
	mass_index = zeros(Int, 0)
	charge_index = zeros(Int, 0)
	#mass_charge_ind = zeros(Int,ncol)
	#mass_charge_ind[mass_cons_map] = charge_cons_map
	#vals = nonzeros(lsys.jac)
	cols = rowvals(At)
	#NB could probably be more efficent vectorized
	for (i, mass_row) in enumerate(mass_cons_map)
		zrange_mass = nzrange(At, mass_row)
		zrange_charge = nzrange(At, charge_cons_map[i])
		#mass_cols = cols[zrange_mass]
		loc_charge_cols = cols[zrange_charge]
		for j in zrange_mass
			mass_col = cols[j]
			charge_ind = indexin(mass_col, loc_charge_cols)
			if charge_ind[1] != 0
				charge_zrange_ind = zrange_charge[charge_ind[1]]
				@assert mass_col == cols[charge_zrange_ind]
				push!(charge_index, charge_zrange_ind)
				push!(mass_index, j)
			end
		end
	end
	return (mass_index, charge_index)
end


function modify_equation!(lsys, maps, tfac, context)#::Jutul.DefaultContext)

	(mass_index, charge_index, mass_cons_map, charge_cons_map) = maps
	vals = nonzeros(lsys.jac)
	@. vals[mass_index] -= tfac * vals[charge_index]
	@. lsys.r[mass_cons_map] -= tfac * lsys.r[charge_cons_map]
end

function modify_equation!(lsys, mass_cons_map, charge_cons_map, tfac, nc, context::ParallelCSRContext)
	#NB not well stested
	vals = nonzeros(lsys.jac)
	#colvals = colvals(lsys.jac)
	for i in 1:nc
		## decouple mass end charge conservation based on the property
		# that charge and mass transport is propotioinal due to change 
		#storage.LinearizedSystem.jac[mass_cons_map[i],:] += storage.LinearizedSystem.jac[charge_cons_map[i],:] 
		#storage.LinearizedSystem.r[mass_cons_map[i],:] += storage.LinearizedSystem.r[charge_cons_map[i],:] 
		mass_ind = nzrange(lsys.jac, mass_cons_map[i])
		charge_ind = nzrange(lsys.jac, mass_cons_map[i])
		@assert length(mass_ind) == length(charge_ind)
		#for j in 1:lenght(mass_ind)
		#    vals[mass_ind[j]] .-= tfac.*vals[charge_ind[i]]
		#end
		@. vals[mass_ind] -= tfac * vals[charge_ind]
		lsys.r[mass_cons_map[i]] -= tfac * lsys.r[charge_cons_map[i]]
	end
end


function fix_control!(lsys, context::DefaultContext)
	if lsys.jac[end, end] == 1 && lsys.jac[end, end-1] == 0
		#Main.@infiltrate !(lsys.jac[end-1,end] == 1)
		@assert lsys.jac[end, end-1] == 0
		@assert lsys.jac[end-1, end] == 1

		fac = lsys.jac[end-1, end]
		lsys.jac[end-1, end] -= lsys.jac[end, end] * fac
		lsys.r[end-1] -= lsys.r[end] * fac
		@assert lsys.jac[end-1, end] == 0
	else
		#NB assume not added sparcity
		if (false)
			#Main.@infiltrate true
			#@assert abs(lsys.jac[end,end-1]) == 1
			@assert lsys.jac[end, end] == 0
			jac_l = deepcopy(lsys.jac[end, :])
			r_l = copy(lsys.r[end])
			lsys.jac[end, :] = lsys.jac[end-1, :]
			lsys.r[end] = lsys.r[end-1]
			lsys.jac[end-1, :] = jac_l
			lsys.r[end-1] = r_l
			#Main.@infiltrate true
		end

	end
end

function fix_control!(lsys, context::ParallelCSRContext)
	if lsys.jac[end, end] == 1
		@assert lsys.jac[end, end-1] == 0
		@assert lsys.jac[end-1, end] == 1
		fac = lsys.jac[end-1, end]
		lsys.jac.At[end, end-1] -= lsys.jac[end, end] * fac
		lsys.r[end-1] -= lsys.r[end] * fac
		@assert lsys.jac[end-1, end] == 0
	else
		if (true)#NB !!!!!!!!!!!!!!!
			@assert lsys.jac[end, end-1] == 1
			@assert lsys.jac[end, end] == 0
			jac_l = deepcopy(lsys.jac[end, :])
			r_l = copy(r[end])
			lsys.jac[end, :] = lsys[end-1, :]
			lsys.r[end] = lsys.r[end-1]
			lsys.jac[end-1, :] = a
			lsys.r[end] = r_l
		end
	end
end

function Jutul.post_update_linearized_system!(lsys, executor, storage, model::MultiModel{:IntercalationBattery})
	context = first(model.models).context# NB hack to get context of mulitmodel
	if (true)
		# fix linear system 
		e_models = [:Electrolyte]
		if isnothing(storage[:eq_maps].maps)
			mass_cons_map = setup_subset_equation_map(model, storage, e_models, :mass_conservation)
			#phi_map = setup_subset_residual_map(model, storage, e_models, :Voltage)
			charge_cons_map = setup_subset_equation_map(model, storage, e_models, :charge_conservation)
			(mass_ind, charge_ind) = matrix_maps(lsys, mass_cons_map, charge_cons_map, context)
			storage[:eq_maps].maps = (mass_ind = mass_ind, charge_ind = charge_ind, mass_cons_map = mass_cons_map, charge_cons_map = charge_cons_map)
		end
		#C_map = setup_subset_residual_map(model, storage, e_models, :Concentration)
		#Main.@infiltrate true
		tfac = model[:Electrolyte].system[:transference] / BattMo.FARADAY_CONSTANT
		modify_equation!(lsys, storage[:eq_maps].maps, tfac, context)
		## to control reduction ?
		#Main.@infiltrate true

		fix_control!(lsys, context)
		#Main.@infiltrate true
		#print("hei")
	end
end


function storage_chpi_precond(index_map)
	n = length(index_map)
	return (ix = index_map, r = zeros(n), x = zeros(n))
end

function update_local_cphi_preconditioner!(prec, A, r, ind_eq, ind_var, executor)
	A_s = A[ind_eq, ind_var]
	b_s = view(r, ind_var)
	sys = LinearizedSystem(A_s)
	dummy_model = Nothing()
	dummy_storage = Nothing()
	update_preconditioner!(prec, sys, DefaultContext(), dummy_model, dummy_storage, ProgressRecorder(), executor)
	#NB ok??
	#Jutul.update_preconditioner!(prec, A_s, view(r, ix), DefaultContext(), executor)
end

function apply_local_cphi_preconditioner!(x, prec, r, S, arg...)
	r_i = S.r
	x_i = S.x
	x_i .= 0.0
	ix = S.ix
	@. r_i = r[ix]
	apply!(x_i, prec, r_i, arg...)
	@. x[ix] = x_i
end


function setup_subset_residual_map(multi_model::MultiModel, storage, model_labels, variable_label)
	M = []
	offsets = get_submodel_offsets(storage)
	m_ix = 1
	for (model_key, model) in pairs(multi_model.models)
		@assert !is_cell_major(matrix_layout(model.context)) "Only supported for equation major"
		if isnothing(model_labels) || model_key in model_labels
			offset = offsets[m_ix]
			nc = number_of_cells(model.domain)
			for (plabel, pvar) in model.primary_variables
				if plabel == variable_label
					@assert associated_entity(pvar) == Cells()
					dof_per_e = degrees_of_freedom_per_entity(model, pvar)
					#@assert dof_per_e == 1 "Found $dof_per_e dof per entity, expected 1?"
					ndof = nc * dof_per_e
					push!(M, (offset+1):(offset+ndof))
					break
				else
					offset += number_of_degrees_of_freedom(model, pvar)
				end
			end
		end
		m_ix += 1
	end
	return vcat(M...)
end

function setup_subset_equation_map(multi_model::MultiModel, storage, model_labels, equation_label)
	M = []
	offsets = get_submodel_offsets(storage)
	m_ix = 1
	for (model_key, model) in pairs(multi_model.models)
		@assert !is_cell_major(matrix_layout(model.context)) "Only supported for equation major"
		if isnothing(model_labels) || model_key in model_labels
			offset = offsets[m_ix]
			nc = number_of_cells(model.domain)
			for (eqlabel, pvar) in model.equations
				if eqlabel == equation_label
					@assert associated_entity(pvar) == Cells()
					eq_per_e = number_of_equations_per_entity(model, pvar)
					#@assert eq_per_e == 1 "Found $eq_per_e eq for each entity, expected 1?"
					neq = nc * eq_per_e
					push!(M, (offset+1):(offset+neq))
					break
				else
					offset += nc * number_of_equations_per_entity(model, pvar)
				end
			end
		end
		m_ix += 1
	end
	return vcat(M...)
end


function battery_linsolve(inputparams)

	set_default_input_params!(inputparams, ["Method"], "Direct")

	method = inputparams["Method"]

	if method == "Direct"

		set_default_input_params!(inputparams, ["MaxSize"], 1000000)
		return LUSolver(; max_size = inputparams["MaxSize"])

	elseif method == "Iterative"

		solver = :fgmres

		set_default_input_params!(inputparams, ["Tolerance"], 1e-7)
		set_default_input_params!(inputparams, ["MaxLinearIterations"], 50)
		set_default_input_params!(inputparams, ["Verbosity"], 0)

		tolerance      = inputparams["Tolerance"]
		atol           = 1e-28
		max_iterations = inputparams["MaxLinearIterations"]
		verbosity      = inputparams["Verbosity"]

		# Battery general preconditioner that combines different preconditioners for different variables as
		# follows. First we solve for the control variables which are removed from the system, We use AMG for electric
		# potential variables (phi) and charge convervation equations in combination with a global smoother which is
		# ILU0. Afte this, we recover the control variables We combine two preconditioners.

		varpreconds = Vector{BattMo.VariablePrecond}()
		push!(varpreconds, BattMo.VariablePrecond(Jutul.AMGPreconditioner(:ruge_stuben), :Voltage, :charge_conservation, nothing))

		# Experimental options for using extra smoothing of concentration in positive and negative active material.
		use_extra_options = false
		if use_extra_options
			push!(varpreconds, BattMo.VariablePrecond(Jutul.ILUZeroPreconditioner(), :ParticleConcentration, :mass_conservation, [:PositiveElectrodeActiveMaterial, :NegativeElectrodeActiveMaterial]))
		end

		# Experimental options for AMG used on concentration in electrolyte
		use_extra_options = false
		if use_extra_options
			push!(varpreconds, BattMo.VariablePrecond(Jutul.AMGPreconditioner(:ruge_stuben), :Concentration, :mass_conservation, [:Electrolyte]))
		end

		# We setup the global preconditioner
		g_varprecond = BattMo.VariablePrecond(Jutul.ILUZeroPreconditioner(), :Global, :Global, nothing)

		params = Dict()

		# Type of method used for the block preconditioners. Here "block" means separatly (other options can be found
		# BatteryGeneralPreconditione)
		params["method"] = "block"
		# Option for post- and pre-solve of the control system. 
		params["post_solve_control"] = true
		params["pre_solve_control"]  = true

		# We setup the preconditioner, which combines both the block and global preconditioners
		prec = BattMo.BatteryGeneralPreconditioner(varpreconds, g_varprecond, params)
		#prec = Jutul.ILUZeroPreconditioner()

		lsolve = Jutul.GenericKrylov(solver,
			verbose = verbosity,
			preconditioner = prec,
			relative_tolerance = tolerance,
			absolute_tolerance = atol, ## may skip linear iterations all to getter.
			max_iterations = max_iterations)

		return lsolve

	else

		error("Wrong method $method for preconditioner")
		return nothing
	end

end
