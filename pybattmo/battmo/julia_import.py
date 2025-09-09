import os
import sys
import warnings

# The following code that handles juliacall issues is copied from PySR
# Copyright 2020 Miles Cranmer, Apache 2.0 License.
# Source: https://github.com/MilesCranmer/PySR/blob/cd055a67728eeb675c76dedfe5d5e669eea3a6d1/pysr/julia_import.py

if "juliacall" in sys.modules:
    warnings.warn(
        "juliacall module already imported. "
        "Make sure that you have set the environment variable `PYTHON_JULIACALL_HANDLE_SIGNALS=yes` to avoid segfaults. "
        "Also note that battmo will not be able to configure `PYTHON_JULIACALL_THREADS` or `PYTHON_JULIACALL_OPTLEVEL` for you."
    )
else:
    # Required to avoid segfaults (https://juliapy.github.io/PythonCall.jl/dev/faq/)
    if os.environ.get("PYTHON_JULIACALL_HANDLE_SIGNALS", "yes") != "yes":
        warnings.warn(
            "PYTHON_JULIACALL_HANDLE_SIGNALS environment variable is set to something other than 'yes' or ''. "
            + "You will experience segfaults if running with multithreading."
        )

    # TODO: Remove these when juliapkg lets you specify this
    for k, default in (
        ("PYTHON_JULIACALL_HANDLE_SIGNALS", "yes"),
        # ("PYTHON_JULIACALL_THREADS", "auto"),
        ("PYTHON_JULIACALL_OPTLEVEL", "3"),
    ):
        os.environ[k] = os.environ.get(k, default)

# Actual start of module - now that juliacall can be imported
import juliacall
from juliacall import convert as jlconvert

jl = juliacall.newmodule("BattMo")
import numpy as np

# Load the main packages
try:
    jl.seval("using BattMo")
except Exception:
    jl.seval(
        """
    import Pkg
    Pkg.add(url="https://github.com/BattMoTeam/BattMo.jl")
    using BattMo
    """
    )
