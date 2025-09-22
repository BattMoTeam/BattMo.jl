import juliapkg
from ..julia_import import jl
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


def make_interactive():
    juliacall.interactive()


def plot_dashboard(output, plot_type="simple"):
    if activate_plotting():
        make_interactive()
        fig = jl.plot_dashboard(output, plot_type=plot_type)

        if plot_type == "line":
            jl.seval(
                """
                    display(current_figure())
                    println("Press Ctrl+C to stop plotting interactivity")
                    while true
                        sleep(0.1)
                    end
                    """
            )
        else:
            jl.seval("display(current_figure())")

    return fig


def plot_output(*arg, **kwargs):
    if activate_plotting():
        make_interactive()
        fig = jl.plot_output(*arg, **kwargs)
        jl.seval("display(current_figure())")
    return fig


def plot_interactive_3d(*arg, **kwargs):
    if activate_plotting():
        make_interactive()
        fig = jl.plot_interactive_3d(*arg, **kwargs)
        jl.seval(
            """
                display(current_figure())
                println("Press Ctrl+C to stop plotting interactivity")
                while true
                    sleep(0.1)
                end
                """
        )
    return fig
