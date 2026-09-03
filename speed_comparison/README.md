# BattMo.jl vs PyBaMM

Comparing [BattMo.jl](https://github.com/BattMoTeam/BattMo.jl) and [PyBaMM](https://github.com/pybamm-team/PyBaMM) on the same simulation: a 1C constant-current discharge of the Chen 2020 cell (LG INR21700 M50, graphite-SiOx negative electrode, NMC811 positive electrode) down to a 2.5 V cutoff. PyBaMM runs its DFN model; BattMo.jl runs the equivalent P2D `LithiumIonBattery` model. Electrolyte conductivity/diffusivity are overridden with matching polynomial fits on both sides so the two are solving as close to the same equations as practical.

Versions used: PyBaMM `26.8.0.0`, BattMo.jl `v0.2.9`, Julia `1.12.1`.

## Files

### Performance benchmark scripts
Timing was split into three regimes because they give materially different answers — see [Findings](#findings) below.

| File | Regime | What it measures |
|---|---|---|
| `pybamm_benchmark.py` / `battmo_benchmark.jl` | 1 — solve only | Simulation object built once; `solve()` timed over 5 repeats (1 untimed warm-up rep absorbs JIT/compilation first) |
| `pybamm_full_benchmark.py` / `battmo_full_benchmark.jl` | 2 — build + solve | A fresh simulation is built *and* solved every repeat, in an already-warm process |
| `pybamm_full_run.py` / `battmo_full_run.jl` | 3 — cold start | A single script invocation timed externally (`time python ...` / `time julia ...`), including package import/precompilation |
| `battmo_stepping_explore.jl` | — | Exploration of BattMo.jl's `TimeStepDuration` (report-step size) vs. speed and cutoff-detection accuracy |
| `compare_benchmark.jl` | — | Loads the result CSVs, prints the summary table, plots `results/benchmark_comparison.png` |

### Results
All in `results/`:
- `battmo_benchmark_times.csv`, `pybamm_benchmark_times.csv` — Tier 1 timings
- `battmo_full_benchmark_times.csv`, `pybamm_full_benchmark_times.csv` — Tier 2 timings
- `benchmark_comparison.png` — chart of Tier 1 timings


## Running the benchmarks

```bash
# Tier 1 — solve only
python pybamm_benchmark.py
julia --project=. battmo_benchmark.jl

# Tier 2 — build + solve
python pybamm_full_benchmark.py
julia --project=. battmo_full_benchmark.jl

# Tier 3 — cold start (note the external `time`)
time python pybamm_full_run.py
time julia --project=. battmo_full_run.jl

# Chart + summary of Tier 1
julia --project=. compare_benchmark.jl
```

`battmo_benchmark.jl` and `battmo_full_benchmark.jl` each run two BattMo.jl variants back to back: the **default** stepping (`TimeStepDuration = 50 s`, 84 report steps) and an **adapted**, coarser stepping (`TimeStepDuration = 100 s`, 44 report steps) — see the accuracy caveat below before treating "adapted" as a free win.

## Findings

No single number answers "which is faster" — it depends which part of the workflow is being timed.

| Workload | Winner | Margin |
|---|---|---|
| Repeated solves on one built model (e.g. an optimization loop re-solving the same object) | PyBaMM | up to 9.8x faster (BattMo.jl default stepping); 4.2x with coarser BattMo.jl stepping |
| Fresh simulation per run, warm process (e.g. a parameter sweep) | roughly tied | BattMo.jl default is 1.1x slower; BattMo.jl adapted stepping is 1.9x faster |
| One-shot script, cold process start | PyBaMM | 1.8x faster warm; 3.7x on the very first run after installing |

**Why**: PyBaMM's DFN runs on CasADi + Sundials IDA — a specialized, adaptive-step DAE integrator with a compiled symbolic Jacobian, honed for exactly this class of problem. BattMo.jl runs on Jutul, a general-purpose implicit finite-volume Newton solver built to scale to full 2D/3D multiphysics geometries, with a generic sparse AD Jacobian assembled every iteration and a *fixed* report-step schedule (a full Newton solve at every requested point, vs. PyBaMM choosing a few large adaptive steps and cheaply interpolating dense output). PyBaMM's cost concentrates in model build/discretization (0.27 s of its 0.30 s build+solve total); BattMo.jl's concentrates in JIT compilation on first use of a given code path plus per-step Newton/linear-solve work (linear solve alone was ~71% of per-step time in profiling).

**Stepping accuracy caveat**: BattMo.jl's constant-current protocol only checks the voltage cutoff at report-step boundaries — it rejects a step that crosses the limit (so it never overshoots past it) but never interpolates back toward the exact target, so it just stops one full report-step early. Effective cutoff error is bounded by the report-step size: ~0.03 V at dt=50s (t=3448.4s, V=2.526) vs. ~0.20 V at dt=100s (t=3396.9s, V=2.701), against a 2.5 V target. Coarsening the stepping for speed is a real, quantifiable accuracy trade-off, not a free win.

**Possible BattMo.jl improvements** (sourced from `BattMoTeam/BattMo.jl`):
1. **Precompilation misses the plain-CC code path.** `src/BattMo.jl`'s `@compile_workload` precompiles against `load_cycling_protocol(from_default_set="cccv")` (a `CyclingCVPolicy`), not the `CCPolicy` used by constant-current discharge (the `chen_2020` default and this benchmark). Since Julia specializes per concrete type, `CCPolicy`'s branches of `check_constraints()` compile cold on first real use — likely a meaningful chunk of the measured ~6-8 s first-solve JIT cost.
2. **Cutoff detection could interpolate instead of just stopping early** — a Sundials-style root-find/bisection on the step `check_constraints()` rejects would let coarse report-step schedules keep an accurate endpoint.
3. **The report-step schedule is flat, not adaptive.** `setup_timesteps()` builds `repeat([dt], n)` — Jutul's `TimestepSelector` only subdivides *within* a report step, never grows *across* the discharge. Letting the outer schedule itself coarsen through the flat middle and refine near the cutoff (like PyBaMM's IDA solver does natively) would close speed and accuracy gaps together instead of trading one for the other.
4. **A PackageCompiler.jl sysimage** would turn the ~14.5 s of JIT compilation (`Simulation()` + first `solve()`) into a one-time build cost for one-shot/CI/batch use cases.
5. **Worth profiling**: whether the direct linear solver's dominant per-step cost (~71%) is inherent to the problem size or a caching gap (e.g. symbolic factorization redone every step instead of reused across a constant sparsity pattern).

## Known methodology gaps

- **Spatial discretization isn't equalized.** PyBaMM's DFN defaults to 20 grid points per electrode/separator and 20 per particle. BattMo.jl's `p2d` default is 10 electrode-coating points, 3 separator points, 10 particle points — roughly half PyBaMM's resolution. Today's numbers therefore mix solver-architecture speed with each tool's default accuracy/cost choice.
- **Termination is event-based, not a fixed time series.** Both tools stop on a voltage-cutoff event rather than a shared, prescribed array of times/currents, which is what makes BattMo.jl's cutoff-detection accuracy trade-off (above) enter the comparison at all. A fixed-duration, no-event protocol on both sides would remove that confound, though PyBaMM's `t_eval` would still only control *where it reports/interpolates* output, not where its adaptive solver actually steps internally.
- **Environment**: this project's Python `.venv` and Julia `.julia_depot` both live inside a OneDrive-synced folder, which plausibly inflates every cold-start import/load number via file-sync overhead. The relative pattern (PyBaMM import-bound, BattMo.jl compile-bound) should hold regardless; the absolute seconds might shrink outside a synced folder.

## Full report

A shareable write-up with charts is published at: https://claude.ai/code/artifact/156c9efb-10e9-4001-9fd7-1301d5f56515
