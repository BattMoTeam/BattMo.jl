"""PyBaMM reference curves for the BattMo.jl BPX import validation.

Runs constant current discharges of the Schmitt et al. (2026) graphite/LNMO
BPX parameter set in PyBaMM and writes the voltage curves as CSV files next to
this script. test/test_bpx_acceptance.jl compares BattMo.jl against the 0.5 A
and 2 A curves, which are committed together with the summary (see
../datasets.toml), so this script only needs to run again when the reference
should change.

Environment used for the committed files: Python 3.11, pybamm 26.4.4,
bpx 0.5.0 (BPX 1.0 schema), casadi 3.7.2, numpy 2.4.6. Newer bpx releases
(1.1 and later) reject the publication file, because its header says
"BPX": 1.0 while its layout predates the "State" section introduced in 1.1.

Two parameter variants are run:

- "original": the file as published. PyBaMM applies a separate electrolyte
  Bruggeman exponent ln(tau)/ln(eps) to each region (1.86 / 4.53 / 1.68).
- "uniform": every region's "Transport efficiency" replaced by
  Porosity ** 1.5, so that one Bruggeman exponent of 1.5 applies everywhere.
  BattMo.jl applies a single exponent to the whole electrolyte, so this is the
  variant that compares like for like.

Usage, from a Python environment with pybamm[bpx] installed:

    python pybamm_reference.py --bpx path/to/the_publication_file.bpx.json

Without --bpx the file is downloaded from the publication repository.
"""

from __future__ import annotations

import argparse
import copy
import json
import tempfile
import urllib.request
from pathlib import Path

import bpx
import numpy as np
import pybamm

SCHMITT_COMMIT = "51092701d66b8dcaa88febaa132ff877f7ebc6db"
SCHMITT_URL = (
    "https://raw.githubusercontent.com/BattMoTeam/"
    "schmitt-2026-lnmo-graphite-hydra-publication/"
    f"{SCHMITT_COMMIT}/parameters/"
    "IMP5-70-120-H0B_graphite-lnmo_schmitt-2026_validation.bpx.json"
)
CURRENTS_A = [0.05, 0.2, 0.5, 1.0, 2.0]
UNIFORM_BRUGGEMAN = 1.5
REGIONS = ("Negative electrode", "Separator", "Positive electrode")
OUTPUT_PERIOD_S = 10.0
MESH_POINTS = 20


def current_label(current_a: float) -> str:
    return f"{current_a:g}".replace(".", "p")


def load_bpx_dict(path: Path) -> dict:
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def uniform_variant(original: dict) -> dict:
    """Copy of the parameter set with Transport efficiency = Porosity ** 1.5 in every region."""
    variant = copy.deepcopy(original)
    parameterisation = variant["Parameterisation"]
    for region in REGIONS:
        section = parameterisation[region]
        section["Transport efficiency"] = section["Porosity"] ** UNIFORM_BRUGGEMAN
    header = variant["Header"]
    header["Description"] = (
        header.get("Description", "")
        + f" Variant with a uniform Bruggeman exponent of {UNIFORM_BRUGGEMAN} in all regions."
    )
    return variant


def run_discharge(
    parameter_values: pybamm.ParameterValues,
    current_a: float,
    *,
    rtol: float = 1e-6,
    atol: float = 1e-6,
) -> dict:
    """Constant current discharge from the initial state until the lower voltage cut-off."""
    parameters = parameter_values.copy()
    parameters.update({"Current function [A]": current_a})
    model = pybamm.lithium_ion.DFN({"thermal": "isothermal"})
    solver = pybamm.CasadiSolver(mode="safe", rtol=rtol, atol=atol)
    var_pts = dict.fromkeys(["x_n", "x_s", "x_p", "r_n", "r_p"], MESH_POINTS)
    simulation = pybamm.Simulation(
        model, parameter_values=parameters, solver=solver, var_pts=var_pts
    )
    capacity_ah = parameters["Nominal cell capacity [A.h]"]
    duration_s = 1.5 * 3600.0 * capacity_ah / current_a
    t_eval = np.arange(0.0, duration_s + OUTPUT_PERIOD_S, OUTPUT_PERIOD_S)
    solution = simulation.solve(t_eval=t_eval)
    if solution.termination != "event: Minimum voltage [V]":
        raise RuntimeError(
            f"The {current_a} A discharge ended with '{solution.termination}' "
            "instead of reaching the lower voltage cut-off."
        )
    return {
        "time_s": solution["Time [s]"].entries,
        "voltage_v": solution["Voltage [V]"].entries,
        "current_a": solution["Current [A]"].entries,
        "termination": solution.termination,
    }


def write_csv(path: Path, result: dict) -> None:
    with path.open("w", encoding="utf-8", newline="") as f:
        f.write("Time [s],Voltage [V],Current [A]\n")
        for t, v, i in zip(result["time_s"], result["voltage_v"], result["current_a"]):
            f.write(f"{t:.6f},{v:.9f},{i:.9f}\n")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--bpx", type=Path, default=None, help="BPX file; downloaded from the publication repository when omitted")
    parser.add_argument("--out-dir", type=Path, default=Path(__file__).resolve().parent)
    parser.add_argument("--currents", type=float, nargs="+", default=CURRENTS_A, help="discharge currents in A")
    args = parser.parse_args()

    out_dir: Path = args.out_dir
    out_dir.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory() as tmp:
        tmp_dir = Path(tmp)
        if args.bpx is None:
            bpx_path = tmp_dir / "schmitt_2026.bpx.json"
            print(f"Downloading {SCHMITT_URL}")
            urllib.request.urlretrieve(SCHMITT_URL, bpx_path)
            source = SCHMITT_URL
        else:
            bpx_path = args.bpx
            source = str(bpx_path)

        original = load_bpx_dict(bpx_path)
        original.pop("Validation", None)
        variants = {"original": original, "uniform": uniform_variant(original)}

        summary = {
            "source": source,
            "pybamm_version": pybamm.__version__,
            "bpx_version": bpx.__version__,
            "mesh_points": MESH_POINTS,
            "output_period_s": OUTPUT_PERIOD_S,
            "uniform_bruggeman_exponent": UNIFORM_BRUGGEMAN,
            "cases": [],
        }
        for name, variant in variants.items():
            variant_path = tmp_dir / f"{name}.bpx.json"
            with variant_path.open("w", encoding="utf-8") as f:
                json.dump(variant, f)
            parameter_values = pybamm.ParameterValues.create_from_bpx(str(variant_path), target_soc=1.0)
            for current_a in args.currents:
                result = run_discharge(parameter_values, current_a)
                csv_path = out_dir / f"pybamm_schmitt2026_{name}_{current_label(current_a)}A.csv"
                write_csv(csv_path, result)
                summary["cases"].append(
                    {
                        "variant": name,
                        "current_a": current_a,
                        "file": csv_path.name,
                        "end_time_s": float(result["time_s"][-1]),
                        "final_voltage_v": float(result["voltage_v"][-1]),
                        "termination": result["termination"],
                    }
                )
                print(f"{name:8s} {current_a:5.2f} A: {len(result['time_s'])} points, ended at {result['time_s'][-1]:.1f} s -> {csv_path.name}")

    summary_path = out_dir / "pybamm_schmitt2026_summary.json"
    summary_path.write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(f"Wrote {summary_path}")


if __name__ == "__main__":
    main()
