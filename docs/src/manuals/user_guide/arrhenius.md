# Temperature dependence

## Arrhenius 
The arrhenius type temperature dependence can be described by the following formula:

```math
A(T) = A_{ref}\exp{\left(-\frac{E_a}{R}(\frac{1}{T}- \frac{1}{T_{ref}})\right)},
```

where, ``A`` is the concerning quantity. In BattMo this can be the electrode diffusion coefficient or reaction rate. ``A_{ref}`` is the value of the quantity at the reference temperature, ``R`` is the Gas constant, ``E_a`` is the activation energy, and ``T`` the temperature.