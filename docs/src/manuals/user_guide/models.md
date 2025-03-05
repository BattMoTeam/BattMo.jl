In the following, all the symbols that are not introduced directly in the text are collected in Table \ref{tab:symb}.

The mass and charge conservation in the electrolyte are given by
```math
\begin{aligned}
  \fracpar{}{t}(\epsi_\elyte c_\elyte) + \dive \Nvec_{\elyte} &=  R_{\elyte},\\
  \dive \jvec_{\elyte} &= FR_{\elyte},
\end{aligned}
```
where the fluxes are given by
```math
\begin{aligned}
  \jvec_\elyte   &= -\kappa_{\elyte,\eff}\grad\phi_\elyte - \kappa_{\elyte,\eff}\frac{1 - t_+}{z_+F}\left(\fracpar{\mu}{c}\right)\grad c_\elyte,\\
  \Nvec_{\elyte} &= - D_{\elyte,\eff}\grad c_{\elyte} + \frac{t_+}{z_+F}\jvec_\elyte.
\end{aligned}
```
The volumetric reaction rate is given as ``R_\elyte = -\sum_\elde \gamma_\elde R_\elde`` where ``\gamma_{\elde}`` is the volumetric surface area and the expression for ``R_\elde`` is given below. Note that the reaction rates depends on the spatial variable ``x``. For the chemical potential, we use ``\mu = 2RT\log(c_\elyte)``. The effective quantities are computed from the intrinsic properties and the volume fraction using a Bruggemann coefficient, denoted ``b``, which yields ``\kappa_{\elyte,\eff} = \epsi_\elyte^{b}\kappa_{\elyte}`` and ``D_{\elyte,\eff} = \epsi_\elyte^{b}D_{\elyte}``. For the electrolyte, we have a spatially dependent Bruggeman coefficient.

In the electrode, the charge conservation equation is given by
```math
  -\dive (\kappa_{\elde, \eff} \grad \phi_\elde) = F\gamma_\elde R_{\elde}.
```
We use a pseudo particle model for ``c_\elde(t, x, r)``
```math
\fracpar{}{t}c_\elde - \frac1{r^2}\fracpar{}{r}(r^2D_\elde\fracpar{}{r} c_\elde) = 0.
```
with boundary condition
```math
- 4\pi r_p^2 D_\elde \fracpar{c_\elde}{r}(t, x, r_p) = \frac{\gamma_\elde R_\elde}{\epsi_\elde}\frac{4\pi r_p^3}{3}.
```

Reaction kinetics. The reaction rate ``R_\elde`` at each electrode is given
```math
R_\elde = j_{\elde}(c_\elde, c_\elyte, T)(e^{\alpha F\frac{\eta_\elde}{RT}} - e^{-(1 - \alpha) F\frac{\eta_\elde}{RT}} ) .
```
where ``\eta_\elde`` and ``j_\elde`` denote the overpotential and the reaction exchange current density. The overpotential
``\eta_\elde`` is given by
```math
\eta_\elde = \phi_\elde - \phi_\elyte - U_\elde(c_\elde, T).
```
where ``U_\elde`` denotes the open circuit potential, given as a function of the Lithium concentration in the electrode
and the temperature.  The exchange current density is given by
```math
  j_\elde = k_{\elde,0} e^{-\frac{E_a}{R}(1/T - 1/T_{\text{ref}})}\left(c_\elyte(c_{\elde,\max} - c_\elde)c_\elde\right)^{\frac12}.
```
