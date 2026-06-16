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

The `move-flow` binary must be on your `$PATH`. Pick one of:

**Unix (Linux + macOS)**
```bash
curl -fsSL https://raw.githubusercontent.com/aptos-labs/aptos-ai/main/install.sh | sh
```

**Windows (PowerShell)**
```powershell
irm https://raw.githubusercontent.com/aptos-labs/aptos-ai/main/install.ps1 | iex
```

**cargo-binstall** (no compile, downloads the prebuilt binary)
```bash
cargo binstall aptos-move-flow
```

**Build from source** — from a local [aptos-core](https://github.com/aptos-labs/aptos-core) checkout:
```bash
cargo install --path aptos-core/aptos-move/flow --locked --profile cli
```

Prebuilt binaries are published as GitHub Releases on this repo. Every archive
is listed in a `SHA256SUMS` file alongside it. See
[Releases](https://github.com/aptos-labs/aptos-ai/releases) for direct downloads.
The release workflow consumes the matching `move-flow-v<version>` tag from
`aptos-core` and regenerates the `plugins/move-flow/` marketplace tree from the
built binary.

**Verifying provenance.** Every release is signed by GitHub's sigstore-backed
build provenance attestation — proof the archive was produced by *this exact
workflow* on *this exact commit*. To verify a downloaded archive:

```bash
gh attestation verify move-flow-v1.0.4-x86_64-apple-darwin.zip \
  --repo aptos-labs/aptos-ai
```

A successful verification prints the source commit, workflow path, and
runner identity. Failure aborts non-zero.

**Supported platforms**

| Platform | Architecture | Notes |
|----------|--------------|-------|
| macOS    | x86_64 (Intel) | |
| macOS    | aarch64 (Apple Silicon) | |
| Linux    | x86_64 | glibc from the build runner (currently 2.39) |
| Linux    | aarch64 | glibc from the build runner (currently 2.39) |
| Linux    | x86_64 — compat | Built on Ubuntu 20.04, baseline `x86-64-v2`. Use on older distros or Docker-on-Mac. |
| Linux    | aarch64 — compat | Built on Ubuntu 20.04. Use on older distros. |
| Windows  | x86_64 | |

The Unix installer auto-selects the compat build when it detects old glibc
(< 2.34) or an x86_64 CPU/emulator that doesn't advertise AVX2 in
`/proc/cpuinfo` (old hardware, Rosetta 2, default qemu-user).

> **Running x86_64 containers on Apple Silicon?**
> The compat build is pinned to `x86-64-v2`, which requires **SSE4.2**.
> Docker Desktop and OrbStack default to **Rosetta 2** for amd64 emulation
> on Apple Silicon — Rosetta 2 exposes SSE4.2, so the compat build works.
> Colima / Lima / Podman Machine default to **qemu-user with the `qemu64`
> CPU model**, which only goes up to SSE3. To run the compat build there,
> either switch the runtime to Rosetta 2 or override qemu's CPU model
> (e.g. `colima start --cpu-type max`, `lima ... cpuType: "max"`).

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
