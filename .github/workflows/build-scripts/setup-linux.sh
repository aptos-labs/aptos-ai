#!/bin/bash
set -euo pipefail

# Install build dependencies for move-flow on Linux.
# Works on native runners (via sudo) and on containers (sudo is pre-installed
# by the workflow before this script runs). DEBIAN_FRONTEND must be passed
# through sudo explicitly — sudo drops env vars by default.

sudo DEBIAN_FRONTEND=noninteractive apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  curl ca-certificates build-essential pkg-config \
  libssl-dev git libudev-dev lld libdw-dev clang llvm cmake unzip zip
