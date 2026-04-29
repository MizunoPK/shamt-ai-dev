# =============================================================================
# Shamt Import Script (PowerShell — Windows)
# =============================================================================
# Run this script from the root of your child project.
# Usage: & ".shamt\scripts\import\import.ps1"
#
# Syncs guides/ and scripts/ from the master shamt-ai-dev repo into this
# project's .shamt/. Generates a diff file for agent review afterward.
# =============================================================================

$ErrorActionPreference = "Stop"

$ChildShamtDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$ChildRoot = Split-Path -Parent $ChildShamtDir

# --- Read master path --------------------------------------------------------

$MasterPathConf = Join-Path $ChildShamtDir "shamt_master_path.conf"
if (-not (Test-Path $MasterPathConf)) {
    Write-Host ""
    Write-Host "  Error: .shamt\shamt_master_path.conf not found." -ForegroundColor Red
    Write-Host "  Run the init script to set up the master path."
    Write-Host ""
    exit 1
}

$MasterDir = (Get-Content $MasterPathConf -Raw).Trim()
if (-not (Test-Path $MasterDir)) {
    Write-Host ""
    Write-Host "  Error: Master directory not found: $MasterDir" -ForegroundColor Red
    Write-Host "  Update .shamt\shamt_master_path.conf with the correct path."
    Write-Host ""
    exit 1
}

$MasterShamtDir = Join-Path $MasterDir ".shamt"

Write-Host ""
Write-Host "============================================================"
Write-Host "  Shamt Import"
Write-Host "============================================================"
Write-Host "  From: $MasterDir"
Write-Host "  To:   $ChildRoot"
Write-Host "============================================================"
Write-Host ""

# --- Freshness check ---------------------------------------------------------

try {
    $null = & git -C $MasterDir fetch origin main --quiet 2>&1
    if ($LASTEXITCODE -eq 0) {
        $freshnessLocal = (& git -C $MasterDir rev-parse main 2>&1 | Out-String).Trim()
        $freshnessRemote = (& git -C $MasterDir rev-parse origin/main 2>&1 | Out-String).Trim()
        if ($freshnessLocal -ne "" -and $freshnessRemote -ne "" -and $freshnessLocal -ne $freshnessRemote) {
            Write-Host "  Warning: master repo's 'main' branch appears to be behind origin/main." -ForegroundColor Yellow
            Write-Host "  Consider running 'git pull' in: $MasterDir" -ForegroundColor Yellow
            Write-Host ""
            $proceedChoice = Read-Host "  Proceed anyway? [y/N]"
            if ([string]::IsNullOrEmpty($proceedChoice)) { $proceedChoice = "N" }
            if ($proceedChoice -notmatch '^[Yy]$') {
                Write-Host "  Import cancelled."
                Write-Host ""
                Write-Host "============================================================"
                Write-Host ""
                exit 0
            }
            Write-Host ""
        }
    } else {
        Write-Host "  No remote configured or fetch unavailable — skipping freshness check."
        Write-Host ""
    }
} catch {
    Write-Host "  No remote configured or fetch unavailable — skipping freshness check."
    Write-Host ""
}

# --- Track changes -----------------------------------------------------------

$Copied = @()
$Deleted = @()
$Preserved = @()
$Sections = [System.Collections.Generic.List[string]]::new()
$SectionLineCounts = [System.Collections.Generic.List[int]]::new()

# --- Read previous sync hash (for deletion safety check) --------------------

$PrevSyncHash = ""
$lastSyncConf = Join-Path $ChildShamtDir "last_sync.conf"
if (Test-Path $lastSyncConf) {
    $lastSyncLine = (Get-Content $lastSyncConf -Raw).Trim()
    $parts = $lastSyncLine -split ' \| '
    if ($parts.Count -ge 2) { $PrevSyncHash = $parts[1].Trim() }
}

# --- Generate unified diff between two files ---------------------------------

function Get-UnifiedDiff {
    param([string]$OldFile, [string]$NewFile, [string]$Label)
    # Use git diff --no-index for portable unified diff output
    $result = & git diff --no-index --unified=3 $OldFile $NewFile 2>&1
    if ($LASTEXITCODE -eq 0) {
        return ""  # No difference (shouldn't happen, but handle it)
    }
    return $result -join "`n"
}

function Write-LastSync {
    $syncDate = Get-Date -Format "yyyy-MM-dd"
    $masterHashResult = & git -C $script:MasterDir rev-parse HEAD 2>&1
    $masterHash = if ($LASTEXITCODE -eq 0) { ($masterHashResult | Out-String).Trim() } else { "unknown" }
    Set-Content (Join-Path $script:ChildShamtDir "last_sync.conf") "$syncDate | $masterHash" -NoNewline
}

# --- Import from master (copy + track diffs) ---------------------------------

function Import-Dir {
    param(
        [string]$MasterDir,
        [string]$ChildDir,
        [string]$SkipPrefix  # forward-slash prefix to skip, e.g. "guides/audit/outputs"
    )
    if (-not (Test-Path $MasterDir)) { return }

    Get-ChildItem -Path $MasterDir -Recurse -File | Sort-Object FullName | ForEach-Object {
        $masterFile = $_.FullName
        $relPath = $masterFile.Substring($script:MasterShamtDir.Length).TrimStart('\', '/')
        $relPathFwd = $relPath.Replace('\', '/')

        # Skip excluded subpaths
        if ($SkipPrefix -and $relPathFwd.StartsWith($SkipPrefix)) {
            return
        }

        $childFile = Join-Path $script:ChildShamtDir $relPath

        if (-not (Test-Path $childFile)) {
            # New file from master
            $childFileDir = Split-Path $childFile -Parent
            New-Item -ItemType Directory -Force -Path $childFileDir | Out-Null
            Copy-Item $masterFile $childFile
            $script:Copied += "$relPathFwd (new)"
        } else {
            $masterHash = (Get-FileHash $masterFile -Algorithm MD5).Hash
            $childHash = (Get-FileHash $childFile -Algorithm MD5).Hash
            if ($masterHash -ne $childHash) {
                # Record diff then apply
                $diffOutput = Get-UnifiedDiff -OldFile $childFile -NewFile $masterFile
                $section = "## $relPathFwd`n`n``````diff`n$diffOutput`n```````n`n---`n`n"
                $lineCount = ($section -split "`n").Count
                $script:Sections.Add($section)
                $script:SectionLineCounts.Add($lineCount)
                Copy-Item $masterFile $childFile -Force
                $script:Copied += $relPathFwd
            }
        }
    }
}

Import-Dir -MasterDir (Join-Path $MasterShamtDir "guides") `
           -ChildDir (Join-Path $ChildShamtDir "guides") `
           -SkipPrefix "guides/audit/outputs"

Import-Dir -MasterDir (Join-Path $MasterShamtDir "scripts") `
           -ChildDir (Join-Path $ChildShamtDir "scripts") `
           -SkipPrefix "scripts/import"

# --- Remove files deleted from master ----------------------------------------

function Remove-Deleted {
    param(
        [string]$ChildDir,
        [string]$MasterDir,
        [string]$SkipPrefix
    )
    if (-not (Test-Path $ChildDir)) { return }

    Get-ChildItem -Path $ChildDir -Recurse -File | Sort-Object FullName | ForEach-Object {
        $childFile = $_.FullName
        $relPath = $childFile.Substring($script:ChildShamtDir.Length).TrimStart('\', '/')
        $relPathFwd = $relPath.Replace('\', '/')

        if ($SkipPrefix -and $relPathFwd.StartsWith($SkipPrefix)) {
            return
        }

        $masterFile = Join-Path $script:MasterShamtDir $relPath
        if (-not (Test-Path $masterFile)) {
            # Determine whether this file ever came from master
            $fromMaster = $false
            if ($script:PrevSyncHash -ne "") {
                $null = & git -C $script:MasterDir cat-file -e "${script:PrevSyncHash}:.shamt/$relPathFwd" 2>&1
                if ($LASTEXITCODE -eq 0) { $fromMaster = $true }
            }

            if ($fromMaster) {
                Remove-Item $childFile -Force
                $script:Deleted += $relPathFwd
                # Remove empty parent directories
                $dir = Split-Path $childFile -Parent
                while ($dir -ne $script:ChildShamtDir -and (Test-Path $dir) -and @(Get-ChildItem $dir).Count -eq 0) {
                    Remove-Item $dir -Force
                    $dir = Split-Path $dir -Parent
                }
            } else {
                $script:Preserved += $relPathFwd
            }
        }
    }
}

Remove-Deleted -ChildDir (Join-Path $ChildShamtDir "guides") `
               -MasterDir (Join-Path $MasterShamtDir "guides") `
               -SkipPrefix "guides/audit/outputs"

Remove-Deleted -ChildDir (Join-Path $ChildShamtDir "scripts") `
               -MasterDir (Join-Path $MasterShamtDir "scripts") `
               -SkipPrefix "scripts/import"

# Record sync state now — before diff generation and output, so a script
# interruption after syncing still produces an accurate last_sync.conf.
Write-LastSync

# --- Import scripts last (avoids overwriting the running script mid-execution) ---
Import-Dir -MasterDir (Join-Path $MasterShamtDir "scripts\import") `
           -ChildDir (Join-Path $ChildShamtDir "scripts\import") `
           -SkipPrefix ""
Remove-Deleted -ChildDir (Join-Path $ChildShamtDir "scripts\import") `
               -MasterDir (Join-Path $MasterShamtDir "scripts\import") `
               -SkipPrefix ""

# --- Write diff file(s) ------------------------------------------------------

$DiffFiles = @()
$today = Get-Date -Format "yyyy-MM-dd"
$DiffHeader = "# Shamt Import Diff`n`n**Generated:** $today`n`nFiles with changes are shown below as unified diffs (child -> master).`n`n---`n`n"

if ($Sections.Count -gt 0) {
    # Pack sections into chunks of <= 1000 lines (split at section boundaries)
    $chunks = [System.Collections.Generic.List[string]]::new()
    $currentChunk = $DiffHeader
    $currentLines = ($DiffHeader -split "`n").Count
    $headerLines = $currentLines

    for ($i = 0; $i -lt $Sections.Count; $i++) {
        $secLines = $SectionLineCounts[$i]
        if ($currentLines -gt $headerLines -and ($currentLines + $secLines) -gt 1000) {
            $chunks.Add($currentChunk)
            $currentChunk = $DiffHeader + $Sections[$i]
            $currentLines = $headerLines + $secLines
        } else {
            $currentChunk += $Sections[$i]
            $currentLines += $secLines
        }
    }
    $chunks.Add($currentChunk)

    if ($chunks.Count -eq 1) {
        $diffPath = Join-Path $ChildShamtDir "import_diff.md"
        Set-Content $diffPath $chunks[0] -NoNewline
        $DiffFiles = @("import_diff.md")
    } else {
        for ($i = 0; $i -lt $chunks.Count; $i++) {
            $diffPath = Join-Path $ChildShamtDir "import_diff_$($i + 1).md"
            Set-Content $diffPath $chunks[$i] -NoNewline
            $DiffFiles += "import_diff_$($i + 1).md"
        }
    }
}

# --- Summary -----------------------------------------------------------------

if ($Copied.Count -eq 0 -and $Deleted.Count -eq 0 -and $Preserved.Count -eq 0) {
    Write-Host "  Already up to date. No changes from master."
    Write-Host ""
    Write-Host "============================================================"
    Write-Host ""
    exit 0
}

if ($Copied.Count -gt 0) {
    Write-Host "  Updated $($Copied.Count) file(s):"
    foreach ($f in $Copied) { Write-Host "    + $f" }
    Write-Host ""
}

if ($Deleted.Count -gt 0) {
    Write-Host "  Removed $($Deleted.Count) file(s) (deleted from master):"
    foreach ($f in $Deleted) { Write-Host "    - $f" }
    Write-Host ""
}

if ($Preserved.Count -gt 0) {
    Write-Host "  Preserved $($Preserved.Count) child-only file(s) (not present in master — not deleted):"
    foreach ($f in $Preserved) { Write-Host "    ~ $f" }
    Write-Host ""
}

# --- Claude Code regen hook --------------------------------------------------

$AiServiceConf = Join-Path $ChildShamtDir "config\ai_service.conf"
if (Test-Path $AiServiceConf) {
    $_aiService = (Get-Content $AiServiceConf -Raw).Trim()
    if ($_aiService -eq "claude_code") {
        $RegenScript = Join-Path $ChildShamtDir "scripts\regen\regen-claude-shims.ps1"
        if (Test-Path $RegenScript) {
            Write-Host "  Claude Code regen"
            & $RegenScript
        } else {
            Write-Host "  ⚠  regen-claude-shims.ps1 not found — skipping shim refresh"
        }
    }
}

# --- Agent prompt ------------------------------------------------------------

Write-Host "------------------------------------------------------------"
Write-Host "  Agent Prompt"
Write-Host "------------------------------------------------------------"
Write-Host ""
Write-Host "Copy and send the following to your AI agent:"
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Host ""
Write-Host "Shamt has been updated from master (guides and/or scripts). To complete the import:"
Write-Host ""
Write-Host "1. Re-read the validation loop protocol before proceeding:"
Write-Host "   ```.shamt/guides/reference/validation_loop_master_protocol.md```"
Write-Host ""
if ($DiffFiles.Count -eq 0) {
    Write-Host "2. No content diffs to review (only new files, deletions, or preserved child-only files)."
} elseif ($DiffFiles.Count -eq 1) {
    Write-Host "2. Read the import diff: ```.shamt/$($DiffFiles[0])```"
} else {
    Write-Host "2. Read the import diffs (split due to size):"
    foreach ($f in $DiffFiles) { Write-Host "     ```.shamt/$f```" }
}
Write-Host ""
Write-Host "3. For each changed file, check whether your ``project-specific-configs/``"
Write-Host "   supplements are still accurate and consistent with the new content."
Write-Host ""
Write-Host "4. Check whether any existing pointers in the changed guide files are"
Write-Host "   still accurately placed."
Write-Host ""
Write-Host "5. Check whether any new pointers should be added to the changed files."
Write-Host ""
if ($Preserved.Count -gt 0) {
    Write-Host "6. Review child-only files that were preserved (not deleted):"
    Write-Host "   These files exist in your .shamt/ but have no presence in master."
    Write-Host "   For each preserved file, determine:"
    Write-Host "     (a) Planned export to master -> keep in guides/, add to CHANGES.md if not already recorded"
    Write-Host "     (b) Correctly project-specific -> move to project-specific-configs/"
    Write-Host "     (c) Obsolete -> delete manually"
    Write-Host ""
    Write-Host "7. Update any affected project-specific files as needed."
    Write-Host ""
    Write-Host "8. Run a validation loop until primary clean round + sub-agent confirmation is achieved."
    Write-Host ""
    Write-Host "9. Delete all import diff files when complete."
} else {
    Write-Host "6. Update any affected project-specific files as needed."
    Write-Host ""
    Write-Host "7. Run a validation loop until primary clean round + sub-agent confirmation is achieved."
    Write-Host ""
    Write-Host "8. Delete all import diff files when complete."
}
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Host ""
Write-Host "============================================================"
Write-Host ""
