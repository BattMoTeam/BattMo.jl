# Solid Electrolyte Interphase (SEI)

For the SEI, we use the model described in the paper Microstructure-resolved degradation simulation of lithium-ion batteries in space applications from [Bolay et al](https://doi.org/10.1016/j.powera.2022.100083).

The model consider the electron diffusion and migration in the SEI layer given by the flux

```math
\begin{aligned}
  N_{sei} = D^{e^{-1}}\frac{c^{e^{-1}}}{L_{sei}} - zF\kappa_{sei}^{e^{-1}}\lambda\phi
\end{aligned}
```

- ``D^{e^-}``: Electron diffusion coefficient
- ``c^{e^-}``: Electron concentration
- ``L^{sei}``: SEI length
- ``\kappa^{e^-}_{sei}``: Electron conductivity in SEI

When the electron reaches the SEI interface, it reacts with the electrolyte to create more SEI. This process is modeled by the differential equation

```math
\begin{aligned}
  \frac{1}{V_{sei}}\frac{dL_{sei}}{dt} = N_{sei}
\end{aligned}
```

where 

- ``V_{sei}``: Mean partial volume of SEI

The SEI layer induces an additional potential drop given by

```math
\begin{aligned}
  U_{sei} = \frac{L_{sei}}{\kappa_{Li^+}^{sei}}j_{Li^+}
\end{aligned}
```

where 

- ``\kappa_{Li^+}^{sei}``: Conductivity for Lithium ion in SEI
- ``j_{Li^+}``: Lithium ion current density