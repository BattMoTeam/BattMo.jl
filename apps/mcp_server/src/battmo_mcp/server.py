"""BattMo MCP server.

Exposes BattMo.jl battery simulations to MCP clients (Claude Code, Claude Desktop,
Cursor, LangGraph agents, ...) over stdio. BattMo runs in-process through juliacall,
so Julia starts and compiles once per server lifetime instead of once per request.
"""

from __future__ import annotations

import json
import os
from typing import Annotated, Any, Literal

from mcp.server.mcpserver import MCPServer
from mcp.server.mcpserver.exceptions import ResourceError, ToolError
from pydantic import Field

# Notes on Julia + MCP:
# - stdout: while serving, the SDK's stdio_server() points fd 1 (and the Windows std
#   handle) at stderr and talks to the client over a private duplicate. Julia is started
#   lazily on the first tool call, i.e. after that diversion, so anything Julia prints
#   lands in the client's server log instead of corrupting the JSON-RPC stream.
# - threads: juliacall must not be called from arbitrary Python threads, and the SDK runs
#   *sync* tools in a worker thread pool. All tools are therefore `async def` and call
#   Julia directly on the event-loop (main) thread. Long simulations block other requests.

mcp = MCPServer(
    "battmo",
    instructions=(
        "Tools for running BattMo.jl lithium-ion / sodium-ion battery simulations (P2D, P4D pouch/cylindrical). "
        "Typical flow: list_default_sets -> (optionally get_parameter_set / cell_kpis / validate_inputs) -> "
        "run_simulation -> get_time_series / get_state / get_metrics using the returned run_id. "
        "Inputs are given as a default-set name, a path to a JSON (or BPX) file, or an inline JSON object, "
        "plus optional nested '*_overrides' objects that are deep-merged on top. "
        "Units are SI unless stated otherwise (time in s, capacity in Ah, run energies in J). "
        "The first call after startup can take a few minutes while Julia compiles BattMo."
    ),
)

# ---------------------------------------------------------------------------
# Julia bridge (started lazily so the server can answer the MCP handshake fast)
# ---------------------------------------------------------------------------
_bridge = None


def _jl():
    global _bridge
    if _bridge is None:
        from juliacall import Main as jl  # noqa: PLC0415

        bridge_file = os.path.join(os.path.dirname(__file__), "bridge.jl")
        jl.include(bridge_file)
        _bridge = jl.BattMoMCPBridge
    return _bridge


def _call(name: str, *args: Any, error_cls: type[Exception] = ToolError) -> Any:
    """Call a bridge function and decode its JSON result.

    Julia exceptions are re-raised as ToolError/ResourceError: the SDK only forwards the
    message of those to the client (any other exception is reported as a generic crash),
    and the model needs the message to fix its inputs.
    """
    try:
        raw = getattr(_jl(), name)(*args)
    except Exception as e:  # juliacall.JuliaError, or Julia failing to start
        msg = str(e).split("\nStacktrace:")[0].strip()
        if len(msg) > 4000:
            msg = msg[:4000] + "\n…(truncated)"
        raise error_cls(msg) from e
    return json.loads(str(raw))


# ---------------------------------------------------------------------------
# Shared argument types
# ---------------------------------------------------------------------------
Source = Annotated[
    str | dict[str, Any] | None,
    Field(
        description=(
            "Default-set name (see list_default_sets), path to a JSON file (BattMo or BPX format), "
            "or an inline JSON object with the full parameter set. Omit to use the default."
        )
    ),
]
Overrides = Annotated[
    dict[str, Any] | None,
    Field(
        description=(
            "Nested object deep-merged on top of the loaded set, e.g. "
            '{"PositiveElectrode": {"Coating": {"Thickness": 8e-5}}} or {"DRate": 2.0}.'
        )
    ),
]


def _spec(**kwargs: Any) -> str:
    return json.dumps({k: v for k, v in kwargs.items() if v is not None})


# ---------------------------------------------------------------------------
# Catalog / inspection tools
# ---------------------------------------------------------------------------
@mcp.tool()
async def battmo_info() -> dict:
    """BattMo/Julia version and install path. Also warms up Julia (first call can be slow)."""
    return _call("battmo_info")


@mcp.tool()
async def list_default_sets() -> dict:
    """List the bundled default parameter sets per category (cell_parameters, cycling_protocol,
    model_settings, simulation_settings, solver_settings) with title, description and source."""
    return _call("list_default_sets")


@mcp.tool()
async def get_parameter_set(
    category: Literal["cell_parameters", "cycling_protocol", "model_settings", "simulation_settings", "solver_settings"],
    source: Annotated[str, Field(description="Default-set name or path to a JSON/BPX file.")],
) -> dict:
    """Return the full JSON content of a parameter set, e.g. to inspect values or use it as a
    starting point for an inline set. BPX files are converted to BattMo format."""
    return _call("get_parameter_set", category, source)


@mcp.tool()
async def describe(
    name: Annotated[str, Field(description="Parameter, setting or output variable name, or a search term (e.g. 'concentration').")],
    view: Annotated[
        Literal["CellParameters", "CyclingProtocol", "ModelSettings", "SimulationSettings", "SolverSettings", "OutputVariable"] | None,
        Field(description="Restrict the search to one category."),
    ] = None,
) -> dict:
    """Explain BattMo parameters/variables: meaning, unit, type and documentation links
    (wraps BattMo.print_info)."""
    return _call("describe", name, view)


@mcp.tool()
async def cell_kpis(cell_parameters: Source = None, cell_parameters_overrides: Overrides = None) -> dict:
    """Compute equilibrium cell KPIs from a cell parameter set without running a simulation:
    component masses, mass loadings, cell volume, theoretical capacity, N:P ratio, mass composition."""
    return _call(
        "cell_kpis",
        json.dumps({"source": cell_parameters or "chen_2020"}),
        json.dumps(cell_parameters_overrides or {}),
    )


# ---------------------------------------------------------------------------
# Simulation tools
# ---------------------------------------------------------------------------
BaseModel = Annotated[Literal["LithiumIonBattery", "SodiumIonBattery"], Field(description="Base battery model.")]


@mcp.tool()
async def validate_inputs(
    cell_parameters: Source = None,
    cycling_protocol: Source = None,
    model_settings: Source = None,
    simulation_settings: Source = None,
    cell_parameters_overrides: Overrides = None,
    cycling_protocol_overrides: Overrides = None,
    model_settings_overrides: Overrides = None,
    simulation_settings_overrides: Overrides = None,
    base_model: BaseModel = "LithiumIonBattery",
) -> dict:
    """Check inputs against BattMo's JSON schemas without solving. Returns is_valid and a log
    listing every issue (path, provided value, violated rule). Defaults: chen_2020, cc_discharge, p2d."""
    return _call(
        "validate_inputs",
        _spec(
            base_model=base_model,
            cell_parameters=cell_parameters,
            cycling_protocol=cycling_protocol,
            model_settings=model_settings,
            simulation_settings=simulation_settings,
            cell_parameters_overrides=cell_parameters_overrides,
            cycling_protocol_overrides=cycling_protocol_overrides,
            model_settings_overrides=model_settings_overrides,
            simulation_settings_overrides=simulation_settings_overrides,
        ),
    )


@mcp.tool()
async def run_simulation(
    cell_parameters: Source = None,
    cycling_protocol: Source = None,
    model_settings: Source = None,
    simulation_settings: Source = None,
    solver_settings: Source = None,
    cell_parameters_overrides: Overrides = None,
    cycling_protocol_overrides: Overrides = None,
    model_settings_overrides: Overrides = None,
    simulation_settings_overrides: Overrides = None,
    solver_settings_overrides: Overrides = None,
    base_model: BaseModel = "LithiumIonBattery",
    accept_invalid: Annotated[bool, Field(description="Run even if schema validation fails.")] = False,
    max_points: Annotated[int, Field(description="Max points in the returned time series preview.", ge=2, le=2000)] = 40,
) -> dict:
    """Run a BattMo simulation and keep the result in memory under a run_id.

    Defaults: cell chen_2020, protocol cc_discharge, model p2d. Returns status
    (success / incomplete / failed), wall time, metrics (capacity, energy, efficiency per cycle),
    a min/max/first/last summary of voltage, current and capacity, a downsampled time series and
    the tail of the solver log. Blocks until the simulation finishes; 3D (P4D) runs can take minutes.
    """
    return _call(
        "run_simulation",
        _spec(
            base_model=base_model,
            cell_parameters=cell_parameters,
            cycling_protocol=cycling_protocol,
            model_settings=model_settings,
            simulation_settings=simulation_settings,
            solver_settings=solver_settings,
            cell_parameters_overrides=cell_parameters_overrides,
            cycling_protocol_overrides=cycling_protocol_overrides,
            model_settings_overrides=model_settings_overrides,
            simulation_settings_overrides=simulation_settings_overrides,
            solver_settings_overrides=solver_settings_overrides,
            accept_invalid=accept_invalid or None,
        ),
        max_points,
    )


# ---------------------------------------------------------------------------
# Result tools
# ---------------------------------------------------------------------------
RunId = Annotated[str, Field(description="run_id returned by run_simulation.")]


@mcp.tool()
async def list_runs() -> dict:
    """List simulations kept in memory in this server session."""
    return _call("list_runs")


@mcp.tool()
async def get_time_series(
    run_id: RunId,
    quantities: Annotated[
        list[str] | None,
        Field(description="Subset of Time, Voltage, Current, CumulativeCapacity, NetCapacity, CycleNumber. Omit for all."),
    ] = None,
    max_points: Annotated[int, Field(ge=2, le=20000)] = 200,
    t_start: Annotated[float | None, Field(description="Start of time window in s.")] = None,
    t_end: Annotated[float | None, Field(description="End of time window in s.")] = None,
) -> dict:
    """Get time-series results of a run (evenly downsampled to max_points within the window)."""
    return _call("get_time_series", run_id, json.dumps(quantities or []), max_points, t_start, t_end)


@mcp.tool()
async def get_metrics(run_id: RunId) -> dict:
    """Per-cycle metrics of a run: discharge/charge capacity and energy, round-trip efficiency."""
    return _call("get_metrics", run_id)


@mcp.tool()
async def list_state_quantities(run_id: RunId) -> dict:
    """List the spatially resolved state quantities of a run as 'Component/Sub/Quantity' paths with array sizes."""
    return _call("list_state_quantities", run_id)


@mcp.tool()
async def get_state(
    run_id: RunId,
    quantity: Annotated[str, Field(description="Path from list_state_quantities, e.g. 'Electrolyte/Concentration'.")],
    time: Annotated[float | None, Field(description="Time in s; the nearest stored step is used. Omit for the final state.")] = None,
    max_points: Annotated[int, Field(ge=2, le=5000)] = 100,
) -> dict:
    """Get a spatial profile of a state quantity at one time (or a coordinate array such as Position)."""
    return _call("get_state", run_id, quantity, time, max_points)


@mcp.tool()
async def get_run_inputs(run_id: RunId) -> dict:
    """Return the spec a run was started with and the fully resolved input BattMo actually used."""
    return _call("get_run_inputs", run_id)


@mcp.tool()
async def export_time_series_csv(
    run_id: RunId,
    path: Annotated[str, Field(description="Destination .csv path on the server machine.")],
) -> dict:
    """Write the full-resolution time series of a run to a CSV file."""
    return _call("export_time_series_csv", run_id, path)


@mcp.tool()
async def delete_run(run_id: RunId) -> dict:
    """Free the memory held by a stored run."""
    return _call("delete_run", run_id)


# ---------------------------------------------------------------------------
# Resources
# ---------------------------------------------------------------------------
@mcp.resource("battmo://defaults", mime_type="application/json")
async def defaults_index() -> str:
    """Index of the bundled default parameter sets."""
    return json.dumps(_call("list_default_sets", error_cls=ResourceError), indent=2)


@mcp.resource("battmo://defaults/{category}/{name}", mime_type="application/json")
async def default_set(category: str, name: str) -> str:
    """A bundled default parameter set, e.g. battmo://defaults/cell_parameters/chen_2020."""
    return json.dumps(_call("get_parameter_set", category, name, error_cls=ResourceError), indent=2)


def main() -> None:
    mcp.run("stdio")


if __name__ == "__main__":
    main()
