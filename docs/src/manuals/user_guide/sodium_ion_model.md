# Sodium-ion / Doyle-Fuller-Newman model
The sodium ion model is the same as the lithium ion PXD model, but you have the option to select a slightly adapted Butler-Volmer equation proposed by [Chayambuka et al.](https://www.sciencedirect.com/science/article/pii/S0013468621020478?via%3Dihub#bib0036):


Select this option in your model settings:

```
model_settings = load_model_settings(;from_file_path = "file_path.json")
model_settings["ButlerVolmer"] = "Chayambuka"

```

### Butler-Volmer equation
```math
  j = j_{0}\left[\frac{c^s_s}{\bar{c}_s}\exp{\left(\frac{\alpha F}{RT}\mu \right)} - \frac{c^{max}_s - c^s_s}{c^{max}_s - \bar{c_s}}\frac{c_e}{\bar{c_e}} \exp{\left(-\frac{(1-\alpha)F}{RT}\mu \right)} \right].
```

Here is ``\sigma_{\text{eff}}`` the charge transfer coefficient, `` \mu`` is the charge transfer overpotential, ``c^s_s`` is the electrode surface concentration of sodium, ``\bar{c_s}`` is the average particle concentration, ``c^{max}_s`` the solid saturation concentration, ``c_e``, the electrolyte concentration, and ``\bar{c_e}`` the average sodium concentration in the electrolyte. The exchange current density can be expressed as:

```math
j_0 = Fk(c^{max}_s - \bar{c_s})^{\alpha_a}(\bar{c_e})^{\alpha_a} (\bar{c_s})^{\alpha_c},
```

where ``k`` is the reaction rate constant.