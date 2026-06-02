using BattMo
using Test

@testset "P2D impedance" begin
    cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
    simulation = impedance_simulation(cell_parameters; soc = 0.5)
    frequencies = [1.0e-4, 1.0e-2, 1.0, 100.0]
    impedance = compute_impedance(simulation, frequencies)

    @test length(impedance) == length(frequencies)
    @test all(isfinite, impedance)
    @test all(real.(impedance) .> 0)
    @test all(imag.(impedance) .<= 0)
    @test real(impedance[1]) > real(impedance[end])
    @test -imag(impedance[1]) > -imag(impedance[end])
end
