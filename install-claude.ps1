#Requires -Version 5.1
<#
.SYNOPSIS
    Install CLAUDE.md development framework to ~/.claude/

.DESCRIPTION
    Downloads and installs the CLAUDE.md development framework including
    skills, agents, and commands for Claude Code.

.PARAMETER ClaudeOnly
    Install only CLAUDE.md

.PARAMETER SkillsOnly
    Install only skills

.PARAMETER AgentsOnly
    Install only agents

.PARAMETER NoAgents
    Install without agents

.PARAMETER Lang
    Install only specific language(s) + core skills.
    Languages: typescript, go, rust, csharp, unity
    Use comma to separate multiple: -Lang "go,rust"
    Note: unity automatically includes csharp

.PARAMETER WithOpenCode
    Also install OpenCode configuration

.PARAMETER OpenCodeOnly
    Install only OpenCode configuration

.PARAMETER Version
    Install specific version (default: main)

.EXAMPLE
    .\install-claude.ps1
    # Install everything (all languages)

.EXAMPLE
    .\install-claude.ps1 -Lang "unity"
    # Install core + Unity + C# (Unity includes C#)

.EXAMPLE
    .\install-claude.ps1 -Lang "go,rust"
    # Install core + Go + Rust

.EXAMPLE
    .\install-claude.ps1 -Version "v3.3.0"
    # Install specific version

.EXAMPLE
    irm https://raw.githubusercontent.com/intinig/claude.md/main/install-claude.ps1 | iex
    # One-liner installation (all languages)

.LINK
    https://github.com/intinig/claude.md
#>

[CmdletBinding()]
param(
    [switch]$ClaudeOnly,
    [switch]$SkillsOnly,
    [switch]$AgentsOnly,
    [switch]$NoAgents,
    [string]$Lang = "",
    [switch]$WithOpenCode,
    [switch]$OpenCodeOnly,
    [string]$Version = "main",
    [switch]$Help
)

# Colors
$Colors = @{
    Red = "Red"
    Green = "Green"
    Yellow = "Yellow"
    Blue = "Cyan"
    Purple = "Magenta"
    Cyan = "DarkCyan"
}

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White",
        [switch]$NoNewline
    )
    if ($NoNewline) {
        Write-Host $Message -ForegroundColor $Color -NoNewline
    } else {
        Write-Host $Message -ForegroundColor $Color
    }
}

function Show-Help {
    @"
Install CLAUDE.md development framework to ~/.claude/

Usage:
    .\install-claude.ps1 [OPTIONS]

Options:
    -ClaudeOnly        Install only CLAUDE.md
    -NoAgents          Install without agents
    -SkillsOnly        Install only skills
    -AgentsOnly        Install only agents
    -Lang LANGUAGES    Install only specific language(s) + core skills
                       Languages: typescript, go, rust, csharp, unity
                       Use comma to separate multiple: -Lang "go,rust"
                       Note: unity automatically includes csharp
    -WithOpenCode      Also install OpenCode configuration
    -OpenCodeOnly      Install only OpenCode configuration
    -Version VERSION   Install specific version (default: main)
    -Help              Show this help message

Supported Languages:
    typescript (ts)    TypeScript/JavaScript + React
    go                 Go/Golang
    rust               Rust
    csharp (cs)        C#/.NET
    unity              Unity game engine (includes C# support)

Examples:
    # Install everything (all languages)
    .\install-claude.ps1

    # Install only Go support
    .\install-claude.ps1 -Lang "go"

    # Install Go and Rust support
    .\install-claude.ps1 -Lang "go,rust"

    # Install Unity support (automatically includes C#)
    .\install-claude.ps1 -Lang "unity"

    # Install specific version
    .\install-claude.ps1 -Version "v3.3.0"

    # One-liner installation (all languages)
    irm https://raw.githubusercontent.com/intinig/claude.md/main/install-claude.ps1 | iex

    # One-liner for specific language (save script first)
    irm https://raw.githubusercontent.com/intinig/claude.md/main/install-claude.ps1 -OutFile install.ps1; .\install.ps1 -Lang "csharp"

"@
}

if ($Help) {
    Show-Help
    exit 0
}

# Settings
$BaseUrl = "https://raw.githubusercontent.com/intinig/claude.md"
$ClaudeDir = Join-Path $HOME ".claude"

$InstallClaude = $true
$InstallSkills = $true
$InstallCommands = $true
$InstallAgents = $true
$InstallOpenCode = $false

# Handle flags
if ($ClaudeOnly) {
    $InstallSkills = $false
    $InstallCommands = $false
    $InstallAgents = $false
}

if ($SkillsOnly) {
    $InstallClaude = $false
    $InstallCommands = $false
    $InstallAgents = $false
}

if ($AgentsOnly) {
    $InstallClaude = $false
    $InstallSkills = $false
    $InstallCommands = $false
}

if ($NoAgents) {
    $InstallAgents = $false
}

if ($WithOpenCode) {
    $InstallOpenCode = $true
}

if ($OpenCodeOnly) {
    $InstallClaude = $false
    $InstallSkills = $false
    $InstallCommands = $false
    $InstallAgents = $false
    $InstallOpenCode = $true
}

# Normalize language names
function Get-NormalizedLanguages {
    param([string]$Input)

    if ([string]::IsNullOrWhiteSpace($Input)) {
        return @()
    }

    $normalized = @()
    $langs = $Input.ToLower() -split ","

    foreach ($lang in $langs) {
        $lang = $lang.Trim()
        switch ($lang) {
            { $_ -in "ts", "typescript" } { $normalized += "typescript" }
            { $_ -in "go", "golang" } { $normalized += "go" }
            { $_ -in "rust", "rs" } { $normalized += "rust" }
            { $_ -in "cs", "csharp", "c#", "dotnet", ".net" } { $normalized += "csharp" }
            { $_ -in "unity", "unity3d" } {
                $normalized += "unity"
                $normalized += "csharp"  # Unity includes C#
            }
            "all" { return @() }  # Empty = all languages
            "" { }  # Skip empty
            default {
                Write-ColorOutput "Error: Unknown language '$lang'" -Color Red
                Write-ColorOutput "Supported languages: typescript, go, rust, csharp, unity" -Color Yellow
                exit 1
            }
        }
    }

    return $normalized | Select-Object -Unique
}

function Test-ShouldInstallLang {
    param([string]$Language)

    if ($script:Languages.Count -eq 0) {
        return $true  # No filter = install all
    }

    return $script:Languages -contains $Language
}

# Parse languages
$Languages = Get-NormalizedLanguages -Input $Lang

function Get-LangDisplay {
    if ($Languages.Count -eq 0) {
        return "all languages"
    }
    return ($Languages -join " + ")
}

# Banner
Write-Host ""
Write-ColorOutput "╔════════════════════════════════════════════════════════════╗" -Color Blue
Write-ColorOutput "║  CLAUDE.md Development Framework Installer                 ║" -Color Blue
Write-ColorOutput ("║  Version: {0,-49}║" -f $Version) -Color Blue
Write-ColorOutput ("║  Languages: {0,-47}║" -f (Get-LangDisplay)) -Color Blue
Write-ColorOutput "╚════════════════════════════════════════════════════════════╝" -Color Blue
Write-Host ""

# Download function
function Get-RemoteFile {
    param(
        [string]$Url,
        [string]$Destination,
        [string]$Description
    )

    Write-ColorOutput "→ " -Color Yellow -NoNewline
    Write-Host "Downloading $Description..."

    try {
        $parentDir = Split-Path -Parent $Destination
        if (-not (Test-Path $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }

        Invoke-WebRequest -Uri $Url -OutFile $Destination -UseBasicParsing -ErrorAction Stop
        Write-ColorOutput "✓ " -Color Green -NoNewline
        Write-Host "$Description installed"
        return $true
    }
    catch {
        Write-ColorOutput "✗ " -Color Red -NoNewline
        Write-Host "Failed to download $Description"
        return $false
    }
}

# Backup function
function Backup-File {
    param([string]$FilePath)

    if (Test-Path $FilePath) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backup = "$FilePath.backup.$timestamp"
        Write-ColorOutput "→ " -Color Yellow -NoNewline
        Write-Host "Backing up existing file to $backup"
        Move-Item -Path $FilePath -Destination $backup -Force
    }
}

# Create directories
Write-ColorOutput "Creating directories..." -Color Blue

$directories = @(
    (Join-Path $ClaudeDir "agents"),
    (Join-Path $ClaudeDir "skills"),
    (Join-Path $ClaudeDir "commands")
)

# Core skill directories
$coreSkillDirs = @("tdd", "testing", "functional", "refactoring", "expectations", "planning", "mutation-testing")
foreach ($skill in $coreSkillDirs) {
    $directories += Join-Path $ClaudeDir "skills\$skill"
}

# TypeScript directories
if (Test-ShouldInstallLang "typescript") {
    $directories += @(
        (Join-Path $ClaudeDir "skills\typescript-strict"),
        (Join-Path $ClaudeDir "skills\front-end-testing"),
        (Join-Path $ClaudeDir "skills\react-testing")
    )
}

# Go directories
if (Test-ShouldInstallLang "go") {
    $directories += @(
        (Join-Path $ClaudeDir "skills\go-strict"),
        (Join-Path $ClaudeDir "skills\go-testing"),
        (Join-Path $ClaudeDir "skills\go-error-handling"),
        (Join-Path $ClaudeDir "skills\go-concurrency")
    )
}

# Rust directories
if (Test-ShouldInstallLang "rust") {
    $directories += @(
        (Join-Path $ClaudeDir "skills\rust-strict"),
        (Join-Path $ClaudeDir "skills\rust-testing"),
        (Join-Path $ClaudeDir "skills\rust-error-handling"),
        (Join-Path $ClaudeDir "skills\rust-concurrency")
    )
}

# C# directories
if (Test-ShouldInstallLang "csharp") {
    $directories += @(
        (Join-Path $ClaudeDir "skills\csharp-strict"),
        (Join-Path $ClaudeDir "skills\csharp-testing"),
        (Join-Path $ClaudeDir "skills\csharp-error-handling"),
        (Join-Path $ClaudeDir "skills\csharp-concurrency")
    )
}

# Unity directories
if (Test-ShouldInstallLang "unity") {
    $directories += @(
        (Join-Path $ClaudeDir "skills\unity-strict"),
        (Join-Path $ClaudeDir "skills\unity-testing"),
        (Join-Path $ClaudeDir "skills\unity-patterns"),
        (Join-Path $ClaudeDir "skills\unity-performance")
    )
}

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

Write-ColorOutput "✓ " -Color Green -NoNewline
Write-Host "Directories created"
Write-Host ""

# Install CLAUDE.md
if ($InstallClaude) {
    Write-ColorOutput "Installing CLAUDE.md..." -Color Blue
    $claudeMdPath = Join-Path $ClaudeDir "CLAUDE.md"
    Backup-File -FilePath $claudeMdPath
    Get-RemoteFile `
        -Url "$BaseUrl/$Version/claude/.claude/CLAUDE.md" `
        -Destination $claudeMdPath `
        -Description "CLAUDE.md"
    Write-Host ""
}

# Install skills
if ($InstallSkills) {
    Write-ColorOutput "Installing skills..." -Color Blue

    # Core skills
    $coreSkills = @(
        "tdd/SKILL.md",
        "testing/SKILL.md",
        "functional/SKILL.md",
        "refactoring/SKILL.md",
        "expectations/SKILL.md",
        "planning/SKILL.md",
        "mutation-testing/SKILL.md"
    )

    Write-ColorOutput "  Core skills (language-agnostic)" -Color Magenta
    foreach ($skill in $coreSkills) {
        $destPath = Join-Path $ClaudeDir "skills\$skill"
        Backup-File -FilePath $destPath
        Get-RemoteFile `
            -Url "$BaseUrl/$Version/claude/.claude/skills/$skill" `
            -Destination $destPath `
            -Description "skills/$skill"
    }

    # TypeScript skills
    if (Test-ShouldInstallLang "typescript") {
        Write-Host ""
        Write-ColorOutput "  TypeScript skills" -Color Yellow
        $tsSkills = @(
            "typescript-strict/SKILL.md",
            "front-end-testing/SKILL.md",
            "react-testing/SKILL.md"
        )
        foreach ($skill in $tsSkills) {
            $destPath = Join-Path $ClaudeDir "skills\$skill"
            Backup-File -FilePath $destPath
            Get-RemoteFile `
                -Url "$BaseUrl/$Version/claude/.claude/skills/$skill" `
                -Destination $destPath `
                -Description "skills/$skill"
        }
    }

    # Go skills
    if (Test-ShouldInstallLang "go") {
        Write-Host ""
        Write-ColorOutput "  Go skills" -Color Cyan
        $goSkills = @(
            "go-strict/SKILL.md",
            "go-testing/SKILL.md",
            "go-error-handling/SKILL.md",
            "go-concurrency/SKILL.md"
        )
        foreach ($skill in $goSkills) {
            $destPath = Join-Path $ClaudeDir "skills\$skill"
            Backup-File -FilePath $destPath
            Get-RemoteFile `
                -Url "$BaseUrl/$Version/claude/.claude/skills/$skill" `
                -Destination $destPath `
                -Description "skills/$skill"
        }
    }

    # Rust skills
    if (Test-ShouldInstallLang "rust") {
        Write-Host ""
        Write-ColorOutput "  Rust skills" -Color Red
        $rustSkills = @(
            "rust-strict/SKILL.md",
            "rust-testing/SKILL.md",
            "rust-error-handling/SKILL.md",
            "rust-concurrency/SKILL.md"
        )
        foreach ($skill in $rustSkills) {
            $destPath = Join-Path $ClaudeDir "skills\$skill"
            Backup-File -FilePath $destPath
            Get-RemoteFile `
                -Url "$BaseUrl/$Version/claude/.claude/skills/$skill" `
                -Destination $destPath `
                -Description "skills/$skill"
        }
    }

    # C# skills
    if (Test-ShouldInstallLang "csharp") {
        Write-Host ""
        Write-ColorOutput "  C# skills" -Color Magenta
        $csharpSkills = @(
            "csharp-strict/SKILL.md",
            "csharp-testing/SKILL.md",
            "csharp-error-handling/SKILL.md",
            "csharp-concurrency/SKILL.md"
        )
        foreach ($skill in $csharpSkills) {
            $destPath = Join-Path $ClaudeDir "skills\$skill"
            Backup-File -FilePath $destPath
            Get-RemoteFile `
                -Url "$BaseUrl/$Version/claude/.claude/skills/$skill" `
                -Destination $destPath `
                -Description "skills/$skill"
        }
    }

    # Unity skills
    if (Test-ShouldInstallLang "unity") {
        Write-Host ""
        Write-ColorOutput "  Unity skills" -Color DarkCyan
        $unitySkills = @(
            "unity-strict/SKILL.md",
            "unity-testing/SKILL.md",
            "unity-patterns/SKILL.md",
            "unity-performance/SKILL.md"
        )
        foreach ($skill in $unitySkills) {
            $destPath = Join-Path $ClaudeDir "skills\$skill"
            Backup-File -FilePath $destPath
            Get-RemoteFile `
                -Url "$BaseUrl/$Version/claude/.claude/skills/$skill" `
                -Destination $destPath `
                -Description "skills/$skill"
        }
    }

    Write-Host ""
}

# Install commands
if ($InstallCommands) {
    Write-ColorOutput "Installing commands (slash commands)..." -Color Blue

    $commands = @("pr.md")
    foreach ($cmd in $commands) {
        $destPath = Join-Path $ClaudeDir "commands\$cmd"
        Backup-File -FilePath $destPath
        Get-RemoteFile `
            -Url "$BaseUrl/$Version/claude/.claude/commands/$cmd" `
            -Destination $destPath `
            -Description "commands/$cmd"
    }
    Write-Host ""
}

# Install agents
if ($InstallAgents) {
    Write-ColorOutput "Installing Claude Code agents..." -Color Blue

    # Core agents
    $coreAgents = @(
        "tdd-guardian.md",
        "refactor-scan.md",
        "docs-guardian.md",
        "adr.md",
        "learn.md",
        "use-case-data-patterns.md",
        "progress-guardian.md",
        "pr-reviewer.md",
        "README.md"
    )

    Write-ColorOutput "  Core agents" -Color Magenta
    foreach ($agent in $coreAgents) {
        $destPath = Join-Path $ClaudeDir "agents\$agent"
        Backup-File -FilePath $destPath
        Get-RemoteFile `
            -Url "$BaseUrl/$Version/claude/.claude/agents/$agent" `
            -Destination $destPath `
            -Description "agents/$agent"
    }

    # TypeScript enforcer
    if (Test-ShouldInstallLang "typescript") {
        Write-Host ""
        Write-ColorOutput "  TypeScript enforcer" -Color Yellow
        $destPath = Join-Path $ClaudeDir "agents\ts-enforcer.md"
        Backup-File -FilePath $destPath
        Get-RemoteFile `
            -Url "$BaseUrl/$Version/claude/.claude/agents/ts-enforcer.md" `
            -Destination $destPath `
            -Description "agents/ts-enforcer.md"
    }

    # Go enforcer
    if (Test-ShouldInstallLang "go") {
        Write-Host ""
        Write-ColorOutput "  Go enforcer" -Color Cyan
        $destPath = Join-Path $ClaudeDir "agents\go-enforcer.md"
        Backup-File -FilePath $destPath
        Get-RemoteFile `
            -Url "$BaseUrl/$Version/claude/.claude/agents/go-enforcer.md" `
            -Destination $destPath `
            -Description "agents/go-enforcer.md"
    }

    # Rust enforcer
    if (Test-ShouldInstallLang "rust") {
        Write-Host ""
        Write-ColorOutput "  Rust enforcer" -Color Red
        $destPath = Join-Path $ClaudeDir "agents\rust-enforcer.md"
        Backup-File -FilePath $destPath
        Get-RemoteFile `
            -Url "$BaseUrl/$Version/claude/.claude/agents/rust-enforcer.md" `
            -Destination $destPath `
            -Description "agents/rust-enforcer.md"
    }

    # C# enforcer
    if (Test-ShouldInstallLang "csharp") {
        Write-Host ""
        Write-ColorOutput "  C# enforcer" -Color Magenta
        $destPath = Join-Path $ClaudeDir "agents\csharp-enforcer.md"
        Backup-File -FilePath $destPath
        Get-RemoteFile `
            -Url "$BaseUrl/$Version/claude/.claude/agents/csharp-enforcer.md" `
            -Destination $destPath `
            -Description "agents/csharp-enforcer.md"
    }

    # Unity enforcer
    if (Test-ShouldInstallLang "unity") {
        Write-Host ""
        Write-ColorOutput "  Unity enforcer" -Color DarkCyan
        $destPath = Join-Path $ClaudeDir "agents\unity-enforcer.md"
        Backup-File -FilePath $destPath
        Get-RemoteFile `
            -Url "$BaseUrl/$Version/claude/.claude/agents/unity-enforcer.md" `
            -Destination $destPath `
            -Description "agents/unity-enforcer.md"
    }

    Write-Host ""
}

# Install OpenCode configuration
if ($InstallOpenCode) {
    Write-ColorOutput "Installing OpenCode configuration..." -Color Blue
    $openCodeDir = Join-Path $HOME ".config\opencode"
    if (-not (Test-Path $openCodeDir)) {
        New-Item -ItemType Directory -Path $openCodeDir -Force | Out-Null
    }
    $destPath = Join-Path $openCodeDir "opencode.json"
    Backup-File -FilePath $destPath
    Get-RemoteFile `
        -Url "$BaseUrl/$Version/opencode/.config/opencode/opencode.json" `
        -Destination $destPath `
        -Description "opencode.json"
    Write-Host ""
}

# Success message
Write-Host ""
Write-ColorOutput "╔════════════════════════════════════════════════════════════╗" -Color Green
Write-ColorOutput "║  Installation complete! ✓                                  ║" -Color Green
Write-ColorOutput "╚════════════════════════════════════════════════════════════╝" -Color Green
Write-Host ""

# Summary
Write-ColorOutput "Installed to $ClaudeDir" -Color Blue
Write-Host ""

if ($InstallClaude) {
    Write-ColorOutput "  ✓ " -Color Green -NoNewline
    Write-Host "CLAUDE.md (lean core principles, v3.3.0)"
}

if ($InstallSkills) {
    Write-ColorOutput "  ✓ " -Color Green -NoNewline
    Write-Host "Core skills: tdd, testing, functional, refactoring, expectations, planning, mutation-testing"

    if (Test-ShouldInstallLang "typescript") {
        Write-ColorOutput "  ✓ " -Color Green -NoNewline
        Write-ColorOutput "TypeScript" -Color Yellow -NoNewline
        Write-Host ": typescript-strict, front-end-testing, react-testing"
    }

    if (Test-ShouldInstallLang "go") {
        Write-ColorOutput "  ✓ " -Color Green -NoNewline
        Write-ColorOutput "Go" -Color Cyan -NoNewline
        Write-Host ": go-strict, go-testing, go-error-handling, go-concurrency"
    }

    if (Test-ShouldInstallLang "rust") {
        Write-ColorOutput "  ✓ " -Color Green -NoNewline
        Write-ColorOutput "Rust" -Color Red -NoNewline
        Write-Host ": rust-strict, rust-testing, rust-error-handling, rust-concurrency"
    }

    if (Test-ShouldInstallLang "csharp") {
        Write-ColorOutput "  ✓ " -Color Green -NoNewline
        Write-ColorOutput "C#" -Color Magenta -NoNewline
        Write-Host ": csharp-strict, csharp-testing, csharp-error-handling, csharp-concurrency"
    }

    if (Test-ShouldInstallLang "unity") {
        Write-ColorOutput "  ✓ " -Color Green -NoNewline
        Write-ColorOutput "Unity" -Color DarkCyan -NoNewline
        Write-Host ": unity-strict, unity-testing, unity-patterns, unity-performance"
    }
}

if ($InstallCommands) {
    Write-ColorOutput "  ✓ " -Color Green -NoNewline
    Write-Host "commands/ (slash command: /pr)"
}

if ($InstallAgents) {
    Write-ColorOutput "  ✓ " -Color Green -NoNewline
    Write-Host "Core agents: tdd-guardian, refactor-scan, docs-guardian, adr, learn, pr-reviewer, etc."

    if (Test-ShouldInstallLang "typescript") {
        Write-ColorOutput "  ✓ " -Color Green -NoNewline
        Write-ColorOutput "ts-enforcer" -Color Yellow -NoNewline
        Write-Host " (TypeScript best practices)"
    }

    if (Test-ShouldInstallLang "go") {
        Write-ColorOutput "  ✓ " -Color Green -NoNewline
        Write-ColorOutput "go-enforcer" -Color Cyan -NoNewline
        Write-Host " (Go best practices)"
    }

    if (Test-ShouldInstallLang "rust") {
        Write-ColorOutput "  ✓ " -Color Green -NoNewline
        Write-ColorOutput "rust-enforcer" -Color Red -NoNewline
        Write-Host " (Rust best practices)"
    }

    if (Test-ShouldInstallLang "csharp") {
        Write-ColorOutput "  ✓ " -Color Green -NoNewline
        Write-ColorOutput "csharp-enforcer" -Color Magenta -NoNewline
        Write-Host " (C# best practices)"
    }

    if (Test-ShouldInstallLang "unity") {
        Write-ColorOutput "  ✓ " -Color Green -NoNewline
        Write-ColorOutput "unity-enforcer" -Color DarkCyan -NoNewline
        Write-Host " (Unity best practices)"
    }
}

if ($InstallOpenCode) {
    Write-Host ""
    Write-ColorOutput "Installed to ~/.config/opencode/" -Color Blue
    Write-ColorOutput "  ✓ " -Color Green -NoNewline
    Write-Host "opencode.json (OpenCode rules configuration)"
}

Write-Host ""
Write-ColorOutput "Architecture (v3.3.0):" -Color Blue
Write-Host ""
Write-ColorOutput "  CLAUDE.md  " -Color Yellow -NoNewline
Write-Host "→ Core principles (~200 lines, always loaded)"
Write-ColorOutput "  skills/    " -Color Yellow -NoNewline
Write-Host "→ Detailed patterns (loaded on-demand when relevant)"
Write-ColorOutput "  commands/  " -Color Yellow -NoNewline
Write-Host "→ Slash commands (manually invoked)"
Write-ColorOutput "  agents/    " -Color Yellow -NoNewline
Write-Host "→ Complex multi-step workflows"
Write-Host ""

Write-ColorOutput "Supported Languages:" -Color Blue
Write-Host ""
Write-ColorOutput "  TypeScript  " -Color Yellow -NoNewline
Write-Host "→ typescript-strict, react-testing, front-end-testing"
Write-ColorOutput "  Go          " -Color Cyan -NoNewline
Write-Host "→ go-strict, go-testing, go-error-handling, go-concurrency"
Write-ColorOutput "  Rust        " -Color Red -NoNewline
Write-Host "→ rust-strict, rust-testing, rust-error-handling, rust-concurrency"
Write-ColorOutput "  C#          " -Color Magenta -NoNewline
Write-Host "→ csharp-strict, csharp-testing, csharp-error-handling, csharp-concurrency"
Write-ColorOutput "  Unity       " -Color DarkCyan -NoNewline
Write-Host "→ unity-strict, unity-testing, unity-patterns, unity-performance (+ C#)"
Write-Host ""

Write-ColorOutput "Next steps:" -Color Blue
Write-Host ""
Write-Host "  1. Verify installation:"
Write-ColorOutput "     Get-ChildItem $ClaudeDir" -Color Yellow
Write-Host ""
Write-Host "  2. Test with Claude Code:"
Write-ColorOutput "     /memory" -Color Yellow
Write-Host ""

if ($InstallAgents) {
    Write-Host "  3. Learn about agents:"
    Write-ColorOutput "     Get-Content $ClaudeDir\agents\README.md" -Color Yellow
    Write-Host ""
}

Write-ColorOutput "Install specific language support:" -Color Blue
Write-Host ""
Write-ColorOutput "  .\install-claude.ps1 -Lang `"go`"" -Color Yellow -NoNewline
Write-Host "         # Go only"
Write-ColorOutput "  .\install-claude.ps1 -Lang `"unity`"" -Color Yellow -NoNewline
Write-Host "      # Unity + C#"
Write-ColorOutput "  .\install-claude.ps1 -Lang `"go,rust`"" -Color Yellow -NoNewline
Write-Host "    # Multiple languages"
Write-Host ""

Write-ColorOutput "For help or issues:" -Color Blue
Write-ColorOutput "  https://github.com/intinig/claude.md" -Color Yellow
Write-Host ""
