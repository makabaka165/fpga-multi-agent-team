# Multi-Agent FPGA Team

Use this reference when FPGA work benefits from explicit role separation, independent checks, or auditable AI team orchestration. It is especially useful when a task spans RTL, testbenches, XDC constraints, Vivado/XSim reports, CDC review, timing analysis, and release handoff.

The core premise is that AI-generated Verilog needs engineering boundaries. Each role should own a specific type of evidence so that plausible code is not mistaken for verified hardware.

## Orchestrator Contract

The Orchestrator owns task decomposition and final integration. Start by writing:

- Goal: what hardware or FPGA workflow must be delivered.
- Inputs: requirements, existing files, target board/part, clocks, reset style, interfaces, and available tools.
- Outputs: RTL, testbench, constraints, scripts, reports, review notes, or release notes.
- Verification bar: the smallest credible check that would make the result trustworthy.
- Agent plan: which roles will run, in what order, and what each role must hand off.
- Tool boundary: which results come from AI reasoning and which require simulator/Vivado evidence.

Run the team sequentially by default: the Orchestrator assigns one professional role at a time, records the handoff, and uses the next role to consume the prior artifact. This still counts as a multi-agent workflow when the roles have explicit responsibilities, scoped inputs, separate outputs or findings, and Orchestrator arbitration.

For proof-oriented validation, load `multi-agent-evidence-protocol.md` and do not claim parallel execution. Runtime-isolated subagent tools may be used as an optional stronger validation aid, but they are not required unless the user explicitly asks for runtime parallelism evidence.

## Handoff Packet

Every agent must produce this compact packet before the next role consumes its work:

```text
Agent: <role name>
Inputs:
- <requirements, files, reports, assumptions consumed>
Outputs:
- <decisions, artifacts, code/report paths, or checks produced>
Assumptions:
- <defaults chosen because user/project data was absent>
Evidence:
- <facts, commands, reports, references, or reasoning that support the output>
Risks:
- <unverified behavior, hardware ambiguity, timing/CDC concern, or next check>
```

Keep handoffs concise. Put detailed RTL, testbench, XDC, or report analysis in the body of the work, then summarize it in the packet.

## Evidence Ledger

For multi-agent proof, maintain an evidence ledger with these fields:

```text
Run id: <validation folder or timestamp>
Coordination mode: orchestrated-agent-team
Execution mode: <orchestrated-sequential-team | runtime-evidenced-subagents | hybrid>
Parallelism claim: <none | runtime-evidenced>
Orchestrator: <main thread or agent>
Agent roster:
- <agent name>: <task>, <input scope>, <output file>, <status>
Isolation rule:
- <what each agent was allowed to read>
Findings:
- <finding id>, <source agent>, <severity>, <artifact>, <accepted/rejected/deferred>
Arbitration:
- <finding id>, <orchestrator decision>, <reason>, <resulting action>
Traceability:
- <requirement>, <agent output>, <artifact>, <evidence>, <remaining risk>
```

The ledger is the primary answer to "how do we know this was multi-agent work?" It should show agent roles, scoped inputs, separate outputs or findings, and at least one Orchestrator decision. It should not rely on parallelism as proof.

## Role Definitions

### Requirements Agent

Extract hardware-significant requirements:

- Clock frequencies, reset polarity/synchrony, target device or board.
- Data widths, register map, streaming protocol, valid/ready behavior, latency, throughput, and backpressure.
- External IO voltage or pin constraints when board integration is involved.
- CDC, reset-domain crossing, asynchronous inputs, debouncing, metastability risk, and reset release assumptions.
- Ambiguities that would change hardware behavior.

Output a requirement table with columns: `Item`, `Value`, `Source`, `Assumption?`, `Impact if wrong`.

### Architecture Agent

Turn requirements into a hardware plan:

- Module list, top-level ports, parameters, and interface contracts.
- FSM states and transition conditions when control logic is needed.
- Datapath blocks, counters, FIFOs, RAMs, DSP usage, and pipeline stages.
- CDC/reset strategy and synchronizer/FIFO structures.
- Verification matrix tied to requirements.

Output the architecture plan plus invariants the RTL must preserve.

### RTL Agent

Implement or modify synthesizable RTL:

- Use Verilog-2001 or conservative SystemVerilog accepted by Vivado.
- Use explicit widths, localparams for constants, named port connections, and deterministic reset behavior.
- Separate combinational and sequential logic.
- Avoid latches, blocking assignments in sequential logic, unsized arithmetic surprises, raw delays, and initial-only behavior in synthesizable modules.
- Use `(* ASYNC_REG = "TRUE" *)` on synchronizer chains for Xilinx/Vivado when appropriate.

Output changed/generated files, module interface summary, and known limitations.

### Verification Agent

Create self-checking verification:

- Use cycle-based synchronization and timeout guards.
- Cover reset behavior, idle behavior, boundary values, simultaneous events, backpressure, overflow/underflow, and protocol stalls.
- Use scoreboards for delayed outputs.
- Emit clear PASS/FAIL messages and dump waves only when useful.
- For CDC designs, use unrelated clock periods and phase offsets in simulation.

Output testbench files, test matrix, expected result, and first failing symptom if any.

### Constraints Agent

Create or review constraints:

- Define primary clocks, generated clocks, IO standards, package pins, and board-level constraints.
- Verify async clock grouping, false paths, and multicycle paths are semantically justified.
- Prefer fixing missing or wrong constraints over suppressing warnings.
- For asynchronous clocks with explicit CDC structures, document why async clock grouping is valid.

Output XDC changes plus the reason each timing exception is valid.

### Vivado Runner Agent

Select checks from fastest to slowest:

1. Static file and syntax checks.
2. Testbench simulation.
3. Vivado synthesis and critical warning review.
4. Implementation, timing, utilization, IO, and bitstream readiness.

Output exact commands or tools used, pass/fail result, warnings, WNS/WHS when available, and report paths.

### Timing Closure Agent

Debug timing using evidence:

- Classify the failing path before editing: missing constraint, CDC, high fanout, long logic depth, route delay, IO timing, clocking, reset/control path, or tool/setup issue.
- Prefer RTL structure, pipelining, register duplication, hierarchy cleanup, or correct constraints over unjustified exceptions.
- Re-run the smallest check that can confirm the fix.

Output classified root cause, chosen fix, expected effect, and remaining risk.

### Release Agent

Prepare the final handoff:

- What was built.
- Files changed or generated.
- Assumptions and unresolved questions.
- Verification evidence and checks not run.
- Integration notes, instantiation example, and next recommended check.

## Review Gates

Do not advance silently past these gates:

- Requirements Gate: no hardware-changing ambiguity remains unstated.
- Architecture Gate: interfaces, state machines, CDC, reset, and verification strategy are clear.
- RTL Gate: code is synthesizable and matches the architecture.
- Verification Gate: at least one self-checking test or clear manual check exists.
- Implementation Gate: Vivado warnings, timing, utilization, and IO status are reported when those checks were run.
- Release Gate: final answer states evidence, assumptions, and residual risk.

## Output Skeleton

Use this skeleton for nontrivial FPGA tasks:

```text
Orchestrator
- Goal:
- Verification bar:
- Agent sequence:

Requirements Agent
- Requirement table:
- Handoff packet:

Architecture Agent
- Design plan:
- Verification matrix:
- Handoff packet:

RTL Agent
- Files or code:
- Integration notes:
- Handoff packet:

Verification Agent
- Testbench strategy:
- Expected PASS criteria:
- Handoff packet:

Constraints Agent
- Clock/IO/CDC constraints:
- Timing exception rationale:
- Handoff packet:

Vivado Runner Agent
- Checks selected:
- Results:
- Handoff packet:

Timing Closure Agent
- Classification and fix, only if needed:
- Handoff packet:

Release Agent
- Ready artifacts:
- Evidence:
- Risks:
- Next check:
```

## Proof-Oriented Run Pattern

When the user asks for proof-oriented validation, document:

1. Natural language requirement.
2. Agent roster and task split.
3. Scoped task card or role section for each professional Agent.
4. Requirements and architecture handoff.
5. RTL and testbench generation.
6. Simulation, static check, or Vivado check result.
7. One issue found by a reviewer or verification agent.
8. Orchestrator arbitration and final Release summary.
9. Explicit statement: `parallelism_claim: none`, unless runtime overlap evidence is captured.

Keep claims grounded in artifacts. If a tool was unavailable, say so and show the substitute check.
