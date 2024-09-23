
function Jutul.update_preconditioner!(prec::BattMo.BatteryGeneralPreconditioner, lsys, context, model, storage, recorder, executor)
    # Solve all Phi with AMG
    # Solve the elyte C with another AMG
    # Let the rest be (?)
    A = lsys.jac
    r = lsys.r
    setup = false 
    if isnothing(prec.data)
        setup = true
    else
        # NB should probably not be here
        if A != prec.data.A
            setup = false
        end 
    end
    #Main.@infiltrate true
    if setup
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
            map = (var =storage_general_precond(var_map), eq_map = eq_map)
            push!(maps,map)
            @assert variable != :Global
            #update_local_preconditioner!(varprecond.precond, A, r, eq_map, var_map, executor)
        end
        ndof = length(r)
        prec.data = (maps = maps, allvars = (r = zeros(ndof), x = zeros(ndof)), n = ndof, A = A)
    else
        #Main.@infiltrate !(A == prec.data.A)
        @assert A == prec.data.A
    end
    #prec.data.A = A
    for (i,varprecond) in enumerate(prec.varpreconds)
        eq_map = copy(prec.data.maps[i].eq_map)
        var_map = copy(prec.data.maps[i].var.ix)
        update_local_preconditioner!(varprecond.precond, A, r, eq_map, var_map, executor)
    end
    
    if !isnothing(prec.g_varprecond)
        precond = prec.g_varprecond
        Jutul.update_preconditioner!(precond.precond, lsys, context, model, storage, recorder, executor)
    end
end
Jutul.operator_nrows(p::BattMo.BatteryGeneralPreconditioner) = p.data.n

function Jutul.apply!(x, prec::BattMo.BatteryGeneralPreconditioner, r, arg...)
    A = prec.data.A
    x .= 0 
    dx = prec.data.allvars.x#copy(x) # maybe move to storage
    dx .= 0.0
    r_local = prec.data.allvars.r #copy(r) # maby move to storage
    r_local .= r
    if prec.params["pre_solve_control"] == true
        solve_for_current!(x,prec.data.A, r_local)
    end
    #println(x)
    #println(r_local)
 
    for (i,varprecond) in enumerate(prec.varpreconds)
        var  = prec.data.maps[i].var # contain storage and index
        dx .= 0.0
        precond = varprecond.precond
        precond = prec.varpreconds[i].precond
        if false   
        println("Apply preconditioner for")
        println("Equations", varprecond.eq)
        println("Variables ", varprecond.var)
        println("Models ", varprecond.models)
        #println(precond)
        end
        apply_local_preconditioner!(dx, precond, r_local, var, arg...)
        #println(dx)
        x .+= dx
        if prec.params["method"] == "seq"
            ## assumes non overlapping variables
            Jutul.mul!(r_local, A, dx, -1, true)
            dx .= 0.0
        else
            @assert prec.params["method"] == "block"
            dx .= 0.0
        end
        #println(x)
        #println(r_local)
    end
    ## if block we need to update residual before global preconditioner
    #println(x)
    if prec.params["method"] == "block"
        r_local .= r
        Jutul.mul!(r_local, A, x, -1, true)
        dx .= 0.0
    end
    #println(x)
    #println(r_local)
    #error()
    if !isnothing(prec.g_varprecond)
        varprec = prec.g_varprecond
        Jutul.apply!(dx, varprec.precond, r_local, arg...)
        x .+= dx
        Jutul.mul!(r_local, A, dx, -1, true)
        dx .= 0.0
    end
    if prec.params["post_solve_control"] == true
        solve_for_current!(x,prec.data.A,r_local)
    end
    #println(x)
    #println(r_local)
end

function solve_for_current!(x,A, r_local)
    ##NB fix for not current control
    if (A[end,end] == 1) && (A[end,end-1] == 0) && (A[end-1,end] == 0)
        ## current control
        @assert A[end-1,end] == 0
        @assert A[end,end-1] == 0
        x[end] += r_local[end]
        r_local[end] = 0
    else
        #NB check last last equations should be changed
        if(false)
        #Main.@infiltrate   
        @assert A[end-1,end-1] != 0
        @assert A[end-1,end] == 0
        val = A[end:end,:]*x
        r_end = r_local[end] - val[1]#A[end:end,:]*x
        x[end] += r_end[end]/A[end,end]
        end
    end
end

function storage_general_precond(index_map)
    n = length(index_map)
    return (ix = index_map, r = zeros(n), x = zeros(n))
end

function update_local_preconditioner!(prec, A, r, ind_eq, ind_var, executor)
    A_s = A[ind_eq, ind_var]
    b_s = view(r, ind_var)
    sys = Jutul.LinearizedSystem(A_s)
    dummy_model = Jutul.Nothing()
    dummy_storage = Jutul.Nothing()
    Jutul.update_preconditioner!(prec, sys, DefaultContext(), dummy_model, dummy_storage , Jutul.ProgressRecorder(), executor)
    #NB ok??
    #Jutul.update_preconditioner!(prec, A_s, view(r, ix), DefaultContext(), executor)
end
function apply_local_preconditioner!(x, prec, r, S, arg...)
    r_i = S.r
    x_i = S.x
    x_i .= 0.0
    ix = S.ix
    @. r_i = r[ix]
    apply!(x_i, prec, r_i,arg...)
    @. x[ix] = x_i
end
