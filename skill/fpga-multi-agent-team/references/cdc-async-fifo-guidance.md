# CDC Async FIFO Guidance

Use this reference when the user asks for an asynchronous FIFO, a cross-clock stream buffer, or gray-pointer CDC guidance.

## Requirement Pattern

Build an asynchronous FIFO for crossing a data stream from a write clock domain into an unrelated read clock domain.

Default assumptions when the user does not specify otherwise:

- RTL language: Verilog-2001.
- Data width: parameter `DATA_WIDTH`, default 8.
- Depth: parameter `ADDR_WIDTH`, default 4, giving 16 entries.
- Write interface: `wr_clk`, `wr_rst`, `wr_en`, `wr_data`, `full`.
- Read interface: `rd_clk`, `rd_rst`, `rd_en`, `rd_data`, `empty`.
- Reset: synchronous active-high reset per clock domain unless project style says otherwise.
- Full/empty scheme: binary pointers locally, gray-coded pointers crossing domains through two-stage synchronizers.
- Timing intent: write and read clocks are asynchronous; functional CDC is handled by gray pointers and synchronizers.

## Agent Sequence

1. Orchestrator: set the goal, verification bar, and role sequence.
2. Requirements Agent: lock the default assumptions and flag depth/reset choices as hardware-impacting.
3. Architecture Agent: define pointer, memory, gray conversion, synchronizer, full, and empty logic.
4. RTL Agent: generate the FIFO and small helper gray/binary logic.
5. Verification Agent: generate unrelated-clock self-checking testbench with scoreboard.
6. Constraints Agent: define two clocks and document async clock grouping only after CDC structure exists.
7. Vivado Runner Agent: run or propose syntax, simulation, synthesis, implementation, and timing checks.
8. Timing Closure Agent: review CDC/timing warnings and avoid hiding real violations.
9. Release Agent: summarize ready artifacts, evidence, and residual risk.

## Requirements Agent Output

Use this table shape:

| Item | Value | Source | Assumption? | Impact if wrong |
| --- | --- | --- | --- | --- |
| Data width | Project-defined via `DATA_WIDTH` | User/project | Maybe | Interface width and scoreboard data type change |
| FIFO depth | Project-defined via `ADDR_WIDTH` | User/project | Maybe | Pointer width, full/empty behavior, memory size change |
| Clock relation | `wr_clk` and `rd_clk` asynchronous | Design goal | No | Determines CDC structure and XDC clock grouping |
| Reset style | Project-defined per domain | User/project | Maybe | RTL reset blocks and integration reset polarity change |
| Overflow behavior | Ignore writes while `full`, unless specified otherwise | Conservative default | Yes | Testbench expected behavior changes |
| Underflow behavior | Hold data and ignore reads while `empty`, unless specified otherwise | Conservative default | Yes | Testbench expected behavior changes |

Ask the user only if reset polarity, depth, interface semantics, or first-word fall-through behavior must match an existing project.

## Architecture Agent Plan

Required design choices:

- Keep one binary write pointer and one gray write pointer in the write domain.
- Keep one binary read pointer and one gray read pointer in the read domain.
- Cross only gray-coded pointers between domains using two-stage synchronizers marked with `ASYNC_REG`.
- Use memory indexed by the lower `ADDR_WIDTH` bits of local binary pointers.
- Compute `empty` in the read domain by comparing next read gray pointer against synchronized write gray pointer.
- Compute `full` in the write domain by comparing next write gray pointer against synchronized read gray pointer with the two most-significant bits inverted.
- Use one extra pointer bit to distinguish full and empty.
- Do not synchronize multi-bit binary pointers directly.

Recommended module interface:

```verilog
module async_fifo #(
  parameter DATA_WIDTH = 8,
  parameter ADDR_WIDTH = 4
) (
  input  wire                  wr_clk,
  input  wire                  wr_rst,
  input  wire                  wr_en,
  input  wire [DATA_WIDTH-1:0] wr_data,
  output wire                  full,
  input  wire                  rd_clk,
  input  wire                  rd_rst,
  input  wire                  rd_en,
  output reg  [DATA_WIDTH-1:0] rd_data,
  output wire                  empty
);
```

Expected latency:

- `full` and `empty` can lag cross-domain activity by synchronizer latency.
- `rd_data` updates on a valid read transaction unless the implementation intentionally chooses first-word fall-through and documents it.

## RTL Agent Focus

Generate or review for these points:

- Use `localparam PTR_WIDTH = ADDR_WIDTH + 1`.
- Use a `bin_to_gray` helper expression: `(bin >> 1) ^ bin`.
- Compute next binary pointers from accepted transactions:
  - `wr_do = wr_en && !full`
  - `rd_do = rd_en && !empty`
- Register local binary and gray pointers in their own domains.
- Synchronize remote gray pointers with two registers in each destination domain.
- Add `(* ASYNC_REG = "TRUE" *)` attributes on synchronizer registers.
- Avoid writing memory when full and avoid reading memory when empty.
- Keep all memory writes in the write clock domain and read data update in the read clock domain.

Potential review issue to catch:

- Computing `full` from the current write pointer instead of the next write pointer causes an off-by-one capacity bug.
- Computing `empty` from the current read pointer can produce stale empty behavior after a read.
- Comparing binary pointers that crossed clock domains is invalid CDC.

## Verification Agent Matrix

The self-checking testbench should use unrelated clock periods, for example 10 ns write clock and 14 ns read clock, with optional initial phase offset.

| Scenario | Expected check |
| --- | --- |
| Reset both domains | FIFO reports empty, not full, and scoreboard is clear |
| Single write then read | Read data equals first written byte in order |
| Fill to full | `full` asserts after accepted capacity and extra writes are ignored |
| Drain to empty | All accepted data is read in order, then `empty` asserts |
| Simultaneous traffic | Scoreboard preserves order under different clock rates |
| Write while full | No extra item enters scoreboard |
| Read while empty | No invalid item is popped |
| Random burst traffic | PASS after many accepted transactions with no mismatch |

Testbench requirements:

- Track accepted writes only when `wr_en && !full`.
- Pop expected data only when `rd_en && !empty`.
- Use timeout guards in both domains or a global simulation timeout.
- Print `PASS` only after scoreboard drains and all comparisons match.
- Use `!==` for comparisons to catch X/Z.

## Constraints Agent Guidance

Minimal clock constraints:

```tcl
create_clock -name wr_clk -period 10.000 [get_ports wr_clk]
create_clock -name rd_clk -period 14.000 [get_ports rd_clk]
```

If the clocks are genuinely asynchronous and all functional crossings are gray-pointer synchronizers, document and use:

```tcl
set_clock_groups -asynchronous \
  -group [get_clocks wr_clk] \
  -group [get_clocks rd_clk]
```

Do not add broad false paths as a substitute for CDC logic. Do not declare clocks asynchronous until the RTL crossing structure is verified.

## Vivado Runner Path

Use the fastest credible checks first:

1. Verilog syntax or lint check for `async_fifo.v` and `tb_async_fifo.v`.
2. Behavioral simulation and PASS/FAIL output.
3. Vivado synthesis, then critical warning review.
4. Implementation and timing summary if a target part/project is available.
5. `report_clock_interaction`, `report_exceptions`, `report_methodology`, and `report_drc` for CDC/constraint confidence.

If Vivado is unavailable, state that limitation and use simulation plus static CDC reasoning as the substitute evidence.

## Timing Closure Agent Triggers

Run timing closure analysis if:

- Vivado reports negative WNS/WHS.
- `report_clock_interaction` shows unexpected related clocks.
- Synchronizer registers are optimized, replicated incorrectly, or lack `ASYNC_REG`.
- Full/empty logic has high fanout or long comparator paths.

Preferred fixes:

- Add or preserve synchronizer attributes.
- Correct clock grouping only when CDC structure is valid.
- Register high-fanout status outputs at module boundaries if integration timing requires it.
- Avoid false paths that mask non-CDC datapaths.

## Release Summary Pattern

Use this final shape:

```text
Built:
- Parameterized async FIFO with gray-pointer CDC.

Artifacts:
- async_fifo.v
- tb_async_fifo.v
- optional async_fifo.xdc

Evidence:
- <syntax/simulation/Vivado checks actually run>

Assumptions:
- DATA_WIDTH=8, ADDR_WIDTH=4, synchronous active-high resets, unrelated clocks.

Residual risks:
- <checks not run, target board unknowns, timing reports unavailable, or integration reset polarity>

Next check:
- Run Vivado synthesis/implementation on the target part and inspect critical warnings, timing summary, and clock interaction.
```
