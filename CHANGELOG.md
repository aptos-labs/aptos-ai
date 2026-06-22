# move-flow Changelog

Released `move-flow` binary changes are recorded here. This project follows
[Semantic Versioning](https://semver.org/spec/v2.0.0.html) and the
[Keep a Changelog](https://keepachangelog.com/en/1.0.0/) format.

Releases are built from [`aptos-labs/aptos-core`][aptos-core-flow] at the
matching `move-flow-v<version>` tag. The release workflow uses the matching
version section as the GitHub Release body.

## [Unreleased]

- Release workflow now regenerates the `move-flow` plugin tree from the
  matching `aptos-core` source tag and opens or updates the plugin PR in this
  repository.

[aptos-core-flow]: https://github.com/aptos-labs/aptos-core/tree/main/aptos-move/flow
