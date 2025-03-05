# PXD model

In the following, all the symbols that are not introduced directly in the text are collected in the table at the end of
the page

The mass and charge conservation in the electrolyte are given by
```math
\begin{aligned}
  \frac{\partial }{\partial t}(\varepsilon_\text{elyte} c_\text{elyte}) + \nabla\cdot \textbf{N}_{\text{elyte}} &=  R_{\text{elyte}},\\
  \nabla\cdot \textbf{j}_{\text{elyte}} &= FR_{\text{elyte}},
\end{aligned}
```
where the fluxes are given by
```math
\begin{aligned}
  \textbf{j}_\text{elyte}   &= -\kappa_{\text{elyte},\text{eff}}\nabla\phi_\text{elyte} - \kappa_{\text{elyte},\text{eff}}\frac{1 - t_+}{z_+F}\left(\frac{\partial \mu}{\partial c}\right)\nabla c_\text{elyte},\\
  \textbf{N}_{\text{elyte}} &= - D_{\text{elyte},\text{eff}}\nabla c_{\text{elyte}} + \frac{t_+}{z_+F}\textbf{j}_\text{elyte}.
\end{aligned}
```
The volumetric reaction rate is given as ``R_\text{elyte} = -\sum_\text{elde} \gamma_\text{elde} R_\text{elde}`` where ``\gamma_{\text{elde}}`` is the volumetric surface area and the expression for ``R_\text{elde}`` is given below. Note that the reaction rates depends on the spatial variable ``x``. For the chemical potential, we use ``\mu = 2RT\log(c_\text{elyte})``. The effective quantities are computed from the intrinsic properties and the volume fraction using a Bruggemann coefficient, denoted ``b``, which yields ``\kappa_{\text{elyte},\text{eff}} = \varepsilon_\text{elyte}^{b}\kappa_{\text{elyte}}`` and ``D_{\text{elyte},\text{eff}} = \varepsilon_\text{elyte}^{b}D_{\text{elyte}}``. For the electrolyte, we have a spatially dependent Bruggeman coefficient.

In the electrode, the charge conservation equation is given by
```math
  -\nabla\cdot (\kappa_{\text{elde}, \text{eff}} \nabla \phi_\text{elde}) = F\gamma_\text{elde} R_{\text{elde}}.
```
We use a pseudo particle model for ``c_\text{elde}(t, x, r)``
```math
\frac{\partial }{\partial t}c_\text{elde} - \frac1{r^2}\frac{\partial }{\partial r}(r^2D_\text{elde}\frac{\partial }{\partial r} c_\text{elde}) = 0.
```
with boundary condition
```math
- 4\pi r_p^2 D_\text{elde} \frac{\partial c_\text{elde}}{\partial r}(t, x, r_p) = \frac{\gamma_\text{elde} R_\text{elde}}{\varepsilon_\text{elde}}\frac{4\pi r_p^3}{3}.
```

Reaction kinetics. The reaction rate ``R_\text{elde}`` at each electrode is given
```math
R_\text{elde} = j_{\text{elde}}(c_\text{elde}, c_\text{elyte}, T)(e^{\alpha F\frac{\eta_\text{elde}}{RT}} - e^{-(1 - \alpha) F\frac{\eta_\text{elde}}{RT}} ) .
```
where ``\eta_\text{elde}`` and ``j_\text{elde}`` denote the overpotential and the reaction exchange current density. The overpotential
``\eta_\text{elde}`` is given by
```math
\eta_\text{elde} = \phi_\text{elde} - \phi_\text{elyte} - U_\text{elde}(c_\text{elde}, T).
```
where ``U_\text{elde}`` denotes the open circuit potential, given as a function of the Lithium concentration in the electrode
and the temperature.  The exchange current density is given by
```math
  j_\text{elde} = k_{\text{elde},0} e^{-\frac{E_a}{R}(1/T - 1/T_{\text{ref}})}\left(c_\text{elyte}(c_{\text{elde},\max} - c_\text{elde})c_\text{elde}\right)^{\frac12}.
```

| Symbol                                      | Definition                                      |
|---------------------------------------------|-------------------------------------------------|
| ``c_\text{elyte}``, ``c_\text{elde}``       | Lithium concentration in electrolyte, electrode |
| ``\phi_\text{elyte}``, ``\phi_\text{elde}`` | Electrolyte potential in electrolyte, electrode |
| ``T``                                       | Temperature                                     |
| ``t_+``                                     | Transference number                             |
| ``z_+``                                     | Charge number                                   |
| ``F``                                       | Faraday coefficient                             |
| ``r_p``                                     | Particle radius                                 |
| ``R_\text{elde}``                           | Reaction rate at electrode                      |
| ``\gamma_\text{elde}``                      | Volumetric surface area                         |
| ``k_{\text{elde}, 0}``                      | Reaction rate constant                          |
| ``\varepsilon_\text{elde}``                 | Volume fraction electrode                       |
| ``\varepsilon_\text{elyte}``                | Volume fraction electrolyte                     |
| ``E_q``                                     | Activation energy of reaction                   |
| ``R``                                       | Ideal gas constant                              |
