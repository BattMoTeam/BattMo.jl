import time
from pathlib import Path

import pandas as pd
import pybamm

# -----------------------------
# PyBaMM model and parameters (Chen 2020, DFN, 1C discharge to 2.5 V)
# Same physical setup as pybamm_chen.py
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

# -----------------------------
# Benchmark: time solve() only, excluding model build/discretization
# -----------------------------
N_WARMUP = 1
N_REPS = 5

sim = pybamm.Simulation(model, parameter_values=param, experiment=experiment)
sim.build()  # discretize once, untimed

for _ in range(N_WARMUP):
    sim.solve()

times = []
for i in range(N_REPS):
    t0 = time.perf_counter()
    sim.solve()
    t1 = time.perf_counter()
    times.append(t1 - t0)
    print(f"rep {i + 1}/{N_REPS}: {times[-1]:.4f} s")

df = pd.DataFrame({"rep": range(1, N_REPS + 1), "solve_time_s": times})
df["tool"] = "PyBaMM"
df["pybamm_version"] = pybamm.__version__

results_dir = Path("results")
results_dir.mkdir(exist_ok=True)
output_path = results_dir / "pybamm_benchmark_times.csv"
df.to_csv(output_path, index=False)

print(f"\nPyBaMM {pybamm.__version__}")
print(f"mean: {df['solve_time_s'].mean():.4f} s")
print(f"min:  {df['solve_time_s'].min():.4f} s")
print(f"std:  {df['solve_time_s'].std():.4f} s")
print(f"Saved {output_path}")
