# FPGA Multi-Agent Team

面向 FPGA / Verilog / SystemVerilog 开发的多 Agent 编排式 skill。它把复杂硬件任务拆成需求、架构、RTL、验证、约束、Vivado 检查、时序收敛和发布交接等专业角色，再由 Orchestrator 汇总证据并做工程仲裁。

这个项目的重点不是“多个 Agent 必须并行运行”，而是让 FPGA 开发过程具备可审计的团队协作结构：

```text
coordination_mode: orchestrated-agent-team
execution_mode: orchestrated-sequential-team
parallelism_claim: none
```

## What It Does

- 将自然语言 FPGA 需求拆成硬件相关 requirement table。
- 生成或审查 Vivado 友好的 RTL、testbench 和 XDC。
- 对 CDC、reset、full/empty、timing exception、DRC/methodology warning 做结构化审查。
- 按角色输出 handoff packet：`Inputs / Outputs / Assumptions / Evidence / Risks`。
- 生成 Evidence Ledger、Orchestrator 仲裁表和 Traceability Matrix。
- 用 Vivado/XSim 报告闭环验证，而不是只停留在文字流程。

## Repository Layout

```text
fpga-multi-agent-team/
  skill/fpga-multi-agent-team/
    SKILL.md
    agents/openai.yaml
    references/
  examples/async-fifo/
    rtl/async_fifo.v
    tb/tb_async_fifo.v
    constraints/async_fifo.xdc
    scripts/run_async_fifo_vivado.tcl
    reports/
  docs/
    design-overview.md
    orchestrator-final-report.md
```

## Install

把 `skill/fpga-multi-agent-team/` 复制到支持本地 skills 的 Agent 环境中。兼容环境通常只需要一个包含 `SKILL.md` 的目录：

```text
fpga-multi-agent-team/
  SKILL.md
  agents/openai.yaml
  references/
```

示例：

```powershell
# Codex-style local skills directory example
Copy-Item -Recurse skill/fpga-multi-agent-team "$env:USERPROFILE\.codex\skills\fpga-multi-agent-team"
```

也可以把 `skill/fpga-multi-agent-team/` 放到 Qoder、Claude Code 或其他支持本地 skill/instruction 约定的 Agent 项目目录中使用。不同工具的目录名称可能不同，但核心内容是同一个 `SKILL.md` 和 `references/`。

## Quick Start Prompt

```text
使用 fpga-multi-agent-team skill。

按 Orchestrator 编排 Requirements、Architecture、RTL、Verification、Constraints、Vivado Runner、Timing Closure、Release Agent，完成一个异步 FIFO 的开发与验证。

最终报告需要包含：
- coordination_mode / execution_mode / parallelism_claim
- Requirements table
- Architecture plan
- RTL/testbench/XDC artifacts
- Evidence Ledger
- Orchestrator arbitration table
- Traceability Matrix
- Vivado/XSim checks actually run
- residual risks and next checks
```

## Included Example: Async FIFO

`examples/async-fifo/` 是一个完整 demo，展示从异步 FIFO 需求到 Vivado 证据闭环的流程。

包含文件：

- `rtl/async_fifo.v`
- `tb/tb_async_fifo.v`
- `constraints/async_fifo.xdc`
- `scripts/run_async_fifo_vivado.tcl`
- `reports/` 下的已捕获 Vivado 报告

已捕获结果：

| Check | Result |
| --- | --- |
| XSim simulation | PASS, `writes=177 reads=177` |
| Synthesis | PASS |
| Implementation | PASS |
| CDC | 18 safe endpoints, 0 unsafe, 0 unknown, 0 missing ASYNC_REG |
| Post-route timing | WNS 6.391 ns, TNS 0.000 ns, WHS 0.116 ns, THS 0.000 ns |

## Re-run Vivado

在安装 Vivado 2024.x 的 Windows 环境中，从仓库根目录运行：

```powershell
vivado -mode batch -source examples/async-fifo/scripts/run_async_fifo_vivado.tcl -nojournal -log examples/async-fifo/build/vivado_batch.log
```

如果 `vivado` 不在 `PATH` 中，可以使用完整路径：

```powershell
& 'E:\Xilinx\Vivado\2024.2\bin\vivado.bat' -mode batch -source examples/async-fifo/scripts/run_async_fifo_vivado.tcl -nojournal -log examples/async-fifo/build/vivado_batch.log
```

脚本会把可再生工程输出写入 `examples/async-fifo/build/`，不会覆盖仓库中保留的报告快照。

## Design Notes

- Skill 正文使用英文，便于 LLM Agent 稳定执行。
- README 和说明文档使用中文，便于中文读者快速理解项目目标。
- 默认多 Agent 证明来自角色分工、隔离输入、独立发现、交接格式、Orchestrator 仲裁和工具验证闭环。
- 不声明并行执行，除非有运行时间证据。
- 不声明 board-level signoff，除非提供真实板级 pin、IOSTANDARD、configuration voltage 和 external I/O delay。

## Documentation

- `docs/design-overview.md`：多 Agent 编排模式、角色职责和边界。
- `docs/orchestrator-final-report.md`：异步 FIFO demo 的编排验证报告。
- `examples/async-fifo/reports/vivado-validation-summary.md`：Vivado/XSim 检查摘要。
- `skill/fpga-multi-agent-team/references/`：skill 执行时按需加载的参考资料。

## Validation

当前开源版已通过基础 skill 校验：

```text
Skill is valid!
```

异步 FIFO 示例已保留 Vivado 2024.2 报告快照。该验证是 standalone IP-level validation，不是板级 bitstream readiness 或 board-level timing signoff。

## License

MIT License. See `LICENSE`.
