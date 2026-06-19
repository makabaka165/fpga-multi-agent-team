# Timing Closure

Use this reference when Vivado reports negative WNS/TNS, hold violations, large route delay, or methodology warnings.

## First Response

Do not guess. Collect:

- clock name, period, WNS/TNS/WHS/THS
- startpoint and endpoint
- path group
- logic levels
- route delay vs logic delay
- fanout on high-delay nets
- whether the path crosses clocks
- related warnings from `report_methodology`, `report_drc`, and `report_clock_interaction`

## Classify The Problem

Missing or wrong constraints:
- unconstrained clock
- incorrect clock period
- missing generated clock
- IO paths lacking input/output delay
- accidental asynchronous clocks treated as related

RTL/datapath issue:
- too many logic levels in one cycle
- wide mux/case/priority chain
- large comparator/add/sub chain
- unregistered module boundaries
- long ready/valid combinational backpressure

Placement/routing issue:
- route delay dominates
- high fanout control/reset/enable
- scattered BRAM/DSP/register placement
- overfull device or congested region

CDC/reset issue:
- data path crosses unrelated clocks
- reset release or async input feeds logic
- missing synchronizer attributes

## Preferred Fixes

RTL fixes:
- add pipeline registers on long datapaths
- register inputs/outputs at module boundaries
- split wide combinational logic into stages
- replace priority logic with balanced decode when possible
- add skid buffers to break ready/valid loops
- reduce fanout by registering replicated control enables

Constraint fixes:
- add missing primary/generated clocks
- add IO delays based on board/external device timing
- declare asynchronous clock groups only for real async clocks with CDC handling
- add multicycle only when the protocol truly captures after multiple cycles

Implementation fixes:
- use Vivado timing report and utilization first
- consider retiming/pipeline-friendly RTL before strategy tweaks
- only after RTL/constraints are sound, try implementation strategies/directives

## What Not To Do

- Do not hide a real setup violation with `set_false_path`.
- Do not add broad wildcard exceptions.
- Do not assume all paths between different clock names are false.
- Do not pipeline control signals without matching data/valid alignment.
- Do not fix setup by weakening hold constraints.

## Result Explanation Template

When reporting a timing fix:

```text
Symptom: WNS <value> on <clock/path>.
Classification: <missing constraint | long logic | high fanout | CDC | IO | route>.
Change: <RTL/XDC/tool change>.
Why it is valid: <hardware reason>.
Verification: <report/test command and result>.
Residual risk: <remaining warnings or assumptions>.
```
