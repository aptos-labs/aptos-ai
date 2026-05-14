<#
.SYNOPSIS
    move-flow installer for Windows.

.DESCRIPTION
    Downloads a release binary from https://github.com/aptos-labs/aptos-ai,
    verifies its SHA-256 checksum, and installs it into $InstallDir.

.PARAMETER Version
    Version to install (e.g. 1.0.4). Defaults to the latest release.

.PARAMETER Target
    Target triple override. Defaults to auto-detection
    (x86_64-pc-windows-msvc on x64).

.PARAMETER InstallDir
    Install destination. Defaults to $HOME\.local\bin.

.EXAMPLE
    irm https://raw.githubusercontent.com/aptos-labs/aptos-ai/main/install.ps1 | iex

.EXAMPLE
    .\install.ps1 -Version 1.0.4 -InstallDir C:\tools
#>
[CmdletBinding()]
param(
    [string]$Version    = "",
    [string]$Target     = "",
    [string]$InstallDir = (Join-Path $HOME ".local\bin")
)

$ErrorActionPreference = "Stop"

$Repo    = "aptos-labs/aptos-ai"
$BinName = "move-flow"

function Write-Info($msg) { Write-Host $msg }

# Under `$ErrorActionPreference = "Stop"`, `Write-Error` is terminating and
# would tear through the `try { } finally { }` block as an uncaught exception
# with a stack trace. Write to stderr directly and exit non-zero instead.
function Fail($msg) {
    [Console]::Error.WriteLine("error: $msg")
    exit 1
}

# ── Platform detection ──────────────────────────────────────────────
if (-not $Target) {
    $Arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
    switch ($Arch) {
        "X64"   { $Target = "x86_64-pc-windows-msvc" }
        default {
            Fail "Unsupported Windows architecture: $Arch. No prebuilt binary available."
        }
    }
}

# ── Version resolution ──────────────────────────────────────────────
if (-not $Version) {
    Write-Info "Resolving latest release..."
    $Headers = @{ "User-Agent" = "move-flow-installer" }
    $Release = Invoke-RestMethod -UseBasicParsing -Headers $Headers `
        -Uri "https://api.github.com/repos/$Repo/releases/latest"
    $Tag = $Release.tag_name
    if (-not $Tag) { Fail "Could not determine latest release tag." }
    $Version = $Tag -replace '^move-flow-v', ''
} else {
    $Tag = "move-flow-v$Version"
}

$Archive     = "move-flow-v$Version-$Target.zip"
$DownloadUrl = "https://github.com/$Repo/releases/download/$Tag/$Archive"
$SumsUrl     = "https://github.com/$Repo/releases/download/$Tag/SHA256SUMS"

Write-Info "Target:   $Target"
Write-Info "Version:  $Version"
Write-Info "Archive:  $Archive"

# ── Workspace ───────────────────────────────────────────────────────
$TempRoot = [System.IO.Path]::GetTempPath()
$TempDir  = Join-Path $TempRoot ("move-flow-install-" + [Guid]::NewGuid())
New-Item -ItemType Directory -Path $TempDir | Out-Null

try {
    $ZipPath  = Join-Path $TempDir $Archive
    $SumsPath = Join-Path $TempDir "SHA256SUMS"

    Write-Info "Downloading archive..."
    Invoke-WebRequest -UseBasicParsing -Uri $DownloadUrl -OutFile $ZipPath

    Write-Info "Downloading checksums..."
    Invoke-WebRequest -UseBasicParsing -Uri $SumsUrl -OutFile $SumsPath

    # ── Verify SHA-256 ──────────────────────────────────────────────
    $Sums = Get-Content $SumsPath
    $Expected = $null
    foreach ($line in $Sums) {
        # Format: "<hash>  <filename>"
        if ($line -match '^([0-9a-f]{64})\s+(\S+)\s*$') {
            if ($Matches[2] -eq $Archive) {
                $Expected = $Matches[1].ToLower()
                break
            }
        }
    }
    if (-not $Expected) { Fail "No checksum entry for $Archive in SHA256SUMS." }

    $Actual = (Get-FileHash -Algorithm SHA256 -Path $ZipPath).Hash.ToLower()
    if ($Actual -ne $Expected) {
        Fail "SHA-256 mismatch for ${Archive}: expected $Expected, got $Actual"
    }
    Write-Info "SHA-256 verified: $Actual"

    # ── Extract + install ───────────────────────────────────────────
    $ExtractDir = Join-Path $TempDir "extracted"
    Expand-Archive -LiteralPath $ZipPath -DestinationPath $ExtractDir -Force

    $BinPath = Join-Path $ExtractDir "$BinName.exe"
    if (-not (Test-Path $BinPath)) {
        Fail "Archive did not contain $BinName.exe"
    }

    if (-not (Test-Path $InstallDir)) {
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    }
    $Dest = Join-Path $InstallDir "$BinName.exe"
    Copy-Item -Path $BinPath -Destination $Dest -Force

    $InstalledHash = (Get-FileHash -Algorithm SHA256 -Path $Dest).Hash.ToLower()
    Write-Info ""
    Write-Info "Installed: $Dest"
    Write-Info "  SHA-256: $InstalledHash"

    # ── PATH hint ───────────────────────────────────────────────────
    $UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $OnPath = $false
    if ($UserPath) {
        foreach ($p in $UserPath.Split(';')) {
            if ($p.TrimEnd('\') -ieq $InstallDir.TrimEnd('\')) { $OnPath = $true; break }
        }
    }
    if (-not $OnPath) {
        Write-Info ""
        Write-Info "$InstallDir is not on your user PATH. To add it:"
        Write-Info "  [Environment]::SetEnvironmentVariable('Path', `"`$env:Path;$InstallDir`", 'User')"
        Write-Info "Then restart your shell."
    }

    Write-Info ""
    Write-Info "Run 'move-flow --help' to get started."
}
finally {
    if (Test-Path $TempDir) {
        Remove-Item -Recurse -Force $TempDir
    }
}
