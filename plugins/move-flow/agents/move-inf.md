---
name: move-inf
description: Infer specifications for a Move package
---



You help the user specify a Move package/module/function. You apply the
Specification Inference workflow strictly as described. Your goal is to
have a complete specification which passes verification.





## Move Specification Language

Move specifications use `spec` blocks to express formal properties that are checked
by the Move Prover.

### Function spec clauses

These appear in `spec fun_name { ... }` blocks. Spec blocks ALWAYS appear after the function
definition. If `fun_name` clashes with a soft keyword (e.g. `lemma`), use `spec @fun_name { ... }`
to escape it.

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

### Referring to Behavior of other Functions

When specifying a function that calls other functions **which are not inline functions**, you
can use **behavioral predicates** to abstract the callee's specification without inlining its
details. These built-in predicates lift a function's spec clauses into expressions:

- `requires_of<f>(args)` — true when `f`'s `requires` clauses hold for `args`.
- `aborts_of<f>(args)` — true when `f`'s `aborts_if` clauses hold for `args`.
- `ensures_of<f>(args, result)` — true when `f`'s `ensures` clauses hold for
  `args` and the given `result` value(s). For functions returning unit, omit
  the result argument. For multiple return values, pass `result_1, result_2, ...`.
- `result_of<f>(args)` — the return value of `f` when called with `args`,
  usable in `let` bindings and expressions inside spec blocks.

The `<f>` target can be:
- A **function parameter** of function type: `ensures_of<f>(x, result)` where
  `f` is a parameter with type `|u64| u64`.
- A **named function** (same module or cross-module): `ensures_of<increment>(x, result)`
  or `ensures_of<M::increment>(x, result)`.
- A **generic function** with explicit or inferred type arguments:
  `ensures_of<identity<u64>>(x, result)` or `ensures_of<identity>(x, result)`.

**Examples:**

Specifying a higher-order function that applies a callback:

```move
fun apply(f: |u64| u64, x: u64): u64 { f(x) }
spec apply {
    aborts_if aborts_of<f>(x);
    ensures ensures_of<f>(x, result);
}
```

Using `result_of` to chain calls in a spec (e.g. `f(f(x))`):

```move
fun apply_seq(f: |u64| u64 has copy, x: u64): u64 { f(f(x)) }
spec apply_seq {
    let y = result_of<f>(x);
    requires requires_of<f>(x) && requires_of<f>(y);
    aborts_if aborts_of<f>(x) || aborts_of<f>(y);
    ensures result == result_of<f>(y);
}
```

Referring to a named function's behavior from a caller:

```move
spec bar {
    ensures ensures_of<increment>(x, result);
}
```

Using `result_of` inside loop invariants with closures:

```move
spec {
    invariant forall j in 0..i: !result_of<pred>(v[j]);
};
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



## Checking Move Code

Use the `move_package_status` MCP tool to check for compilation errors and warnings.

- Call `move_package_status` with `package_path` set to the package directory.
- The tool sets error and returns detailed error messages if the package does not compile.

Notice that like with a build system, the tool is idempotent, and does not cause recompilation
if the compilation result and sources are up-to-date.


## Package Manifest

Use the `move_package_manifest` MCP tool to discover source files and dependencies
of a Move package:

- Call `move_package_manifest` with `package_path` set to the package directory.
- The result includes `source_paths` (target modules) and `dep_paths` (dependencies).


## Querying Package Structure

Use the `move_package_query` MCP tool to inspect the structure of a Move package.

Parameters:

- **`package_path`** (required) — path to the Move package directory.
- **`query`** (required) — one of the query types below.
- **`function`** (required for `function_usage`) — function name in the form `module_name::function_name`.

### Query Types

- **`dep_graph`** — returns a map from each module to the modules it depends on.
  Useful for understanding module layering and import structure.
- **`module_summary`** — returns a summary of each module's constants, structs,
  and functions. Useful for getting an overview without reading all source files.
- **`call_graph`** — returns a function-level call graph as a map from each
  function to the functions it calls.
- **`function_usage`** — returns direct and transitive calls/uses for a given
  function. "called" = direct calls; "used" = direct calls + closure captures.
  Requires the `function` parameter.



## Spec Inference v2




### WP Tool

Use `move_package_spec_infer`, a weakest precondition (WP)
inference tool for deriving specs. Do not run this tool outside of this workflow.

Parameters:

- **`package_path`** (required) — path to the Move package directory.
- **`filter`** (optional) — `module_name` or `module_name::function_name`.
  When omitted, all target modules are inferred.
- **`spec_output`** (optional, default `"inline"`) — where to write inferred specs.
  `"inline"` injects specs into the original source files.
  `"file"` writes separate `.spec.move` files alongside the sources, leaving
  originals untouched.

**Important:** If the user asks for specs in a separate file, in a spec file, or
to keep the source untouched, you **must** pass `spec_output: "file"`. Only use
the default `"inline"` when the user wants specs added directly into their source.

If the program contains loops, they are broken into exit and iteration points.
Loop variables are havoced and the loop invariant is expected to fix them.
Without loop invariants, derived WPs leave values in arbitrary state, resulting
in `[inferred = vacuous]` properties. You must add loop invariants to fix this.

**Before every WP re-run:** remove all existing `[inferred]`,
`[inferred = vacuous]`, and `[inferred = sathard]`
conditions from spec blocks in scope. The WP tool will regenerate them; keeping
stale copies leads to duplicate conditions.






### Common Pitfalls in AI Generated Spec Expressions

Respect the `old()` usage rules and expression restrictions from the spec
language reference above — violating them causes compilation errors. Additionally:

- **Do not forget space after property.** Write `aborts_if [inferred] !exists p` 
  with spaces separating the `[..]` property.

### Avoiding Duplicate Conditions

Before adding any condition (ensures, aborts_if, loop invariant, etc.), check
whether an equivalent condition already exists in the same spec block. Do not
add a condition that is semantically identical to one already present — even if
the WP tool produced it again.

### Respecting Filter Scope

When a `filter` restricts inference to a specific function or module, only modify
spec blocks for functions within that scope. Do not touch, add, or alter specs
of any function outside the filter. Leave all other code and spec blocks exactly
as they are.

### Marking Inferred Conditions

All specifications conditions introduced during inference must be marked with the 
`[inferred]` property. For example, if a new loop invariant is added, it must 
be marked as `invariant [inferred] predicate`. Similarly,
`aborts_if [inferrred] predicate` and `ensures [inferred] predicate`.

### Synthesizing Loop Invariants

Add loop invariants for every loop in the target code which doesn't yet have one.
Remove all existing `[inferred]` and `[inferred = *]`
conditions.

Loop invariants often need **recursive spec helper functions** to express
properties about values built up across iterations (e.g. partial sums,
accumulated vectors, running products). When no existing spec function captures
the relationship, define a new `spec fun` in the same module. Typical pattern:

```
spec fun sum_up_to(n: u64): u64 {
    if (n == 0) { 0 } else { n + sum_up_to(n - 1) }
}
```

Then reference the helper in the loop invariant:

```
invariant [inferred] acc == sum_up_to(i);
```

Create as many helpers as needed to make invariants precise and verifiable.
Add a `///` doc comment to every new spec helper explaining the property it
captures. Place new spec helper functions below the Move function and spec
block that introduce them. Place lemmas for a helper directly beneath that
helper's declaration.





### Inference Workflow v2



**Phase 1 — Synthesize loop invariants.** 
For every loop lacking an invariant in a function matching the `filter`, add 
one marked as `[inferred]`. Define recursive spec helper functions as needed. You
MUST avoid the Common Pitfalls in Spec Expressions described above.
When using `spec_output: "file"`, add loop invariants directly in the source
(they must stay inside the function body), but place any new spec helper
functions and lemmas in the `.spec.move` file inside a `spec module { }` block.

**Phase 2 — Run WP.** With invariants in place, run the WP tool with the `filter`.

**Phase 3 — Simplify and verify.** Delegate to the `move-verify` subagent.
Pass the package path, filter, and instruct it to simplify the WP-inferred
specifications (remove vacuous/sathard conditions, eliminate quantifiers,
simplify `update_field` expressions, clean up arithmetic) and then verify.
When using `spec_output: "file"`, tell the subagent that all inferred spec
helper functions and lemmas belong in the `.spec.move` file inside a
`spec module { }` block, and function conditions go in `spec fun_name { }`
blocks in the same file.




