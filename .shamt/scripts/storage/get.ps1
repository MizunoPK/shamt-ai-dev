# =============================================================================
# Shamt Storage Get Script (PowerShell — Windows)
# =============================================================================
# Run this script from the root of your child project.
# Usage: & ".shamt\scripts\storage\get.ps1" [-DryRun] [-Force]
#
# Pulls stored .shamt/ and AI rules files from a dedicated Storage repo
# back into this machine. Overwrites local .shamt/ with the stored version
# (preserving machine-local conf files).
# =============================================================================

param(
    [switch]$DryRun,
    [switch]$Force
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
Write-Host "  Shamt Storage Get"
Write-Host "============================================================"
Write-Host "  Project: $ProjectName"
Write-Host "  From:    $StorageDir\$ProjectName"
Write-Host "  To:      $ChildRoot"
Write-Host "============================================================"
Write-Host ""

# --- Pre-pull dirty-tree check -----------------------------------------------

$storageStatus = & git -C $StorageDir status --porcelain 2>&1
if ($storageStatus -and ($storageStatus | Where-Object { $_ -ne "" }).Count -gt 0) {
    Write-Host "  Error: Storage repo has uncommitted changes." -ForegroundColor Red
    Write-Host "  Commit or stash changes in: $StorageDir"
    Write-Host "  Then re-run this script."
    Write-Host ""
    exit 1
}

# --- Pull latest from storage remote -----------------------------------------

try {
    $null = & git -C $StorageDir pull 2>&1
    if ($LASTEXITCODE -ne 0) { throw "pull failed" }
} catch {
    Write-Host "  Warning: git pull failed in storage repo — continuing with local state." -ForegroundColor Yellow
    Write-Host "  (This is non-fatal: you may be offline or have no remote configured.)"
    Write-Host ""
}

# --- Validate project exists in storage --------------------------------------

$SourceDir = Join-Path $StorageDir $ProjectName
if (-not (Test-Path $SourceDir)) {
    Write-Host "  Error: No storage found for project: $ProjectName" -ForegroundColor Red
    Write-Host "  Run store.ps1 first to save this project's state."
    Write-Host ""
    exit 1
}

# --- Print what will be overwritten ------------------------------------------

Write-Host "  The following will be overwritten with the stored version:"
Write-Host ""
Write-Host "    .shamt/  (preserving machine-local conf files)"

$RulesFiles = @(
    "CLAUDE.md",
    ".github\copilot-instructions.md",
    ".cursorrules",
    ".windsurfrules",
    "GEMINI.md"
)

$PresentRules = @()
foreach ($rulesFile in $RulesFiles) {
    $localPath = Join-Path $ChildRoot $rulesFile
    $storedPath = Join-Path $SourceDir $rulesFile
    if ((Test-Path $localPath) -and (Test-Path $storedPath)) {
        $PresentRules += $rulesFile.Replace('\', '/')
    }
}

if ($PresentRules.Count -gt 0) {
    foreach ($f in $PresentRules) {
        Write-Host "    $f"
    }
}

Write-Host ""

if ($DryRun) {
    Write-Host "------------------------------------------------------------"
    Write-Host "  DRY RUN — no changes were made." -ForegroundColor Cyan
    Write-Host "  Re-run without -DryRun to apply."
    Write-Host ""
    Write-Host "============================================================"
    Write-Host ""
    exit 0
}

# --- Interactive confirmation (unless -Force) ---------------------------------

if (-not $Force) {
    $confirm = Read-Host "  Proceed? [y/N]"
    if ([string]::IsNullOrEmpty($confirm)) { $confirm = "N" }
    if ($confirm -notmatch '^[Yy]$') {
        Write-Host "  Get cancelled."
        Write-Host ""
        Write-Host "============================================================"
        Write-Host ""
        exit 0
    }
    Write-Host ""
}

# --- Sync storage .shamt/ -> local .shamt/ -----------------------------------

$ExcludedFiles = @("storage_path.conf", "shamt_master_path.conf", "rules_file_path.conf")
$SourceShamtDir = Join-Path $SourceDir ".shamt"

if (Test-Path $SourceShamtDir) {
    Get-ChildItem -Path $SourceShamtDir -Recurse -File | ForEach-Object {
        $srcFile = $_.FullName
        $relPath = $srcFile.Substring($SourceShamtDir.Length).TrimStart('\', '/')
        $fileName = $_.Name

        # Skip excluded files (should not exist in source, but guard anyway)
        if ($ExcludedFiles -contains $fileName) { return }
        if ($fileName -match '^import_diff') { return }

        $dstFile = Join-Path $ChildShamtDir $relPath
        $dstFileDir = Split-Path $dstFile -Parent
        New-Item -ItemType Directory -Force -Path $dstFileDir | Out-Null
        Copy-Item $srcFile $dstFile -Force
    }

    # Remove files in local .shamt/ that are not in stored .shamt/ (mirror --delete)
    # Only for files that exist in source (i.e., came from storage), excluding conf files
    Get-ChildItem -Path $ChildShamtDir -Recurse -File | ForEach-Object {
        $localFile = $_.FullName
        $relPath = $localFile.Substring($ChildShamtDir.Length).TrimStart('\', '/')
        $fileName = $_.Name

        # Never delete machine-local conf files
        if ($ExcludedFiles -contains $fileName) { return }
        if ($fileName -match '^import_diff') { return }

        $storedFile = Join-Path $SourceShamtDir $relPath
        if (-not (Test-Path $storedFile)) {
            Remove-Item $localFile -Force
        }
    }
}

Write-Host "  Restored .shamt/ from storage."

# --- Restore AI rules files --------------------------------------------------

$RestoredRules = @()
foreach ($rulesFile in $RulesFiles) {
    $src = Join-Path $SourceDir $rulesFile
    if (Test-Path $src) {
        $dst = Join-Path $ChildRoot $rulesFile
        $dstDir = Split-Path $dst -Parent
        New-Item -ItemType Directory -Force -Path $dstDir | Out-Null
        Copy-Item $src $dst -Force
        $RestoredRules += $rulesFile.Replace('\', '/')
    }
}

if ($RestoredRules.Count -gt 0) {
    Write-Host ""
    Write-Host "  Restored AI rules files:"
    foreach ($f in $RestoredRules) {
        Write-Host "    + $f"
    }
}

Write-Host ""
Write-Host "============================================================"
Write-Host ""
