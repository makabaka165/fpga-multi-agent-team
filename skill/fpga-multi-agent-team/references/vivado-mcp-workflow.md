# Vivado MCP Workflow

Use this reference when the `vivado` MCP tools are available.

## Fast-To-Slow Checks

1. Static XDC check: `xdc_lint` when constraints exist.
2. RTL syntax check: `verilog_compile_check` for selected files when Icarus/Verilator is available.
3. Vivado project info: `get_project_info`.
4. Synthesis: `run_synthesis`, then `get_critical_warnings`.
5. Implementation: `run_implementation`, then `get_timing_report`, `get_utilization_report`, and `get_io_report`.
6. Bitstream readiness: `check_bitstream_readiness` before `generate_bitstream`.

## Vivado Session Guidance

- Prefer `mode="tcl"` for batch checks.
- Use `mode="gui"` when the user wants to inspect project state, block designs, or waveforms.
- Use `mode="attach"` only when Vivado GUI is already open and vivado-mcp install hook is configured.
- Set `VIVADO_PATH` to the installed Vivado version if auto-detect fails.

## Safe Timing Flow

1. Run implementation before trusting final timing.
2. Read timing summary and critical paths.
3. Classify the path using `timing-closure.md`.
4. Change RTL/XDC narrowly.
5. Re-run the smallest necessary check.

## Warning Handling

- Treat `CRITICAL WARNING` as important until classified.
- Do not force bitstream generation through critical warnings unless the user explicitly accepts the risk.
- For XDC warnings, prefer fixing constraints rather than suppressing messages.

## Reporting

Always tell the user:

- which Vivado version/session was used
- whether synth/impl completed
- WNS/WHS or timing PASS/FAIL
- remaining critical warnings
- what files were changed
