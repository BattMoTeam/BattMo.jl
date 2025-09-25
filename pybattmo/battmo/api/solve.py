from ..julia_import import jl


def Simulation(*arg, **kwargs):
    return jl.Simulation(*arg, **kwargs)


def VoltageCalibration(*arg, **kwargs):
    return jl.VoltageCalibration(*arg, **kwargs)


def solve(*arg, **kwargs):
    return jl.solve(*arg, **kwargs)


def free_calibration_parameter(cal, parameter_path, **kwargs):
    parameter_path_jl = jl.seval(f"[{','.join([f'\"{p}\"' for p in parameter_path])}]")
    julia_func = getattr(jl, "free_calibration_parameter!")
    return julia_func(cal, parameter_path_jl, **kwargs)


def print_calibration_overview(*arg, **kwargs):
    return jl.print_calibration_overview(*arg, **kwargs)


def run_simulation(*arg, **kwargs):
    return jl.run_simulation(*arg, **kwargs)
