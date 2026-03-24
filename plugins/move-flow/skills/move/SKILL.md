---
name: move
description: Move development on Aptos
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



## Move Specification Language

Move specifications use `spec` blocks to express formal properties that are checked
by the Move Prover.

### Function spec clauses

These appear in `spec fun_name { ... }` blocks. Spec blocks ALWAYS appear after the function
definition.

- `ensures <expr>`: Postcondition that must hold when the function returns normally.
  Evaluated in the **post-state**. Use `old(expr)` to refer to pre-state values.
- `aborts_if <expr>`: Condition under which the function may abort. **Evaluated in the
  pre-state** — **NEVER use `old()`** (see `old()` usage rules below). If any
  `aborts_if` conditions are present, the function must abort if and only if one of the
  conditions holds. Omitting all `aborts_if` clauses means abort behavior is *unspecified*
  (any abort is allowed). To express that a function never aborts, write `aborts_if false;`.
- `requires <expr>`: Precondition that callers must satisfy. **Evaluated in the pre-state** —
  **NEVER use `old()`** (see `old()` usage rules below).
- `modifies <resource>`: Declares which global resources the function may modify.

### Loop invariants

Loop invariants appear in a `spec` block after the loop body:

```move
while (cond) {
    // body
} spec {
    invariant <expr>;
};
```

- `invariant <expr>`: A property that holds before the first iteration and is preserved by
  each iteration. `old(x)` is only allowed on function parameters (see `old()` usage rules below.)

Loops without invariants cause the prover to *havoc* all loop-modified variables, which can
produce vacuous, incorrect, or overly weak specifications. Every loop needs an invariant —
examine the actual `while` loops in function bodies to find all loops that lack one.

A good invariant:
1. Holds before the first iteration (initial values satisfy it).
2. Is preserved by each iteration (inductive step).
3. Relates loop-modified variables to function parameters and constants
   (e.g., bounds like `i <= n`, accumulators like `sum == i * step`).

### Expressions in specs

- `old(expr)`: Value of `expr` at function entry. See `old()` usage rules below for
  where this is allowed.
- `result`: Return value. Only valid in `ensures`.
- `global<T>(addr)`: Global resource of type `T` at address `addr`.
- `exists<T>(addr)`: True if a resource of type `T` exists at address `addr`.
- Numeric type bounds: `MAX_U8`, `MAX_U16`, `MAX_U32`, `MAX_U64`, `MAX_U128`, `MAX_U256`.
- **No dereference or borrow**: `*e` and `&e` are not allowed in spec
  expressions. Spec expressions operate on values, not references — access
  fields directly (e.g. `v.field`, not `(*v).field` or `(&v).field`).

### `old()` usage rules

`old(expr)` means "value of `expr` at function entry." It is only valid in specific contexts:

**Wrong / Right examples:**

```move
// WRONG: old() in aborts_if — compilation error
aborts_if old(x) + old(y) > MAX_U64;
// RIGHT: aborts_if is pre-state, just use the variables directly
aborts_if x + y > MAX_U64;

// WRONG: old() in requires — compilation error
requires old(len(v)) > 0;
// RIGHT: requires is pre-state
requires len(v) > 0;

// WRONG: old(local) in loop invariant — compilation error
invariant old(sum) <= old(n) * MAX_U64;
// RIGHT: sum is a local — use it directly; n is a parameter — old(n) is ok
invariant sum <= old(n) * MAX_U64;

// WRONG: old(resource) in loop invariant — compilation error
invariant old(global<T>(addr)).field == 0;
// RIGHT: use resource directly
invariant global<T>(addr).field == 0;
```

### Property markers

The `[inferred]` property marks conditions that were not written by the user. Its value indicates
the origin or quality:

- `[inferred]`: Automatically inferred by weakest-precondition (WP) analysis. It may be overly complex, redundant,
  or occasionally incorrect.
- `[inferred = vacuous]`: Inferred by WP but detected as potentially vacuous (trivially true)
  due to unconstrained quantifier variables. Typically results from missing loop invariants.
- `[inferred = sathard]`: Inferred by WP but contains quantifier patterns that are hard for
  SMT solvers. Likely to cause verification timeouts — should be simplified or reformulated.


## Reference

- [Move Specification Language](https://aptos.dev/en/build/smart-contracts/prover/spec-lang)


