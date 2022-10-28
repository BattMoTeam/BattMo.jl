function Jutul.update!(prec::BatteryCPhiPreconditioner, lsys, model, storage, recorder)
    # Solve all Phi with AMG
    # Solve the elyte C with another AMG
    # Let the rest be (?)
    A = lsys.jac
    r = lsys.r
    if isnothing(prec.data)
        # Set up various mappings
        c_map = setup_subset_residual_map(model, storage, [:ELYTE], :C)
        phi_map = setup_subset_residual_map(model, storage, nothing, :Phi)
        # @assert length(intersect(c_map, phi_map)) == 0
        prec.data = (c = storage_chpi_precond(c_map),
                     phi = storage_chpi_precond(phi_map),
                     n = length(r))
    end
    (; c, phi) = prec.data

    update_local_cphi_preconditioner!(prec.c_precond, A, r, c)
    update_local_cphi_preconditioner!(prec.p_precond, A, r, phi)
end

function Jutul.apply!(x, prec::BatteryCPhiPreconditioner, r, arg...)
    (; c, phi) = prec.data
    @. x .= r
    apply_local_cphi_preconditioner!(x, prec.c_precond, r, c)
    apply_local_cphi_preconditioner!(x, prec.p_precond, r, phi)
end

function storage_chpi_precond(index_map)
    n = length(index_map)
    return (ix = index_map, r = zeros(n), x = zeros(n))
end

function update_local_cphi_preconditioner!(prec, A, r, S)
    ix = S.ix
    A_s = A[ix, ix]
    update!(prec, A_s, view(r, ix), DefaultContext())
end

function apply_local_cphi_preconditioner!(x, prec, r, S)
    r_i = S.r
    x_i = S.x
    ix = S.ix
    @. r_i = r[ix]
    apply!(x_i, prec, r_i)
    @. x[ix] = x_i
end


function setup_subset_residual_map(multi_model::MultiModel, storage, model_labels, variable_label)
    M = []
    offsets = Jutul.get_submodel_offsets(storage)
    m_ix = 1
    for (model_key, model) in pairs(multi_model.models)
        @assert !Jutul.is_cell_major(matrix_layout(model.context)) "Only supported for equation major"
        if isnothing(model_labels) || model_key in model_labels
            offset = offsets[m_ix]
            nc = number_of_cells(model.domain)
            for (plabel, pvar) in model.primary_variables
                if plabel == variable_label
                    @assert associated_entity(pvar) == Cells()
                    dof_per_e = degrees_of_freedom_per_entity(model, pvar)
                    @assert dof_per_e == 1 "Found $dof_per_e dof per entity, expected 1?"
                    push!(M, (offset+1):(offset+nc))
                    break
                else
                    offset += Jutul.number_of_degrees_of_freedom(model, pvar)
                end
            end
        end
        m_ix += 1
    end
    return vcat(M...)
end

Jutul.operator_nrows(p::BatteryCPhiPreconditioner) = p.data.n

function battery_linsolve(model, method = :ilu0;
                                 rtol = 0.005,
                                 solver = :gmres,
                                 verbose = 0,
                                 kwarg...)
    if method == :amg
        prec = amg_precond()   
    elseif method == :ilu0
        prec = ILUZeroPreconditioner()
    elseif method == :direct
        return LUSolver()
    elseif method == :cphi
        prec = BatteryCPhiPreconditioner()
    else
        return nothing
    end
    max_it = 200
    atol = nothing

    lsolve = GenericKrylov(solver, verbose = verbose,
                                   preconditioner = prec, 
                                   relative_tolerance = rtol,
                                   absolute_tolerance = atol,
                                   max_iterations = max_it; kwarg...)
    return lsolve
end
