---
name: move-check
description: Check a Move package for compilation errors
---





## Move Language

Move on Aptos is a safe, resource-oriented programming language for smart contracts on the
Aptos blockchain. It uses a linear type system to enforce ownership and prevent
double-spending at compile time.

## Move Language Basics

- **Modules** are the unit of code organization, published at an address.
- **Structs** define data types; abilities (`key`, `store`, `copy`, `drop`) control what
  operations are permitted.
- **Entry functions** (`entry fun`) are transaction entry points callable from outside Move.
- **View functions** (`#[view]`) are read-only queries that do not modify state.
- **Global storage** stores resources (structs with `key`) at addresses.
- **Move 2 syntax** (required):
    - Read resource: `&T[addr]` (not `borrow_global<T>(addr)`)
    - Mutate resource: `&mut T[addr]` (not `borrow_global_mut<T>(addr)`)
    - Access field: `T[addr].field` directly (the compiler inserts the ref op)
    - `acquires` annotations are no longer needed — do not add them.
- **Error codes**: Use named constants for abort codes (`const E_NOT_FOUND: u64 = 1;`) and
  document them.
- **Edit hook**: The edit hook auto-runs on `.move` files after edits. If it reports
  compilation errors, fix them before proceeding with further changes.


## Reference

- [The Move Book](https://aptos.dev/move/book/SUMMARY)
- [Aptos Framework Reference](https://aptos.dev/reference/move/?branch=mainnet&page=aptos-framework/doc/overview.md)



## Move Packages

A Move package is a directory with a `Move.toml` manifest and source files. The manifest defines the package name, dependencies, and named addresses.

### Named Addresses

Modules are published at named addresses (e.g., `@my_package`). These must resolve to hex values for compilation.

- **`[addresses]`** — production addresses (may use `_` placeholder for deploy-time assignment)
- **`[dev-addresses]`** — development/test values (used when compiling in dev or test mode)

**Fixing "Unresolved addresses" errors:** For each `Named address 'X' in package 'Y'`, add `X = "0x..."` to `[dev-addresses]` in that package's `Move.toml`. Use `0x100` and up, avoiding reserved addresses (`0x0`=vm_reserved, `0x1`=std/aptos_std/aptos_framework, `0x3`=aptos_token, `0x4`=aptos_token_objects, `0x5`=aptos_trading, `0x7`=aptos_experimental, `0xA`=aptos_fungible_asset, `0xA550C18`=core_resources):

```toml
[dev-addresses]
my_package = "0x100"
other_addr = "0x101"
```



## Checking Move Code

Use the `move_package_status` MCP tool to check for compilation errors and warnings.

- Call `move_package_status` with `package_path` set to the package directory.
- The tool sets error and returns detailed error messages if the package does not compile.

Notice that like with a build system, the tool is idempotent, and does not cause recompilation
if the compilation result and sources are up-to-date.


## Package Information

Use the `move_package_manifest` MCP tool to discover source files and dependencies
of a Move package:

- Call `move_package_manifest` with `package_path` set to the package directory.
- The result includes `source_paths` (target modules) and `dep_paths` (dependencies).



## Writing and Editing Move Code

### Edit–Compile Cycle

When fixing compilation errors, follow this iterative loop:

1. Call `move_package_status` with the package path.
2. If the package compiles cleanly, report success and stop.
3. If there are errors, read the diagnostics carefully, fix the source, and go back to step 1.



## Task

Run the Edit–Compile Cycle on the current Move package.
