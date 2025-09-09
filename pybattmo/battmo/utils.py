from .julia_import import jl


def print_submodels_info(*arg, **kwargs):
    return jl.print_submodels_info(*arg, **kwargs)


def print_default_input_sets_info(*arg, **kwargs):
    return jl.print_default_input_sets_info(*arg, **kwargs)


def print_parameter_info(*arg, **kwargs):
    return jl.print_parameter_info(*arg, **kwargs)


def print_setting_info(*arg, **kwargs):
    return jl.print_setting_info(*arg, **kwargs)


def print_output_variable_info(*arg, **kwargs):
    return jl.print_output_variable_info(*arg, **kwargs)


def generate_default_parameter_files(*arg, **kwargs):
    return jl.generate_default_parameter_files(*arg, **kwargs)


def write_to_json_file(*arg, **kwargs):
    return jl.write_to_json_file(*arg, **kwargs)
