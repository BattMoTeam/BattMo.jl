# Lithium-ion / Doyle-Fuller-Newman model

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
- 4\pi r^2 D_\text{s} \frac{\partial c_\text{s}}{\partial r}(t, x, r) = \frac{a_\text{s} j}{\varepsilon_\text{s}}\frac{4\pi r^3}{3}, D_s\frac{\partial c_s}{\partial r}\bigg\vert_{r=0} = 0,
```

where ``\varepsilon_s`` is the volume fraction of the electrode.

The initial values are:

```math
  c_{s,0} = c_{s,max}(\theta_0 + z_0(\theta_{100} - \theta_0)),
```

where ``0 \leq z_0 \leq 1`` is the initial cell SOC. ``\theta_0`` is when the SOC is ``0 %``, and ``\theta_{100}`` is when the SOC is ``100 %``.



### Charge conservation in the electrolyte

The charge conservation in the electrolyte is given by
```math
  -\frac{\partial}{\partial x}\textbf{j}_{\text{e}} = a_{\text{s}}Fj,
```

where 
```math
\textbf{j}_\text{e} = -\kappa_{\text{e},\text{eff}}\frac{\partial \phi_\text{e}}{\partial x} - \kappa_{\text{e},\text{eff}}\frac{1 - t_+}{z_+F}\left(\frac{\partial \mu}{\partial c}\right)\frac{\partial c_\text{e}}{\partial x} .
```


Here ``\mu = 2RT\log(c_\text{e})`` is the chemical potential, with ``R``, the universal gas constant, ``T``, the temperature, and ``c_\text{e}`` the concentration of lithium in the electrolyte. ``\kappa_{e,eff}`` is the effective conductivity of the electrolyte, ``z_+`` is the charge number, and ``t_+`` is the transference number of the positive ion in the electrolyte with respect to the solvent. The effective quantities are computed from the intrinsic properties and the volume fraction using a Bruggemann coefficient, denoted ``b``, which yields ``\kappa_{\text{e},\text{eff}} = \varepsilon_\text{e}^{b}\kappa_{\text{e}}``. For the electrolyte, we have a spatially dependent Bruggeman coefficient.

The boundary conditions must be such that all current at the current collector boundaries are electronic, and all current at the separator boundaries are ionic:

```math
 \textbf{j}_\text{e}\bigg\vert_{x=0, x=L^{tot}} = 0,
```

```math
 \textbf{j}_\text{e}\bigg\vert_{x=L^n, x=L^{n} + L^s} = \frac{i_{app}}{A}.
```

The initial condition is:

```math
\phi_{e,0} = -U^n_{ocp(\theta^n_{s,0})}
```

### Mass conservation in the electrolyte

The mass conservation in the electrolyte is modeled as:
```math
 \frac{\partial }{\partial t}(\varepsilon_\text{e} c_\text{e}) + \frac{\partial}{\partial x} \textbf{N}_{\text{e}} =  a_{\text{s}}j,
```

where ``\varepsilon_e`` is thevolume fraction of the electrolyte, and the flux ``\textbf{N}_{\text{e}}`` is equal to: 
```math
  \textbf{N}_{\text{e}} = - D_{\text{e},\text{eff}}\frac{\partial c_{\text{e}}}{\partial x}  + \frac{t_+}{z_+F}\textbf{j}_\text{e}.
```

The effective diffusion coefficient is calculated by ``D_{\text{e},\text{eff}} = \varepsilon_\text{e}^{b}D_{\text{e}}``. The boundary conditions enforce continuity of electrolyte concentration and flux of lithium across the cell, and enforces that there is no movement of lithium from the inside of the cell to the exterior of the cell:

```math
 \frac{\partial c^n_e}{\partial x}\bigg\vert_{x=0} = \frac{\partial c^p_e}{\partial x}\bigg\vert_{x=L^{tot}} = 0
```
```math
 D^n_{e,eff}\frac{\partial c^n_e}{\partial x}\bigg\vert_{x=L^n} = D^s_{e,eff}\frac{\partial c^s_e}{\partial x}\bigg\vert_{x=L^{n}}
```
```math
 D^s_{e,eff}\frac{\partial c^s_e}{\partial x}\bigg\vert_{x=L^n+L^s} = D^p_{e,eff}\frac{\partial c^p_e}{\partial x}\bigg\vert_{x=L^{n}+L^s}
```
```math
c^n_e\bigg\vert_{x=L^n} = c^s_e\bigg\vert_{x=L^n}
```
```math
c^s_e\bigg\vert_{x=L^n+L^s} = c^p_e\bigg\vert_{x=L^n+L^s}
```

The initial values are>
```math
c_e = c_{e,0}
```

### Reaction kinetics

The reaction rate is equal to the rate of lithium flux from the electrode particles into the electrolyte:

```math
j = j_{0}(c_\text{s}, c_\text{e}, T)(e^{\alpha F\frac{\eta_\text{s}}{RT}} - e^{-(1 - \alpha) F\frac{\eta_\text{s}}{RT}} ) .
```
where ``\eta_\text{s}`` and ``j_0`` denote the overpotential and the reaction exchange current density. The overpotential
``\eta_\text{s}`` is given by
```math
\eta_\text{s} = \phi_\text{s} - \phi_\text{e} - U_\text{ocp}(c_\text{s}, T).
```
where ``U_\text{ocp}`` denotes the open circuit potential, given as a function of the Lithium concentration in the electrode and the temperature.  The exchange current density is given by
```math
  j_0 = k_{\text{s},0} \left(c_\text{e}(c_{\text{s},\max} - c_\text{s})c_\text{s}\right)^{\frac12} n F.
```

### DFN Model Parameters (BattMo)

This table lists all required parameters from the DFN model used in BattMo.

---

| Negative Electrode        | Separator              | Positive Electrode        | Description                                                 | BattMo Name         |
|---------------------------|------------------------|----------------------------|-------------------------------------------------------------|---------------------|
| ``\sigma^n_{\text{eff}}``   |                        | ``\sigma^p_{\text{eff}}``   | Effective electrode conductivity                          | ElectronicConductivity     |
| ``a^n_{\text{s}}``          |                        | ``a^p_{\text{s}}``          | Specific interfacial surface area                           | VolumetricSurfaceArea           |
| ``D^n_s``                   |                        | ``D^p_s``                   | Lithium diffusivity in solid phase                          | DiffusionCoefficient           |
| ``\varepsilon^n``           | ``\varepsilon^s``        | ``\varepsilon^p``           | Porosity                                                    | Porosity     |
| ``c_{s,\text{max}}^n``      |                        | ``c_{s,\text{max}}^p``      | Max lithium concentration in solid phase                    | MaximumConcentration      |
| ``\kappa_{\text{e}}``       | ``\kappa_{\text{e}}``    | ``\kappa_{\text{e}}``       | Electrolyte conductivity                                     | IonicConductivity   |
| ``D_{\text{e}}``            | ``D_{\text{e}}``          | ``D_{\text{e}}``           | Electrolyte diffusivity                                      | DiffusionCoefficient       |
| ``U^n_{\text{ocp}}(\theta)``|                        | ``U^p_{\text{ocp}}(\theta)``| Open circuit potential as function of stoichiometry         | OpenCircuitPotential           |
| ``\theta^n_0``              |                        | ``\theta^p_0``              | Stoichiometry at 0% SOC                                     | StoichiometricCoefficientAtSOC0           |
| ``\theta^n_{100}``          |                        | ``\theta^p_{100}``          | Stoichiometry at 100% SOC                                   | StoichiometricCoefficientAtSOC100         |
| ``z_0``                     |                        |                            | Initial state of charge                                     | InitialStateOfCharge               |
| ``k^n_s0``                  |                        | ``k^p_s0``                   | Reaction rate constant                                      | ReactionRateConstant              |
| ``E^n_a``                   |                        | ``E^p_a``                    | Activation energy of the reaction                                          | ActivationEnergyOfReaction               |
| ``\alpha^n``                          |                        | ``\alpha^p``                           | Charge transfer coefficient                                 | ChargeTransferCoefficient             |
| ``A``                          |                        |  ``A``                          | Electrode surface area                                      | ElectrodeGeometricSurfaceArea                 |
| ``T``                          |  ``T``                      | ``T``                           | Temperature                                                 | InitialTemperature                |
| ``t_+``                          |  ``t_+``                      |  ``t_+``                          | Transference number                                         | TransferenceNumber            |
| ``z_+``                          | ``z_+``                       | ``z_+``                           | Charge number of positive ion                               | ChargeNumber            |
| ``c_e_0``                          | ``c_e_0``                       | ``c_e_0``                           | Initial electrolyte concentration                           | Concentration             |
| ``b^n``                          | ``b^s``                       | ``b^p``                           | Bruggeman coefficient (porosity scaling)                    | BruggemanCoefficient       |
| ``L^n``                     | ``L^s``                       | ``L^p``                           | Thickness                              | Thickness               |
| ``r^n``                       |                        | ``r^p``                           | Radius of particles in electrode                         | ParticleRadius                 |


## P4D Pouch



## P4D Cylindrical