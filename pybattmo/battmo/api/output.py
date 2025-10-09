from ..julia_import import jl
import numpy as np
import pandas as pd


def to_pandas(julia_data):
    # Get field names as Python strings
    fields = [str(f) for f in jl.keys(julia_data)]
    # Build dictionary with NumPy arrays
    data = {f: np.array(julia_data[f]) for f in fields}
    # Create DataFrame
    df = pd.DataFrame(data)
    return df
