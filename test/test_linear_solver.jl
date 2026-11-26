using BattMo, Jutul
using Test

@testset "direct linear solver" begin
    # The "Direct" method and Jutul's own solver selection, as for adjoints, use KLU for P2D and UMFPACK for P4D.
    for (settings_set, cell_set, solver_type) in (("p2d", "chen_2020", KLUSolver), ("p4d_pouch", "xu_2015", LUSolver))
        cell_parameters = load_cell_parameters(; from_default_set = cell_set)
        cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
        model_settings = load_model_settings(; from_default_set = settings_set)
        simulation_settings = load_simulation_settings(; from_default_set = settings_set)
        sim = Simulation(LithiumIonBattery(; model_settings), cell_parameters, cycling_protocol; simulation_settings)
        multimodel = sim.model.multimodel

        @test Jutul.select_linear_solver(multimodel; mode = :adjoint, rtol = 1.0e-6) isa solver_type
        linear_solver = BattMo.battery_linsolve(multimodel, Dict{String, Any}("Method" => "Direct", "MaxSize" => 1000))
        @test linear_solver isa solver_type
        @test linear_solver.max_size == 1000
    end
end
