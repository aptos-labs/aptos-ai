# Aptos AI

Aptos AI hosts plugins and integrations for AI coding assistants that work with
Aptos and the Move language.

## Plugins

| Plugin | Status | Platform | Description |
|--------|--------|----------|-------------|
| [MoveFlow](#moveflow) | Available | Claude Code | Move smart contract development on Aptos |

## MoveFlow

[MoveFlow][move-flow] is a Claude Code plugin for Move smart contract
development on Aptos. It provides:

- MCP tools for package status, tests, coverage, verification, and transaction
  replay.
- Skills for Move development, compilation fixes, test generation, spec
  inference, and formal verification.
- Agents for longer Move workflows.
- Hooks that check and format `.move` files after edits.

### Quick Start

Install the `move-flow` binary first. The Claude Code plugin expects it on
`$PATH`; alternatively, set `MOVE_FLOW` to the binary path.

**Unix (Linux + macOS)**

```bash
curl -fsSL https://raw.githubusercontent.com/aptos-labs/aptos-ai/main/install.sh | sh
```

**Windows (PowerShell)**

```powershell
irm https://raw.githubusercontent.com/aptos-labs/aptos-ai/main/install.ps1 | iex
```

Confirm the binary is available:

```bash
move-flow --help
```

Then install the Claude Code marketplace and plugin:

```text
/plugin marketplace add aptos-labs/aptos-ai
/plugin install move-flow@aptos-ai
```

Inside a Move project, run:

```text
/move-init
```

### Install Options

Use the installer when possible. To pin a version:

```bash
curl -fsSL https://raw.githubusercontent.com/aptos-labs/aptos-ai/main/install.sh | \
  sh -s -- --version 1.0.4
```

```powershell
irm https://raw.githubusercontent.com/aptos-labs/aptos-ai/main/install.ps1 `
  -OutFile install.ps1
.\install.ps1 -Version 1.0.4
```

Other options:

- Build from a local [aptos-core][aptos-core] checkout:
  ```bash
  cargo install --path aptos-core/aptos-move/flow --locked --profile cli
  ```
- [GitHub Releases][releases] contains direct downloads and `SHA256SUMS`.

Direct Git installs through Cargo and cargo-binstall are not supported today.
Use the installer, direct release downloads, or a local `aptos-core` checkout.

### Claude Code Commands

| Capability | Skill | Agent |
|------------|-------|-------|
| Initialize project routing | `/move-init` | |
| General Move help | `/move` | |
| Compilation diagnostics | `/move-check` | `move-check` |
| Spec inference | `/move-inf` | `move-inf` |
| Formal verification | `/move-prove` | `move-verify` |
| Unit test generation | `/move-test` | `move-test` |
| Transaction replay | `/move-replay` | |

### Supported Binaries

| Platform | Architecture | Notes |
|----------|--------------|-------|
| macOS | x86_64 (Intel) | |
| macOS | aarch64 (Apple Silicon) | |
| Linux | x86_64 | glibc from the build runner, currently 2.39 |
| Linux | aarch64 | glibc from the build runner, currently 2.39 |
| Linux | x86_64 compat | Built on Ubuntu 20.04, baseline `x86-64-v2` |
| Linux | aarch64 compat | Built on Ubuntu 20.04 |
| Windows | x86_64 | |

The Unix installer selects the compat build when it detects an older glibc
version (< 2.34) or an x86_64 CPU/emulator without AVX2 in `/proc/cpuinfo`.
Use compat builds on older distros or when running Linux under Docker-on-Mac.

> **Running x86_64 containers on Apple Silicon?**
> The compat build requires SSE4.2. Docker Desktop and OrbStack default to
> Rosetta 2 for amd64 emulation on Apple Silicon, which exposes SSE4.2.
> Colima, Lima, and Podman Machine default to qemu-user with the `qemu64`
> CPU model, which only goes up to SSE3. Switch the runtime to Rosetta 2 or
> override qemu's CPU model, for example `colima start --cpu-type max`.

### Verify Downloads

Each release publishes a `SHA256SUMS` file next to the archives. Releases also
include GitHub's sigstore-backed build provenance attestation.

To verify a downloaded archive:

```bash
gh attestation verify move-flow-v1.0.4-x86_64-apple-darwin.zip \
  --repo aptos-labs/aptos-ai
```

Successful attestation verification prints the source commit, workflow path,
and runner identity.

### Releases

Released binaries are built from the matching `move-flow-v<version>` tag in
[`aptos-labs/aptos-core`][move-flow]. The release workflow also regenerates the
`plugins/move-flow/` marketplace tree from the built binary.

## Support

Use GitHub issues to report bugs or request changes.

[aptos-core]: https://github.com/aptos-labs/aptos-core
[move-flow]: https://github.com/aptos-labs/aptos-core/tree/main/aptos-move/flow
[releases]: https://github.com/aptos-labs/aptos-ai/releases
