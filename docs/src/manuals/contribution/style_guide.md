# Style Guide

When writing code for BattMo we use the [Blue Style](https://github.com/JuliaDiff/BlueStyle?tab=readme-ov-file#module-imports) coding style in general, but we apply some specific rules that are a bit more strict.


## Modules import
When importing packages into BattMo like for example Jutul.jl we prefer to import the package with `using` and explicitly write down the used functions and types using qualification (`Jutul.function()`) notation.

So:

`using Jutul`
`Jutul.number_of_cells()`

### Why we prefer qualifications? (i.e using dot ``.`` notation)
[Julia](https://docs.julialang.org/en/v1/manual/modules/) prefers the use of ``using Module`` without qualification, as it exports the functions and types within ``Module``. This choice results in readable code if there are multiple functions with the same name, but designed for different types. 
* Plots: we can define a single funcion ``plot()`` across multiple modules, and they will carry out different actions according to the type of the arguments passed. In this way, we keep the number of functions small in the namespace.  

**However**, when the number of actions needed in the namespace is large, not keeping track of where these many functions come from will result in unreadable code. This is the case of BattMo, where we must carry many actions (load parameters, define a grid, run simulation, .....).
This is why **qualification is preferred when loading modules and using funcitons**.

