# Doyle-Fuller-Newman model

On this page, we describe the different models available in BattMo for simulation a lithium ion battery cell. We have models available for simulating 1D and 3D geometries:
 - P2D: Pseudo-two-dimensional model
 - P4D Pouch: Pseudo-four-dimensional model for pouch cells
 - P4D Cylindrical: Pseudo-four-dimensional model for cylindrical cells

## P2D model

### Charge conservation in the electrode

In the solid particles that make up the electrodes, the charge conservation equation is given by
```math
  -\frac{\partial}{\partial x}\sigma_{\text{eff}} \frac{\partial}{\partial x} \phi_\text{s} = a_\text{s}Fj.
```

Here is ``\sigma_{\text{eff}}`` the effective conductivity of the electrode, ``\phi_\text{s}`` is the potential, ``a_\text{s}`` is the volumetric surface area (specific interfacial surface area) of the electrode, ``F`` is the Faraday constant, and ``j`` is the rate of lithium flux (reaction rate). This equation describes electron movement. It is a linear diffusion equation with a forcing term that models the flux of electrons. This flux is equal to the local flux of lithium from the electrode to the electrolyte.

The boundary conditions are:

```math
  \sigma^n_{eff}\frac{\partial}{\partial x}\phi^n_s\bigg\vert_{x=0} = \sigma^p_{eff}\frac{\partial}{\partial x}\phi^p_s
\bigg\vert_{x=L^{tot}} = \frac{i_{app}}{A},
```

```math
  \frac{\partial}{\partial x}\phi^n_s\bigg\vert_{x=L^n} = \frac{\partial}{\partial x}\phi^p_s
\bigg\vert_{x=L^n + L^p} = 0.
```

Here is ``i_{app}`` the electrical current at the terminals of the cell, ``L^{tot} = L^n + L^s + L^p`` where ``L^n`` is the thickness of the negative electrode, ``L^s`` is the thickness of the separator and ``L^p`` is the thickness of the positive electrode. ``A`` is the surface area of the current collector or electrode.

The initial values are:

```math
\sigma^n_{s,0} = 0, \sigma^p_{s,0} = U^p_{ocp}(\theta^p_{s,0}) - U^n_{ocp}(\theta^n_{s,0}),
```

where ``\theta_s = c_s/c_{s,max}`` is the stoichiometry of the electrode such that `` 0 \leq \theta_s \leq 1``, and ``U_{ocp}(\theta_s)`` is the open-circuit potential (OCP) of the electrode.

### Mass conservation in the electrode

The mass conversation in the solid electrode particles is defined as:

```math
 \frac{\partial c_s}{\partial t} = \frac{1}{r^2}\frac{\partial}{\partial r}(D_s r^2 \frac{\partial c_s}{\partial r}),
```

where ``c_s`` is the concentration of lithium in the solid electrode particles, and ``D_s`` is the diffusion coefficient of the electrode. This PDE is a reformulation of Fick's second law in spherical coordinate, assuming spherical symmetry.

The boundary conditions are:

```math
 D_s \frac{\partial c_s}{\partial r}\bigg\vert_{r=R_s} = -j,  D_s\frac{\partial c_S}{\partial r}\bigg\vert_{r=0} = 0.
```

The initial values are:

```math
  c_{s,0} = c_{s,max}(\theta_0 + z_0(\theta_{100} - \theta_0)),
```

where ``0 \leq z_0 \leq 1`` is the initial cell SOC. ``\theta_0`` is when the SOC is ``0 %``, and ``\theta_{100}`` is when the SOC is ``100 %``.



### Electrolyte

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

### Electrode

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

### Reaction kinetics

The reaction rate ``R_\text{elde}`` at each electrode is given
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

### Symbol list

| Symbol                                      | Definition                                      | Parameter name in BattMo                      |
|---------------------------------------------|-------------------------------------------------|-----------------------------------------------|
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


### Input parameters

| Symbol                                      | Definition                                      | Parameter name in BattMo                      |
|---------------------------------------------|-------------------------------------------------|-----------------------------------------------|
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

## P4D Pouch



## P4D Cylindrical