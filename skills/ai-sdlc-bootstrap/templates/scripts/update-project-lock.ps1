<#
.SYNOPSIS
  ai-sdlc-bootstrap multi-repo engine v1.0 (Windows).
  Resolves project.deps.yaml into .project.lock.yaml (gitignored, machine-local).
  See scripts/update-project-lock.sh for macOS/Linux. Full design:
  reference/multi-repo.md in the ai-sdlc-bootstrap skill.

.PARAMETER Check
  Verify only — no prompting, no mutation. Exits non-zero if anything required
  is unresolved or missing on disk.

.PARAMETER Yes
  Auto-accept clone offers using the conventional sibling path.

.PARAMETER NoClone
  Never offer/perform a clone; list what's missing instead.

.PARAMETER Set
  Pre-supply a local path for a dependency as "name=path" (repeatable). Always
  wins over the lock file or the sibling-path guess.

.NOTES
  Non-interactive (agent) usage: never invoke this and expect it to prompt —
  there is no interactive host in a tool-call shell. Ask the human for any
  missing path first, then re-run with -Set name=path for each. See
  CONTRIBUTING.md for the full two-mode contract.
#>
[CmdletBinding()]
param(
    [switch]$Check,
    [switch]$Yes,
    [switch]$NoClone,
    [string[]]$Set = @()
)

$ErrorActionPreference = 'Stop'

# Write-Error is a *terminating* call once $ErrorActionPreference = 'Stop' is
# set (as above) — using it for "log an error but keep resolving the rest of
# the graph" would abort the whole walk at the first miss, unlike the bash
# engine, which finishes the walk and reports every unresolved required entry
# before exiting. This writes straight to the stderr stream instead, bypassing
# the error-record machinery entirely, so control flow stays in our hands.
function Write-ErrLine {
    param([string]$Message)
    [Console]::Error.WriteLine($Message)
}

# Closer analog to bash's `[ -t 0 ] && [ -t 1 ]` than [Environment]::UserInteractive,
# which can read $true even when stdin/stdout are actually redirected by an
# agent's shell tool call — the exact case we must never block in.
function Test-InteractiveConsole {
    -not [Console]::IsInputRedirected -and -not [Console]::IsOutputRedirected
}

function Get-RepoRoot {
    $root = (git rev-parse --show-toplevel 2>$null)
    if (-not $root) { throw "not inside a git repository" }
    return $root.Trim()
}

$RepoRoot = Get-RepoRoot
Set-Location $RepoRoot

$Manifest = Join-Path $RepoRoot 'project.deps.yaml'
$LockFile = Join-Path $RepoRoot '.project.lock.yaml'

if (-not (Test-Path $Manifest)) {
    Write-Host "no project.deps.yaml found — nothing to resolve"
    exit 0
}

$PresetPaths = @{}
foreach ($item in $Set) {
    $parts = $item.Split('=', 2)
    if ($parts.Length -eq 2) { $PresetPaths[$parts[0]] = $parts[1] }
}

# ─── restricted-YAML parser ──────────────────────────────────────────────────
#
# Returns an array of hashtables built from whatever key/value pairs appear
# under `projects:`. Handles both the manifest (name/path/repo/notes/required)
# and the lock file (name/path/repo/local_path/parent/depth) — records simply
# carry whichever keys were present; absent keys read back as $null.

function Parse-ProjectList {
    param([string]$Path)

    $lines = Get-Content -LiteralPath $Path
    $inList = $false
    $records = New-Object System.Collections.Generic.List[hashtable]
    $current = $null

    foreach ($raw in $lines) {
        $line = $raw.TrimEnd("`r")
        if ($line -match '^projects:\s*$') { $inList = $true; continue }
        if (-not $inList) { continue }
        if ($line -match '^\s{2}-\s+([a-zA-Z_]+):\s*(.*)$') {
            if ($current) { $records.Add($current) }
            $current = @{}
            $current[$Matches[1]] = $Matches[2].Trim('"')
            continue
        }
        if ($line -match '^\s{4,}([a-zA-Z_]+):\s*(.*)$') {
            if ($current) { $current[$Matches[1]] = $Matches[2].Trim('"') }
            continue
        }
        if ($line -match '^\S') { $inList = $false }
    }
    if ($current) { $records.Add($current) }
    return $records
}

function Get-Field {
    param([hashtable]$Record, [string]$Key, [string]$Default = '')
    if ($Record.ContainsKey($Key) -and $Record[$Key]) { return $Record[$Key] }
    return $Default
}

$nameMatch = Select-String -Path $Manifest -Pattern '^name:\s*"?([^"]*)"?\s*$' | Select-Object -First 1
$RootName = if ($nameMatch) { $nameMatch.Matches[0].Groups[1].Value } else { '' }

# ─── load existing lock (best-effort local-path reuse) ──────────────────────

$ExistingLockPath = @{}
if (Test-Path $LockFile) {
    foreach ($rec in (Parse-ProjectList -Path $LockFile)) {
        $n = Get-Field $rec 'name'
        if ($n) { $ExistingLockPath[$n] = Get-Field $rec 'local_path' }
    }
}

# ─── local-path resolution ───────────────────────────────────────────────────

function Resolve-LocalPath {
    param([string]$Name, [string]$Repo)

    $parent = Split-Path $RepoRoot -Parent
    $sibling = Join-Path $parent $Name
    $candidate = $null

    if ($PresetPaths.ContainsKey($Name)) {
        $candidate = $PresetPaths[$Name]
    } elseif ($ExistingLockPath.ContainsKey($Name) -and (Test-Path (Join-Path $ExistingLockPath[$Name] '.git'))) {
        $candidate = $ExistingLockPath[$Name]
    } elseif (Test-Path (Join-Path $sibling '.git')) {
        $candidate = $sibling
    } elseif ($Check) {
        return $null
    } elseif (Test-InteractiveConsole) {
        $candidate = Read-Host "Local path for '$Name' ($Repo)? [blank = offer to clone]"
    }

    if ([string]::IsNullOrWhiteSpace($candidate)) {
        if ($NoClone) { return $null }
        $doClone = $Yes.IsPresent
        if (-not $doClone -and Test-InteractiveConsole) {
            $ans = Read-Host "Clone '$Repo' into '$sibling'? [y/N]"
            $doClone = $ans -match '^[Yy]'
        }
        if ($doClone) {
            Write-Host "Cloning $Repo into $sibling ..."
            git clone $Repo $sibling | Out-Host
            $candidate = (Resolve-Path $sibling).Path
        } else {
            return $null
        }
    } else {
        if (-not (Test-Path (Join-Path $candidate '.git'))) {
            Write-ErrLine "warning: '$candidate' does not look like a git checkout (no .git)"
        }
        $candidate = (Resolve-Path $candidate).Path
    }

    return $candidate
}

# ─── DFS resolution with cycle detection ─────────────────────────────────────

function Normalize-Repo {
    param([string]$Repo)
    $r = $Repo -replace '\.git$', ''
    $r = $r -replace '^git@', ''
    $r = $r -replace '^(ssh|https?|git)://', ''
    $r = $r -replace ':', '/'
    return $r
}

$VisitedState = @{}
$CycleChain = New-Object System.Collections.Generic.List[string]
$LockEntries = New-Object System.Collections.Generic.List[hashtable]
$FailedRequired = $false

function Resolve-Node {
    param([string]$Name, [string]$Repo, [string]$Path, [string]$Required, [string]$Parent, [int]$Depth)

    $repoNorm = Normalize-Repo $Repo
    $key = "$repoNorm|$Path"

    if ($VisitedState[$key] -eq 'stack') {
        Write-ErrLine "error: cyclic dependency detected — $([string]::Join(' -> ', $CycleChain)) -> $Name"
        exit 1
    }
    if ($VisitedState[$key] -eq 'done') { return }

    $VisitedState[$key] = 'stack'
    $CycleChain.Add($Name)

    $localPath = Resolve-LocalPath -Name $Name -Repo $Repo

    if ($localPath) {
        $LockEntries.Add(@{ name = $Name; repo = $Repo; path = $Path; local_path = $localPath; parent = $Parent; depth = $Depth })

        $childManifest = Join-Path $localPath 'project.deps.yaml'
        if (Test-Path $childManifest) {
            foreach ($child in (Parse-ProjectList -Path $childManifest)) {
                $cRepo = Get-Field $child 'repo'
                if (-not $cRepo) { continue }
                Resolve-Node -Name (Get-Field $child 'name') -Repo $cRepo -Path (Get-Field $child 'path') `
                    -Required (Get-Field $child 'required' 'true') -Parent $Name -Depth ($Depth + 1)
            }
        }
    } elseif ($Required -eq 'true') {
        Write-ErrLine "error: required project '$Name' ($Repo) could not be resolved"
        $script:FailedRequired = $true
    } else {
        Write-ErrLine "warning: optional project '$Name' ($Repo) not resolved — skipping"
    }

    $VisitedState[$key] = 'done'
    $CycleChain.RemoveAt($CycleChain.Count - 1)
}

foreach ($rec in (Parse-ProjectList -Path $Manifest)) {
    $name = Get-Field $rec 'name'
    if (-not $name) { continue }
    $repo = Get-Field $rec 'repo'
    $path = Get-Field $rec 'path'

    if (-not $repo) {
        $full = Join-Path $RepoRoot $path
        if (-not (Test-Path $full)) {
            Write-ErrLine "warning: in-repo project '$name' declares path '$path' which does not exist"
        }
        continue
    }

    Resolve-Node -Name $name -Repo $repo -Path $path -Required (Get-Field $rec 'required' 'true') -Parent 'root' -Depth 1
}

if ($FailedRequired) { exit 1 }

# ─── -Check: report only, never write ────────────────────────────────────────

if ($Check) {
    $missing = $LockEntries | Where-Object { -not (Test-Path $_.local_path) }
    if ($missing.Count -gt 0) {
        Write-ErrLine "error: local path(s) no longer exist: $($missing.name -join ', ')"
        exit 1
    }
    Write-Host "all related projects resolved"
    exit 0
}

# ─── write the lock file ─────────────────────────────────────────────────────

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("resolved_at: $((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'))")
$lines.Add("root: $RootName")
$lines.Add('projects:')
foreach ($e in $LockEntries) {
    $lines.Add("  - name: $($e.name)")
    $lines.Add("    repo: $($e.repo)")
    $lines.Add("    path: $($e.path)")
    $lines.Add("    local_path: $($e.local_path)")
    $lines.Add("    parent: $($e.parent)")
    $lines.Add("    depth: $($e.depth)")
}
Set-Content -LiteralPath $LockFile -Value $lines
Write-Host "wrote $LockFile"
