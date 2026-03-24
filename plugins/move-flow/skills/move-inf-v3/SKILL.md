---
name: move-inf-v3
description: Infer specifications for a Move package (v3 — synthesize specs directly)
---








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



## Writing and Editing Specs

When writing or editing specifications:

1. Use `move_package_manifest` to discover source files.
2. Read the function body to understand its behavior and abort conditions.
3. Write `spec fun_name { ... }` blocks after each function, following the Move Specification
   Language rules above.
4. Spec functions are put into a `spec fun` declarations
5. Axioms are in `spec module { axiom P; }` blocks.
6. If the project already uses `.spec.move` files, put new specs into that file instead of the 
   main Move file.
7. Spec modules (as in `spec <module_name> { items }`) share the same 
   namespace as `<module_name>`

### Simplifying Specifications

Work through the following in order when cleaning up inferred or hand-written specs.

**Remove vacuous conditions.** Delete every condition marked `[inferred = vacuous]`.
These arise from havoced loop variables without sufficient invariants and are
semantically meaningless (e.g.
`ensures [inferred = vacuous] forall x: u64: result == x`).

**Eliminate quantifiers.** Conditions with quantifiers over unbounded types
(`forall x: u64`, `exists x: u64`, `forall x: address`) cause SMT solver timeouts.
They are often marked `[inferred = sathard]` but not always. Replace each with an
equivalent **non-quantified** expression:

- `exists x: u64: x < n && f(x)` — replace with a concrete bound or closed-form
  expression derived from the loop logic.
- `forall x: address: x != a ==> g(x)` — this expresses a frame condition ("nothing
  else changed"). Replace with an explicit `modifies` clause or enumerate the affected
  addresses.

**Ensure quantifiers have triggers.** Quantifiers without triggers must be avoided. Move 
supports lists of triggers as in `Q x: T, y: R {p1, .., pn}..{q1, .., qn}: e`, where each outer 
list is an alternative where all inner patterns must match. Notice that only triggers over 
uninterpreted functions are allowed, not over builtin operators.

**Simplify `update_field` expressions.** The WP engine uses
`update_field(s, field, val)` for struct mutations. Rewrite to direct struct
construction when all fields are determined, e.g.:

- `update_field(old(global<T>(addr)), value, v)` becomes
  `T { value: v, ..old(global<T>(addr)) }`, or when the struct has a single field,
  simply `T { value: v }`.
- Nested `update_field(update_field(old(p), x, a), y, b)` becomes
  `Point { x: a, y: b }` when all fields are covered.

**Consolidate unrolled specs.** When `pragma unroll` is used, the WP produces one
condition per unrolling step (e.g. `n == 0 ==> ...`, `n == 1 ==> ...`, ...,
`k < n ==> ...`). If there is a closed-form generalization, replace the case list
with a single condition. Remove the `pragma unroll` once the closed-form is in place.

**General cleanup:**

- Fix `old()` usage: `old()` in `aborts_if` or `requires` is invalid — those
  clauses are already evaluated in the pre-state. Remove `old()` wrappers.
- Remove redundant conditions implied by others or by language guarantees (e.g. an
  `aborts_if` subsumed by a stronger one).
- Simplify arithmetic. The WP engine mirrors the computation steps, producing
  expressions that can be algebraically reduced:
  - Combine terms: `(n - 1) * n / 2 + n` simplifies to `n * (n + 1) / 2`.
  - Flatten nested offsets: `old(v) + 1 + 1` becomes `old(v) + 2`.
  - Simplify overflow bounds: `v + (n - 1) > MAX_U64 - 1` becomes `v + n > MAX_U64`.
  - Specs use mathematical (unbounded) integers, so unlike Move code there is no
    risk of underflow in spec expressions — reorder freely for clarity.
- Remove `[inferred]` and `[inferred = sathard]` markers from conditions you keep.

### Additional Rules for Editing Specs

1. **Do NOT change function bodies.** Only modify `spec` blocks and their contents.
2. **Preserve** any user-written (non-inferred) specifications exactly as they are.
3. **Never duplicate conditions.** Before adding any condition to a spec block,
   check whether an equivalent condition already exists. Do not create a condition
   that is semantically identical to one already present in the same spec block.
4. **No empty spec blocks.** Never create or leave behind an empty
   `spec fun_name {}` block. If removing inferred conditions would leave a spec
   block with no conditions or pragmas, delete the entire block instead.








## Verification 

### Verification Tool

Use `move_package_verify` to run the Move Prover on a package and
formally verify its specifications:

- Call with `package_path` set to the package directory and `timeout` set to
  5.
- The tool returns "verification succeeded" when all specs hold, or a diagnostic with a
  counterexample when a spec fails.

#### Narrowing scope with filters

Use the `filter` parameter to restrict the verification scope:

- **Single function:** set `filter` to `module_name::function_name`.
- **Single module:** set `filter` to `module_name`.

#### Excluding targets

Use the `exclude` parameter to skip specific functions or modules while
verifying the rest of the scope:

- **Exclude function(s):** set `exclude` to `["module_name::function_name"]`.
- **Exclude module(s):** set `exclude` to `["module_name"]`.

Exclusions take precedence over the `filter` scope — a target that matches both
`filter` and `exclude` is excluded. This is useful in Phase 2 to skip timed-out
functions without modifying source files.

#### Setting timeout

Verification can be long-running (10 seconds or more). Always explicitly specify a timeout. 
Start with a low timeout of 5 to get quick feedback.
Increase the timeout to not more than 10 in the case of 
investigating difficult verification problems. 

### Diagnosing Verification Failures

When the prover reports a counterexample or error:

- **Postcondition failure**: The `ensures` clause doesn't hold for some execution path.
  Check whether an edge case is missing or the condition is too strong.
- **Abort condition failure**: An abort path is not covered by `aborts_if`. Trace which
  operations can abort (arithmetic overflow, missing resource, vector out-of-bounds) and
  add the missing condition.
- **Wrong `old()` usage**: Using `old()` in `aborts_if` or `requires` causes a compilation
  error. Remove it — those clauses are already evaluated in the pre-state.
- **Loop-related failures**: Missing or too-weak loop invariants cause havoced variables.
  Strengthen the invariant to constrain all loop-modified variables.
- **Timeout ("out of resources")**:

  > **HARD RULE — do NOT delete, comment out, or weaken any `aborts_if` or
  > `ensures` condition to resolve a timeout.** This includes adding
  > `pragma aborts_if_is_partial;`, which silently suppresses uncovered abort
  > paths. Every condition is assumed semantically correct; removing one hides
  > real properties and makes the specification unsound. If you are tempted to
  > remove a condition because verification is slow, you MUST instead rewrite
  > it in a semantically equivalent form or add axioms/lemmas.

  Timeout resolution strategies (all preserve existing conditions):
  - Split complex `ensures` into multiple simpler clauses.
  - Replace quantifiers with concrete bounds.
  - Add helper lemma functions that break a proof into smaller steps.
  - Add explicit axioms to guide the solver. When you add an axiom, ensure quantifiers have 
    valid triggers. Move quantifiers support a disjunction of a conjunction of triggers.
  - Restructure expressions while preserving their meaning (e.g. factor out common
    sub-expressions into `let` bindings, reorder conjuncts).
  - Document every new helper or axiom with a `///` doc comment explaining
    what property it captures and why it is needed.

  **Avoid non-linear arithmetic in spec helpers.** SMT solvers handle linear
  arithmetic well but struggle with multiplication, division, or modulo between
  two non-constant expressions. When defining helper functions or axioms, prefer
  additive recurrences over closed-form formulas that involve products of
  variables. For example, use `sum_up_to(n) == sum_up_to(n - 1) + n` (linear)
  rather than the closed form `n * (n + 1) / 2` (non-linear). If a non-linear
  closed form is needed for the final specification, connect it to the recursive
  helper via a separate lemma or axiom so the solver can reason about each step
  linearly.

  **Do not redefine built-in operations as spec helpers.** The SMT solver
  already understands arithmetic operators (`*`, `/`, `%`), comparisons, and
  bitwise operations natively. Wrapping them in a recursive spec function
  (e.g. `spec fun mul(a: u64, b: u64): u64 { if (b == 0) { 0 } else { a + mul(a, b - 1) } }`)
  adds an unnecessary unfolding layer that makes solving harder, not easier.
  Only introduce a spec helper when it encodes logic the solver does not have
  built in — such as a loop accumulation pattern or a recursive
  data-structure traversal.

  **Document every helper and axiom.** When introducing a spec helper function
  or axiom, add a `///` doc comment explaining what property it captures and
  why it is needed (e.g. which loop or timeout it supports). Place new spec
  helper functions below the Move function and spec block that introduce them.
  Place axioms for a helper function directly beneath that helper's
  declaration.

### Verification Workflow

Follow this three-phase approach to resolve verification failures efficiently.

**Phase 1 — Full-scope run.** Run verification for the full requested scope with
`timeout` set to 5. This gives an overview of all failures —
both logical errors and timeouts. 

**Phase 2** — If they are any logical errors, iterate to fix them using the `exclude` 
parameter of the verify tool to exclude functions whose verification timed out. Only 
continue to phase 3 once all non-timeouts cleanly pass.

**Phase 3** — Resolve timeouts one by one calling prover with a **function-level filter** (see above) 
and apply the timeout resolution strategies described above. As a timeout value,
10 must be used. If a function cannot be resolved after
2 attempts and the user did not request otherwise, add
`pragma verify = false;` and keep the specifications so the user can investigate.

**Phase 4** -- Finally run the prover for the full requested scope using as timeout
10 to verify success.




## Spec Inference v3




### Common Pitfalls in AI Generated Spec Expressions

When writing spec expressions — especially loop invariants — these rules are
**hard constraints** enforced by the compiler. Violating them will cause
compilation errors and wasted iterations:

- **No `old(expr)` on locals or complex expressions.** In loop invariants,
  `old(x)` is only allowed when `x` is a simple function parameter name.
  Use locals directly — they refer to the current iteration's values.
- **No `*e` or `&e`.** Spec expressions operate on values, not references.
  Access fields directly (e.g. `v.field`, not `(*v).field`).
- **Do not forgot space after property** Write`aborts_if [inferred] !exists p` 
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

### Synthesizing Loop Invariants

Add loop invariants for every loop in the target code which doesn't yet have one
and mark them as `[inferred]`. Remove all existing `[inferred = *]`
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
block that introduce them. Place axioms for a helper directly beneath that
helper's declaration.

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





### Inference Workflow v3



**Phase 1 — Synthesize specifications.**
Synthesize loop invariants and function specifications for all functions
matching the `filter`. Respect existing user specifications. Define recursive spec 
helper functions as needed. You MUST avoid the Common Pitfalls in Spec Expressions 
described above.

**Phase 2 — Verify functions.** 
Using the verification workflow define above, verify the functions matching the filter.






## Task

Run specification inference v3 workflow for current package.
