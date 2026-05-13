#!/bin/sh
# move-flow installer (Linux + macOS)
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/aptos-labs/aptos-ai/main/install.sh | sh
#   curl -fsSL .../install.sh | sh -s -- --version 1.0.4
#   curl -fsSL .../install.sh | sh -s -- --target x86_64-unknown-linux-gnu --compat
#   curl -fsSL .../install.sh | sh -s -- --install-dir /usr/local/bin

set -eu

REPO="aptos-labs/aptos-ai"
BIN_NAME="move-flow"
DEFAULT_INSTALL_DIR="$HOME/.local/bin"

VERSION=""
TARGET=""
INSTALL_DIR="$DEFAULT_INSTALL_DIR"
COMPAT=""

usage() {
  cat <<EOF
move-flow installer

Usage: install.sh [options]

Options:
  --version <ver>      Version to install (e.g. 1.0.4). Default: latest release.
  --target <triple>    Override auto-detected target triple
                       (e.g. x86_64-unknown-linux-gnu, aarch64-apple-darwin).
  --install-dir <dir>  Install destination. Default: ${DEFAULT_INSTALL_DIR}
  --compat             Use the compat build (older glibc / older CPU baseline).
                       Auto-detected on Linux based on glibc and emulation.
  -h, --help           Show this help.
EOF
}

err()  { printf "error: %s\n" "$*" >&2; exit 1; }
info() { printf "%s\n" "$*"; }

while [ $# -gt 0 ]; do
  case "$1" in
    --version)     VERSION="$2"; shift 2 ;;
    --version=*)   VERSION="${1#*=}"; shift ;;
    --target)      TARGET="$2"; shift 2 ;;
    --target=*)    TARGET="${1#*=}"; shift ;;
    --install-dir) INSTALL_DIR="$2"; shift 2 ;;
    --install-dir=*) INSTALL_DIR="${1#*=}"; shift ;;
    --compat)      COMPAT="true"; shift ;;
    -h|--help)     usage; exit 0 ;;
    *)             err "Unknown argument: $1 (try --help)" ;;
  esac
done

# ── Dependency check ────────────────────────────────────────────────
need() {
  command -v "$1" >/dev/null 2>&1 || err "Missing required command: $1"
}

have() { command -v "$1" >/dev/null 2>&1; }

if ! have curl && ! have wget; then
  err "Need either 'curl' or 'wget' to download files."
fi
need unzip

# Pick a downloader.
download() {
  # download <url> <output-path>
  if have curl; then
    curl -fsSL --retry 3 -o "$2" "$1"
  else
    wget -qO "$2" "$1"
  fi
}

http_get() {
  # http_get <url>  → stdout
  if have curl; then
    curl -fsSL --retry 3 "$1"
  else
    wget -qO- "$1"
  fi
}

# ── SHA-256 helper ──────────────────────────────────────────────────
sha256() {
  # sha256 <path> → hex digest
  if have sha256sum; then
    sha256sum "$1" | awk '{print $1}'
  elif have shasum; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    err "Need 'sha256sum' or 'shasum' to verify download integrity."
  fi
}

# ── Platform detection ──────────────────────────────────────────────
detect_target() {
  OS="$(uname -s)"
  ARCH="$(uname -m)"

  case "$ARCH" in
    arm64|aarch64) ARCH="aarch64" ;;
    x86_64|amd64)  ARCH="x86_64"  ;;
    *) err "Unsupported architecture: $ARCH" ;;
  esac

  case "$OS" in
    Darwin)
      echo "${ARCH}-apple-darwin"
      ;;
    Linux)
      echo "${ARCH}-unknown-linux-gnu"
      ;;
    *) err "Unsupported OS: $OS" ;;
  esac
}

# Auto-detect when the compat build is needed.
#
# The non-compat build is pinned to `target-cpu=x86-64-v3` (Haswell, 2013+),
# which requires AVX2. Compat is pinned to `x86-64-v2` (SSE4.2, 2008+).
#
# Cases that need compat on x86_64 Linux:
#   1. CPU lacks AVX2 — old hardware, Rosetta 2 on Apple Silicon, default
#      qemu-user, certain hypervisors that mask AVX from guests.
#   2. glibc older than the build runner's (currently 2.39 from ubuntu-24.04).
#
# We prefer direct CPU-feature detection over indirect "am I in a VM?" checks,
# because OrbStack / Colima / Podman Machine on Mac don't expose the LinuxKit
# marker that Docker Desktop does, but they still emulate x86_64 without AVX2.
auto_compat() {
  case "$(uname -s)" in
    Linux) ;;
    *) return 1 ;;
  esac

  ARCH="$(uname -m)"
  case "$ARCH" in
    x86_64|amd64)
      # If /proc/cpuinfo doesn't advertise AVX2, the v3-baseline binary will
      # SIGILL on the first AVX2 instruction.
      if [ -r /proc/cpuinfo ]; then
        if ! grep -qE '^flags[[:space:]]*:.*[[:space:]]avx2([[:space:]]|$)' /proc/cpuinfo; then
          return 0
        fi
      else
        # No /proc/cpuinfo (extremely unusual). Be safe — assume emulation.
        return 0
      fi
      ;;
    aarch64|arm64)
      # ARMv8-A baseline is stable across all supported targets; nothing to
      # gate on at the instruction level. Fall through to the glibc check.
      :
      ;;
  esac

  # glibc version check via ldd.
  if have ldd; then
    GLIBC="$(ldd --version 2>/dev/null | head -n 1 | awk '{print $NF}')"
    case "$GLIBC" in
      ''|*[!0-9.]*) ;;
      *)
        MAJOR="${GLIBC%%.*}"
        MINOR="${GLIBC#*.}"; MINOR="${MINOR%%.*}"
        if [ "${MAJOR:-0}" -lt 2 ] || \
           { [ "${MAJOR:-0}" -eq 2 ] && [ "${MINOR:-0}" -lt 34 ]; }; then
          return 0
        fi
        ;;
    esac
  fi

  return 1
}

if [ -z "$TARGET" ]; then
  TARGET="$(detect_target)"
fi

# Compat only applies to Linux targets.
case "$TARGET" in
  *linux*)
    if [ -z "$COMPAT" ] && auto_compat; then
      info "Detected older glibc or emulated environment — using compat build."
      COMPAT="true"
    fi
    ;;
  *)
    if [ "$COMPAT" = "true" ]; then
      err "--compat only applies to Linux targets (got $TARGET)"
    fi
    ;;
esac

SUFFIX=""
[ "${COMPAT:-}" = "true" ] && SUFFIX="-compat"

# ── Resolve version ─────────────────────────────────────────────────
if [ -z "$VERSION" ]; then
  info "Resolving latest release..."
  API_URL="https://api.github.com/repos/${REPO}/releases/latest"
  TAG="$(http_get "$API_URL" | grep -m1 '"tag_name"' | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')"
  [ -n "$TAG" ] || err "Could not determine latest release tag from $API_URL"
  VERSION="${TAG#move-flow-v}"
else
  TAG="move-flow-v${VERSION}"
fi

ARCHIVE="move-flow-v${VERSION}-${TARGET}${SUFFIX}.zip"
DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${TAG}/${ARCHIVE}"
SUMS_URL="https://github.com/${REPO}/releases/download/${TAG}/SHA256SUMS"

info "Target:    $TARGET${SUFFIX:+ (compat)}"
info "Version:   $VERSION"
info "Archive:   $ARCHIVE"

# ── Download + verify ───────────────────────────────────────────────
TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t move-flow.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

info "Downloading archive..."
download "$DOWNLOAD_URL" "$TMP_DIR/$ARCHIVE" \
  || err "Download failed: $DOWNLOAD_URL"

info "Downloading checksums..."
download "$SUMS_URL" "$TMP_DIR/SHA256SUMS" \
  || err "Checksums file not found: $SUMS_URL"

EXPECTED="$(awk -v name="$ARCHIVE" '$2 == name { print $1; exit }' "$TMP_DIR/SHA256SUMS")"
[ -n "$EXPECTED" ] || err "No checksum entry for $ARCHIVE in SHA256SUMS"

ACTUAL="$(sha256 "$TMP_DIR/$ARCHIVE")"
if [ "$EXPECTED" != "$ACTUAL" ]; then
  err "SHA-256 mismatch for $ARCHIVE: expected $EXPECTED, got $ACTUAL"
fi
info "SHA-256 verified: $ACTUAL"

# ── Extract + install ───────────────────────────────────────────────
( cd "$TMP_DIR" && unzip -q "$ARCHIVE" )

[ -f "$TMP_DIR/$BIN_NAME" ] || err "Archive did not contain '$BIN_NAME'"

mkdir -p "$INSTALL_DIR"
cp "$TMP_DIR/$BIN_NAME" "$INSTALL_DIR/$BIN_NAME"
chmod +x "$INSTALL_DIR/$BIN_NAME"

info ""
info "Installed: $INSTALL_DIR/$BIN_NAME"
info "  SHA-256: $(sha256 "$INSTALL_DIR/$BIN_NAME")"

# ── PATH hint ───────────────────────────────────────────────────────
case ":${PATH}:" in
  *":${INSTALL_DIR}:"*) ;;
  *)
    info ""
    info "${INSTALL_DIR} is not in your PATH."
    SHELL_NAME="$(basename "${SHELL:-sh}")"
    case "$SHELL_NAME" in
      zsh)  RC="$HOME/.zshrc" ;;
      bash) RC="$HOME/.bashrc" ;;
      fish)
        info "  Add to ~/.config/fish/config.fish:"
        info "    set -gx PATH ${INSTALL_DIR} \$PATH"
        RC=""
        ;;
      *) RC="$HOME/.profile" ;;
    esac
    if [ -n "$RC" ]; then
      info "  Add to $RC:"
      info "    export PATH=\"${INSTALL_DIR}:\$PATH\""
    fi
    ;;
esac

info ""
info "Run 'move-flow --help' to get started."
