import juliapkg
from ..julia_import import jl
import juliacall


def activate_plotting():
    try:
        jl.seval("using WGLMakie; WGLMakie.activate!()")
    except:
        print("Unable to load WGLMakie. Have you called install_plotting()?")

        return False
    return True


def install_plotting():
    juliapkg.add("WGLMakie", "276b4fcb-3e11-5398-bf8b-a0c2d153d008")
    juliapkg.resolve()
    activate_plotting()
    return True


def uninstall_plotting():
    juliapkg.rm("WGLMakie", "276b4fcb-3e11-5398-bf8b-a0c2d153d008")
    juliapkg.resolve()
    return True


def make_interactive():
    juliacall.interactive()


def plot_dashboard(output, plot_type="simple"):
    if activate_plotting():
        fig = jl.plot_dashboard(output, plot_type=plot_type)
        make_interactive()
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
        fig = jl.plot_output(*arg, **kwargs)
        make_interactive()
        jl.seval("display(current_figure())")
    return fig


def plot_interactive_3d(*arg, **kwargs):
    if activate_plotting():
        fig = jl.plot_interactive_3d(*arg, **kwargs)
        make_interactive()
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
