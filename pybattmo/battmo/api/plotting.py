from ..julia_import import jl
from .output import *
import numpy as np
import plotly.graph_objects as go
from plotly.subplots import make_subplots


def plot_dashboard_plotly(output, plot_type="simple", new_window=True):
    # Example replacements for your Julia functions:
    # Replace with your real data extraction
    time_series = get_output_time_series(output)
    t = np.array(time_series.Time)
    I = np.array(time_series.Current)
    E = np.array(time_series.Voltage)

    states = get_output_states(output)

    n_steps = len(t)
    x = np.array(states.Position) * 1e6

    NeAm_conc = states.NeAmSurfaceConcentration
    PeAm_conc = states.PeAmSurfaceConcentration
    Elyte_conc = states.ElectrolyteConcentration

    NeAm_pot = states.NeAmPotential
    PeAm_pot = states.PeAmPotential
    Elyte_pot = states.ElectrolytePotential

    if plot_type == "simple":
        fig = make_subplots(rows=2, cols=1, subplot_titles=("Current / A", "Voltage / V"))
        fig.add_trace(
            go.Scatter(
                x=t,
                y=I,
                mode="lines+markers",
                marker=dict(symbol="x", color="black"),
                line=dict(width=4, color="blue"),
                name="Current",
            ),
            row=1,
            col=1,
        )
        fig.add_trace(
            go.Scatter(
                x=t,
                y=E,
                mode="lines+markers",
                marker=dict(symbol="x", color="black"),
                line=dict(width=4, color="blue"),
                name="Voltage",
            ),
            row=2,
            col=1,
        )
        fig.update_xaxes(title_text="Time / s", row=1, col=1)
        fig.update_xaxes(title_text="Time / s", row=2, col=1)
        fig.update_layout(title="Simple Dashboard", height=1000, width=1200)

        fig.show()

        return fig

    elif plot_type == "line":
        fig = make_subplots(
            rows=4,
            cols=3,
            subplot_titles=(
                "Current / A",
                "Voltage / V",
                "NeAm Surface Conc",
                "Elyte Conc",
                "PeAm Surface Conc",
                "NeAm Potential",
                "Elyte Potential",
                "PeAm Potential",
            ),
        )

        # Current & Voltage
        fig.add_trace(
            go.Scatter(
                x=t,
                y=I,
                mode="lines+markers",
                marker=dict(symbol="x", color="black"),
                line=dict(width=4, color="blue"),
                name="Current",
            ),
            row=1,
            col=1,
        )
        fig.add_trace(
            go.Scatter(
                x=t,
                y=E,
                mode="lines+markers",
                marker=dict(symbol="x", color="black"),
                line=dict(width=4, color="blue"),
                name="Voltage",
            ),
            row=1,
            col=2,
        )

        # Initial traces for states (slider will update them)
        def add_state(row, col, data, label):
            fig.add_trace(
                go.Scatter(
                    x=x, y=data[0, :], mode="lines", line=dict(width=4), name=label, visible=True
                ),
                row=row,
                col=col,
            )

        add_state(2, 1, NeAm_conc, "NeAm Conc")
        add_state(2, 2, Elyte_conc, "Elyte Conc")
        add_state(2, 3, PeAm_conc, "PeAm Conc")

        add_state(3, 1, NeAm_pot, "NeAm Pot")
        add_state(3, 2, Elyte_pot, "Elyte Pot")
        add_state(3, 3, PeAm_pot, "PeAm Pot")

        # Slider steps
        steps = []
        for i in range(n_steps):
            step = dict(
                method="update",
                args=[
                    {
                        "y": [
                            NeAm_conc[i, :],
                            Elyte_conc[i, :],
                            PeAm_conc[i, :],
                            NeAm_pot[i, :],
                            Elyte_pot[i, :],
                            PeAm_pot[i, :],
                        ]
                    }
                ],
                label=str(i),
            )
            steps.append(step)

        sliders = [dict(active=0, steps=steps, currentvalue={"prefix": "Step: "})]
        fig.update_layout(title="Line Dashboard", height=1000, width=1200, sliders=sliders)

        fig.show()

        return fig

    elif plot_type == "contour":
        fig = make_subplots(
            rows=4,
            cols=3,
            subplot_titles=(
                "Current / A",
                "Voltage / V",
                "",
                "NeAm Surface Conc",
                "Elyte Conc",
                "PeAm Surface Conc",
                "NeAm Potential",
                "Elyte Potential",
                "PeAm Potential",
            ),
            horizontal_spacing=0.15,  # more space for colorbars
            vertical_spacing=0.1,
        )

        # Current & Voltage
        fig.add_trace(
            go.Scatter(
                x=t,
                y=I,
                mode="lines+markers",
                marker=dict(symbol="x", color="black"),
                line=dict(width=4, color="blue"),
                name="Current",
            ),
            row=1,
            col=1,
        )
        fig.add_trace(
            go.Scatter(
                x=t,
                y=E,
                mode="lines+markers",
                marker=dict(symbol="x", color="black"),
                line=dict(width=4, color="blue"),
                name="Voltage",
            ),
            row=1,
            col=2,
        )

        def add_contour(fig, row, col, data, x, y, title):
            trace = go.Contour(
                z=data,
                x=x,
                y=y,
                colorscale="Viridis",
                colorbar=dict(
                    title=title,
                    thickness=20,
                    lenmode="fraction",
                    len=0.8,  # fraction of subplot height
                    yanchor="middle",
                    y=0.5,  # center vertically
                    xanchor="left",
                    x=1.02,  # just outside the subplot
                ),
                showscale=True,
                row=row,
                col=col,
            )

        # Concentrations
        add_contour(fig, 2, 1, NeAm_conc, x, t, "NeAm Conc")
        add_contour(fig, 2, 2, Elyte_conc, x, t, "Elyte Conc")
        add_contour(fig, 2, 3, PeAm_conc, x, t, "PeAm Conc")

        # Potentials
        add_contour(fig, 3, 1, NeAm_pot, x, t, "NeAm Pot")
        add_contour(fig, 3, 2, Elyte_pot, x, t, "Elyte Pot")
        add_contour(fig, 3, 3, PeAm_pot, x, t, "PeAm Pot")

        fig.update_layout(title="Contour Dashboard", height=1000, width=1200)
        fig.show()

        return fig

    else:
        raise ValueError(f"Unsupported plot_type {plot_type}. Use 'simple', 'line', or 'contour'.")


def finite_bounds(arr):
    """Return (min, max) ignoring NaN/inf."""
    arr = np.asarray(arr)
    arr = arr[np.isfinite(arr)]
    if arr.size == 0:
        return None
    return arr.min(), arr.max()
