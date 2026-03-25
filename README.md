# Aptos AI (BETA)

Plugins and integrations for AI coding assistants working with the Aptos
blockchain and the Move language. Currently supports Claude Code, with other
platforms planned.

## Available Plugins

| Plugin | Description | Platforms |
|--------|-------------|-----------|
| [MoveFlow](https://github.com/aptos-labs/aptos-core/tree/main/aptos-move/flow) | Move smart contract development — MCP tools, edit hooks, agents, and skills for the Move language and Move Prover | Claude Code |

## Claude Code

### Prerequisites

The `move-flow` binary must be on your `$PATH`. Install it from a local
[aptos-core](https://github.com/aptos-labs/aptos-core) checkout:

```bash
cd aptos-core
cargo install --path aptos-move/flow --locked --profile ci
```

> **Note:** `aptos update move-flow` will be available in the future but is not
> yet supported.

### Install the Marketplace

```
/plugin marketplace add aptos-labs/aptos-ai
```

### Start Flowing

```
/plugin install move-flow@aptos-ai
```

You are all set. Try:

```
> /mcp
    Built-in MCPs (always available)
    plugin:move-flow:move-flow · ✔ connected
```

```
❯ List move-flow commands                                                                                                                                                                                                                                                 

● Here are the available move-flow MCP tools:

  ┌─────────────────────────┬─────────────────────────────────────────────────────────────────────────────────┐
  │          Tool           │                                   Description                                   │
  ├─────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ move_package_status     │ Check a Move package for compilation errors and warnings                        │
  ├─────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ move_package_manifest   │ Get package info (source paths, dependencies)                                   │
  ├─────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ move_package_query      │ Query package structure (dep graph, module summary, call graph, function usage) │
  ├─────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ move_package_test       │ Run Move unit tests (with optional baseline for coverage tracking)              │
  ├─────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ move_package_coverage   │ Get uncovered source lines, optionally scoped to a function                     │
  ├─────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ move_package_verify     │ Run the Move Prover for formal verification                                     │
  ├─────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ move_package_spec_infer │ Infer specifications for a Move package                                         │
  └─────────────────────────┴─────────────────────────────────────────────────────────────────────────────────┘

  And the available move-flow skills (slash commands):

  ┌──────────────┬───────────────────────────────────────────────────────┐
  │    Skill     │                      Description                      │
  ├──────────────┼───────────────────────────────────────────────────────┤
  │ /move        │ General Move development on Aptos                     │
  ├──────────────┼───────────────────────────────────────────────────────┤
  │ /move-check  │ Check a Move package for compilation errors           │
  ├──────────────┼───────────────────────────────────────────────────────┤
  │ /move-prove  │ Run the Move Prover to formally verify specifications │
  ├──────────────┼───────────────────────────────────────────────────────┤
  │ /move-test   │ Generate unit tests for Move code                     │
  ├──────────────┼───────────────────────────────────────────────────────┤
  │ /move-inf    │ Infer specifications for a Move package               │
  └──────────────┴───────────────────────────────────────────────────────┘                                                                                                                                                                                                
   
```

You should now be able to use prompts like `compile Move`, `compile Move and fix errors`, `generate tests`, and more.

Please report any oddities and feature suggestions to `#move-eng`! 
