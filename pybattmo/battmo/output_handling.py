from .julia_import import jl


def get_output_time_series(*arg, **kwargs):
    return jl.get_output_time_series(*arg, **kwargs)


def get_output_states(*arg, **kwargs):
    return jl.get_output_states(*arg, **kwargs)


def get_output_metrics(*arg, **kwargs):
    return jl.get_output_metrics(*arg, **kwargs)


def print_output_overview(*arg, **kwargs):
    return jl.print_output_overview(*arg, **kwargs)
