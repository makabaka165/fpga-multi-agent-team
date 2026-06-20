---
name: fpga-multi-agent-team
description: Multi-agent FPGA development and verification workflow for Vivado-focused Verilog/SystemVerilog projects. Use when Codex needs to orchestrate an AI hardware team to turn requirements into RTL, testbenches, constraints, simulation/synthesis/implementation checks, CDC analysis, timing debug, repair iterations, and final engineering handoff for FPGA modules or projects.
---

# FPGA Multi-Agent Development Team

Use this skill to run a coordinated FPGA engineering team. Optimize for correct hardware behavior first, then verification confidence, then coding clarity, then timing/resource efficiency. Prefer project files and measured tool output over generic code generation. Use vendor documentation to verify exact Vivado behavior, XDC semantics, timing analysis, and device-specific details when precision matters.

This skill is ready to run as `SKILL.md` inside a compatible skill directory. Keep private development copies outside installed skill directories when iterating.

## Source Priority

1. Project files and user requirements.
2. Actual evidence: simulator output, Vivado logs, synthesis/implementation reports, CDC reports, DRC/methodology reports, timing summaries, and board files.
3. Vendor documentation for exact Vivado/XDC/device behavior when needed.
4. This skill's bundled references for workflow, role handoffs, RTL style, verification, constraints, timing, and evidence protocols.
5. Public style guides may inform readability preferences only when attributed; project style overrides generic style.

## Motivation And Boundary

General LLMs can accelerate Verilog/SystemVerilog work, but FPGA code has hardware-specific failure modes that may not appear as syntax errors: unsafe CDC, ambiguous reset release, weak testbenches, incorrect full/empty logic, unjustified timing exceptions, or unverified timing claims.

This skill turns those risks into an Orchestrator-led workflow. It extends the single-assistant FPGA workflow pattern used by `verilog-fpga-assistant` into a multi-agent team: each role owns a slice of the engineering evidence, then the Orchestrator integrates findings and states what is verified versus still assumed.

## Team Operating Model

Load `references/multi-agent-fpga-team.md` for complex FPGA tasks, project bring-up, verification-heavy requests, timing/debug work, or any request that benefits from explicit role handoffs. If the task is small, collapse the team into a single response but keep the same checkpoints: requirements, architecture, RTL, verification, constraints, implementation evidence, and risks.

Load `references/cdc-async-fifo-guidance.md` when the user asks for an asynchronous FIFO, cross-clock stream buffering, or gray-pointer CDC guidance.

Load `references/multi-agent-evidence-protocol.md` when the user asks to prove, validate, or document the multi-agent nature of the work.

Use an Orchestrator-led sequential team by default. Treat "multi-agent" as explicit role specialization, handoff packets, evidence ownership, arbitration, and traceability; do not imply parallel execution unless the user explicitly asks for it and runtime evidence exists. Runtime-isolated subagent tools are optional validation aids. The final report must declare `coordination_mode`, `execution_mode`, and `parallelism_claim`; for the default flow use `coordination_mode: orchestrated-agent-team`, `execution_mode: orchestrated-sequential-team`, and `parallelism_claim: none`.

## Default Workflow

Start with an Orchestrator pass that assigns roles and defines the artifact contract. Every role must hand off a compact packet with `Inputs`, `Outputs`, `Assumptions`, `Evidence`, and `Risks`. The default roles are:

- Requirements Agent: identify clocks, resets, interfaces, widths, latency/throughput needs, target board/part, IO assumptions, and CDC risk.
- Architecture Agent: define module boundaries, parameters, FSMs, datapaths, buffering, backpressure, reset strategy, and verification strategy.
- RTL Agent: implement synthesizable Verilog-2001 or conservative SystemVerilog accepted by Vivado.
- Verification Agent: produce self-checking testbenches, directed edge cases, timeout guards, scoreboards, and waveform hooks when useful.
- Constraints Agent: create or review XDC, clock definitions, IO constraints, generated clocks, and justified timing exceptions.
- Vivado Runner Agent: choose the fastest credible checks first, then escalate to simulation, synthesis, implementation, timing, and bitstream readiness as risk increases.
- Timing Closure Agent: classify timing failures before changing RTL/XDC.
- Release Agent: summarize artifacts, assumptions, checks, residual risks, and integration notes.

Run the roles in this order by default:

1. Orchestrator defines scope, tools, verification bar, and role sequence.
2. Requirements Agent extracts hardware-significant facts and open questions.
3. Architecture Agent produces the design plan and verification matrix.
4. RTL Agent implements or patches RTL.
5. Verification Agent creates self-checking tests and predicts expected observations.
6. Constraints Agent reviews clock, IO, CDC, and exception intent.
7. Vivado Runner Agent selects and reports the fastest credible checks.
8. Timing Closure Agent runs only when reports or design structure show timing risk.
9. Release Agent integrates results and states what is ready versus unverified.

Before writing or changing RTL, the Requirements Agent must identify hardware behavior that would change the design if answered differently. Ask only for those missing facts; otherwise choose conservative defaults and state them.

For new modules, the Architecture Agent must produce a concise hardware plan first: module purpose, ports/parameters, clock/reset assumptions, state machines, datapath, CDC handling, expected latency, and verification strategy. For complex modules, include a small block diagram or state table before coding.

When coding, the RTL Agent must prefer explicit widths, named port connections, clear reset behavior, separated combinational/sequential logic, complete case/if coverage, and no delays or initial-only behavior in synthesizable RTL.

When testbenches are needed, load `references/testbench-patterns.md`. Prefer self-checking tests with cycle-based synchronization, timeout guards, edge cases, and expected-vs-actual checks.

When constraints are involved, load `references/vivado-xdc-guidelines.md`. Never add `false_path`, `multicycle_path`, or async clock groups as a timing "fix" unless the path semantics justify the exception and the explanation is documented.

When timing is involved, load `references/timing-closure.md`. Read or request actual report data before changing RTL/XDC. Classify the path before fixing: missing constraints, CDC, high fanout, long logic depth, route delay, IO timing, clocking, or reset/control path.

When common logic is requested, load `references/rtl-patterns.md` and adapt the relevant pattern rather than inventing from scratch.

When Vivado MCP tools are available, use `references/vivado-mcp-workflow.md` to choose checks. Prefer fast lint/compile checks first, then simulation, synthesis, implementation, timing, and bitstream readiness as risk increases.

## Deliverable Rules

For every nontrivial FPGA task, produce:

- Requirements table with assumptions and hardware-changing unknowns.
- Architecture plan with ports, parameters, clock/reset strategy, CDC strategy, latency/throughput notes, and verification matrix.
- RTL/testbench/constraint changes or proposed files, with module-level integration notes.
- Evidence section listing checks actually run, checks not run, and why.
- Release summary with residual risks and the next recommended engineering check.

For proof-oriented validation, also produce an evidence ledger: agent roster, task cards or role sections, isolated inputs, agent-owned outputs or findings, orchestrator arbitration, and traceability from requirement to artifact to evidence. The ledger proves orchestration and collaboration, not parallelism.

## Arbitration Rules

When agents disagree, prefer evidence in this order: passing simulation with relevant coverage, Vivado critical warnings and timing reports, project constraints and board files, source requirements, then style preferences. Never hide a failing check behind a polished final answer. If implementation cannot be verified, state exactly what was not run and why.

## Reference Map

- `references/multi-agent-fpga-team.md`: Role definitions, handoff artifacts, review gates, and workflow structure for FPGA multi-agent orchestration.
- `references/multi-agent-evidence-protocol.md`: Proof protocol for orchestrated multi-agent collaboration, isolated role inputs, evidence ledgers, arbitration, traceability matrices, and explicit parallelism claims.
- `references/cdc-async-fifo-guidance.md`: Async FIFO and gray-pointer CDC guidance for cross-clock stream buffering tasks.
- `references/vivado-rtl-guidelines.md`: Vivado-friendly RTL, reset, RAM/DSP/register inference, CDC attributes, synthesis safety.
- `references/vivado-xdc-guidelines.md`: XDC clocks, IO, generated clocks, async groups, false paths, multicycle paths, pin safety.
- `references/timing-closure.md`: How to interpret timing reports and choose RTL/constraint fixes.
- `references/rtl-style-guidelines.md`: Local RTL style guidance for readable Verilog/SystemVerilog; project style overrides it.
- `references/rtl-patterns.md`: Common RTL building blocks and selection rules.
- `references/testbench-patterns.md`: Simple self-checking Verilog/SystemVerilog testbench patterns.
- `references/vivado-mcp-workflow.md`: How to use Vivado MCP tools safely with this skill.

## Output Expectations

For RTL changes, include which agents contributed, what changed, assumptions, and how it was checked. For generated modules, include a minimal instantiation example or integration note when useful. For timing or constraint changes, include the report symptom, chosen fix, and why it is a real hardware fix rather than a hidden exception.

For documentation or release handoff use, produce a concise engineering narrative: user request, team roster, role handoffs, generated artifacts, verification evidence, one debug iteration if available, and final result.
