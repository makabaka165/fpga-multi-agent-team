# Vivado XDC Guidelines

Use this reference when creating or reviewing constraints for Vivado.

## Constraint Order

1. Define clocks.
2. Define generated clocks.
3. Define IO timing relative to board/external devices.
4. Define clock relationships and CDC exceptions only when true.
5. Define physical constraints: pins, IOSTANDARD, drive, slew, placement attributes.

## Clocks

- Every real design clock needs a `create_clock` on the input port or source pin.
- Use the actual board oscillator period. Example for 100 MHz:

```tcl
create_clock -name sys_clk -period 10.000 [get_ports clk]
```

- Generated clocks should be tied to the actual generated-clock source, not invented at a downstream random net.
- MMCM/PLL generated clocks are often auto-derived, but verify with `report_clocks` and `report_clock_interaction`.

## IO Constraints

- Every constrained pin should have an `IOSTANDARD`.
- Do not guess pins. Use the board schematic/master XDC and verify voltage bank compatibility.
- External timing interfaces need `set_input_delay` and `set_output_delay` relative to a clock when setup/hold at the device boundary matters.
- Simple LEDs/buttons/UART can often start with pin and IOSTANDARD only, but clocks still need timing constraints.

## Timing Exceptions

Timing exceptions are not timing fixes. They are design intent declarations.

- `set_clock_groups -asynchronous`: use only for clocks that are genuinely asynchronous and whose crossings are handled by CDC logic.
- `set_false_path`: use for paths that must never be timed because the logic relationship is not functional or is covered by another valid mechanism.
- `set_multicycle_path`: use only when the source and destination intentionally allow multiple clock cycles for data capture. Always consider both setup and hold side effects.
- Do not add exceptions simply because WNS is negative.
- Document each exception with the signal/path reason.

## Common Safe Patterns

Async clock groups:

```tcl
set_clock_groups -asynchronous \
  -group [get_clocks clk_a] \
  -group [get_clocks clk_b]
```

Synchronizer attributes in XDC if not in RTL:

```tcl
set_property ASYNC_REG TRUE [get_cells -hier -regexp {.*sync_reg.*}]
```

Pin with IO standard:

```tcl
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
```

## Validation Commands

- `report_clocks`
- `report_clock_interaction`
- `report_exceptions`
- `report_timing_summary`
- `report_methodology`
- `report_drc`

## Review Checklist

- All primary clocks constrained.
- No unconstrained internal/generated clocks that affect logic.
- No missing IOSTANDARD on physical IO.
- No false/multicycle paths without a written hardware reason.
- CDC paths have real synchronizers/FIFOs/handshakes.
- Constraints match board voltage and pinout.
