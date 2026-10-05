# Solid Electrolyte Interphase (SEI)

The negative-electrode P2D SEI model follows
[Bolay et al.](https://doi.org/10.1016/j.powera.2022.100083). It couples film growth to
irreversible lithium consumption and charge conservation. Particle geometry, reactive
surface area, and phase volume fractions remain fixed; solvent depletion and porosity
changes are not represented.

## Growth and lithium consumption

The lithium consumption flux `N` is positive into SEI and has units mol/(m^2 s):

```text
eta_sei = phi_s - phi_e - U_sei
N_raw = De * ce0/L * exp(-F*eta_sei/(R_gas*T)) * (1 - F*U_sei/(2*R_gas*T))
N = max(N_raw, 0)
(s/V_m) * dL/dt = N
```

Here `De` is `ElectronicDiffusionCoefficient`, `ce0` is `InterstitialConcentration`, `L`
is physical film thickness, `T` is temperature, and `V_m` is `MolarVolume` of SEI product.
`StoichiometricCoefficient`, denoted `s`, is the number of moles of lithium consumed per
mole of SEI product. It is not an electrode state of charge. `N` already counts lithium,
so consumption and current do not receive another factor of `s`.

The nonnegative branch prevents the approximate migration term from dissolving SEI.
It is continuous but not differentiable where the raw flux switches sign. Derivatives
for calibration are evaluated on the active branch, without an artificial smoothing
parameter. Growth and consumption use the same flux at the current implicit iterate.

Let `R` be the intercalation flux, positive when lithium leaves a particle. The currents
per interface area are:

```text
j_intercalation = F*R
j_sei = -F*N
j_total = F*(R - N)
```

The electrolyte receives a net lithium source `a_s*(R - N)`, where `a_s` is reactive area
per bulk electrode volume. Both charge equations use the total current with opposite
signs. The electrolyte migration flux is already included in its mass equation; no extra
`(1 - t_plus)` factor belongs in the reaction cross term.

Particle diffusion still uses `R` alone. At open circuit, particles can release lithium
that feeds SEI growth while the net external current remains zero. Adding a separate
particle consumption sink would count that loss twice.

## Film resistance and inputs

The ionic film drop uses the intercalation current crossing the film:

```text
U_sei = F*R*L/IonicConductivity
eta_intercalation = phi_s - phi_e - OCP - U_sei
```

`InitialThickness`, `MolarVolume`, `StoichiometricCoefficient`, `IonicConductivity`, and
`InitialPotentialDrop` must be finite and positive. The growth prefactors must be finite
and nonnegative. Setting either growth prefactor to zero disables consumption and growth
while retaining the initial film resistance.

The parameter metadata uses `min_value` for an inclusive lower bound (`x >= bound`)
and `exclusive_min_value` for a strict lower bound (`x > bound`). The schema generator
maps these fields to JSON Schema `minimum` and `exclusiveMinimum`, respectively.
For `StoichiometricCoefficient` and `InitialPotentialDrop`,
`"exclusive_min_value" => 0.0` excludes zero. When both lower bounds are present, both
constraints apply. These fields describe validation rules in BattMo's metadata; users
do not add them to cell parameter inputs.

`InitialPotentialDrop` is the normalization scale of `NormalizedSEIVoltageDrop`. The
fresh state starts with zero physical drop; the algebraic voltage equation determines
its value during the solve. This parameter is not an imposed initial resistance offset.
Thickness is normalized by `InitialThickness`, with a small positive numerical lower
bound to keep the growth law defined during Newton updates.

For disabled growth, the SEI mass-equation tolerance uses the initial film lithium
inventory per area divided by one hour as a positive numerical reference. This changes
only the tolerance scale, not the zero physical flux. Explicit solver tolerances override
the default model scales. Tighten charge, mass, and SEI tolerances together when resolving
small inventory losses against much larger cycling currents.

## Inventory and restarting

Use the raw Jutul states with the fixed BOL baseline:

```julia
baseline = deepcopy(sim.initial_state)
output = solve(sim)
inventory = compute_lithium_inventory(
    sim, output.jutul_output.states[end]; baseline_state = baseline,
)
```

`compute_lithium_inventory` returns `negative`, `positive`, `electrolyte`, `sei_added`,
`mobile`, and `total` in mol, and `sei_loss_ah` in Ah. Particle inventory uses radial shell
volume weights and the actual active-material fraction. Electrolyte inventory uses its
pore volume. For fixed interface area `A` in each negative-electrode cell:

```text
sei_added = sum(cells, A*s/V_m * (L - L_BOL))
mobile = negative + positive + electrolyte
total = mobile + sei_added
sei_loss_ah = F*sei_added/3600
```

The accounted `total` must remain constant in a closed cell. The pre-existing SEI at BOL
is excluded from this incremental accounting: the calibrated BOL electrode concentrations
already describe the formed cell. Do not subtract that historical consumption again.

Carry the full physical state through the existing `initial_state` restart path, using
`output_all_secondary_variables = true` when constructing simulations whose final states
will be reused. Preserve the same mesh, normalization parameters, and original
`baseline_state` across blocks. Protocol time may restart; the BOL inventory reference
must not. Initializing each aged RPT from the original SOC endpoints loses the accumulated
change in electrode balance.

For a discrete balance audit, integrate the kinetic flux at every accepted backward-Euler
endpoint, including the first interval from the initial state. Compare that independent
integral with the thickness-derived `sei_added`. Use `output_substates = true` to retain
accepted substeps, omit rejected steps, and avoid counting restart boundaries twice.

`sei_loss_ah` is an inventory diagnostic, not a direct prediction of delivered RPT
capacity. Simulate the RPT preparation and discharge to cutoff to obtain delivered
capacity. Check the voltage effect of enabling the initial film separately, because it
can alter an existing BOL fit even before additional lithium is consumed.
