# 📈 Ramp-Up Model

## Overview

In battery cell simulations, **current ramping** is an essential strategy to prevent non-physical transients and numerical instability that can arise from abrupt current steps. Applying a current instantaneously can introduce high-frequency artifacts or convergence issues in certain electrochemical and thermal models. To avoid this, a smooth transition from 0 to the target current is often applied, known as a *ramp-up*.

---

## Why Use a Ramp-Up?

- **Physical realism**: In real-world systems, power electronics and control loops rarely apply a step input instantly. A ramp reflects this behavior more accurately.
- **Numerical stability**: Sudden changes in current can lead to instability or oscillations in the solver, particularly for tightly coupled electrochemical-thermal systems.

---

## Implementation in the Simulation

Our implementation uses a **sinusoidal ramp function**, providing a smooth, differentiable curve that avoids sharp discontinuities.
The user can choose to use the ramp up function in their simulation by setting the following model setting:

```JSON
{"UseRampUp": "Sinusoidal"}
``` 