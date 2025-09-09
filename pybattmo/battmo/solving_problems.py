from .julia_import import jl


def Simulation(*arg, **kwargs):
    return jl.Simulation(*arg, **kwargs)


def VoltageCalibration(*arg, **kwargs):
    return jl.VoltageCalibration(*arg, **kwargs)


def solve(*arg, **kwargs):
    return jl.solve(*arg, **kwargs)


def free_calibration_parameter(*arg, **kwargs):
    return jl.free_calibration_parameter(*arg, **kwargs)


def print_calibration_overview(*arg, **kwargs):
    return jl.print_calibration_overview(*arg, **kwargs)
