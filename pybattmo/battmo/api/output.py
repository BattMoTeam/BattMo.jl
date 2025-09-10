from ..julia_import import jl
import numpy as np
import pandas as pd


def get_output_time_series(*arg, **kwargs):
    return jl.get_output_time_series(*arg, **kwargs)


def get_output_states(*arg, **kwargs):
    return jl.get_output_states(*arg, **kwargs)


def get_output_metrics(*arg, **kwargs):
    return jl.get_output_metrics(*arg, **kwargs)


def print_output_overview(*arg, **kwargs):
    return jl.print_output_overview(*arg, **kwargs)


def to_pandas(julia_data):
    # Get field names as Python strings
    fields = [str(f) for f in jl.keys(julia_data)]
    # Build dictionary with NumPy arrays
    data = {f: np.array(getattr(julia_data, f)) for f in fields}
    # Create DataFrame
    df = pd.DataFrame(data)
    return df
