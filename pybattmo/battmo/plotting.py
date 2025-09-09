import juliapkg
from .julia_import import jl
import juliacall


def activate_plotting():
    try:
        jl.seval("using GLMakie; GLMakie.activate!()")
    except:
        print("Unable to load GLMakie. Have you called install_plotting()?")
        return False
    return True


def install_plotting():
    juliapkg.add("GLMakie", "e9467ef8-e4e7-5192-8a1a-b1aee30e663a")
    juliapkg.resolve()
    activate_plotting()
    return True


def uninstall_plotting():
    juliapkg.rm("GLMakie", "e9467ef8-e4e7-5192-8a1a-b1aee30e663a")
    juliapkg.resolve()
    return True


# def plot_dashboard(*arg, **kwargs):
#     if activate_plotting():
#         return jl.plot_dashboard(*arg, **kwargs)


# def plot_output(*arg, **kwargs):
#     if activate_plotting():
#         return jl.plot_output(*arg, **kwargs)


# def plot_interactive_3d(*arg, **kwargs):
#     if activate_plotting():
#         return jl.plot_interactive_3d(*arg, **kwargs)


def make_interactive():
    juliacall.interactive()
