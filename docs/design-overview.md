# 设计概览：FPGA 多 Agent 编排团队

本项目的目标不是把 FPGA 开发包装成单次代码生成，而是把复杂硬件任务拆成可审计的工程流程。Orchestrator 负责拆解任务、安排专业 Agent、收集证据、处理冲突，并给出最终交付边界。

## 核心模式

```text
coordination_mode: orchestrated-agent-team
execution_mode: orchestrated-sequential-team
parallelism_claim: none
```

这里的“多 Agent”指角色专业化和交接闭环，不要求并行执行。每个 Agent 必须有明确职责、输入范围、输出证据、风险判断和交接包；Orchestrator 必须保留仲裁结论和可追溯矩阵。

## Agent 角色

| Agent | 职责 | 典型输出 |
| --- | --- | --- |
| Orchestrator | 拆解任务、设定验证门槛、安排角色、仲裁发现、给出交付状态。 | Agent roster、Evidence Ledger、仲裁表、Traceability Matrix |
| Requirements Agent | 提取硬件相关需求、时钟、复位、接口、吞吐、CDC 风险和硬件变化点。 | Requirement table、assumptions、open risks |
| Architecture Agent | 规划模块边界、参数、状态机、datapath、CDC/reset 策略和验证矩阵。 | Architecture plan、verification matrix |
| RTL Agent | 生成或修改 Vivado 友好的可综合 RTL。 | RTL 文件、接口说明、集成限制 |
| Verification Agent | 构建自检 testbench、scoreboard、timeout、边界场景和 PASS/FAIL 标准。 | Testbench、coverage notes、expected results |
| Constraints Agent | 创建或审查 XDC、clock、IO、timing exception 和 CDC 约束意图。 | XDC、exception rationale |
| Vivado Runner Agent | 选择并执行语法、仿真、综合、实现、timing、CDC、DRC 等检查。 | 工具命令、报告路径、pass/fail 结果 |
| Timing Closure Agent | 根据报告分类 timing 问题并选择 RTL/约束修复策略。 | Root cause、fix proposal、remaining risk |
| Release Agent | 汇总已验证产物、残留风险、集成说明和下一步检查。 | Release summary |

## 交接格式

每个角色输出统一格式，便于下一个角色消费：

```text
Agent: <role name>
Inputs:
- <used requirements, files, reports, assumptions>
Outputs:
- <decisions, files, checks, or review results>
Assumptions:
- <defaults selected due to missing data>
Evidence:
- <commands, reports, files, line references, or reasoning>
Risks:
- <unverified behavior, CDC/timing risk, integration boundary>
```

## 示例选择

仓库中的主示例是异步 FIFO，因为它覆盖 FPGA 开发中的关键问题：

- 两个无关时钟域。
- Gray pointer CDC 和两级同步器。
- `full` / `empty` 的跨域一致性。
- 自检 testbench 和 scoreboard。
- XDC 中异步 clock group 的语义边界。
- Vivado simulation、synthesis、implementation、CDC、timing、DRC 和 methodology 报告。

详见 `examples/async-fifo/README.md` 和 `docs/orchestrator-final-report.md`。

## 不做的声明

- 不声称并行 Agent 执行，除非另有运行时间证据。
- 不声称板级 bitstream readiness，除非提供真实 pin、IOSTANDARD、configuration voltage 和 external I/O delay。
- 不把 `set_clock_groups` 或 `false_path` 当作隐藏 timing 问题的通用手段。
- 不把通过一次 demo 等同于通用 FPGA IP signoff。
