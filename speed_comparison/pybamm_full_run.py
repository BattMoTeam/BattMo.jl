import time

t_script_start = time.perf_counter()

import pybamm

t_after_import = time.perf_counter()

# -----------------------------
# PyBaMM model and parameters (Chen 2020, DFN, 1C discharge to 2.5 V)
# Same physical setup as pybamm_chen.py / pybamm_benchmark.py
# -----------------------------
model = pybamm.lithium_ion.DFN()

param = pybamm.ParameterValues("Chen2020")


def elyte_conductivity(c, T):
    return 0.1297 * (c / 1000) ** 3 - 2.51 * (c / 1000) ** 1.5 + 3.329 * (c / 1000)


def elyte_diffus(c, T):
    return 8.794e-11 * (c / 1000) ** 2 - 3.972e-10 * (c / 1000) + 4.862e-10


param["Electrolyte conductivity [S.m-1]"] = elyte_conductivity
param["Electrolyte diffusivity [m2.s-1]"] = elyte_diffus

experiment = pybamm.Experiment(["Discharge at 1C until 2.5 V"])

sim = pybamm.Simulation(model, parameter_values=param, experiment=experiment)

t_before_solve = time.perf_counter()
solution = sim.solve()
t_after_solve = time.perf_counter()

voltage_V = solution["Terminal voltage [V]"].entries
time_s = solution["Time [s]"].entries

print(f"PyBaMM {pybamm.__version__}")
print(f"import time:        {t_after_import - t_script_start:.4f} s")
print(f"setup time:         {t_before_solve - t_after_import:.4f} s")
print(f"solve time:         {t_after_solve - t_before_solve:.4f} s")
print(f"total (from import): {t_after_solve - t_script_start:.4f} s")
print(f"t_final={time_s[-1]:.1f} s  v_final={voltage_V[-1]:.4f} V")
