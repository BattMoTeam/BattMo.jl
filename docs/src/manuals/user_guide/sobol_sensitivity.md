# Sobol sensitivity analysis

A global sensitivity analysis tells which input parameters drive the variation of a simulated quantity when the parameters are uncertain. BattMo computes variance-based Sobol indices [sobol2001](@cite) of scalar quantities of a simulation, such as the delivered energy or the generated heat, with respect to scalar cell parameters. Unlike a local sensitivity (a derivative at one point), Sobol indices account for the full range of each parameter and for interactions between parameters.

The workflow follows the calibration API: create a [`SobolSensitivity`](@ref) from a [`Simulation`](@ref), free the parameters to vary, and call `solve`. Two estimation methods are available:

- `:saltelli` (default): Monte Carlo estimators on the Saltelli sampling scheme [saltelli2010](@cite). They make no assumption on how the quantities depend on the parameters, but need many simulations.
- `:pce`: a polynomial chaos expansion (PCE) [sudret2008](@cite), a polynomial surrogate of the quantities fitted to the simulations, from which the indices follow analytically. It needs far fewer simulations when the quantities depend smoothly on the parameters.

A complete, runnable study that compares both methods is given in the [Sobol sensitivity example](../../examples/example_sobol.md).

## Sobol indices

Let ``Y = f(X_1, \dots, X_d)`` be a scalar quantity of the simulation and let the parameters ``X_i`` be independent random variables. The variance of ``Y`` can be split into contributions from single parameters and from groups of interacting parameters. BattMo reports two indices per parameter and quantity:

- The **first-order index** is the fraction of the variance explained by ``X_i`` alone,

```math
S_i = \frac{\operatorname{Var}\left(\mathbb{E}[Y \mid X_i]\right)}{\operatorname{Var}(Y)}.
```

- The **total-order index** is the fraction of the variance that involves ``X_i``, including all its interactions with the other parameters,

```math
S_{T,i} = \frac{\mathbb{E}\left[\operatorname{Var}(Y \mid X_{\sim i})\right]}{\operatorname{Var}(Y)},
```

  where ``X_{\sim i}`` denotes all parameters except ``X_i``.

Both indices lie in ``[0, 1]`` and ``S_i \le S_{T,i}``. How to read them:

- A parameter with a small ``S_{T,i}`` has no influence on the quantity within its bounds and can be fixed at its nominal value, for example before a calibration.
- A large gap ``S_{T,i} - S_i`` means that the effect of the parameter depends on the values of other parameters.
- If ``\sum_i S_i`` is close to one, the quantity is close to additive in the parameters.

The indices depend on the chosen bounds. Widening the range of one parameter increases its share of the variance at the expense of the others, so the bounds should reflect the actual uncertainty of each parameter.

## Usage

### Setting up the analysis

```julia
using BattMo

cell_parameters = load_cell_parameters(; from_default_set = "chen_2020")
cycling_protocol = load_cycling_protocol(; from_default_set = "cc_discharge")
model = LithiumIonBattery()
sim = Simulation(model, cell_parameters, cycling_protocol)

sa = SobolSensitivity(sim)
```

`SobolSensitivity` stores a deep copy of the simulation, so the original `sim` can be reused.

### Selecting parameters

A parameter is identified by its path in the cell parameters, as for calibration. Each free parameter needs a lower and an upper bound, and its nominal value in the cell parameters must lie within them:

```julia
free_sensitivity_parameter!(sa, ["NegativeElectrode", "ActiveMaterial", "DiffusionCoefficient"];
    lower_bound = 1e-14, upper_bound = 1e-13, scaling = :log)
free_sensitivity_parameter!(sa, ["Electrolyte", "BruggemanCoefficient"];
    lower_bound = 1.3, upper_bound = 2.0)
```

Parameters are sampled independently and uniformly between their bounds:

- `scaling = :linear` (default) samples ``p`` uniformly in ``[p_\text{min}, p_\text{max}]``.
- `scaling = :log` samples ``\log_{10} p`` uniformly, which suits parameters that span several orders of magnitude, such as diffusion coefficients and reaction rate constants. The lower bound must be positive.

Only scalar parameters can be varied. Functional parameters, such as an OCP or a concentration-dependent conductivity given as a function or table, cannot be selected. A parameter is removed again with [`freeze_sensitivity_parameter!`](@ref), and [`print_sensitivity_overview`](@ref) prints the free parameters, their bounds and scaling, and the quantities.

### Selecting quantities

`sa.quantities` is a dictionary from a name to a function `f(output::SimulationOutput) -> Float64`. The defaults, from [`default_sobol_quantities`](@ref), are:

| Name | Definition | Unit |
| --- | --- | --- |
| `Energy` | Energy throughput ``\int V\,\lvert I \rvert\,\mathrm{d}t`` | Wh |
| `Power` | Energy throughput divided by the time with nonzero current | W |
| `Heat` | Generated irreversible heat, see [Heat generation](@ref sobol_heat) | Wh |

These definitions assume a single charge or discharge. For a cycling protocol, or for any other quantity, add or replace entries:

```julia
sa.quantities["PeakHeatRate"] = output -> maximum(compute_heat_generation(output).rate)
sa.quantities["Capacity"] = output -> output.metrics["DischargeCapacity"][end]
delete!(sa.quantities, "Power")
```

A quantity function that throws an error gives `NaN` for that sample, which is treated as a failed sample (see below).

### Running the analysis

```julia
result = solve(sa; N = 64)                         # Saltelli, 64 * (d + 2) simulations
result_pce = solve(sa; method = :pce, degree = 3)  # PCE, 2 * binomial(d + 3, 3) simulations
print_sensitivity_overview(sa)
```

The main keyword arguments of [`solve(sa::SobolSensitivity)`](@ref) are:

| Keyword | Default | Description |
| --- | --- | --- |
| `method` | `:saltelli` | `:saltelli` or `:pce`, see [Choosing a method](@ref sobol_choosing). |
| `N` | see description | `:saltelli`: number of base samples (default `64`), giving ``N(d+2)`` simulations. `:pce`: number of simulations (default twice the number of basis polynomials). |
| `degree` | `3` | Total degree of the PCE (`:pce` only). |
| `bootstrap` | `100` | Number of bootstrap resamples for the confidence intervals. `0` skips them. |
| `confidence` | `0.95` | Level of the confidence intervals. |
| `rng` | `Random.default_rng()` | Random number generator for sampling and bootstrapping. Pass a seeded generator, e.g. `Random.Xoshiro(42)`, for reproducible results. |
| `sampler` | `nothing` | Custom generator of the samples, see [Quasi-random sampling](@ref sobol_sampler). |
| `solver_settings` | model defaults | Solver settings used for every simulation. |
| `parallel` | `Threads.nthreads() > 1` | Run the simulations on all Julia threads. |
| `info_level` | `0` | Print progress when `>= 0`. |

The result is returned as a [`SobolResult`](@ref) and also stored in `sa.result`, which each call overwrites. The returned results are independent, so the results of both methods can be kept side by side.

### [Choosing a method](@id sobol_choosing)

| | `:saltelli` | `:pce` |
| --- | --- | --- |
| Simulations | ``N(d+2)``, typically hundreds to thousands | ``2\binom{d+p}{p}`` by default, e.g. 112 for ``d = 5``, ``p = 3`` |
| Assumptions on the quantity | None | Well approximated by a polynomial of degree ``p`` |
| Error | Monte Carlo, ``\propto 1/\sqrt{N}`` | Truncation of the polynomial, plus sampling error of the fit |
| Accuracy check | Width of the bootstrap intervals | Leave-one-out ``Q^2``, and the bootstrap intervals |
| Failed simulations | Drop their base sample (``d + 2`` simulations) | Drop only themselves |

Integral quantities of a charge or discharge, such as the energy or the generated heat, usually depend smoothly on transport and kinetic parameters within moderate bounds, and the PCE then reaches a given accuracy with far fewer simulations. The Saltelli scheme is the safer choice for quantities with kinks or jumps, and as a reference to verify a PCE. Typical non-smooth quantities are maxima over time, such as a peak heat generation rate (the time of the peak can jump from one part of the discharge to another), and quantities of discharges that end erratically, for example when strong electrolyte depletion makes the end of the discharge sensitive to small parameter changes. Note that such behaviour also affects the Saltelli estimates, which then attribute variance to the parameters that is caused by the non-smooth response; plotting the samples (see the [example](../../examples/example_sobol.md)) helps to spot it. A low ``Q^2`` (a warning is printed below 0.9) shows that the polynomial does not represent the quantity well, and that the PCE indices should not be trusted.

The PCE needs ``\binom{d+p}{p}`` coefficients, which grows quickly with the number of parameters and the degree: 56 for ``d = 5, p = 3``, 286 for ``d = 10, p = 3`` and 1771 for ``d = 20, p = 3``. For many parameters, use a low degree or screen out unimportant parameters first.

## Implementation

Both methods sample the parameters in the unit cube ``[0, 1]^d``. Each point is mapped to physical parameter values according to the bounds and scaling of each parameter, the values are written into a copy of the cell parameters, and a new simulation is set up and solved with logging switched off. The cost is dominated by the simulations; the estimators themselves take a negligible time.

### Saltelli scheme

The indices are estimated with the Saltelli sampling scheme [saltelli2010](@cite). Two independent ``N \times d`` matrices ``A`` and ``B`` of points in the unit cube are drawn. For each parameter ``i``, the matrix ``A_B^{(i)}`` equals ``A`` with column ``i`` taken from ``B``. The quantities are evaluated at all rows of ``A``, ``B`` and the ``d`` matrices ``A_B^{(i)}``, which requires

```math
N\,(d + 2)
```

simulations. The cost grows linearly with both `N` and the number of parameters. Timing one simulation of the base case before starting the analysis gives a good estimate of the total cost; the example shows how. Simulations near the parameter bounds can take longer than the base case.

With ``f_A``, ``f_B`` and ``f_{A_B^{(i)}}`` the quantity values at the rows of the respective matrices, and ``V`` the sample variance of all values in ``f_A`` and ``f_B``, the indices are estimated as

```math
S_i \approx \frac{1}{V}\,\frac{1}{N}\sum_{j=1}^{N} \tilde f_B^{(j)} \left(f_{A_B^{(i)}}^{(j)} - f_A^{(j)}\right),
\qquad
S_{T,i} \approx \frac{1}{V}\,\frac{1}{2N}\sum_{j=1}^{N} \left(f_A^{(j)} - f_{A_B^{(i)}}^{(j)}\right)^2,
```

using the first-order estimator of Saltelli et al. [saltelli2010](@cite) and the total-order estimator of Jansen [jansen1999](@cite). In the first-order estimator, ``\tilde f_B = f_B - \bar f`` is centred by the mean of all values in ``f_A`` and ``f_B``. Centring does not change the expected value of the estimator but strongly reduces its variance for quantities with a large mean compared to their spread, which is typical for battery quantities such as the energy of a discharge.

These are Monte Carlo estimates. With small `N`, they can fall slightly outside ``[0, 1]``, and ``S_i`` can exceed ``S_{T,i}`` for parameters with little influence.

The confidence intervals are computed by bootstrapping: the ``N`` base samples (each with its ``d + 2`` values) are resampled with replacement `bootstrap` times, the indices are recomputed for each resample, and the interval is given by the empirical quantiles at ``(1 - \text{confidence})/2`` and ``(1 + \text{confidence})/2``. Wide intervals mean that `N` must be increased. In practice, rankings of the most influential parameters are often stable at moderate `N`, while small indices need many more samples to be resolved.

### [Quasi-random sampling](@id sobol_sampler)

By default, ``A`` and ``B`` are uniform random samples. Quasi-random (low-discrepancy) sequences usually converge faster. They can be used through the `sampler` keyword, a function `(N, d, rng) -> (A, B)` that returns two ``N \times d`` matrices with values in ``[0, 1]``. A common choice is to draw ``N`` points of a ``2d``-dimensional Sobol sequence and split the columns, for example with the [Sobol.jl](https://github.com/JuliaMath/Sobol.jl) package:

```julia
using Sobol

function sobol_sampler(N, d, rng)
    s = SobolSeq(2d)
    X = reduce(vcat, (next!(s)' for _ in 1:N))
    return X[:, 1:d], X[:, (d + 1):end]
end

result = solve(sa; N = 64, sampler = sobol_sampler)
```

Use a power of two for `N` with Sobol sequences. With `method = :pce`, the sampler is called in the same way and only ``A`` is used.

### Polynomial chaos expansion

A PCE approximates a quantity as a sum of polynomials in the parameters [sudret2008](@cite). With ``u \in [0, 1]^d`` the parameters in the unit cube (in `log10` space for `:log` scaling), the expansion of total degree ``p`` is

```math
Y \approx \sum_{\alpha \in \mathcal{A}} c_\alpha \Psi_\alpha(u),
\qquad
\Psi_\alpha(u) = \prod_{i=1}^{d} \psi_{\alpha_i}(u_i),
\qquad
\mathcal{A} = \Big\{\alpha \in \mathbb{N}^d : \sum_i \alpha_i \le p\Big\},
```

where ``\psi_n`` is the Legendre polynomial of degree ``n``, shifted to ``[0, 1]`` and scaled to be orthonormal for the uniform distribution, ``\mathbb{E}[\psi_m \psi_n] = \delta_{mn}``. The basis has ``P = \binom{d+p}{p}`` polynomials.

**Sampling and fit.** By default, the ``N`` points are a Latin hypercube sample, which places exactly one point in each of the ``N`` equal intervals of every parameter. The coefficients are fitted by least squares (with a column-pivoted QR factorisation), which requires ``N > P``; the default ``N = 2P`` is a common choice.

**Sobol indices.** Because the basis is orthonormal, the mean of the surrogate is ``c_0`` and its variance splits exactly over the coefficients, ``V = \sum_{\alpha \neq 0} c_\alpha^2``. The variance explained by parameter ``i`` alone comes from the polynomials that depend on ``u_i`` only, and the total variance involving ``u_i`` from all polynomials that depend on ``u_i``:

```math
S_i = \frac{1}{V} \sum_{\alpha \in \mathcal{A}_i} c_\alpha^2,
\quad
\mathcal{A}_i = \{\alpha : \alpha_i > 0,\ \alpha_j = 0 \ \forall j \neq i\},
\qquad
S_{T,i} = \frac{1}{V} \sum_{\alpha : \alpha_i > 0} c_\alpha^2.
```

These are the exact Sobol indices of the surrogate, so they always lie in ``[0, 1]`` and satisfy ``S_i \le S_{T,i}``. Their accuracy is that of the surrogate.

**Accuracy.** The fit is checked with the leave-one-out coefficient of determination [blatman2010](@cite)

```math
Q^2 = 1 - \frac{\frac{1}{N}\sum_{j} \left(\frac{y_j - \hat y(u_j)}{1 - h_j}\right)^2}{\operatorname{Var}(y)},
```

where ``\hat y`` is the fitted PCE and ``h_j`` the leverage of point ``j`` (the diagonal of the hat matrix). The ratio in the sum is the prediction error at point ``j`` of the PCE fitted without that point, computed from a single fit. ``Q^2`` close to one means that the PCE predicts unseen simulations well. ``Q^2`` per quantity is stored in `result.pce.q2` and printed in the table titles. A low ``Q^2`` means either overfitting (too few simulations for the degree; add simulations or lower the degree) or a quantity that is not smooth enough for a polynomial (raise the degree, or use the Saltelli scheme).

**Confidence intervals.** The intervals are computed with a residual bootstrap: the residuals of the fit, scaled by ``1/\sqrt{1 - h_j}`` and centred, are resampled with replacement and added to the fitted values, the PCE is refitted to these values `bootstrap` times (reusing the QR factorisation), and the interval is given by the empirical quantiles of the indices. The intervals thus reflect how the misfit of the PCE propagates into the indices. Resampling the points themselves, as for the Saltelli scheme, is not used: a resample contains only about 63% distinct points, so with ``N \approx 2P`` every refit overfits and the intervals of small indices are biased upwards. The residual bootstrap does not capture the bias from truncating the expansion at degree ``p``, so the intervals are too narrow when the truncation error is not negligible. In a test on the Ishigami function with ``N = 2P``, the 95% intervals of the total-order indices contained the exact values in 75–90% of the repetitions for ``Q^2 \approx 0.97``-``0.999``, while the point resampling scheme gave intervals three to five times wider that missed the smallest index in most repetitions. The intervals are therefore only meaningful when ``Q^2`` is close to one.

The fitted expansion is stored in `result.pce` as `(degree, multi_indices, coefficients, q2)`, with the multi-indices ``\alpha`` as rows of `multi_indices` and one column of `coefficients` per quantity.

### Failed simulations

Some parameter combinations can make a simulation fail, for example when the solver does not converge or the cell reaches a cut-off immediately. A failed simulation returns `NaN` for every quantity, and a quantity function that throws returns `NaN` for that quantity. A warning reports the number of failed simulations.

With the Saltelli scheme, the estimators combine values from the same row of ``A``, ``B`` and every ``A_B^{(i)}``, so a base sample ``j`` is dropped for a quantity when any of its ``d + 2`` values is not finite. With the PCE, only the failed simulation itself is dropped from the fit. The number of samples used is reported per quantity in `result.n_valid` and in the printed table. If many samples fail, the remaining samples no longer cover the parameter space uniformly and the indices are biased; narrowing the bounds or adjusting the solver settings is then preferable. If too few samples remain (fewer than two base samples for `:saltelli`, at most ``P`` for `:pce`) or a quantity has zero variance, its indices are `NaN`.

### Parallel execution

With `parallel = true` (the default when Julia runs with several threads), the simulations are split into one chunk per thread. Each chunk works on its own copy of the model, since setting up a simulation modifies the model. Jutul's internal (Polyester) threading of the assembly is not safe to use from several tasks at once, so it is switched off while the simulations run in parallel; each simulation then runs on a single thread. Start Julia with `julia -t auto` to use all cores. The speed-up is usually lower than the number of threads; measure it on your machine for large studies.

### [Heat generation](@id sobol_heat)

The `Heat` quantity is computed with [`compute_heat_generation`](@ref), which returns the time series of the irreversible heat generation rate in W and its time integral in J. Reversible (entropic) heat is not included. Two methods are available:

- `:bernardi` (default) uses the energy balance of Bernardi et al. [bernardi1985](@cite),

```math
\dot Q = I\,\left(U_\text{ocv} - V\right),
```

  where ``U_\text{ocv}`` is the difference of the positive and negative electrode open-circuit potentials, evaluated at the volume-averaged particle concentration of each electrode. This is the total dissipated energy, including the energy stored in concentration gradients, which is released as heat when the cell relaxes. It is cheap and works for every geometry.

- `:source_terms` sums the ohmic, electrolyte diffusion and irreversible reaction heat sources of the BattMo thermal model over the domain. Energy stored in concentration gradients inside the particles is not included. This method evaluates all secondary variables at every report step and is much slower than the simulation itself.

The method used by the default quantities is chosen with `default_sobol_quantities(; heat_method = :source_terms)`. The time integrals use the trapezoidal rule over the report steps, with the rate at the first report step used for the first interval from time zero.

## Working with the result

A [`SobolResult`](@ref) holds:

- `parameter_names` and `quantity_names`, sorted alphabetically. Parameter paths are joined with `.`.
- `first_order` and `total_order`: matrices with one row per parameter and one column per quantity.
- `first_order_ci` and `total_order_ci`: `(lower, upper)` matrices of the same size, or `nothing` when `bootstrap = 0`.
- `samples` and `values`: the physical parameter values and the quantity values of all simulations, one row per simulation.
- `N` and `n_valid`.
- `method`: `:saltelli` or `:pce`.
- `pce`: the fitted expansion and its ``Q^2`` for `:pce`, otherwise `nothing`.

[`print_sobol_indices`](@ref) prints one table per quantity, sorted by total-order index. The stored samples can be reused without new simulations, for example for scatter plots of each quantity against each parameter, which show *how* a parameter acts where the indices show *how much*. The [example](../../examples/example_sobol.md) plots the indices, compares the two methods, and shows the scatter plots.

## Limitations

- Parameters are assumed independent and uniformly distributed (in linear or `log10` space). Correlated parameters or other distributions are not supported.
- Only scalar cell parameters can be varied; cycling protocol and simulation settings are fixed.
- Only first- and total-order indices are computed; second-order interaction indices are not.
- The PCE uses a full total-degree basis. Sparse or adaptive bases, which scale better to many parameters, are not implemented.
- The default quantities assume a single charge or discharge.
