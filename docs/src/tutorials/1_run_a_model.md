```@meta
EditURL = "../../../examples/beginner_tutorials/1_run_a_model.jl"
```

# How to run a model

Lets how we can run a model in BattMo in the most simple way. We ofcourse start with importing the BattMo package.

````@example 1_run_a_model
using BattMo
````

BattMo utilizes the JSON format to store all the input parameters of a model in a clear and intuitive way. We can use one of the default
parameter sets, for example the Li-ion parameter set that has been created from the [Chen 2020 paper](https://doi.org/10.1149/1945-7111/ab9050).

````@example 1_run_a_model
file_name = "p2d_40_jl_chen2020.json"
file_path = string(dirname(pathof(BattMo)), "/../test/data/jsonfiles/", file_name)
````

First we convert the json data to a julia dict and format it using the folowing function.

````@example 1_run_a_model
inputparams = readBattMoJsonInputFile(file_path)
````

Then we can run the model.

````@example 1_run_a_model
results = run_battery(inputparams);
nothing #hide
````

## Example on GitHub
If you would like to run this example yourself, it can be downloaded from the BattMo.jl GitHub repository [as a script](https://github.com/BattMoTeam/BattMo.jl/blob/main/examples/1_run_a_model.jl), or as a [Jupyter Notebook](https://github.com/BattMoTeam/BattMo.jl/blob/gh-pages/dev/final_site/notebooks/1_run_a_model.ipynb)

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

