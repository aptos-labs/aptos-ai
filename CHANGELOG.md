# move-flow Changelog

Released `move-flow` binary changes are recorded here. This project follows
[Semantic Versioning](https://semver.org/spec/v2.0.0.html) and the
[Keep a Changelog](https://keepachangelog.com/en/1.0.0/) format.

Releases are built from [`aptos-labs/aptos-core`][aptos-core-flow] at the
matching `move-flow-v<version>` tag. The release workflow uses the matching
version section as the GitHub Release body.

## [Unreleased]

## [2.0.0] - 2026-07-11

### Changed
- **Breaking:** `facts` queries report function returns as `returnTypes`, an
  array with one entry per tuple element, instead of the optional
  `returnType` display string.
- **Breaking:** struct types in function signatures, struct fields,
  `resourceAccess`, and cross-module references are fully qualified
  (`address::module::Name`) in `facts` output.
- Package build failures in `move_package_query` return `invalid_params`
  instead of internal errors.
- Release workflow now regenerates the `move-flow` plugin tree from the
  matching `aptos-core` source tag and opens or updates the plugin PR in this
  repository.

### Added
- Attribute arguments and assignment values are preserved in `facts` output
  (previously only attribute names were serialized).
- Compiler-synthesized lambda-lifted functions are tagged with
  `isLambdaLifted` and linked to their defining function via `definedIn`;
  `module_summary` carries the same flag.
- `move_package_query` is annotated read-only in its MCP tool annotations.

### Fixed
- The `facts` path is guarded against panics, matching `function_usage`.

[aptos-core-flow]: https://github.com/aptos-labs/aptos-core/tree/main/aptos-move/flow
