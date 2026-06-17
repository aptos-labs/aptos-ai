---
name: move-prove
description: Run the Move Prover to formally verify specifications
---

Before doing any work, use TaskCreate to create one task for each
`**Task:**` entry listed below. Then execute them in order, marking
each in_progress when you start it and completed when you finish.




## Verification Tasks — Execute In Order

**Task: Full-scope verification run.** Run verification for the full requested scope
with `timeout` set to 5. This gives an
overview of all failures — both logical errors and timeouts.

**Task: Fix logical errors.** If there are any logical errors, iterate to fix them
using the `exclude` parameter of the verify tool to exclude functions whose
verification timed out. Only continue once all non-timeouts cleanly pass.

**Task: Resolve timeouts.** Resolve timeouts one by one calling the prover with a
function-level filter and `timeout` set to 10.
Apply the timeout resolution strategies from the reference material below
(spec helpers, lemmas, proofs). If a function cannot be resolved after
2 attempts and the user did not request
otherwise, add `pragma verify_duration_estimate = N;` where `N` is the exact
timeout at which you observed verification succeed. If verification never
succeeded, use `pragma verify = false;` instead.

**Task: Final full-scope verification.** Run the prover for the full requested scope
using `timeout` 10 to verify success. Functions
with `pragma verify_duration_estimate = N;` where `N` exceeds the timeout will
be automatically skipped — this is expected.




The reference material below supports the tasks above.


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
- **Comments**: Use `//` for regular comments. `///` is a **doc comment** and is only valid
  directly before a `module`, `struct`, `enum`, `fun`, or `const` declaration.
- **Edit hook**: The edit hook auto-runs on `.move` files after edits. If it reports
  compilation errors, fix them before proceeding with further changes.


### Links

- [The Move Book](https://aptos-labs.github.io/move-book/)
- [Aptos Framework Book](https://aptos-labs.github.io/framework-book/)



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



## Move Specification Language

Move specifications use `spec` blocks to express formal properties that are checked
by the Move Prover.

### Function spec clauses

These appear in `spec fun_name { ... }` blocks. Spec blocks always appear after the function
definition. If `fun_name` clashes with a soft keyword (e.g. `lemma`), use `spec @fun_name { ... }`
to escape it.

- `ensures <expr>`: Postcondition that must hold when the function returns normally.
  Evaluated in the **post-state**. Use `old(expr)` to refer to pre-state values.
- `aborts_if <expr>`: Condition under which the function may abort. **Evaluated in the
  pre-state** — do not use `old()` (see `old()` usage rules below). If any
  `aborts_if` conditions are present, the function must abort if and only if one of the
  conditions holds. Omitting all `aborts_if` clauses means abort behavior is *unspecified*
  (any abort is allowed). To express that a function never aborts, write `aborts_if false;`.
- `requires <expr>`: Precondition that callers must satisfy. **Evaluated in the pre-state** —
  Do not use `old()` (see `old()` usage rules below).
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


### Links

- [Move Specification Language](https://aptos.dev/en/build/smart-contracts/prover/spec-lang)










## Writing and Editing Specs

When writing or editing specifications:

1. Use `move_package_manifest` to discover source files.
2. Read the function body to understand its behavior and abort conditions.
3. Write `spec fun_name { ... }` blocks after each function, following the Move Specification
   Language rules above.
4. Write `spec lemma lemma_name ...` block after the function for which they are introduced.
5. Spec functions are put into a `spec fun` declarations.
6. If the project already uses `.spec.move` files, put new specs into that file instead of the 
   main Move file.

**`.spec.move` files:** A `.spec.move` file is compiled as part of the same module
as the corresponding source file. Use `spec module { }` (the keyword `module`,
not a module name) to declare module-level spec items (helper functions, lemmas).
Use `spec fun_name { }` to add conditions to functions defined in the main source.
There is no `spec <module_name> { }` syntax — `spec name { }` always targets a
function named `name`.

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
- **Keep `[inferred]` markers** on all inferred conditions — they distinguish
  inferred specs from user-written ones and are needed for WP re-runs.
  Remove `[inferred = vacuous]` and `[inferred = sathard]` conditions entirely
  (as described above), but keep plain `[inferred]` on conditions you retain.
- **Keep `pragma opaque = true;`** — never remove it. It is essential for
  verification performance, not an inference artifact. If a function with
  `pragma opaque` fails verification, add `pragma verify = false;` rather
  than removing the opaque pragma.

### Additional Rules for Editing Specs

1. **Do not change function bodies.** Only modify `spec` blocks and their contents.
2. **Preserve** any user-written (non-inferred) specifications exactly as they are.
3. **Never drop `aborts_if` conditions.** Every function that can abort must have
   `aborts_if` conditions. The WP tool infers both `ensures` and `aborts_if` —
   simplify them but never remove them just because they are complex or hard to
   verify. If an `aborts_if` needs rewriting, replace it with a semantically
   equivalent expression, do not delete it.
4. **Never remove `pragma opaque`.** The WP tool marks inferred specs as opaque
   so the prover uses the spec contract instead of inlining the function body.
   Removing it causes verification to re-analyze the implementation, leading to
   timeouts. Preserve `pragma opaque = true;` in every spec block that has it.
   If verification fails on an opaque function (e.g., the prover cannot reason
   about closure side effects), add `pragma verify = false;` to disable
   verification while keeping the spec contract intact for callers.
5. **Never duplicate conditions.** Before adding any condition to a spec block,
   check whether an equivalent condition already exists. Do not create a condition
   that is semantically identical to one already present in the same spec block.
6. **No empty spec blocks.** Never create or leave behind an empty
   `spec fun_name {}` block. If removing inferred conditions would leave a spec
   block with no conditions or pragmas, delete the entire block instead.










## Proofs and Lemmas

### Example

```move
spec fun sum(n: u64): u64 {
    if (n == 0) { 0 } else { n + sum(n - 1) }
}

spec lemma monotonicity(x: num, y: num) {
    requires x <= y;
    ensures sum(x) <= sum(y);
} proof {
    if (x < y) {
        assert sum(y - 1) <= sum(y);
        apply monotonicity(x, y - 1);
    }
}


fun sum_up_to(n: u64): u64 { /* iterative impl */ }
spec sum_up_to {
    requires n <= 5;
    ensures result == sum(n);
} proof {
   forall x,y {sum(x), sum(y)} apply monotonicity(x, y);
}
```

### Proofs

A proof consists of a sequence of
proof statements together with if-then-else and let bindings.

Proof statements: `let name = Expr`, `if (Expr) Proof else Proof`,
`assert Expr`, `assume Expr`, `apply LemmaInstance`,
`forall QuantifierDecls [Patterns] apply LemmaInstance`,
`calc (Expr { RelOp Expr })`.

A proof block can be attached to any specification block as postfix to that block, for example:

```
spec sum_to_n {
  ensures result == sum(n);
} proof {
  forall x: u64, y: u64 apply Monotonicity(x, y);
}  
```

A proof is translated by mapping it to a sequence of assumes/asserts at the
verification entry points of a function.

- The split statement is translated by creating different verification variants for each value split 
  with according assumptions of the value at the split point and otherwise identical content.
- The apply statement is translated by injecting pre/post conditions of the (expected to be proven) lemma.
  This is very similar like calling an opaque function in Move code.

### Lemmas

A Lemma is a member of a specification block, similar like a spec function. Its
user syntax is:

```
spec fun sum(n: u64): u64 {
    if (n == 0) { 0 } else { n + sum(n - 1) }
}
spec lemma sum_monotonicity(x: num, y: num) {
    requires x <= y;
    ensures sum(x) <= sum(y);
} proof {
    if (x < y) {
        assert sum(y - 1) <= sum(y);
        apply sum_monotonicity(x, y - 1);
    }
}
```

Or inside a `spec module { }` block (the keyword `module`, not a module name):

```
spec module {
  fun sum ...
  lemma sum_monotonicity ...
}
```

**Important:** `spec name { }` always targets a *function* named `name`.
There is no `spec <module_name> { }` syntax. Module-level items (helper
functions, lemmas) go inside `spec module { }`. Lemmas are **not valid**
inside function spec blocks (`spec fun_name { }`).

The `spec lemma` shortcut is sugar for `spec module { lemma ... }`, analogous
to the `spec fun` shortcut for helper functions.

It has a parameter list like a spec function (but no return value) followed by a
specification block (with requires, ensures, and pragmas the only allowed conditions).
Attached to this is an (optional) proof.

Lemma names are in a separate namespace. They are scoped to modules,
similar like specification functions. They can only be referenced from
proof 'apply' statements.




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
`filter` and `exclude` is excluded. This is useful in the "Fix logical errors" task to skip timed-out
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

  Do not delete, comment out, or weaken any `aborts_if` or `ensures`
  condition to resolve a timeout. This includes adding
  `pragma aborts_if_is_partial;`, which silently suppresses uncovered abort
  paths. Every condition is assumed semantically correct; removing one hides
  real properties and makes the specification unsound.

  Timeout resolution strategies — try these in order, and iterate
  aggressively before resorting to `pragma verify_duration_estimate`:

  1. **Add data invariants and global update invariants** to constrain
     resource state. These are checked once per modifying function and then
     assumed at every call site (including inside loops), giving the prover
     facts for free without recursive helpers. See the inference reference
     for details on when to use each kind.

  2. **Introduce spec helper functions** that capture intermediate properties.
     Factor complex `ensures` into compositions of simpler helpers. Each
     helper should express one logical step the solver can verify independently.

  3. **Add lemmas** to establish properties about spec helpers
     (e.g. monotonicity, induction steps) that the solver cannot discover
     on its own. Lemmas are proven propositions — do not introduce axioms.

  4. **Add `proof { ... }` blocks** to function specs or lemmas to guide
     the verifier with `assert`, `apply`, and `calc` steps. Use `apply`
     to instantiate lemmas at specific points in the proof.

  5. **Rewrite spec expressions** while preserving their meaning — factor
     out common sub-expressions into `let` bindings, reorder conjuncts,
     or replace a complex closed-form with a recursive helper connected
     by a lemma.

  When you use universal lemma application, always add triggers, as
  in `forall x: u64 {f(x)} apply lemma_for_f(x)`.

  **Avoid non-linear arithmetic in spec helpers.** SMT solvers handle linear
  arithmetic well but struggle with multiplication, division, or modulo between
  two non-constant expressions. Prefer additive recurrences over closed-form
  products. If a non-linear closed form is needed, connect it to a recursive
  helper via a lemma so the solver reasons about each step linearly.

  **Do not redefine built-in operations as spec helpers.** The SMT solver
  already understands `*`, `/`, `%`, comparisons, and bitwise operations
  natively. Only introduce a spec helper when it encodes logic the solver
  does not have built in — such as a loop accumulation pattern or a
  recursive data-structure traversal.

  **Document every function and lemma.** Add a `///` doc comment explaining
  what property it captures and why it is needed. Place new spec helper
  functions below the Move function that introduces them. Place lemmas
  directly beneath their helper's declaration.





## Task

Run the Move Prover to verify the current package.
