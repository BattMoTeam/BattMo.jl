function Jutul.update_preconditioner!(prec::BattMo.BatteryGeneralPreconditioner, lsys::Jutul.JutulLinearSystem, context, model, storage, recorder, executor)
    # Solve all Voltage with AMG
    # Solve the elyte C with another AMG
    # Let the rest be (?)
    A = lsys.jac
    r = lsys.r
    setup = isnothing(prec.data)
    #Main.@infiltrate true
    if setup
        @tic "setup genneral precond" begin
            maps = []
            for varprecond in prec.varpreconds
                if isnothing(varprecond.models)
                    models = keys(model.models)
                else
                    models = varprecond.models
                end
                variable = varprecond.var
                equation = varprecond.eq
                var_map = BattMo.setup_subset_residual_map(model, storage, models, variable)
                eq_map = BattMo.setup_subset_equation_map(model, storage, models, equation)
                @assert length(var_map) == length(eq_map)
                @assert var_map == eq_map ## preliminary assert no restriction
                #map = (var =storage_general_precond(copy(var_map)), eq_map = copy(eq_map))
                map = (var = storage_general_precond(var_map), eq_map = eq_map)
                push!(maps, map)
                @assert variable != :Global
                #update_local_preconditioner!(varprecond.precond, A, r, eq_map, var_map, executor)
            end
            ndof = length(r)
            # In block mode, the correction before the global stage is zero outside the variables of the blocks and the
            # control, the last unknown, so the residual update needs only these columns of A.
            columns = sort!(unique!(vcat(ndof, (map.var.ix for map in maps)...)))
            prec.data = (maps = maps, allvars = (r = zeros(ndof), x = zeros(ndof)), n = ndof, A = A, columns = columns)
        end
        #    for (i,varprecond) in enumerate(prec.varpreconds)
        #         #eq_map = copy(prec.data.maps[i].eq_map)
        #         #var_map = copy(prec.data.maps[i].var.ix)
        #         eq_map = prec.data.maps[i].eq_map
        #         var_map = copy(prec.data.maps[i].var.ix)
        #         Jutul.@tic "update local preconditioner" update_local_preconditioner!(varprecond, A, r, eq_map, var_map, executor)
        #         #Main.@timit_debug "update local preconditioner" update_local_preconditioner!(varprecond.precond, A, r, eq_map, var_map, executor)
        #     end
        precond = prec.g_varprecond
        @tic "update global preconditioner" update_preconditioner!(precond.precond, lsys, context, model, storage, recorder, executor)
    else
        # The linear system updates its matrix in place, so it is still the matrix of the setup. Comparing the values
        # instead would read the whole matrix.
        @assert A === prec.data.A
    end
    #prec.data.A = A
    for (i, varprecond) in enumerate(prec.varpreconds)
        #eq_map = copy(prec.data.maps[i].eq_map)
        #var_map = copy(prec.data.maps[i].var.ix)
        eq_map = prec.data.maps[i].eq_map
        var_map = copy(prec.data.maps[i].var.ix)
        @tic "update local var preconditioner" update_local_preconditioner!(varprecond, A, r, eq_map, var_map, executor)
        #Main.@timit_debug "update local preconditioner" update_local_preconditioner!(varprecond.precond, A, r, eq_map, var_map, executor)
    end

    return if !isnothing(prec.g_varprecond)
        precond = prec.g_varprecond
        #Jutul.@tic "global partial update global preconditioner" Jutul.update_preconditioner!(precond.precond, lsys, context, model, storage, recorder, executor)
        @tic "partial update global preconditioner" partial_update_preconditioner!(precond.precond, lsys.jac, lsys.r, context, executor)
    end
end
Jutul.operator_nrows(p::BattMo.BatteryGeneralPreconditioner) = p.data.n

function Jutul.apply!(x, prec::BattMo.BatteryGeneralPreconditioner, r)
    A = prec.data.A
    method = prec.params["method"]
    @assert method == "block" || method == "seq"
    dx = prec.data.allvars.x
    r_local = prec.data.allvars.r
    x .= 0
    r_local .= r
    if prec.params["pre_solve_control"] == true
        solve_for_current!(x, A, r_local)
    end
    if method == "seq"
        # dx holds the correction of one block and is zero outside its variables
        dx .= 0
    end
    for (i, varprecond) in enumerate(prec.varpreconds)
        var = prec.data.maps[i].var # The indices of the block and its local storage
        apply_local_preconditioner!(x, varprecond.precond, r_local, var)
        if method == "seq"
            # The blocks do not overlap: subtract the product with the correction of this block from the residual
            block_correction = view(dx, var.ix)
            block_correction .= var.x
            subtract_product!(r_local, A, dx, var.ix)
            block_correction .= 0
        end
    end
    if method == "block"
        # The residual of the corrections of all blocks before the global stage
        r_local .= r
        subtract_product!(r_local, A, x, prec.data.columns)
    end
    if !isnothing(prec.g_varprecond)
        dx .= 0
        apply!(dx, prec.g_varprecond.precond, r_local)
        x .+= dx
        # Only the post-solve of the control reads this residual
        if prec.params["post_solve_control"] == true
            mul!(r_local, A, dx, -1, true)
        end
    end
    if prec.params["post_solve_control"] == true
        solve_for_current!(x, A, r_local)
    end
    return x
end

"""
    subtract_product!(r, A, x, columns)

Subtract `A * x` from `r` for an `x` that is zero outside `columns`. A CSC matrix is read in these columns only; for
sorted `columns`, the sums are those of the product with the whole matrix.
"""
function subtract_product!(r, A::SparseMatrixCSC, x, columns)
    @assert length(r) == size(A, 1) && length(x) == size(A, 2)
    rows = rowvals(A)
    values = nonzeros(A)
    for column in columns
        # Fused as in the product of SparseArrays, so that the sums are the same
        minus_x = -x[column]
        @inbounds for position in nzrange(A, column)
            row = rows[position]
            r[row] = muladd(values[position], minus_x, r[row])
        end
    end
    return r
end

# Other formats, such as Jutul's CSR matrix, do not store the columns contiguously
function subtract_product!(r, A, x, columns)
    return mul!(r, A, x, -1, true)
end

function solve_for_current!(x, A, r_local)
    ##NB fix for not current control
    return if (A[end, end] == 1) && (A[end, end - 1] == 0) && (A[end - 1, end] == 0)
        ## current control
        @assert A[end - 1, end] == 0
        @assert A[end, end - 1] == 0
        x[end] += r_local[end]
        r_local[end] = 0
    else
        #NB check last last equations should be changed
        if (false)
            #Main.@infiltrate
            @assert A[end - 1, end - 1] != 0
            @assert A[end - 1, end] == 0
            val = A[end:end, :] * x
            r_end = r_local[end] - val[1] #A[end:end,:]*x
            x[end] += r_end[end] / A[end, end]
        end
    end
end

function storage_general_precond(index_map)
    n = length(index_map)
    return (ix = index_map, r = zeros(n), x = zeros(n))
end

function getMatrixAndInd(A::SparseMatrixCSC, ind_eq, ind_var)
    (A_s, ind) = getindex_I_sorted_bsearch_I_new(A, ind_eq, ind_var)
    return (A_s, ind)
end

function getMatrixAndInd(A::StaticCSR.StaticSparsityMatrixCSR, ind_eq, ind_var)
    At = A.At
    (At_s, ind) = getindex_I_sorted_bsearch_I_new(At, ind_var, ind_eq)
    A_s = StaticCSR.StaticSparsityMatrixCSR(At_s)
    return (A_s, ind)
end

function update_local_preconditioner!(varprec, A, r, ind_eq, ind_var, executor)
    prec = varprec.precond
    full_update = true
    if isnothing(varprec.data)
        #A_s = A[ind_eq, ind_var]
        #A_s, ind) = getindex_I_sorted_linear_new(A,ind_eq,ind_var)
        #(A_s, ind) = getindex_I_sorted_bsearch_I_new(A,ind_eq,ind_var)
        (A_s, ind) = getMatrixAndInd(A, ind_eq, ind_var)
        varprec.data = (Al = A_s, indg = ind)
    else
        full_update = false
        valsg = nonzeros(A)
        valsl = nonzeros(varprec.data.Al)
        @. valsl = valsg[varprec.data.indg]
    end
    #b_s = view(r, ind_var)
    sys = LinearizedSystem(varprec.data.Al)
    dummy_model = Nothing()
    dummy_storage = Nothing()
    return if full_update
        @tic "update local preconditioner" update_preconditioner!(prec, sys, DefaultContext(), dummy_model, dummy_storage, Jutul.ProgressRecorder(), executor)
    else
        @tic "partial update local preconditioner" partial_update_preconditioner!(prec, sys.jac, sys.r, DefaultContext(), executor)
    end
    #NB ok??
    #Jutul.update_preconditioner!(prec, A_s, view(r, ix), DefaultContext(), executor)
end

"""
    apply_local_preconditioner!(x, prec, r, S)

Apply the preconditioner `prec` of one block to the residual `r` at the indices `S.ix` and add the result to `x` there.
The local residual and result stay in `S.r` and `S.x`.
"""
function apply_local_preconditioner!(x, prec, r, S)
    r_i = S.r
    x_i = S.x
    x_i .= 0.0
    ix = S.ix
    r_i .= view(r, ix)
    apply!(x_i, prec, r_i)
    x_block = view(x, ix)
    x_block .+= x_i
    return x
end
