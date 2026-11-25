# [OCP hysteresis](@id ocp_hysteresis)

The open-circuit potential of many electrode materials, graphite among them, is not the same
after lithiation and after delithiation: after a charge a cell rests at a higher voltage than
after a discharge to the same state of charge. BattMo models this with the one-state
hysteresis model of PyBaMM [sulzer2021](@cite) ("one-state hysteresis", after [axen2022](@cite)), for each electrode
whose active material gives two OCP branches.

## Model

The open-circuit potential of the electrode is a blend of its lithiation and delithiation
branches, weighted by a hysteresis state `h` in [-1, 1] in each electrode cell:

```text
U = (1 + h) / 2 * U_delith(theta_s, T) + (1 - h) / 2 * U_lith(theta_s, T)
dh/dt = gamma * r * (1 - sign(r) * h) / 2
```

Here `theta_s` is the surface stoichiometry, `r = i_vol / (F * c_max * eps_s)` the rate of
change of the stoichiometry by the interfacial current density `i_vol` (positive on
delithiation), and `gamma` the decay rate: `gamma_delith` on delithiation, `gamma_lith` on
lithiation, each a constant or a function of the surface stoichiometry. `h = 1` is the
delithiation branch, `h = -1` the lithiation branch.

- At rest `h` does not change: the electrode stays on the branch it came from.
- After a reversal, the distance to the new branch falls as `exp(-gamma * |dtheta| / 2)`
  with the change of stoichiometry `dtheta`, not with time.
- The entropy change, if used, is added to the blended OCP as to the single OCP.

BattMo integrates the law with the implicit Euler step of the simulation, in each electrode
cell, with `dtheta` the change of the cell's mean particle stoichiometry over the step. By the
particle mass balance this equals `r * dt`. Each step is a convex combination of the previous
`h` and the branch of the current direction, so `h` stays in [-1, 1] for any time step.

## Input

The model setting switches the model on:

```json
"ModelSettings": { "OCPHysteresis": "OneState" }
```

An electrode then has hysteresis if its `ActiveMaterial` gives both branches. The two branches
and the two decay rates take the forms of `OpenCircuitPotential`: a constant, a table of the
stoichiometry, an expression of `c`, `T`, `refT` and `cmax`, or a Julia function with these
arguments.

| Key (ActiveMaterial) | Meaning |
|:--|:--|
| `OpenCircuitPotentialLithiation` | Lithiation branch of the OCP [V] |
| `OpenCircuitPotentialDelithiation` | Delithiation branch of the OCP [V] |
| `HysteresisDecayRateLithiation` | Decay rate on lithiation [-] |
| `HysteresisDecayRateDelithiation` | Decay rate on delithiation [-] |

`OpenCircuitPotential` stays required. With hysteresis it is used only by tools that need an
equilibrium OCP, such as the equilibrium calibration.

The initial hysteresis state of each electrode is part of the cycling protocol, as the initial
state of charge, and is 0, the mean of the branches, if not given:

| Key (CyclingProtocol) | Meaning |
|:--|:--|
| `InitialHysteresisStateNegativeElectrode` | `h` of the negative electrode at the start, in [-1, 1] |
| `InitialHysteresisStatePositiveElectrode` | `h` of the positive electrode at the start, in [-1, 1] |

The initial electrode potentials are those of the blended OCP at this state. A simulation
started from a stored state continues with the hysteresis state of that state.

The model needs the full solid diffusion model (`TransportInSolid = "FullDiffusion"`), and
can be combined with the SEI model. BPX parameter sets with OCP hysteresis are converted as
described in [BPX parameter sets](@ref bpx_functions).

## Output

The hysteresis state of each electrode cell is a state variable,
`NegativeElectrodeActiveMaterialHysteresisState` and `PositiveElectrodeActiveMaterialHysteresisState`;
`...OpenCircuitPotential` is the blended OCP. The voltage breakdown evaluates the average OCV on
the branches at the hysteresis state.
