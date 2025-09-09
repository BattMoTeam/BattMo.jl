from .julia_import import jl


def load_cell_parameters(*arg, **kwargs):
    return jl.load_cell_parameters(*arg, **kwargs)


def load_cycling_protocol(*arg, **kwargs):
    return jl.load_cycling_protocol(*arg, **kwargs)


def load_model_settings(*arg, **kwargs):
    return jl.load_model_settings(*arg, **kwargs)


def load_simulation_settings(*arg, **kwargs):
    return jl.load_simulation_settings(*arg, **kwargs)


def CellParameters(*arg, **kwargs):
    return jl.CellParameters(*arg, **kwargs)


def CyclingProtocol(*arg, **kwargs):
    return jl.CyclingProtocol(*arg, **kwargs)


def ModelSettings(*arg, **kwargs):
    return jl.ModelSettings(*arg, **kwargs)


def SimulationSettings(*arg, **kwargs):
    return jl.SimulationSettings(*arg, **kwargs)
