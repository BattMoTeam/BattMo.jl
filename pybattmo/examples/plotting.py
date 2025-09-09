# %%
import juliacall

# %% Create Julia module
jl = juliacall.newmodule("BattMo")

# %% Load packages (don’t reinstall every run)
jl.seval(
    """
using GLMakie
GLMakie.activate!()
"""
)

# %% Define plotting function
jl.Figure()

# %%
f = jl.scatter(jl.rand(2, 5))

# %% Call it
jl.display(f)

# %% Keep window alive
juliacall.interactive()
