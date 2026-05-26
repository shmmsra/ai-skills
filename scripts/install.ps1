#Requires -Version 5.1
# install.ps1 — Install AI skills from github.com/shmmsra/ai-skills
#
# Usage (piped):
#   irm https://raw.githubusercontent.com/shmmsra/ai-skills/main/scripts/install.ps1 | iex
#
# Usage (downloaded):
#   .\install.ps1 [-Update]
#
# Env var:
#   $env:UPDATE_MODE=1; irm ... | iex

param(
    [switch]$Update
)

# ── re-exec from file when piped (irm ... | iex) ──────────────────────
# iex eval context: stdin is redirected, Read-Host doesn't reach the terminal.
# Detect this, save the script to disk, and re-run it interactively.
$_isPiped = ($MyInvocation.InvocationName -eq '') -or
            ([Console]::IsInputRedirected -and $MyInvocation.ScriptName -eq '')
if ($_isPiped) {
    $tmp = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.ps1'
    try {
        $src = 'https://raw.githubusercontent.com/shmmsra/ai-skills/main/scripts/install.ps1'
        Invoke-WebRequest -Uri $src -OutFile $tmp -UseBasicParsing
        $extraArgs = if ($env:UPDATE_MODE -eq '1') { @('-Update') } else { @() }
        & powershell.exe -ExecutionPolicy Bypass -File $tmp @extraArgs
    } finally {
        Remove-Item $tmp -Force -ErrorAction SilentlyContinue
    }
    exit $LASTEXITCODE
}

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$UpdateMode = $Update.IsPresent -or ($env:UPDATE_MODE -eq '1')
$RepoUrl    = 'https://github.com/shmmsra/ai-skills'

# ── helpers ───────────────────────────────────────────────────────────
function Write-Log     { param($m) Write-Host "->  $m" -ForegroundColor Cyan }
function Write-Ok      { param($m) Write-Host "v   $m" -ForegroundColor Green }
function Write-Warn    { param($m) Write-Host "!   $m" -ForegroundColor Yellow }
function Write-Dim     { param($m) Write-Host "    $m" -ForegroundColor DarkGray }
function Write-Heading { param($m) Write-Host "`n$m" -ForegroundColor White }
function Fail          { param($m) Write-Host "x   $m" -ForegroundColor Red; exit 1 }

# ── prereq check ──────────────────────────────────────────────────────
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Fail "git is required. Install from https://git-scm.com"
}

# ── clone repo to temp dir ────────────────────────────────────────────
$WorkDir = Join-Path ([System.IO.Path]::GetTempPath()) `
    "ai-skills-$([System.Guid]::NewGuid().ToString('N').Substring(0,8))"
New-Item -ItemType Directory -Path $WorkDir | Out-Null

try {

Write-Log "Fetching skills repository (shallow clone)..."
git clone --depth=1 --quiet --branch dist $RepoUrl "$WorkDir\repo" 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { Fail "Failed to clone $RepoUrl" }

# ── discover skills ───────────────────────────────────────────────────
$AllSkills = @(
    Get-ChildItem -Path "$WorkDir\repo" -Directory |
    Where-Object { Test-Path (Join-Path $_.FullName 'SKILL.md') } |
    Select-Object -ExpandProperty Name | Sort-Object
)
if ($AllSkills.Count -eq 0) { Fail "No skills found in repository." }

# ── helper: strip YAML frontmatter, return body ───────────────────────
function Get-SkillBody {
    param([string]$Path)
    $lines  = Get-Content $Path
    $dashes = 0
    $body   = [System.Collections.Generic.List[string]]::new()
    foreach ($line in $lines) {
        if ($line -eq '---') { $dashes++; continue }
        if ($dashes -ge 2)   { $body.Add($line) }
    }
    return $body -join "`n"
}

# ── helper: first line of description field ───────────────────────────
function Get-SkillDesc {
    param([string]$Path)
    $lines = Get-Content $Path; $inDesc = $false; $isBlock = $false
    foreach ($line in $lines) {
        if ($line -match '^description:\s*\|')    { $inDesc = $true; $isBlock = $true; continue }
        if ($line -match '^description:\s+(.+)')  { $v = $Matches[1]; return ($v -replace '^(.{120}).+$','$1...') }
        if ($isBlock -and $line -match '^  (.+)') { $v = $Matches[1]; return ($v -replace '^(.{120}).+$','$1...') }
        if ($inDesc -and $line -notmatch '^\s')   { break }
    }
    return ""
}

# ── helper: remove a skill block from an instruction file ─────────────
function Remove-SkillBlock {
    param([string]$File, [string]$Skill)
    if (-not (Test-Path $File)) { return }
    $raw     = Get-Content $File -Raw
    $escaped = [regex]::Escape($Skill)
    $raw     = $raw -replace "(?s)\n<!-- skill:$escaped -->.*?<!-- /skill:$escaped -->", ""
    Set-Content $File -Value $raw -Encoding UTF8 -NoNewline
}

# ── helper: insert or update a skill block ────────────────────────────
function Invoke-GuardedUpsert {
    param([string]$File, [string]$Skill, [string]$Content)
    $exists = (Test-Path $File) -and ((Get-Content $File -Raw) -match "<!-- skill:$([regex]::Escape($Skill)) -->")

    if ($exists) {
        if ($UpdateMode) {
            Remove-SkillBlock $File $Skill
            Add-Content -Path $File -Value $Content -Encoding UTF8
            Write-Ok "    updated in $File"
        } else {
            Write-Warn "    Already present in $File — skipping  (use -Update to overwrite)"
        }
    } else {
        Add-Content -Path $File -Value $Content -Encoding UTF8
    }
}

# ── helper: add a pattern to .gitattributes at the git root ──────────
function Add-GitAttribute {
    param([string]$Pattern)
    $gitRoot = & git rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $gitRoot) { return }
    $attrs = Join-Path $gitRoot ".gitattributes"
    if (-not ((Test-Path $attrs) -and ((Get-Content $attrs -Raw) -match [regex]::Escape($Pattern)))) {
        Add-Content -Path $attrs -Value $Pattern -Encoding UTF8
        Write-Ok "    .gitattributes  ->  added '$Pattern'"
    }
}


# ── multi-select prompt ───────────────────────────────────────────────
function Invoke-MultiSelect {
    param([string]$Prompt, [string[]]$Items)
    Write-Heading $Prompt
    for ($i = 0; $i -lt $Items.Count; $i++) {
        Write-Host ("  {0,2}.  {1}" -f ($i + 1), $Items[$i])
    }
    Write-Host "   a.  All`n"
    $raw = Read-Host "  Select (e.g. 1,2 or a)"

    if ($raw -match '^[aA]$') { return (0..($Items.Count - 1)) }

    $indices = @()
    foreach ($part in ($raw -split ',')) {
        $p = $part.Trim()
        if ($p -match '^\d+$') {
            $n = [int]$p
            if ($n -ge 1 -and $n -le $Items.Count) { $indices += ($n - 1) }
            else { Write-Warn "    Skipping out-of-range: $p" }
        } else {
            Write-Warn "    Skipping unrecognised input: $p"
        }
    }
    if ($indices.Count -eq 0) { Fail "No valid selections made." }
    return $indices
}

# ────────────────────────────────────────────────────────────────────
# Interactive flow
# ────────────────────────────────────────────────────────────────────

# ── 1. Skill selection ────────────────────────────────────────────────
$skillIndices = @(Invoke-MultiSelect "Which skills would you like to install?" $AllSkills)
$ChosenSkills = @($skillIndices | ForEach-Object { $AllSkills[$_] })

# ── 2. Scope ──────────────────────────────────────────────────────────
Write-Heading "Install scope"
Write-Host "  1.  Project  — installs into the current working directory"
Write-Host "  2.  User     — installs globally (~\.claude, ~\.gemini, ~\.windsurfrules)"
Write-Host ""
Write-Dim "Note: user-level is supported by Claude Code, Gemini CLI, and Windsurf."
Write-Dim "      Other agents fall back to project-level automatically."
Write-Host ""
$scopeInput = Read-Host "  Scope [1/2, default 1]"
$Scope = if ($scopeInput -eq '2') { 'user' } else { 'project' }

# ── 3. Agent selection ────────────────────────────────────────────────
$AgentKeys   = @('claude-code','cursor','copilot','gemini','windsurf','aider')
$AgentLabels = @(
    'Claude Code     ->  .claude\skills\<name>\'
    'Cursor          ->  .cursor\rules\<name>.mdc'
    'GitHub Copilot  ->  .github\copilot-instructions.md'
    'Gemini CLI      ->  GEMINI.md'
    'Windsurf        ->  .windsurfrules'
    'Aider           ->  CONVENTIONS.md'
)

$agentIndices = @(Invoke-MultiSelect "Which agents to install for?" $AgentLabels)
$ChosenAgents = @($agentIndices | ForEach-Object { $AgentKeys[$_] })

# ── 4. Pre-install scan ───────────────────────────────────────────────
$ExistingFound = $false

foreach ($skill in $ChosenSkills) {
    foreach ($agent in $ChosenAgents) {
        $found = $false
        switch ($agent) {
            'claude-code' {
                $d = if ($Scope -eq 'user') { "$HOME\.claude\skills\$skill" } `
                     else { ".claude\skills\$skill" }
                $found = Test-Path $d
            }
            'cursor' { $found = Test-Path ".cursor\rules\$skill.mdc" }
            'copilot' {
                $f = ".github\copilot-instructions.md"
                $found = (Test-Path $f) -and ((Get-Content $f -Raw) -match "<!-- skill:$([regex]::Escape($skill)) -->")
            }
            'gemini' {
                $f = if ($Scope -eq 'user') { "$HOME\.gemini\GEMINI.md" } else { "GEMINI.md" }
                $found = (Test-Path $f) -and ((Get-Content $f -Raw) -match "<!-- skill:$([regex]::Escape($skill)) -->")
            }
            'windsurf' {
                $f = if ($Scope -eq 'user') { "$HOME\.windsurfrules" } else { ".windsurfrules" }
                $found = (Test-Path $f) -and ((Get-Content $f -Raw) -match "<!-- skill:$([regex]::Escape($skill)) -->")
            }
            'aider' {
                $f = "CONVENTIONS.md"
                $found = (Test-Path $f) -and ((Get-Content $f -Raw) -match "<!-- skill:$([regex]::Escape($skill)) -->")
            }
        }
        if ($found) {
            Write-Warn "  Existing: $agent / $skill"
            $ExistingFound = $true
        }
    }
}

if ($ExistingFound -and -not $UpdateMode) {
    Write-Host ""
    $ans = Read-Host "  Update existing installations? [y/N]"
    if ($ans -match '^[yY]') { $UpdateMode = $true }
}

# ── 5. Confirm ────────────────────────────────────────────────────────
Write-Heading "Summary"
Write-Host "  Skills  :  $($ChosenSkills -join ', ')"
Write-Host "  Scope   :  $Scope"
Write-Host "  Agents  :  $($ChosenAgents -join ', ')"
if ($UpdateMode) { Write-Host "  Mode    :  update (existing will be replaced)" }
Write-Host ""
$confirm = Read-Host "  Proceed? [Y/n]"
if ($confirm -match '^[nN]') { Write-Log "Aborted."; exit 0 }

# ────────────────────────────────────────────────────────────────────
# Install functions
# ────────────────────────────────────────────────────────────────────

function Install-ClaudeCode {
    param([string]$Skill)
    $dest = if ($Scope -eq 'user') { "$HOME\.claude\skills\$Skill" } `
            else { ".claude\skills\$Skill" }

    if ((Test-Path $dest) -and -not $UpdateMode) {
        Write-Warn "    Already present — skipping  (use -Update to overwrite)"
        return
    }

    New-Item -ItemType Directory -Path $dest -Force | Out-Null
    Copy-Item -Path "$WorkDir\repo\$Skill\*" -Destination $dest -Recurse -Force
    Write-Ok "Claude Code  ->  $dest\"

    if ($Scope -eq 'project') { Add-GitAttribute ".claude/skills/** linguist-vendored" }
}

function Install-Cursor {
    param([string]$Skill)
    if ($Scope -eq 'user') {
        Write-Warn "    Cursor: no standard user-level location — installing at project level"
    }
    $destDir  = ".cursor\rules"
    $destFile = "$destDir\$Skill.mdc"

    if ((Test-Path $destFile) -and -not $UpdateMode) {
        Write-Warn "    Already present — skipping  (use -Update to overwrite)"
        return
    }

    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    $src  = "$WorkDir\repo\$Skill\SKILL.md"
    $desc = Get-SkillDesc $src
    $body = Get-SkillBody $src
    Set-Content -Path $destFile -Value "---`ndescription: `"$desc`"`nglobs:`nalwaysApply: false`n---`n`n$body" -Encoding UTF8
    Write-Ok "Cursor       ->  $destFile"

    Add-GitAttribute ".cursor/rules/*.mdc linguist-vendored"
}

function Install-Copilot {
    param([string]$Skill)
    if ($Scope -eq 'user') {
        Write-Warn "    GitHub Copilot: no standard user-level location — installing at project level"
    }
    $dest = ".github\copilot-instructions.md"
    New-Item -ItemType Directory -Path ".github" -Force | Out-Null
    $body    = Get-SkillBody "$WorkDir\repo\$Skill\SKILL.md"
    $content = "`n<!-- skill:$Skill -->`n$body`n<!-- /skill:$Skill -->"
    Invoke-GuardedUpsert $dest $Skill $content
    Write-Ok "Copilot      ->  $dest"
}

function Install-Gemini {
    param([string]$Skill)
    $dest = if ($Scope -eq 'user') {
        New-Item -ItemType Directory -Path "$HOME\.gemini" -Force | Out-Null
        "$HOME\.gemini\GEMINI.md"
    } else { "GEMINI.md" }
    $body    = Get-SkillBody "$WorkDir\repo\$Skill\SKILL.md"
    $content = "`n<!-- skill:$Skill -->`n$body`n<!-- /skill:$Skill -->"
    Invoke-GuardedUpsert $dest $Skill $content
    Write-Ok "Gemini       ->  $dest"
}

function Install-Windsurf {
    param([string]$Skill)
    $dest    = if ($Scope -eq 'user') { "$HOME\.windsurfrules" } else { ".windsurfrules" }
    $body    = Get-SkillBody "$WorkDir\repo\$Skill\SKILL.md"
    $content = "`n<!-- skill:$Skill -->`n$body`n<!-- /skill:$Skill -->"
    Invoke-GuardedUpsert $dest $Skill $content
    Write-Ok "Windsurf     ->  $dest"
}

function Install-Aider {
    param([string]$Skill)
    if ($Scope -eq 'user') {
        Write-Warn "    Aider: no standard user-level location — installing at project level"
    }
    $dest    = "CONVENTIONS.md"
    $body    = Get-SkillBody "$WorkDir\repo\$Skill\SKILL.md"
    $content = "`n<!-- skill:$Skill -->`n$body`n<!-- /skill:$Skill -->"
    Invoke-GuardedUpsert $dest $Skill $content
    Write-Ok "Aider        ->  $dest"
}

# ────────────────────────────────────────────────────────────────────
# Main install loop
# ────────────────────────────────────────────────────────────────────
Write-Heading "Installing..."
Write-Host ""

foreach ($skill in $ChosenSkills) {
    Write-Host "  $skill" -ForegroundColor White
    foreach ($agent in $ChosenAgents) {
        switch ($agent) {
            'claude-code' { Install-ClaudeCode $skill }
            'cursor'      { Install-Cursor     $skill }
            'copilot'     { Install-Copilot    $skill }
            'gemini'      { Install-Gemini     $skill }
            'windsurf'    { Install-Windsurf   $skill }
            'aider'       { Install-Aider      $skill }
        }
    }
    Write-Host ""
}

Write-Ok "All done. Skills are ready to use."

} finally {
    Remove-Item $WorkDir -Recurse -Force -ErrorAction SilentlyContinue
}
