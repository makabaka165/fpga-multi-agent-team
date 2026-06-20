# Multi-Agent Evidence Protocol

Use this reference when the work must prove orchestrated multi-agent collaboration rather than merely present informal role sections.

For FPGA work, the proof should connect role outputs to engineering artifacts and tool evidence. A strong result shows how the team moved from requirements to RTL/testbench/XDC and then to simulator or Vivado reports, while preserving residual risks such as missing board constraints or checks not run.

## Proof Standard

A strong multi-agent orchestration proof needs all of the following:

- Explicitly declared professional Agents with separate task cards or role sections.
- Isolated input scope for each agent.
- Agent-owned output artifact, finding, or handoff packet for each role.
- Findings or decisions that can be traced to a specific agent.
- Orchestrator arbitration that accepts, rejects, defers, or converts findings into action.
- Final traceability matrix linking requirements, agent outputs, artifacts, evidence, and residual risks.
- A clear `parallelism_claim`. Use `none` unless runtime overlap evidence is available.

The default claim is `execution_mode: orchestrated-sequential-team` and `parallelism_claim: none`. Do not claim parallel execution unless runtime logs, start/end timestamps, or run IDs prove overlap.

## Task Card Template

```text
Task card: <agent name>
Goal:
- <one concrete responsibility>
Allowed inputs:
- <specific files or pasted snippets>
Forbidden inputs:
- <files or conclusions this agent should not use>
Required output:
- <markdown report path or handoff packet>
Required sections:
- Inputs
- Outputs
- Assumptions
- Evidence
- Risks
- Findings
```

## Agent Report Template

```text
# <Agent Name> Report

Execution mode: orchestrated-agent-role
Parallelism claim: none

## Inputs
- <files or text actually used>

## Outputs
- <decisions, artifacts reviewed, or recommendations>

## Assumptions
- <defaults or missing data>

## Evidence
- <line references, file names, commands, static checks, or reasoning>

## Risks
- <unverified or unsafe items>

## Findings
| ID | Severity | Finding | Evidence | Recommendation |
| --- | --- | --- | --- | --- |
```

## Orchestrator Final Report Template

```text
# Orchestrator Final Report

Coordination mode: orchestrated-agent-team
Execution mode: orchestrated-sequential-team
Parallelism claim: none

## Agent Roster
| Agent | Task | Input scope | Output | Status |

## Evidence Ledger
| Finding ID | Source Agent | Artifact | Decision | Reason | Action |

## Arbitration Summary
- Accepted:
- Rejected:
- Deferred:

## Traceability Matrix
| Requirement | Agent evidence | Artifact | Verification evidence | Residual risk |

## Final Result
- Ready artifacts:
- Checks run:
- Checks not run:
- Next check:
```

## Arbitration Rules

- Accept findings that identify concrete hardware, CDC, timing, verification, or integration risk.
- Reject findings that require a project constraint not present in the task card.
- Defer findings that need simulator/Vivado evidence unavailable in the current environment.
- Do not silently edit artifacts after arbitration; record the action or explicitly say no action was taken.

## Documentation Notes

For demos, reviews, or public documentation, capture:

- The Orchestrator task split.
- At least four professional Agent role outputs or report sections.
- One finding from an agent and the Orchestrator decision.
- The final traceability matrix.
- The Vivado/XSim result table when available.
- The boundary between AI-produced reasoning and tool-produced evidence.

The strongest story is not "many roles were listed" or "agents ran in parallel"; it is "a designed AI team decomposed a complex FPGA problem, specialized agents owned different evidence, one or more agents found concrete risks, the Orchestrator arbitrated them, and tool reports closed the loop."
