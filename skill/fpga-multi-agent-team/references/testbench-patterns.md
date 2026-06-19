# Testbench Patterns

Use this reference for fast, practical RTL tests.

## Defaults

- Keep simple tests in plain Verilog/SystemVerilog compatible with Icarus, Verilator, or XSim.
- Use cycle-based synchronization: `@(posedge clk)` rather than raw `#` delays after reset/stimulus except for clock generation.
- Add a timeout.
- Make tests self-checking and print a clear PASS/FAIL.
- Dump VCD/FST only when waveform inspection is useful.

## Minimal Self-Checking TB

```verilog
`timescale 1ns/1ps

module tb_example;
  reg clk = 1'b0;
  reg rst = 1'b1;

  always #5 clk = ~clk;

  initial begin
    repeat (5) @(posedge clk);
    rst = 1'b0;
  end

  initial begin
    repeat (1000) @(posedge clk);
    $display("FAIL: timeout");
    $finish;
  end
endmodule
```

## Checks

- Use tasks for repeated transactions.
- Store expected values in a small scoreboard when outputs are delayed.
- For pipelines, track valid bits and expected data through the same latency.
- Use `!==` when checking for X/Z sensitivity.
- Exercise reset, idle, boundary values, max/min counter values, simultaneous events, and backpressure.

## Waveform Workflow

Add:

```verilog
initial begin
  $dumpfile("wave.vcd");
  $dumpvars(0, tb_name);
end
```

Inspect waveforms when:

- a self-check fails
- a protocol handshake stalls
- timing alignment is unclear
- reset/CDC behavior is suspect

## Comparison Template

```text
Expected:
- <behavior>

Observed:
- <simulation output or waveform fact>

Result:
- PASS if all expected conditions match; otherwise describe first mismatch.
```
