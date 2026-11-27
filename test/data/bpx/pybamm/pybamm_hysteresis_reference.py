# /// script
# requires-python = ">=3.12"
# dependencies = ["pybamm[bpx]==26.11.0", "numpy"]
# ///
"""PyBaMM reference for the OCP hysteresis of BattMo.jl.

Runs the Schmitt et al. (2026) graphite/LNMO BPX parameter set (../schmitt_2026.bpx.json,
BPX 1.1) with OCP hysteresis on the negative electrode, in PyBaMM's "one-state hysteresis"
model, and without it. The hysteresis variant adds to the negative electrode:

- "OCP (lithiation) [V]" and "OCP (delithiation) [V]": the OCP table, 10 mV lower and higher;
- "OCP hysteresis decay constant": 20;
- in State, "Initial hysteresis state: Negative electrode": -1, the lithiation branch.

From full charge (target_soc = 1, the BPX stoichiometry limits, as in BattMo) the cell is
discharged at 0.5 A for 40 min, rests 15 min, is charged at 0.5 A for 20 min and rests 15 min.
The voltages with and without hysteresis are written to pybamm_schmitt2026_hysteresis.csv, which
test/test_bpx_acceptance.jl compares with BattMo.jl through the effect of the hysteresis, the
difference of the two voltages. The test builds the same variant from the same file.

Environment of the committed file: Python 3.12, pybamm 26.11.0.0, bpx 1.1.1.

Usage: uv run pybamm_hysteresis_reference.py
"""

from __future__ import annotations

import copy
import json
import tempfile
import warnings
from pathlib import Path

import numpy as np
import pybamm

HERE = Path(__file__).resolve().parent
BPX_FILE = HERE.parent / "schmitt_2026.bpx.json"
OFFSET_V = 0.01
DECAY_CONSTANT = 20.0
INITIAL_STATE = -1.0
STEPS = [
    "Discharge at 0.5 A for 40 minutes",
    "Rest for 15 minutes",
    "Charge at 0.5 A for 20 minutes",
    "Rest for 15 minutes",
]
PERIOD_S = 10.0
MESH_POINTS = 20


def hysteresis_variant(data: dict) -> dict:
    variant = copy.deepcopy(data)
    negative = variant["Parameterisation"]["Negative electrode"]
    ocp = negative["OCP [V]"]
    negative["OCP (lithiation) [V]"] = {"x": ocp["x"], "y": [y - OFFSET_V for y in ocp["y"]]}
    negative["OCP (delithiation) [V]"] = {"x": ocp["x"], "y": [y + OFFSET_V for y in ocp["y"]]}
    negative["OCP hysteresis decay constant"] = DECAY_CONSTANT
    variant["State"]["Initial conditions"]["Initial hysteresis state: Negative electrode"] = INITIAL_STATE
    return variant


def run(parameter_values: pybamm.ParameterValues, hysteresis: bool) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    options = {"thermal": "isothermal"}
    if hysteresis:
        options["open-circuit potential"] = ("one-state hysteresis", "single")
    model = pybamm.lithium_ion.DFN(options)
    experiment = pybamm.Experiment(STEPS, period=f"{PERIOD_S:g} seconds")
    solver = pybamm.CasadiSolver(mode="safe", rtol=1e-6, atol=1e-6)
    var_pts = dict.fromkeys(["x_n", "x_s", "x_p", "r_n", "r_p"], MESH_POINTS)
    simulation = pybamm.Simulation(model, parameter_values=parameter_values, experiment=experiment, solver=solver, var_pts=var_pts)
    solution = simulation.solve(calc_esoh=False)
    t, v, i = (solution[name].entries for name in ("Time [s]", "Voltage [V]", "Current [A]"))
    # Consecutive steps share their end point; keep the end of the earlier step.
    keep = np.r_[True, np.diff(t) > 1e-9]
    return t[keep], v[keep], i[keep]


def main() -> None:
    data = json.loads(BPX_FILE.read_text(encoding="utf-8"))
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / "hysteresis.bpx.json"
        path.write_text(json.dumps(hysteresis_variant(data)), encoding="utf-8")
        with warnings.catch_warnings():
            # target_soc is deprecated; it sets the concentrations from the stoichiometry limits
            warnings.simplefilter("ignore", DeprecationWarning)
            parameter_values = pybamm.ParameterValues.create_from_bpx(str(path), target_soc=1.0)
    t, v, i = run(parameter_values, hysteresis=True)
    t0, v0, _ = run(parameter_values, hysteresis=False)
    if len(t) != len(t0) or not np.allclose(t, t0):
        raise RuntimeError("The runs with and without hysteresis have different output times.")

    csv_path = HERE / "pybamm_schmitt2026_hysteresis.csv"
    with csv_path.open("w", encoding="utf-8", newline="") as f:
        f.write("Time [s],Voltage [V],Voltage without hysteresis [V],Current [A]\n")
        for row in zip(t, v, v0, i):
            f.write("{:.6f},{:.9f},{:.9f},{:.9f}\n".format(*row))
    summary = {
        "source": str(BPX_FILE.name),
        "pybamm_version": pybamm.__version__,
        "steps": STEPS,
        "offset_V": OFFSET_V,
        "decay_constant": DECAY_CONSTANT,
        "initial_hysteresis_state": INITIAL_STATE,
        "mesh_points": MESH_POINTS,
        "output_period_s": PERIOD_S,
        "points": len(t),
        "largest_effect_V": float(np.max(np.abs(v - v0))),
    }
    (HERE / "pybamm_schmitt2026_hysteresis_summary.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {csv_path.name}: {len(t)} points, largest effect of the hysteresis {1000 * summary['largest_effect_V']:.2f} mV")


if __name__ == "__main__":
    main()
