from ..julia_import import jl
from juliacall import Main as jl_main


def load_cell_parameters(*arg, **kwargs):
    return jl.load_cell_parameters(*arg, **kwargs)


def load_cycling_protocol(*arg, **kwargs):
    return jl.load_cycling_protocol(*arg, **kwargs)


def load_model_settings(*arg, **kwargs):
    return jl.load_model_settings(*arg, **kwargs)


def load_simulation_settings(*arg, **kwargs):
    return jl.load_simulation_settings(*arg, **kwargs)


def load_solver_settings(*arg, **kwargs):
    return jl.load_solver_settings(*arg, **kwargs)


def load_full_simulation_input(*arg, **kwargs):
    return jl.load_full_simulation_input(*arg, **kwargs)


def CellParameters(*arg, **kwargs):
    return jl.CellParameters(*arg, **kwargs)


def CyclingProtocol(*arg, **kwargs):
    return jl.CyclingProtocol(*arg, **kwargs)


def ModelSettings(*arg, **kwargs):
    return jl.ModelSettings(*arg, **kwargs)


def SimulationSettings(*arg, **kwargs):
    return jl.SimulationSettings(*arg, **kwargs)


def expose_to_battmo(func):
    name = func.__name__
    setattr(jl_main, name, func)  # register Python function in Main

    jl.eval(
        f"""
        function {name}_jl(*args)
            return Float64(Main.{name}(*args))
        end
        Main.{name} = {name}_jl
        """
    )
