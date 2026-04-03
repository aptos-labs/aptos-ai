# MoveFlow

Move smart contract development plugin for Claude Code.

## Overview

MoveFlow provides skills, agents, hooks, and an MCP server for developing, testing, and formally verifying [Move](https://aptos.dev/en/build/smart-contracts) smart contracts on [Aptos](https://aptos.dev). Version 1.0.2.

## Skills

| Skill | Description |
|-------|-------------|
| `/move` | Move development on Aptos |
| `/move-check` | Check a Move package for compilation errors |
| `/move-inf` | Infer specifications for a Move package |
| `/move-prove` | Run the Move Prover to formally verify specifications |
| `/move-test` | Generate unit tests for Move code. Use for test generation, writing tests, or improving coverage. |

## Agents

| Agent | Description |
|-------|-------------|
| `move-check` | Check and fix compilation errors in a Move package |
| `move-inf` | Infer specifications for a Move package |
| `move-verify` | Verify Move specifications using the Move Prover |

## MCP Tools

Provided by the `move-flow` MCP server (configured in `.mcp.json`).

| Tool | Description |
|------|-------------|
| `move_package_coverage` | Get uncovered source lines for a package |
| `move_package_manifest` | Get information about the current Move package |
| `move_package_query` | Query structural information about a Move package. |
| `move_package_spec_infer` | Infer specifications via weakest-precondition analysis |
| `move_package_status` | Check a Move package for compilation errors and warnings |
| `move_package_test` | Run Move unit tests for a package |
| `move_package_verify` | Verify Move specifications using the Move Prover |

## Hooks

- **PostToolUse** — After every `Edit` or `Write` that touches a `.move` file, runs syntax checks and auto-formatting.
- **UserPromptSubmit** — Detects Move package paths in the working directory.
- **SessionStart** — Verifies that the `move-flow` binary is installed.

## Requirements

- `move-flow` binary on `$PATH` (or set `$MOVE_FLOW` to the binary path)

## Author

Aptos Labs — version 1.0.2
