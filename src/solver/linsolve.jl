using LinearAlgebra
using SparseArrays
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
function matrix_maps(lsys, mass_cons_map, charge_cons_map, context)#only work for CSC::Jutul.DefaultContext)
    ## make pair
    ncol = size(lsys.jac,1)
    mass_index = zeros(Int,0)
    charge_index = zeros(Int,0)
    mass_charge_ind = zeros(Int,ncol)
    mass_charge_ind[mass_cons_map] = charge_cons_map
    #vals = nonzeros(lsys.jac)
    rows = rowvals(lsys.jac)
    #NB could probably be more efficent vectorized
    for j in 1:size(lsys.jac,2)
        zrange = nzrange(lsys.jac,j)
        loc_rows = rows[zrange]
        for i in zrange
            row = rows[i]
            charge_row = mass_charge_ind[row]
            if charge_row != 0
                 charge_ind = indexin(charge_row, loc_rows)
                 if !(charge_ind[1] == nothing)
                    charge_val_index =  zrange[charge_ind[1]]
                    push!(charge_index,charge_val_index)
                    push!(mass_index,i)
                   end
            end
        end
    end
    return (mass_index, charge_index)
end


function modify_equation!(lsys, maps,tfac, context)#::Jutul.DefaultContext)
    
    (mass_index, charge_index, mass_cons_map, charge_cons_map) = maps
    vals = nonzeros(lsys.jac)
    @. vals[mass_index] -= tfac*vals[charge_index]
    @. lsys.r[mass_cons_map] -= tfac*lsys.r[charge_cons_map]
end

function modify_equation!(lsys, mass_cons_map, charge_cons_map,tfac, nc, context::Jutul.ParallelCSRContext)
    #NB not well stested
    vals = nonzeros(lsys.jac)
    #colvals = colvals(lsys.jac)
    for i in 1:nc
        ## decouple mass end charge conservation based on the property
        # that charge and mass transport is propotioinal due to change 
        #storage.LinearizedSystem.jac[mass_cons_map[i],:] += storage.LinearizedSystem.jac[charge_cons_map[i],:] 
        #storage.LinearizedSystem.r[mass_cons_map[i],:] += storage.LinearizedSystem.r[charge_cons_map[i],:] 
        mass_ind = nzrange(lsys.jac,mass_cons_map[i])
        charge_ind = nzrange(lsys.jac,mass_cons_map[i])
        @assert length(mass_ind) == length(charge_ind)
        #for j in 1:lenght(mass_ind)
        #    vals[mass_ind[j]] .-= tfac.*vals[charge_ind[i]]
        #end
        @. vals[mass_ind] -= tfac*vals[charge_ind]
        lsys.r[mass_cons_map[i]] -= tfac*lsys.r[charge_cons_map[i]]
    end
end 


function fix_control!(lsys, context)
if lsys.jac[end,end] == 1 && lsys.jac[end,end-1] == 0
    #Main.@infiltrate !(lsys.jac[end-1,end] == 1)
    @assert    lsys.jac[end,end-1] == 0
    @assert    lsys.jac[end-1,end] == 1
  
    fac = lsys.jac[end-1,end]
    lsys.jac[end-1,end] -= lsys.jac[end,end]*fac
    lsys.r[end-1] -=  lsys.r[end]*fac 
    @assert lsys.jac[end-1,end] == 0
else
    #NB assume not added sparcity
    if(false)
    #Main.@infiltrate true
    #@assert abs(lsys.jac[end,end-1]) == 1
    @assert lsys.jac[end,end] == 0
    jac_l = deepcopy(lsys.jac[end,:])
    r_l= copy(lsys.r[end])
    lsys.jac[end,:] = lsys.jac[end-1,:]
    lsys.r[end] = lsys.r[end-1] 
    lsys.jac[end-1,:] = jac_l
    lsys.r[end-1] = r_l
    #Main.@infiltrate true
    end
    
end
end

function fix_control!(lsys, context::Jutul.ParallelCSRContext)
    if lsys.jac[end,end] == 1
        @assert    lsys.jac[end,end-1] == 0
        @assert    lsys.jac[end-1,end] == 1
        fac = lsys.jac[end-1,end]
        lsys.jac.At[end,end-1] -= lsys.jac[end,end]*fac
        lsys.r[end-1] -=  lsys.r[end]*fac 
        @assert lsys.jac[end-1,end] == 0
    else
        if(true)#NB !!!!!!!!!!!!!!!
        @assert lsys.jac[end,end-1] == 1
        @assert lsys.jac[end,end] == 0
        jac_l = deepcopy(lsys.jac[end,:])
        r_l= copy(r[end])
        lsys.jac[end,:] = lsys[end-1,:]
        lsys.r[end] = lsys.r[end-1] 
        lsys.jac[end-1,:] = a
        lsys.r[end] = r_l
        end
    end
    end

function Jutul.post_update_linearized_system!(lsys, executor, storage, model::Jutul.MultiModel)
    if(true)
    # fix linear system 
    e_models = [:Elyte]
    if isnothing(storage[:eq_maps].maps)
        mass_cons_map = setup_subset_equation_map(model, storage, e_models, :mass_conservation)
        #phi_map = setup_subset_residual_map(model, storage, e_models, :Phi)
        charge_cons_map = setup_subset_equation_map(model, storage, e_models, :charge_conservation)
        (mass_ind, charge_ind) = matrix_maps(lsys, mass_cons_map, charge_cons_map, model.context)
        storage[:eq_maps].maps = (mass_ind = mass_ind, charge_ind = charge_ind, mass_cons_map = mass_cons_map, charge_cons_map = charge_cons_map) 
    end
    #C_map = setup_subset_residual_map(model, storage, e_models, :C)
    #Main.@infiltrate true
    tfac = model[:Elyte].system[:transference]/BattMo.FARADAY_CONSTANT
    modify_equation!(lsys, storage[:eq_maps].maps,tfac, model.context)
    ## to control reduction ?
    #Main.@infiltrate true
    fix_control!(lsys, model.context)
    #Main.@infiltrate true
    #print("hei")
    end
end


function Jutul.update_preconditioner!(prec::BatteryCPhiPreconditioner, lsys, context, model, storage, recorder, executor)
    # Solve all Phi with AMG
    # Solve the elyte C with another AMG
    # Let the rest be (?)
    A = lsys.jac
    r = lsys.r

    if isnothing(prec.data)
        models_without_control = setdiff(keys(model.models), [:Control])
        allmodels = keys(model.models)
        # Set up various mappings
        # Concentration part
        #c_models = [:Elyte]
        #c_models = nothing
        c_models = models_without_control
        c_map = setup_subset_residual_map(model, storage, c_models, :C)
        mass_cons_map = setup_subset_equation_map(model, storage, c_models, :mass_conservation)
        # Phi part
        # p_models = nothing
        p_models = allmodels#models_without_control
        phi_map = setup_subset_residual_map(model, storage, p_models, :Phi)
        charge_cons_map = setup_subset_equation_map(model, storage, p_models, :charge_conservation)
        # @assert length(intersect(c_map, phi_map)) == 0
        nc = length(r)
        prec.data = (c   = storage_chpi_precond(c_map),
                     phi = storage_chpi_precond(phi_map),
                     allvars =  (r = zeros(nc), x = zeros(nc)),
                     n   = length(r),
                     charge_map = charge_cons_map,
                     mass_map = mass_cons_map,
                     A = A
                     )
    else
        @assert A == prec.data.A
    end
    #prec.data.A = A
    (c, phi, allvars, n, charge_map, mass_map, A) = prec.data
    if !isnothing(prec.g_precond)
        Jutul.update_preconditioner!(prec.g_precond, lsys, context, model, storage, recorder, executor)
    end
    update_local_cphi_preconditioner!(prec.c_precond, A, r, mass_map, c.ix, executor)
    update_local_cphi_preconditioner!(prec.p_precond, A, r, charge_map, phi.ix, executor)
    #Main.@infiltrate true
    #pmat = A[charge_map, phi.ix]
    #cmat = A[mass_map, c.ix]
    #@exfiltrate mass_map, c, charge_map, phi
end

function Jutul.apply!(x, prec::BatteryCPhiPreconditioner, r, arg...)
    (; c, phi, allvars, A) = prec.data
    #@. x .= r
    dx = allvars.x
    x .= 0 
    r_local = allvars.r;
    r_local .= r
    #@assert A[end,end] == 1
    #@assert A[end-1,end] == 1
    if A[end,end] == 1
        @assert A[end-1,end] == 0
        x[end] += r_local[end]
        r_local[end] = 0
    end
    if A[end,end] == 1 && false
        @assert A[end,end] == 1
        @assert A[end-1,end] == 1
        # seems to be needed
        dx .= 0.0
        dx[end] = r_local[end]/A[end,end]
        r_local[end-1] -= A[end-1,end]*dx[end]
        r_local[end] = 0.0
        x .+= dx
    else

    end
    #println(x)
    #println(r_local)
    
    ## asume p_prec and c_prec is orthogonal
    #println("Start consentration")
    dx .= 0.0
    apply_local_cphi_preconditioner!(dx, prec.p_precond, r_local, phi, arg...)
    #apply_local_cphi_preconditioner!(dx, prec.c_precond, r_local, c, arg...)
    #println(dx)
    x .+= dx
    #println(x)
    #println(r_local)
    #Jutul.mul!(r_local, A, dx, -1, true)
    dx .= 0.0
    #println("Start Volatage")
    apply_local_cphi_preconditioner!(dx, prec.c_precond, r_local, c, arg...)
    #println(dx)
    #apply_local_cphi_preconditioner!(dx, prec.p_precond, r_local, phi, arg...)
    x .+= dx
    #println(x)
    #println(r_local)
    #NB just done to avoid to do gaus sidal
    r_local .= r
    #println(x)
    Jutul.mul!(r_local, A, x, -1, true)
    #println(x)
    #println(r_local)
    
    #println(r_local)
    #println("Norm after Voltage and consentration ")#,norm(r_local,2) )
    #Jutul.mul!(r_local, A, dx, -1, true)
    dx .= 0.0
    if !isnothing(prec.g_precond)
        #r_local = allvars.r
        dx .= 0.0
        #r_local .= r
        #Jutul.mul!(r_local, A, x, -1, true)
        Jutul.apply!(dx, prec.g_precond, r_local, arg...)
        @. x .+= dx
        Jutul.mul!(r_local, A, dx, -1, true)
        dx .= 0.0
    end
    if A[end,end] == 1 && false
        # seems to be needed
        dx .= 0.0
        dx[end] = r_local[end]/A[end,end]
        r_local[end-1] -= A[end-1,end]*dx[end]
        r_local[end] = 0.0
        x .+= dx
    else

    end
    if A[end,end] == 1
        x[end] += r_local[end]
        r_local[end] = 0
    end
    #println(x)
    #println(r_local)
    #error()
    #apply_local_cphi_preconditioner!(x, prec.p_precond, r, allvar, arg...)
end

function storage_chpi_precond(index_map)
    n = length(index_map)
    return (ix = index_map, r = zeros(n), x = zeros(n))
end

function update_local_cphi_preconditioner!(prec, A, r, ind_eq, ind_var, executor)
    A_s = A[ind_eq, ind_var]
    b_s = view(r, ind_var)
    sys = Jutul.LinearizedSystem(A_s)
    dummy_model = Jutul.Nothing()
    dummy_storage = Jutul.Nothing()
    Jutul.update_preconditioner!(prec, sys, DefaultContext(), dummy_model, dummy_storage , Jutul.ProgressRecorder(), executor)
    #NB ok??
    #Jutul.update_preconditioner!(prec, A_s, view(r, ix), DefaultContext(), executor)
end

function apply_local_cphi_preconditioner!(x, prec, r, S, arg...)
    r_i = S.r
    x_i = S.x
    x_i .= 0.0
    ix = S.ix
    @. r_i = r[ix]
    apply!(x_i, prec, r_i,arg...)
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
                    #@assert dof_per_e == 1 "Found $dof_per_e dof per entity, expected 1?"
                    ndof = nc*dof_per_e
                    push!(M, (offset+1):(offset+ndof))
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

function setup_subset_equation_map(multi_model::MultiModel, storage, model_labels, equation_label)
    M = []
    offsets = Jutul.get_submodel_offsets(storage)
    m_ix = 1
    for (model_key, model) in pairs(multi_model.models)
        @assert !Jutul.is_cell_major(matrix_layout(model.context)) "Only supported for equation major"
        if isnothing(model_labels) || model_key in model_labels
            offset = offsets[m_ix]
            nc = number_of_cells(model.domain)
            for (eqlabel, pvar) in model.equations
                if eqlabel == equation_label
                    @assert associated_entity(pvar) == Cells()
                    eq_per_e = Jutul.number_of_equations_per_entity(model, pvar)
                    #@assert eq_per_e == 1 "Found $eq_per_e eq for each entity, expected 1?"
                    neq = nc*eq_per_e
                    push!(M, (offset+1):(offset+neq))
                    break
                else
                    offset += nc*Jutul.number_of_equations_per_entity(model, pvar)
                end
            end
        end
        m_ix += 1
    end
    return vcat(M...)
end


Jutul.operator_nrows(p::BatteryCPhiPreconditioner) = p.data.n

function battery_linsolve(model, method = :ilu0;
                                 rtol = 0.001,
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
        prec = BatteryCPhiPreconditioner() # c_preconditioner =amg  p_preconditioner =amg
    elseif method == :cphi_ilu
        prec = BatteryCPhiPreconditioner(ILUZeroPreconditioner()) 
    elseif method == :cphi_ilu_ilu
        prec = BatteryCPhiPreconditioner(ILUZeroPreconditioner(),ILUZeroPreconditioner())
    else
        error("Wrong input for preconditioner")
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
