import os
from battmo import expose_to_battmo
import pandas as pd
import numpy as np
from scipy.interpolate import interp1d

# --- locate data dirs (similar to Julia code) ---
battmo_base = os.path.dirname(
    os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
)
exdata = os.path.join(battmo_base, "examples", "example_data")
defaultdata = os.path.join(
    battmo_base, "src", "input", "defaults", "cell_parameters", "data", "sodium_ion"
)

# --- load CSV files ---
data_pe_ocp = pd.read_csv(os.path.join(defaultdata, "Chayambuka_pe_ocp.csv"), header=None)
data_ne_ocp = pd.read_csv(os.path.join(defaultdata, "Chayambuka_ne_ocp.csv"), header=None)
data_pe_D = pd.read_csv(os.path.join(defaultdata, "Chayambuka_pe_D.csv"), header=None)
data_ne_D = pd.read_csv(os.path.join(defaultdata, "Chayambuka_ne_D.csv"), header=None)
data_pe_k = pd.read_csv(os.path.join(defaultdata, "Chayambuka_pe_k.csv"), header=None)
data_ne_k = pd.read_csv(os.path.join(defaultdata, "Chayambuka_ne_k.csv"), header=None)
data_elyte_cond = pd.read_csv(
    os.path.join(defaultdata, "Chayambuka_elyte_conductivity.csv"), header=None
)
data_elyte_diff = pd.read_csv(os.path.join(defaultdata, "Chayambuka_elyte_D.csv"), header=None)

# --- assign + scale ---
pe_ocp = data_pe_ocp[1].to_numpy()
x_pe = data_pe_ocp[0].to_numpy()

ne_ocp = data_ne_ocp[1].to_numpy()
ne_transfered_charge = data_ne_ocp[0].to_numpy()

cond_elyte = data_elyte_cond[1].to_numpy() * 1e-3 * 1e2  # mS/cm -> S/m
c_elyte = data_elyte_cond[0].to_numpy() * 1e3  # kmol/m^3 -> mol/m^3

diff_elyte = data_elyte_diff[1].to_numpy()
c_elyte_diff = data_elyte_diff[0].to_numpy() * 1e3

pe_D = data_pe_D[1].to_numpy()
c_pe_D = data_pe_D[0].to_numpy() * 1e3

pe_k = data_pe_k[1].to_numpy()
c_pe_k = data_pe_k[0].to_numpy() * 1e3

ne_D = data_ne_D[1].to_numpy()
c_ne_D = data_ne_D[0].to_numpy() * 1e3

ne_k = data_ne_k[1].to_numpy()
c_ne_k = data_ne_k[0].to_numpy() * 1e3

# normalize stoichiometry for ne
max_ne_charge = np.max(ne_transfered_charge)
min_ne_charge = np.min(ne_transfered_charge)
x_ne = (ne_transfered_charge - min_ne_charge) / (max_ne_charge - min_ne_charge)


# --- define interpolator helpers ---
def get_1d_interpolator(x, y):
    return interp1d(x, y, bounds_error=False, fill_value="extrapolate")


# --- define calc_* functions ---
def calc_ne_ocp(c, T, refT, cmax):
    ocp = get_1d_interpolator(x_ne, ne_ocp)
    return float(ocp(c / cmax))


def calc_pe_ocp(c, T, refT, cmax):
    ocp = get_1d_interpolator(x_pe, pe_ocp)
    return float(ocp(c / cmax))


def calc_elyte_cond(c, T):
    cond = get_1d_interpolator(c_elyte, cond_elyte)
    return float(cond(c))


def calc_elyte_diff(c, T):
    diff = get_1d_interpolator(c_elyte_diff, diff_elyte)
    return float(diff(c))


def calc_pe_D(c, T, refT, cmax):
    diff = get_1d_interpolator(c_pe_D, pe_D)
    return float(diff(c))


def calc_ne_D(c, T, refT, cmax):
    diff = get_1d_interpolator(c_ne_D, ne_D)
    return float(diff(c))


def calc_ne_k(c, T):
    diff = get_1d_interpolator(c_ne_k, ne_k)
    return float(diff(c))


def calc_pe_k(c, T):
    diff = get_1d_interpolator(c_pe_k, pe_k)
    return float(diff(c))


# --- Expose to Julia / BattMo ---
expose_to_battmo(calc_ne_ocp)
expose_to_battmo(calc_pe_ocp)
expose_to_battmo(calc_elyte_cond)
expose_to_battmo(calc_elyte_diff)
expose_to_battmo(calc_pe_D)
expose_to_battmo(calc_ne_D)
expose_to_battmo(calc_ne_k)
expose_to_battmo(calc_pe_k)
