import pytest
import os

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

    cell_parameters = load_cell_parameters(from_default_set="Chayambuka2022")
    model_settings = load_model_settings(from_default_set="P2D")
    model_settings["ButlerVolmer"] = "Chayambuka"

    model_setup = SodiumIonBattery(model_settings=model_settings)
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

    cell_parameters = load_cell_parameters(from_default_set="Chen2020")
    print_cell_info(cell_parameters)

    # plot_cell_curves(cell_parameters)


def test_calibration():
    battmo_base = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    exdata = os.path.join(battmo_base, "examples", "example_data")

    df_05 = pd.read_csv(
        os.path.join(exdata, "Xu_2015_voltageCurve_05C.csv"), names=["Time", "Voltage"]
    )

    cell_parameters = load_cell_parameters(from_default_set="Xu2015")
    cycling_protocol = load_cycling_protocol(from_default_set="CCDischarge")

    cycling_protocol["LowerVoltageLimit"] = 2.25
    cycling_protocol["DRate"] = 0.5

    model = LithiumIonBattery()
    sim = Simulation(model, cell_parameters, cycling_protocol)
    output0 = solve(sim)

    time_series = get_output_time_series(output0)
    df_sim = to_pandas(time_series)

    cal = VoltageCalibration(np.array(df_05["Time"]), np.array(df_05["Voltage"]), sim)

    free_calibration_parameter(
        cal,
        ["NegativeElectrode", "ActiveMaterial", "StoichiometricCoefficientAtSOC100"],
        lower_bound=0.0,
        upper_bound=1.0,
    )
    free_calibration_parameter(
        cal,
        ["PositiveElectrode", "ActiveMaterial", "StoichiometricCoefficientAtSOC100"],
        lower_bound=0.0,
        upper_bound=1.0,
    )

    free_calibration_parameter(
        cal,
        ["NegativeElectrode", "ActiveMaterial", "StoichiometricCoefficientAtSOC0"],
        lower_bound=0.0,
        upper_bound=1.0,
    )
    free_calibration_parameter(
        cal,
        ["PositiveElectrode", "ActiveMaterial", "StoichiometricCoefficientAtSOC0"],
        lower_bound=0.0,
        upper_bound=1.0,
    )

    free_calibration_parameter(
        cal,
        ["NegativeElectrode", "ActiveMaterial", "MaximumConcentration"],
        lower_bound=10000.0,
        upper_bound=1e5,
    )
    free_calibration_parameter(
        cal,
        ["PositiveElectrode", "ActiveMaterial", "MaximumConcentration"],
        lower_bound=10000.0,
        upper_bound=1e5,
    )

    solve(cal)

    cell_parameters_calibrated = cal.calibrated_cell_parameters

    sim_calibrated = Simulation(model, cell_parameters_calibrated, cycling_protocol)
    output_calibrated = solve(sim_calibrated)

    time_series_cal = get_output_time_series(output_calibrated)

    df_sim_cal = to_pandas(time_series_cal)
