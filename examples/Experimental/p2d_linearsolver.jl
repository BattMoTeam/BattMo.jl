
function p2dPreconditioner(split=false)
    solver = :fgmres
    rtol = 1e-7  # for simple face rtol=1e7 and atol 1e-9 seems give same number ononlinear as direct
    atol = 1e-9 # seems important
    max_it = 100
    verbose = 0
    if split
        prec_org_s = Jutul.AMGPreconditioner(:ruge_stuben)
        ksolver_s = GenericKrylov(
            solver;
            verbose=0,
            preconditioner=prec_org_s,
            relative_tolerance=1e-5,
            absolute_tolerance=1e-28,
            max_iterations=max_it,
            min_iterations=4,
        )
        prec_org_p = Jutul.AMGPreconditioner(:ruge_stuben)
        ksolver_p = GenericKrylov(
            solver;
            verbose=0,
            preconditioner=prec_org_p,
            relative_tolerance=1e-6,
            absolute_tolerance=1e-28,
            max_iterations=max_it,
            min_iterations=4,
        )
        s_prec = SolverAsPreconditionerSystem(ksolver_s)
        p_prec = SolverAsPreconditionerSystem(ksolver_p)
        g_prec = Jutul.TrivialPreconditioner()

    else
        p_prec = Jutul.AMGPreconditioner(:ruge_stuben)
        s_prec = Jutul.TrivialPreconditioner()
        g_prec = Jutul.ILUZeroPreconditioner()
    end
    solver = GenericKrylov(
        solver;
        verbose=verbose,
        preconditioner=prec,
        relative_tolerance=rtol,
        absolute_tolerance=atol,
        max_iterations=max_it,
    )
    return solver
end
##
lsys = sim.storage.LinearizedSystem
storage = sim.storage
e_models = [:Elyte]
mass_cons_map = BattMo.setup_subset_equation_map(
    model, storage, e_models, :mass_conservation
)
charge_cons_map = BattMo.setup_subset_equation_map(
    model, storage, e_models, :charge_conservation
)
i = 1
tfac = model[:Elyte].system[:transference]/BattMo.FARADAY_CONST
##
vals = nonzeros(lsys.jac)
mass_ind = nzrange(lsys.jac, mass_cons_map[i])
charge_ind = nzrange(lsys.jac, mass_cons_map[i])
@assert length(mass_ind) == length(charge_ind)
#for j in 1:lenght(mass_ind)
#    vals[mass_ind[j]] .-= tfac.*vals[charge_ind[i]]
#end
@. vals[mass_ind] -= tfac*vals[charge_ind]
lsys.r[mass_cons_map[i]] -= tfac*lsys.r[charge_cons_map[i]]
