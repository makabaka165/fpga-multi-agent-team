# Vivado RTL Guidelines

Use this reference when writing or reviewing synthesizable RTL for Vivado FPGA projects.

## Defaults

- Target Vivado 2024.x unless the project says otherwise.
- Prefer Verilog-2001 compatible RTL when the user is learning or the project already uses `.v`.
- Use conservative SystemVerilog (`logic`, `always_ff`, `always_comb`, `typedef enum`) only when the project already uses `.sv` or the user requests it.
- Keep simulation-only constructs out of synthesizable modules: `#delay`, event controls inside tasks for hardware behavior, `$display`, `$finish`, file IO, force/release, and unsynthesizable `initial` usage.

## Clocks And Resets

- Use one primary clock domain when possible.
- Do not create clocks in LUT fabric with ordinary logic. Use clock enables for divided-rate logic unless a real generated clock/MMCM/PLL/BUFG flow is intended.
- Pick reset style from project convention. If absent, prefer synchronous active-high or active-low reset consistently; for Xilinx IP-style interfaces active-low `rst_n`/`aresetn` is common.
- For asynchronous reset, prefer async assert and synchronous deassert per clock domain. Do not feed unsynchronized reset release into many domains.
- Avoid resetting large inferred memories unless required; reset control pointers/valid bits instead.

## Always Blocks

- Sequential logic: one clock edge per always block; use nonblocking assignments.
- Combinational logic: assign every output/default before conditionals; use blocking assignments.
- Do not drive the same register from multiple always blocks.
- Do not mix blocking and nonblocking assignments to the same signal.
- Give every `case` a `default`; use explicit safe fallback for FSMs.

## Width And Numeric Safety

- Use sized constants for arithmetic and comparisons (`8'd1`, `16'h00ff`).
- Keep counters wide enough for the terminal value. For `0..N-1`, width is `ceil(log2(N))`.
- Avoid implicit truncation/extension. Slice or cast intentionally.
- Use localparams for derived constants and magic numbers.

## FSMs

- Prefer two-process FSM for beginners: state register plus combinational next-state/output defaults.
- For glitch-sensitive outputs, register outputs.
- Define reset state and illegal-state default recovery.
- Keep state transitions based on synchronized inputs.

## Memory And DSP Inference

- For block RAM, use synchronous read patterns unless the project intentionally needs LUT RAM.
- Use attributes only when needed and comment why, for example `(* ram_style = "block" *)`.
- For multipliers/adders that should map to DSPs, keep pipeline stages clear and widths aligned with device DSP capabilities.

## CDC And Synchronizers

- Single-bit CDC: use 2+ flip-flop synchronizer in the destination clock domain.
- Multi-bit CDC: use handshake, async FIFO, or gray-coded pointer scheme; never synchronize each bit independently as data.
- Pulse CDC: stretch, toggle-sync, or handshake so the destination cannot miss it.
- Xilinx synchronizer flops should use `(* ASYNC_REG = "TRUE" *)`; keep stages adjacent and out of ordinary logic.
- Do not apply CDC exceptions without a real CDC structure.

## Review Checklist

- No inferred latches unless intentionally documented.
- No combinational loops.
- No uninitialized control register after reset.
- No implicit nets. Add ``default_nettype none`` when compatible with the project.
- All module instances use named port connections.
- Inputs crossing domains are synchronized.
- Testbench has a timeout and self-checking assertions or comparisons.
