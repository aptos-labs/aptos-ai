---
name: move-test
description: Generate unit tests for Move code. Use for test generation, writing tests, or improving coverage.
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



## Unit Test Generation Rules




## Move Unit Testing Reference

### Test Attributes

| Attribute | Usage |
|-----------|-------|
| `#[test]` | Marks a function as a test |
| `#[test(name = @addr)]` | Test with signer parameters bound to addresses |
| `#[test_only]` | Code only compiled for testing (modules, functions, structs, constants) |
| `#[expected_failure]` | Test expected to abort (any code) |
| `#[expected_failure(abort_code = N)]` | Expects abort with specific code |
| `#[expected_failure(abort_code = N, location = mod)]` | Expects abort at specific location |

### Signer Parameters

Signers are bound via the test attribute, not passed as arguments:

```move
// Single signer
#[test(account = @0x1)]
fun test_single(account: &signer) { }

// Multiple signers
#[test(admin = @admin_addr, user = @0x42)]
fun test_multi(admin: &signer, user: &signer) { }

// Framework signer for timestamp, account creation, etc.
#[test(aptos_framework = @aptos_framework)]
fun test_framework(aptos_framework: &signer) { }
```

### Expected Failure

Use `#[expected_failure]` to test that code correctly aborts under certain conditions.

**Basic usage** (any abort passes):
```move
#[test]
#[expected_failure]
fun test_will_abort() { abort 1 }
```

**With abort code** (must match exactly):
```move
#[test]
#[expected_failure(abort_code = E_NOT_AUTHORIZED, location = Self)]
fun test_unauthorized() { /* should abort with E_NOT_AUTHORIZED */ }
```

**With location** (when error originates in another module):
```move
#[test]
#[expected_failure(abort_code = 26113, location = extensions::table)]
fun test_table_error() { /* should abort in table module */ }
```

**Execution errors** (not abort, but runtime failures):
```move
// Arithmetic error (overflow, divide by zero)
#[test]
#[expected_failure(arithmetic_error, location = Self)]
fun test_overflow() { let _ = 255u8 + 1; }

// Vector out of bounds
#[test]
#[expected_failure(vector_error, minor_status = 1, location = Self)]
fun test_out_of_bounds() { vector::borrow(&vector::empty<u8>(), 0); }
```

### Test-Only Code

```move
// Test-only module (entire module only compiled for tests)
#[test_only]
module my_addr::test_helpers {
    public fun setup(): u64 { 100 }
}

// Test-only function in regular module
module my_addr::my_module {
    #[test_only]
    public fun init_for_testing(account: &signer, value: u64) {
        move_to(account, MyResource { value });
    }
}
```

### Useful Test Utilities

```move
// Get address from signer
use std::signer;
let addr = signer::address_of(account);

// Create account (registers on-chain)
use aptos_framework::account;
account::create_account_for_test(addr);

// Create signer without registering (lightweight)
let signer = account::create_signer_for_test(@0x123);

// Check resource exists
assert!(exists<MyResource>(addr), E_NOT_FOUND);

// Initialize timestamp (required before time functions)
use aptos_framework::timestamp;
timestamp::set_time_has_started_for_testing(aptos_framework);

// Advance time
timestamp::update_global_time_for_test(1000000); // microseconds
timestamp::update_global_time_for_test_secs(100); // seconds
```

## Test Design Rules

**HARD RULES:**
- **One behavior per test.** Each test verifies exactly one scenario. Never combine success and failure cases.
- **Minimal setup.** Only initialize what the specific test needs.
- **Test the target function.** Every test must call the user-specified function.
- **Document purpose.** Every test needs a comment explaining what behavior is tested.

**Naming:** `test_<function>_<scenario>` (e.g., `test_transfer_insufficient_balance`), module: `<module>_tests`

**Common Mistakes:**
- `RESOURCE_ALREADY_EXISTS`: Don't initialize the same resource twice
- `MISSING_DATA`: Ensure required resources exist before calling
- Signer mismatch: Operations checking `signer::address_of()` require the correct signer. Match signers to expected addresses in test attributes.




## Unit Test Generation Workflow

### Phase 1 — Check Package

1. Call `move_package_manifest` to build the package and discover sources. **Fix any compilation errors before proceeding.**
2. Call `move_package_test` with `establish_baseline` set to true. **Fix failing tests before proceeding.**

### Phase 2 — Analyze Target Code

**Specific function requested:**
1. Call `move_package_coverage` with `function` set to `"module_name::function_name"` — get uncovered lines in that function
2. Read the source and identify behaviors to test:
   - Success path with valid inputs
   - Each distinct abort condition
   - Edge cases (empty, zero, boundaries)
   - Potential bugs

**Full module mode:**
1. Call `move_package_coverage` — get uncovered lines per source file
2. Read the source files that contain uncovered lines
3. Identify testable functions: public, entry, public(friend) — skip `#[test_only]` and private
4. For functions with uncovered lines, identify behaviors to test (same as above)

### Phase 3 — Generate Test Module

Create `tests/move_flow/<module>_tests.move` (create directory if needed).

```move
// =============================================================================
// AUTO-GENERATED TESTS - DO NOT EDIT MANUALLY
// Generated by: move-test agent
// Source module: <module>
// =============================================================================

#[test_only]
module <package_address>::<module>_tests {
    use <package_address>::<module>;

    /// @ai-generated
    /// Verifies that <function> <behavior>.
    #[test(account = @0x1)]
    fun test_<function>_<scenario>(account: &signer) { ... }
}
```

**Full module mode:** Generate tests in batches.

**Suspected bugs:** Assert the *correct* expected behavior — the test should fail against the buggy code.

### Phase 4 — Validate Tests

Call `move_package_test`. If `success` is false, classify each failure:

- **Compilation error**: Fix the test
- **Runtime failure**: Compare test expectation against expected behavior
  - Test is wrong → Fix it
  - Code is wrong → Move test to `bugs/` (at package root, next to `sources/` and `tests/`) and document:
    - Expected behavior
    - Actual behavior
    - Why this indicates a bug

Iterate until all tests in `tests/move_flow/` pass.

### Phase 5 — Check Coverage Improvement

Check `newly_covered` from Phase 4 to confirm the generated tests added coverage. Use `move_package_coverage` to check remaining gaps (pass `function` as `"module_name::function_name"` when targeting a specific function) — generate additional tests if needed and feasible.

### Phase 6 — Minimize Tests (do not skip)

Delete tests that add no new coverage. Keep tests with distinct scenarios (different abort conditions, branches, edge cases). When duplicates exist, prefer simpler setup and clearer naming.

Only modify tests in `tests/move_flow/` — do not touch `sources/` or `tests/` root.

### Phase 7 — Report

Summarize:
- Tests generated and coverage achieved
- If any tests were moved to `bugs/`, alert the user with a summary of potential bugs found





## Task

Generate unit tests for the current Move package.
