# move-flow Changelog

All notable changes to released `move-flow` binaries are captured here. This
project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html) and
the format from [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

Releases are built from
[`aptos-labs/aptos-core`](https://github.com/aptos-labs/aptos-core/tree/main/aptos-move/flow)
at the matching `move-flow-v<version>` tag. The release workflow extracts the
section below for the version being built and includes it in the GitHub
Release body.

## [Unreleased]

- Release workflow now regenerates the `move-flow` plugin tree from the
  matching `aptos-core` source tag and opens or updates the plugin PR in this
  repository.
