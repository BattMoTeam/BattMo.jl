import pytest

from battmo import *


def test_loading():

    cell_parameters = load_cell_parameters(from_default_set="Chen2020")
    cycling_protocol = load_cycling_protocol(from_default_set="CCDischarge")
    model_settings = load_model_settings(from_default_set="P2D")
    simulation_settings = load_simulation_settings(from_default_set="P2D")


def test_simulation():
    cell_parameters = load_cell_parameters(from_default_set="Chen2020")
    cycling_protocol = load_cycling_protocol(from_default_set="CCDischarge")
    model_setup = LithiumIonBattery()
    sim = Simulation(model_setup, cell_parameters, cycling_protocol)
    output = solve(sim)


def test_output_handling():
    cell_parameters = load_cell_parameters(from_default_set="Chen2020")
    cycling_protocol = load_cycling_protocol(from_default_set="CCDischarge")
    model_setup = LithiumIonBattery()
    sim = Simulation(model_setup, cell_parameters, cycling_protocol)
    output = solve(sim)

    ts = get_output_time_series(output)
    states = get_output_states(output)
    metrics = get_output_metrics(output)
    print_output_overview(output)


# def test_plotting():

#     install_plotting()
#     activate_plotting()
#     make_interactive()

#     uninstall_plotting()


def test_utils():
    print_submodels_info()
    print_default_input_sets_info()
    print_parameter_info("Electrode")
    print_setting_info("Grid")
    print_output_variable_info("Concentration")


# def test_calibration():
#     cell_parameters = load_cell_parameters(from_default_set="Chen2020")
#     cycling_protocol = load_cycling_protocol(from_default_set="CCDischarge")
#     model_setup = LithiumIonBattery()
#     sim = Simulation(model_setup, cell_parameters, cycling_protocol)
#     output = solve(sim)

#     calibration = VoltageCalibration(sim, output)

#     free_calibration_parameter(calibration, "Negative electrode active material volume fraction")
#     print_calibration_overview(calibration)
#     solve(calibration)
#     print_calibration_overview(calibration)
