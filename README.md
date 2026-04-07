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

After installing, run `/move-init` to set up your project for Move development. Then try:

```
❯ What can you do with Move?                                                                                                                                                                                                   
                                                                                                                                                                                                                          
● Here's what I can help with for Move development:                                                                                                                                                                         
                                                                                                                                                                                                                          
  Skills / Agents available:                                                                                                                                                                                                
   
  ┌────────────────────────────────────────────────────────────────────┬─────────────┬─────────────┐                                                                                                                        
  │                             Capability                             │    Skill    │    Agent    │                                                                                                                      
  ├────────────────────────────────────────────────────────────────────┼─────────────┼─────────────┤
  │ Spec inference — infer specifications, generate specs, WP analysis │ /move-inf   │ move-inf    │
  ├────────────────────────────────────────────────────────────────────┼─────────────┼─────────────┤
  │ Verification — prove, run prover, check specifications             │ /move-prove │ move-verify │                                                                                                                        
  ├────────────────────────────────────────────────────────────────────┼─────────────┼─────────────┤                                                                                                                        
  │ Testing — generate unit tests, improve coverage                    │ /move-test  │ move-test   │                                                                                                                        
  ├────────────────────────────────────────────────────────────────────┼─────────────┼─────────────┤                                                                                                                        
  │ Fix compilation — diagnose and fix compile errors                  │ /move-check │ move-check  │                                                                                                                      
  ├────────────────────────────────────────────────────────────────────┼─────────────┼─────────────┤                                                                                                                        
  │ General Move — language reference, writing/reading/explaining code │ /move       │ —           │
  └────────────────────────────────────────────────────────────────────┴─────────────┴─────────────┘                                                                                                                        
                                                                                                                                                                                                                          
  General development tasks:                                                                                                                                                                                                
                                                                                                                                                                                                                          
  - Write new Move modules, functions, and structs                                                                                                                                                                          
  - Read and explain existing Move code
  - Refactor Move code (using Move 2 syntax per your preferences)                                                                                                                                                           
  - Add loop invariants, pre/post conditions, and other formal specs                                                                                                                                                        
  - Debug failing tests or prover errors                                                                                                                                                                                    
```

Please report any oddities and feature suggestions to `#move-eng`! 
