# lowRISC-Style RTL Adaptation

Use this reference for readable Verilog/SystemVerilog style. It is adapted for Vivado FPGA work; project conventions override it.

## Naming

- Modules/files: `lower_snake_case`, file name matches module name.
- Signals: `lower_snake_case`.
- Active-low signals: suffix `_n`.
- Clocks: `clk`, or domain-specific `clk_sys`, `clk_pix`.
- Resets: `rst_n`, `rst_sys_n`, or project convention.
- Parameters/localparams: `UPPER_SNAKE_CASE`.
- Instances: `u_<module_or_role>`.

## File Organization

1. Header comment with purpose and key assumptions.
2. Parameters.
3. Ports grouped by clock/reset, input interfaces, output interfaces.
4. Localparams.
5. Internal signals.
6. Combinational assignments.
7. Sequential blocks.
8. Submodule instances.

## Formatting

- Use consistent 2 or 4 space indentation; follow existing project style.
- One declaration per line for important signals.
- Align port directions and widths where readable.
- Prefer named port connections over positional connections.

## Comments

- Comment hardware intent, not syntax.
- Document clock domain, reset behavior, latency, and any timing exception assumptions.
- Comment non-obvious constants and protocol behavior.

## Style Rules

- Avoid implicit nets; use ``default_nettype none`` if the project supports it.
- Avoid `casex`; use `casez` only with care and comments.
- Use default assignments in combinational logic.
- Use localparams for FSM state encodings in Verilog-2001; use enum only when SystemVerilog is acceptable.
- Keep module interfaces narrow and explicit. Do not expose debug internals unless needed.

## Beginner-Friendly Default

For a user still learning FPGA/Verilog, generate:

- plain `.v` Verilog-2001 unless `.sv` is requested
- one clock and one reset
- explicit `reg`/`wire`
- simple two-process FSM
- self-checking testbench with `$fatal`/`$display`
- XDC notes separately from RTL
