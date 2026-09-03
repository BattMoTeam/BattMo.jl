import time
from pathlib import Path

import pandas as pd
import pybamm


def elyte_conductivity(c, T):
    return 0.1297 * (c / 1000) ** 3 - 2.51 * (c / 1000) ** 1.5 + 3.329 * (c / 1000)


def elyte_diffus(c, T):
    return 8.794e-11 * (c / 1000) ** 2 - 3.972e-10 * (c / 1000) + 4.862e-10


def build_and_solve():
    model = pybamm.lithium_ion.DFN()
    param = pybamm.ParameterValues("Chen2020")
    param["Electrolyte conductivity [S.m-1]"] = elyte_conductivity
    param["Electrolyte diffusivity [m2.s-1]"] = elyte_diffus
    experiment = pybamm.Experiment(["Discharge at 1C until 2.5 V"])
    sim = pybamm.Simulation(model, parameter_values=param, experiment=experiment)
    sim.solve()
    return sim.solution


# -----------------------------
# Benchmark: time the FULL build+solve pipeline (fresh Simulation each rep),
# already-compiled/warm process (package already imported, casadi already
# JIT-compiled by the warmup rep) - i.e. what repeated "run the whole
# simulation" calls cost once the process is warm, not a cold start.
# -----------------------------
N_WARMUP = 1
N_REPS = 5

for _ in range(N_WARMUP):
    build_and_solve()

times = []
for i in range(N_REPS):
    t0 = time.perf_counter()
    solution = build_and_solve()
    t1 = time.perf_counter()
    times.append(t1 - t0)
    print(f"rep {i + 1}/{N_REPS}: {times[-1]:.4f} s")

df = pd.DataFrame({"rep": range(1, N_REPS + 1), "build_solve_time_s": times})
df["tool"] = "PyBaMM (build+solve)"
df["pybamm_version"] = pybamm.__version__

results_dir = Path("results")
results_dir.mkdir(exist_ok=True)
output_path = results_dir / "pybamm_full_benchmark_times.csv"
df.to_csv(output_path, index=False)

print(f"\nPyBaMM {pybamm.__version__} (already compiled, full build+solve)")
print(f"mean: {df['build_solve_time_s'].mean():.4f} s")
print(f"min:  {df['build_solve_time_s'].min():.4f} s")
print(f"std:  {df['build_solve_time_s'].std():.4f} s")
print(f"Saved {output_path}")
