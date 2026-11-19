# BattMo MCP server

A local [Model Context Protocol](https://modelcontextprotocol.io) server that lets LLM clients (Claude Code, Claude Desktop, Cursor, LangGraph agents, ...) run and inspect BattMo.jl simulations.

It is built with the official Python MCP SDK (`FastMCP`) and runs BattMo in-process through [juliacall](https://github.com/JuliaPy/PythonCall.jl). Julia starts and compiles once per server process, so only the first simulation is slow.

The server uses the BattMo.jl checkout it lives in (`dev` mode, see `src/battmo_mcp/juliapkg.json`), so local changes to BattMo are picked up on the next server start.

## Setup

Requires [uv](https://docs.astral.sh/uv/) and Julia ≥ 1.10 on `PATH` (juliaup recommended).

```sh
cd apps/mcp_server
uv sync
# One-time: resolve the Julia environment and precompile BattMo (several minutes)
uv run python -c "from juliacall import Main as jl; jl.seval('using BattMo')"
# Optional end-to-end check over stdio
uv run python smoke_test.py
```

The Julia environment lives in `.venv/julia_env`, separate from your other Julia projects.

## Connecting a client

Claude Code:

```sh
claude mcp add battmo -- uv --directory <path-to>/BattMo.jl/apps/mcp_server run battmo-mcp
```

Claude Desktop / Cursor / other clients (`mcpServers` JSON):

```json
{
  "mcpServers": {
    "battmo": {
      "command": "uv",
      "args": ["--directory", "<path-to>/BattMo.jl/apps/mcp_server", "run", "battmo-mcp"]
    }
  }
}
```

Debug with the MCP Inspector: `npx @modelcontextprotocol/inspector uv --directory . run battmo-mcp`.

## Tools

| Tool | Purpose |
|---|---|
| `battmo_info` | BattMo/Julia versions; warms up Julia |
| `list_default_sets` | Bundled cell parameters, protocols, model/simulation/solver settings |
| `get_parameter_set` | Full JSON of a default set or JSON/BPX file |
| `describe` | Meaning, unit and docs of a parameter or output variable (`print_info`) |
| `cell_kpis` | Masses, loadings, theoretical capacity, N:P ratio, mass composition, without simulating |
| `validate_inputs` | Schema validation with every issue listed |
| `run_simulation` | Solve and store the result under a `run_id`; returns metrics, a summary and a downsampled curve |
| `list_runs`, `get_run_inputs`, `delete_run` | Manage stored runs |
| `get_time_series`, `get_metrics` | Time-series results (windowed and downsampled) and per-cycle metrics |
| `list_state_quantities`, `get_state` | Spatial profiles (concentrations, potentials, ...) at a chosen time |
| `export_time_series_csv` | Full-resolution time series to CSV |

Resources: `battmo://defaults` and `battmo://defaults/{category}/{name}`.

### Specifying inputs

Every input (`cell_parameters`, `cycling_protocol`, `model_settings`, `simulation_settings`, `solver_settings`) accepts:

- a default-set name, e.g. `"chen_2020"`, `"cccv"`, `"p4d_pouch"`
- a path to a JSON file (BPX files are detected and converted automatically)
- an inline JSON object

A matching `*_overrides` object is deep-merged on top, e.g.

```json
{
  "cell_parameters": "chen_2020",
  "cycling_protocol": "cc_discharge",
  "cycling_protocol_overrides": {"DRate": 2.0},
  "cell_parameters_overrides": {"PositiveElectrode": {"Coating": {"Thickness": 8e-5}}}
}
```

Defaults are `chen_2020`, `cc_discharge` and `p2d`.

## Design notes

- **Stdout protection.** MCP over stdio owns file descriptor 1. On startup the server keeps a private copy of fd 1 for MCP and points fd 1 at stderr, so anything Julia prints goes to the client's server log. Output from BattMo calls is also captured and returned in each tool's `log` field.
- **Small responses.** Simulations are kept in memory and responses carry only summaries and downsampled data. Fetch more with `get_time_series` / `get_state`.
- **One thing at a time.** Julia is called from the event-loop thread (juliacall is not thread-safe), so a running simulation blocks other requests until it finishes. Runs are lost when the server restarts.
