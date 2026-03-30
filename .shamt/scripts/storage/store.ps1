# =============================================================================
# Shamt Storage Store Script (PowerShell — Windows)
# =============================================================================
# Run this script from the root of your child project.
# Usage: & ".shamt\scripts\storage\store.ps1" [-DryRun]
#
# Copies your .shamt/ directory and AI rules files to a dedicated Storage
# repo, then commits and pushes. This makes your Shamt state portable across
# machines.
# =============================================================================

param(
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$ChildShamtDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$ChildRoot = Split-Path -Parent $ChildShamtDir

# --- Read storage path -------------------------------------------------------

$StoragePathConf = Join-Path $ChildShamtDir "storage_path.conf"
if (-not (Test-Path $StoragePathConf)) {
    Write-Host ""
    Write-Host "  Error: .shamt\storage_path.conf not found." -ForegroundColor Red
    Write-Host "  Ask your agent: ""What is the path to my Storage repo?"""
    Write-Host "  The agent will ask you for the path and save it to .shamt\storage_path.conf."
    Write-Host ""
    exit 1
}

$StorageDir = (Get-Content $StoragePathConf -Raw).Trim()
if (-not (Test-Path $StorageDir)) {
    Write-Host ""
    Write-Host "  Error: Storage directory not found: $StorageDir" -ForegroundColor Red
    Write-Host "  Update .shamt\storage_path.conf with the correct path."
    Write-Host ""
    exit 1
}

# --- Derive project name -----------------------------------------------------

$ProjectName = (Split-Path $ChildRoot -Leaf).Replace(' ', '_')

Write-Host ""
Write-Host "============================================================"
Write-Host "  Shamt Storage Store"
Write-Host "============================================================"
Write-Host "  Project: $ProjectName"
Write-Host "  From:    $ChildRoot"
Write-Host "  To:      $StorageDir\$ProjectName"
Write-Host "============================================================"
Write-Host ""

# --- Create project dir in storage if needed ---------------------------------

$DestDir = Join-Path $StorageDir $ProjectName
if (-not $DryRun) {
    New-Item -ItemType Directory -Force -Path $DestDir | Out-Null
}

# --- Excluded conf files -----------------------------------------------------

$ExcludedFiles = @("storage_path.conf", "shamt_master_path.conf", "rules_file_path.conf")

# --- Sync .shamt/ to storage -------------------------------------------------

if ($DryRun) {
    Write-Host "  Would sync .shamt/ to storage:"
    Write-Host "    $ChildShamtDir\ -> $DestDir\.shamt\"
    Write-Host ""
    Write-Host "  Excluded (machine-local conf files):"
    Write-Host "    storage_path.conf, shamt_master_path.conf, rules_file_path.conf, import_diff*.md"
    Write-Host ""
} else {
    $DestShamtDir = Join-Path $DestDir ".shamt"
    New-Item -ItemType Directory -Force -Path $DestShamtDir | Out-Null

    # Copy all files from .shamt/, excluding conf files and import_diff*.md
    Get-ChildItem -Path $ChildShamtDir -Recurse -File | ForEach-Object {
        $srcFile = $_.FullName
        $relPath = $srcFile.Substring($ChildShamtDir.Length).TrimStart('\', '/')
        $fileName = $_.Name

        # Skip excluded files
        if ($ExcludedFiles -contains $fileName) { return }
        if ($fileName -match '^import_diff') { return }

        $dstFile = Join-Path $DestShamtDir $relPath
        $dstFileDir = Split-Path $dstFile -Parent
        New-Item -ItemType Directory -Force -Path $dstFileDir | Out-Null
        Copy-Item $srcFile $dstFile -Force
    }

    # Remove files in storage that no longer exist locally (mirror --delete behavior)
    if (Test-Path $DestShamtDir) {
        Get-ChildItem -Path $DestShamtDir -Recurse -File | ForEach-Object {
            $dstFile = $_.FullName
            $relPath = $dstFile.Substring($DestShamtDir.Length).TrimStart('\', '/')
            $srcFile = Join-Path $ChildShamtDir $relPath
            if (-not (Test-Path $srcFile)) {
                Remove-Item $dstFile -Force
            }
        }
    }

    Write-Host "  Synced .shamt/ to storage."
}

# --- Copy AI rules files -----------------------------------------------------

$RulesFiles = @(
    "CLAUDE.md",
    ".github\copilot-instructions.md",
    ".cursorrules",
    ".windsurfrules",
    "GEMINI.md"
)

$CopiedRules = @()

foreach ($rulesFile in $RulesFiles) {
    $src = Join-Path $ChildRoot $rulesFile
    if (Test-Path $src) {
        if ($DryRun) {
            $CopiedRules += $rulesFile.Replace('\', '/')
        } else {
            $dst = Join-Path $DestDir $rulesFile
            $dstDir = Split-Path $dst -Parent
            New-Item -ItemType Directory -Force -Path $dstDir | Out-Null
            Copy-Item $src $dst -Force
            $CopiedRules += $rulesFile.Replace('\', '/')
        }
    }
}

if ($CopiedRules.Count -gt 0) {
    if ($DryRun) {
        Write-Host "  Would copy AI rules files:"
    } else {
        Write-Host "  Copied AI rules files:"
    }
    foreach ($f in $CopiedRules) {
        Write-Host "    + $f"
    }
    Write-Host ""
}

if ($DryRun) {
    Write-Host "------------------------------------------------------------"
    Write-Host "  DRY RUN — no changes were made to storage." -ForegroundColor Cyan
    Write-Host "  Re-run without -DryRun to apply."
    Write-Host ""
    Write-Host "============================================================"
    Write-Host ""
    exit 0
}

# --- Stage changes -----------------------------------------------------------

$null = & git -C $StorageDir add $ProjectName 2>&1

# --- Check if anything was staged --------------------------------------------

$stagedStatus = & git -C $StorageDir diff --cached --name-only 2>&1
if (-not $stagedStatus -or ($stagedStatus | Where-Object { $_ -ne "" }).Count -eq 0) {
    Write-Host "  Already up to date — nothing to commit."
    Write-Host ""
    Write-Host "============================================================"
    Write-Host ""
    exit 0
}

# --- Commit ------------------------------------------------------------------

$CommitDate = Get-Date -Format "yyyy-MM-dd"
$null = & git -C $StorageDir commit -m "sync: $ProjectName — $CommitDate" 2>&1
Write-Host "  Committed to storage repo."
Write-Host ""

# --- Push --------------------------------------------------------------------

try {
    $pushResult = & git -C $StorageDir push 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "push failed"
    }
    Write-Host "  Pushed to remote."
} catch {
    Write-Host ""
    Write-Host "  Warning: push failed. Your changes are committed locally in the storage repo" -ForegroundColor Yellow
    Write-Host "  but were not pushed to the remote. Run 'git push' in: $StorageDir" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

Write-Host ""
Write-Host "============================================================"
Write-Host ""
