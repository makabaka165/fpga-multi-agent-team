# Vivado 异步 FIFO 验证摘要

日期：2026-06-19

验证对象：

- `examples/async-fifo/rtl/async_fifo.v`
- `examples/async-fifo/tb/tb_async_fifo.v`
- `examples/async-fifo/constraints/async_fifo.xdc`

工具：

- Vivado 2024.2
- 目标器件：`xc7a35tcsg324-1`
- 可复现脚本：`examples/async-fifo/scripts/run_async_fifo_vivado.tcl`

推荐重新运行命令：

```powershell
vivado -mode batch -source examples/async-fifo/scripts/run_async_fifo_vivado.tcl -nojournal -log examples/async-fifo/build/vivado_batch.log
```

## Scope / 范围

这是异步 FIFO demo 的 standalone IP-level validation。检查范围包括 XSim 行为仿真、Vivado 综合、布局布线、时序、clock interaction、timing exceptions、CDC 分类、DRC、methodology 和资源占用。

这不是 board-level bitstream signoff，因为 demo 没有提供板级引脚位置、I/O 标准、configuration voltage 属性或外部 input/output delay 约束。

## Result Summary / 结果摘要

| 检查项 | 结果 | 证据 |
| --- | --- | --- |
| 行为仿真 | Pass | `simulate.log` 报告 `PASS: async FIFO self-check completed writes=177 reads=177`，覆盖基础顺序、full/empty、read-while-empty 和随机 stall/burst 阶段。 |
| 综合 | Pass | `run_status.txt` 记录 `synthesis: passed`；Vivado synthesis 无 errors 或 critical warnings。 |
| 实现 | Pass | `run_status.txt` 记录 `implementation: passed`；route status 为 0 routing errors。 |
| Post-route timing | 对已声明约束 Pass | `post_route_timing_summary.rpt`：WNS 6.391 ns，TNS 0.000 ns，WHS 0.116 ns，THS 0.000 ns，且所有 user specified timing constraints met。 |
| CDC report | 对识别到的同步器路径 Pass | `cdc.rpt`：wr_clk 到 rd_clk 有 13 个 safe endpoints，rd_clk 到 wr_clk 有 5 个 safe endpoints，0 unsafe，0 unknown，0 missing ASYNC_REG。 |
| Clock interaction | 符合预期 | `post_route_clock_interaction.rpt`：同 clock paths 被正常计时，wr_clk / rd_clk crossing 被 asynchronous groups 忽略。 |
| Timing exceptions | 符合预期 | `exceptions.rpt`：仅报告 wr_clk 与 rd_clk 之间的两个 clock-group exceptions。 |
| 资源占用 | 很小 | `post_route_utilization.rpt`：28 LUTs，48 registers，0 BRAM，0 DSP，2 BUFGCTRL，24 bonded IOBs。 |
| DRC | 保留板级 warning | `post_route_drc.rpt`：NSTD-1、UCIO-1 critical warnings 和 CFGBVS-1 warning，原因是刻意未提供 board pins、I/O standards 和 configuration voltage。 |
| Methodology | 保留板级 / 接口 warning | `post_route_methodology.rpt`：22 个 TIMING-18 warning，原因是 standalone IP demo 刻意未提供外部 input/output delays。 |

## Agent Evidence Use / Agent 证据用途

该报告用于支撑 Orchestrator 的最终仲裁：

- `TIM-003`：Vivado 报告可用，standalone IP-level synthesis/implementation/timing/CDC 证据成立。
- `TIM-004`：在已声明内部约束下 post-route timing 通过。
- board-level signoff 仍不在范围内，必须等真实 top-level design 提供 pins、I/O standards、configuration voltage 和 external I/O delays 后才能声明。

## Residual Risks / 残留风险

- 单独复位某一个时钟域并在运行中恢复，仍然是集成级设计风险。
- testbench 已补充 read-while-empty underflow 刺激和随机 burst/stall 覆盖；仍可继续增加多组时钟比例 / 相位 sweep 和 passive handshake monitor。
- 发布为可复用 FIFO IP 前，应记录或强制 `ADDR_WIDTH >= 2`。
- 没有生成 bitstream；DRC 结果说明在没有板级约束时不应声明 bitstream readiness。

## Artifact Index / 产物索引

| 产物 | 用途 |
| --- | --- |
| `simulate.log` | XSim 行为仿真结果。 |
| `run_status.txt` | 机器可读 pass/fail 摘要。 |
| `post_route_timing_summary.rpt` | 最终 routed timing summary。 |
| `cdc.rpt` | 综合后的 CDC report。 |
| `post_route_clock_interaction.rpt` | routed clock interaction report。 |
| `exceptions.rpt` | timing exception report。 |
| `post_route_drc.rpt` | routed DRC report。 |
| `post_route_methodology.rpt` | routed methodology report。 |
| `post_route_utilization.rpt` | routed utilization report。 |

