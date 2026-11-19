"""End-to-end smoke test: starts the server over stdio and calls each tool once.

    uv run python smoke_test.py
"""

import asyncio
import json
import sys
import time

from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client


def show(name, result, limit=900):
    text = result.content[0].text if result.content else ""
    flag = "ERROR " if result.is_error else ""
    print(f"\n=== {flag}{name} ===\n{text[:limit]}{'…' if len(text) > limit else ''}", flush=True)
    return None if result.is_error else json.loads(text)


async def main():
    params = StdioServerParameters(command=sys.executable, args=["-m", "battmo_mcp.server"])
    async with stdio_client(params) as (read, write):
        async with ClientSession(read, write) as session:
            await session.initialize()
            tools = await session.list_tools()
            print("tools:", [t.name for t in tools.tools])

            t0 = time.time()
            show("battmo_info", await session.call_tool("battmo_info", {}))
            print(f"(startup {time.time() - t0:.0f}s)")

            show("list_default_sets", await session.call_tool("list_default_sets", {}), 400)
            show("describe", await session.call_tool("describe", {"name": "DRate"}), 600)
            show("cell_kpis", await session.call_tool("cell_kpis", {"cell_parameters": "chen_2020"}))
            show(
                "validate_inputs (bad)",
                await session.call_tool("validate_inputs", {"cycling_protocol_overrides": {"DRate": -3}}),
                1200,
            )

            t0 = time.time()
            r = show("run_simulation", await session.call_tool("run_simulation", {"max_points": 5}), 1500)
            print(f"(run {time.time() - t0:.0f}s)")
            t0 = time.time()
            r2 = show(
                "run_simulation 2C",
                await session.call_tool("run_simulation", {"cycling_protocol_overrides": {"DRate": 2.0}, "max_points": 3}),
                600,
            )
            print(f"(second run {time.time() - t0:.0f}s)")

            rid = r["run_id"]
            show("get_time_series", await session.call_tool("get_time_series", {"run_id": rid, "quantities": ["Time", "Voltage"], "max_points": 5}))
            show("get_metrics", await session.call_tool("get_metrics", {"run_id": rid}))
            q = show("list_state_quantities", await session.call_tool("list_state_quantities", {"run_id": rid}), 1500)
            path = next((k for k in q["quantities"] if "Electrolyte" in k and "Concentration" in k), next(iter(q["quantities"])))
            show("get_state", await session.call_tool("get_state", {"run_id": rid, "quantity": path, "max_points": 6}))
            show("list_runs", await session.call_tool("list_runs", {}))
            show("get_time_series unknown run", await session.call_tool("get_time_series", {"run_id": "run_99"}))

            res = await session.read_resource("battmo://defaults/cycling_protocol/cc_discharge")
            print("\n=== resource ===\n", res.contents[0].text[:300])


asyncio.run(main())
