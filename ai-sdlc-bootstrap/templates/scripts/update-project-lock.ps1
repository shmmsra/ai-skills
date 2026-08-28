<#
.SYNOPSIS
  ai-sdlc-bootstrap multi-repo engine v2.3 (Windows).
  Resolves project.deps.yaml (raw, hand-authored) into .project.lock.yaml
  (gitignored, fully resolved — the source of truth agents should read).
  See scripts/update-project-lock.sh for macOS/Linux. Full design:
  reference/multi-repo.md in the ai-sdlc-bootstrap skill.

  Both in-repo and external entries are graph nodes in the same recursive
  walk: an in-repo sub-project's own project.deps.yaml (if it has one) is
  walked exactly like an external dependency's, at any depth, in any mix.

.PARAMETER Check
  Verify only — no prompting, no mutation. Exits non-zero if anything required
  is unresolved or missing on disk.

.PARAMETER Yes
  Auto-accept clone offers using the conventional sibling path.

.PARAMETER NoClone
  Never offer/perform a clone; list what's missing instead.

.PARAMETER Set
  Pre-supply a local path for an external dependency as "name=path"
  (repeatable). Always wins over the lock file or the sibling-path guess.
  Not applicable to in-repo entries (their path is always relative to a
  known checkout).

.PARAMETER Porcelain
  Combine with -Check: also emit one "DECISION ..." line per entry needing
  a human decision, on stdout (machine-parseable, in addition to the
  existing stderr text). Requires -Check.

.PARAMETER RequireDecisions
  Combine with a real (mutating) run: fail non-zero if any optional
  dependency would be silently skipped instead of resolved — use after
  every decision has been supplied via -Set, as a safety net against a
  decision surfacing after -Check was last run.

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
    [switch]$Porcelain,
    [switch]$RequireDecisions,
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

if ($Porcelain -and -not $Check) {
    Write-ErrLine "error: -Porcelain requires -Check"
    exit 64
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
# and the lock file (name/kind/path/repo/local_path/notes/parent/depth) —
# records simply carry whichever keys were present; absent keys read back as
# $null via Get-Field's default.
#
# Supports YAML's literal block scalar (`key: |`) for any field, most useful
# for multi-line `notes`: content lines must be indented >= 6 spaces (more
# than the normal 4-space continuation-field indent, regardless of whether
# the field appeared on the list-item's own line or a continuation line);
# blank lines are part of the block; the block ends at the first non-blank
# line indented less than that. Folded scalars (`>`) are not supported.
#
# Unlike the bash engine, no record-separator plumbing is needed here — this
# returns real in-memory hashtables, not text serialized through a stream
# that a separate reader has to re-split, so an embedded newline in a value
# can't be confused with a record boundary.

function Read-BlockScalar {
    param([string[]]$Lines, [int]$StartIndex)

    $content = New-Object System.Collections.Generic.List[string]
    $stripWidth = -1
    $idx = $StartIndex

    while ($idx -lt $Lines.Count) {
        $raw = $Lines[$idx].TrimEnd("`r")
        if ($raw -eq '') {
            $content.Add('')
            $idx++
            continue
        }
        $leading = 0
        if ($raw -match '^(\s*)') { $leading = $Matches[1].Length }
        if ($leading -ge 6) {
            if ($stripWidth -lt 0) { $stripWidth = $leading }
            $strip = [Math]::Min($stripWidth, $leading)
            $content.Add($raw.Substring($strip))
            $idx++
            continue
        }
        break
    }

    # YAML "clip" chomping: drop trailing blank lines.
    while ($content.Count -gt 0 -and $content[$content.Count - 1] -eq '') {
        $content.RemoveAt($content.Count - 1)
    }

    return @{ Value = [string]::Join("`n", $content); NextIndex = $idx }
}

function Parse-ProjectList {
    param([string]$Path)

    $lines = @(Get-Content -LiteralPath $Path)
    $inList = $false
    $records = New-Object System.Collections.Generic.List[hashtable]
    $current = $null
    $idx = 0

    while ($idx -lt $lines.Count) {
        $line = $lines[$idx].TrimEnd("`r")

        if ($line -match '^projects:\s*$') { $inList = $true; $idx++; continue }
        if (-not $inList) { $idx++; continue }

        $recordStart = $line -match '^\s{2}-\s+([a-zA-Z_]+):\s*(.*)$'
        $continuation = -not $recordStart -and $line -match '^\s{4,}([a-zA-Z_]+):\s*(.*)$'

        if ($recordStart -or $continuation) {
            $key = $Matches[1]
            $val = $Matches[2]

            if ($recordStart) {
                if ($current) { $records.Add($current) }
                $current = @{}
            }

            if ($val -match '^\|[+-]?\d*\s*$') {
                $idx++
                $block = Read-BlockScalar -Lines $lines -StartIndex $idx
                if ($current) { $current[$key] = $block.Value }
                $idx = $block.NextIndex
                continue
            }

            if ($current) { $current[$key] = $val.Trim('"') }
            $idx++
            continue
        }

        if ($line -match '^\S') { $inList = $false }
        $idx++
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

# ─── load existing lock (best-effort local-path reuse for external entries) ─

$ExistingLockPath = @{}
if (Test-Path $LockFile) {
    foreach ($rec in (Parse-ProjectList -Path $LockFile)) {
        $n = Get-Field $rec 'name'
        if ($n) { $ExistingLockPath[$n] = Get-Field $rec 'local_path' }
    }
}

# ─── local-path resolution (external entries only) ───────────────────────────

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

# ─── unified DFS resolution (in-repo + external) with cycle detection ────────

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
$DecisionsNeeded = 0

# Resolve-Node -Name -Repo -Path -Notes -Required -Parent -Depth -BaseDir
#
# -Repo empty  -> in-repo entry. -Path is resolved relative to -BaseDir (the
#                 local_path of whichever manifest declared it — the repo
#                 root at depth 1, or a previously-resolved node's checkout
#                 at deeper levels). No resolution is possible to fail — the
#                 path is either there or it isn't.
# -Repo set    -> external entry. Resolved via Resolve-LocalPath exactly as
#                 before; -BaseDir is irrelevant for it.
#
# Either kind, once resolved, is recorded in the lock and recursed into if it
# has its own project.deps.yaml — the walk doesn't care which kind a node or
# its children are.
function Resolve-Node {
    param([string]$Name, [string]$Repo, [string]$Path, [string]$Notes, [string]$Required,
          [string]$Parent, [int]$Depth, [string]$BaseDir)

    $localPath = $null
    if (-not $Repo) {
        $kind = 'in-repo'
        $joined = Join-Path $BaseDir $Path
        if (Test-Path $joined) {
            $localPath = (Resolve-Path $joined).Path
        } else {
            $localPath = $joined
            Write-ErrLine "warning: in-repo project '$Name' declares path '$Path' which does not exist (looked under $BaseDir)"
        }
        $key = "inrepo|$localPath"
    } else {
        $kind = 'external'
        $repoNorm = Normalize-Repo $Repo
        $key = "ext|$repoNorm|$Path"
    }

    if ($VisitedState[$key] -eq 'stack') {
        Write-ErrLine "error: cyclic dependency detected — $([string]::Join(' -> ', $CycleChain)) -> $Name"
        exit 1
    }
    if ($VisitedState[$key] -eq 'done') { return }

    $VisitedState[$key] = 'stack'
    $CycleChain.Add($Name)

    if ($kind -eq 'external') {
        $localPath = Resolve-LocalPath -Name $Name -Repo $Repo
    }

    if ($kind -eq 'in-repo' -or $localPath) {
        $LockEntries.Add(@{ name = $Name; kind = $kind; repo = $Repo; path = $Path; local_path = $localPath; notes = $Notes; parent = $Parent; depth = $Depth })

        # For an external entry with a Path (a subpath into a monorepo
        # dependency), the addressed package's own project.deps.yaml — and
        # anything it declares in-repo — lives under localPath/Path, not at
        # localPath (the checkout root). nodeDir is that effective directory;
        # it's what recursion and any in-repo children resolve relative to.
        $nodeDir = $localPath
        if ($kind -eq 'external' -and $Path) {
            $nodeDir = Join-Path $localPath $Path
        }

        # If this node has its own .project.lock.yaml (it was independently
        # resolved before, on this machine, outside of this run), seed its
        # already-resolved external entries into $PresetPaths — the same
        # top-priority mechanism -Set uses — so resolving this node's own
        # dependencies below can reuse them instead of asking from scratch.
        # An explicit -Set (or an already-known top-level lock entry) always
        # outranks this and is never overwritten.
        $childLock = Join-Path $nodeDir '.project.lock.yaml'
        if (Test-Path $childLock) {
            foreach ($seed in (Parse-ProjectList -Path $childLock)) {
                $sName = Get-Field $seed 'name'
                if (-not $sName) { continue }
                if ((Get-Field $seed 'kind') -ne 'external') { continue }
                if ($PresetPaths.ContainsKey($sName)) { continue }
                if ($ExistingLockPath.ContainsKey($sName)) { continue }
                $sLocalPath = Get-Field $seed 'local_path'
                if (-not (Test-Path (Join-Path $sLocalPath '.git'))) { continue }

                if ($Check) {
                    Write-ErrLine "preset: '$sName' already resolved by '$Name's own lock at $sLocalPath"
                    if ($Porcelain) {
                        Write-Host "DECISION name=$sName repo=$(Get-Field $seed 'repo') parent=$Name kind=preset preset_path=$sLocalPath"
                    }
                    $PresetPaths[$sName] = $sLocalPath
                } elseif (Test-InteractiveConsole) {
                    $pAns = Read-Host "Found '$sName' already resolved by '$Name's own lock at '$sLocalPath' — use it? [Y/n, or type a different path]"
                    if ($pAns -match '^[Nn]') {
                        # declined — fall through to normal resolution for this name
                    } elseif ([string]::IsNullOrWhiteSpace($pAns) -or $pAns -match '^[Yy]') {
                        Write-ErrLine "preset: using '$sName' -> $sLocalPath"
                        $PresetPaths[$sName] = $sLocalPath
                    } else {
                        if (-not (Test-Path (Join-Path $pAns '.git'))) {
                            Write-ErrLine "warning: '$pAns' does not look like a git checkout (no .git)"
                        }
                        $pAns = if (Test-Path $pAns) { (Resolve-Path $pAns).Path } else { $pAns }
                        Write-ErrLine "preset: using '$sName' -> $pAns"
                        $PresetPaths[$sName] = $pAns
                    }
                } else {
                    Write-ErrLine "preset: '$sName' already resolved by '$Name's own lock at $sLocalPath — using it (pass -Set $sName=PATH to override)"
                    $PresetPaths[$sName] = $sLocalPath
                }
            }
        }

        $childManifest = Join-Path $nodeDir 'project.deps.yaml'
        if (Test-Path $childManifest) {
            foreach ($child in (Parse-ProjectList -Path $childManifest)) {
                $cName = Get-Field $child 'name'
                if (-not $cName) { continue }
                Resolve-Node -Name $cName -Repo (Get-Field $child 'repo') -Path (Get-Field $child 'path') `
                    -Notes (Get-Field $child 'notes') -Required (Get-Field $child 'required' 'true') `
                    -Parent $Name -Depth ($Depth + 1) -BaseDir $nodeDir
            }
        }
    } elseif ($Required -eq 'true') {
        Write-ErrLine "error: required project '$Name' ($Repo) could not be resolved"
        if ($Porcelain) {
            Write-Host "DECISION name=$Name repo=$Repo parent=$Parent kind=unresolved required=true"
        }
        $script:FailedRequired = $true
    } else {
        Write-ErrLine "warning: optional project '$Name' ($Repo) not resolved — skipping"
        if ($Porcelain) {
            Write-Host "DECISION name=$Name repo=$Repo parent=$Parent kind=unresolved required=false"
        }
        $script:DecisionsNeeded++
    }

    $VisitedState[$key] = 'done'
    $CycleChain.RemoveAt($CycleChain.Count - 1)
}

foreach ($rec in (Parse-ProjectList -Path $Manifest)) {
    $name = Get-Field $rec 'name'
    if (-not $name) { continue }
    Resolve-Node -Name $name -Repo (Get-Field $rec 'repo') -Path (Get-Field $rec 'path') `
        -Notes (Get-Field $rec 'notes') -Required (Get-Field $rec 'required' 'true') `
        -Parent 'root' -Depth 1 -BaseDir $RepoRoot
}

if ($FailedRequired) { exit 1 }

if ($RequireDecisions -and $DecisionsNeeded -gt 0) {
    Write-ErrLine "error: $DecisionsNeeded project(s) need a human decision before this can complete — run -Check first"
    exit 1
}

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
#
# Write-Field emits a flat `key: value` line, unless the value contains an
# embedded newline (e.g. a multi-line `notes`), in which case it emits a
# literal block scalar (`key: |` + 6-space-indented lines) — the exact
# counterpart to Read-BlockScalar, so a multi-line value carried through from
# project.deps.yaml round-trips correctly.
function Write-Field {
    param([System.Collections.Generic.List[string]]$Lines, [string]$Key, [string]$Value)
    if ($Value -match "`n") {
        $Lines.Add("    ${Key}: |")
        foreach ($vline in ($Value -split "`n")) {
            $Lines.Add("      $vline")
        }
    } else {
        $Lines.Add("    ${Key}: $Value")
    }
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("resolved_at: $((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'))")
$lines.Add("root: $RootName")
$lines.Add('projects:')
foreach ($e in $LockEntries) {
    $lines.Add("  - name: $($e.name)")
    Write-Field -Lines $lines -Key 'kind' -Value $e.kind
    Write-Field -Lines $lines -Key 'repo' -Value $e.repo
    Write-Field -Lines $lines -Key 'path' -Value $e.path
    Write-Field -Lines $lines -Key 'local_path' -Value $e.local_path
    Write-Field -Lines $lines -Key 'notes' -Value $e.notes
    Write-Field -Lines $lines -Key 'parent' -Value $e.parent
    Write-Field -Lines $lines -Key 'depth' -Value $e.depth
}
Set-Content -LiteralPath $LockFile -Value $lines
Write-Host "wrote $LockFile"
