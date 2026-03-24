# Aptos AI

Plugins and integrations for AI coding assistants working with the Aptos
blockchain and the Move language. Currently supports Claude Code, with other
platforms planned.

## Available Plugins

| Plugin | Description | Platforms |
|--------|-------------|-----------|
| [MoveFlow](https://github.com/aptos-labs/aptos-core/tree/main/aptos-move/flow) | Move smart contract development — MCP tools, edit hooks, agents, and skills for the Move language and Move Prover | Claude Code |

## Claude Code

### Prerequisites

The `move-flow` binary must be on your `$PATH`. Install it from
[aptos-core](https://github.com/aptos-labs/aptos-core):

```bash
cargo install --git https://github.com/aptos-labs/aptos-core.git \
  --locked --profile ci aptos-move-flow
```

### Install the Marketplace

```
/plugin marketplace add aptos-labs/aptos-ai
```

### Install MoveFlow

```
/plugin install move-flow@aptos-ai
```

See the [MoveFlow README](https://github.com/aptos-labs/aptos-core/tree/main/aptos-move/flow)
for configuration options and usage details.
