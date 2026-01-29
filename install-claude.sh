#!/usr/bin/env bash
#
# Install CLAUDE.md development framework to "$INSTALL_DIR"/
#
# Usage:
#   ./install-claude.sh                    # Install everything to ~/.claude/ (default)
#   ./install-claude.sh --target project   # Install to ./.claude/ (current directory)
#   ./install-claude.sh --target /path     # Install to custom absolute path
#   ./install-claude.sh --claude-only      # Install only CLAUDE.md
#   ./install-claude.sh --no-agents        # Install without agents
#   ./install-claude.sh --skills-only      # Install only skills
#   ./install-claude.sh --lang typescript  # Install core + TypeScript only
#   ./install-claude.sh --lang go          # Install core + Go only
#   ./install-claude.sh --lang rust        # Install core + Rust only
#   ./install-claude.sh --lang csharp      # Install core + C# only
#   ./install-claude.sh --lang unity       # Install core + Unity + C# (Unity includes C#)
#   ./install-claude.sh --lang go,rust     # Install core + multiple languages
#   ./install-claude.sh --version v3.3.0   # Install specific version
#   ./install-claude.sh --with-opencode    # Also install OpenCode configuration
#
# One-liner installation:
#   curl -fsSL https://raw.githubusercontent.com/intinig/claude.md/main/install-claude.sh | bash
#
# Language-specific one-liner:
#   curl -fsSL https://raw.githubusercontent.com/intinig/claude.md/main/install-claude.sh | bash -s -- --lang unity
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default settings
VERSION="${VERSION:-main}"
INSTALL_CLAUDE=true
INSTALL_SKILLS=true
INSTALL_COMMANDS=true
INSTALL_AGENTS=true
INSTALL_OPENCODE=false
BASE_URL="https://raw.githubusercontent.com/intinig/claude.md"

# Installation directory (default: $HOME/.claude; can be overridden by CLAUDE_INSTALL_DIR env var, and further overridden by --target flag)
INSTALL_DIR="${CLAUDE_INSTALL_DIR:-$HOME/.claude}"

# Language selection (empty = all languages)
LANGUAGES=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --claude-only)
      INSTALL_SKILLS=false
      INSTALL_COMMANDS=false
      INSTALL_AGENTS=false
      shift
      ;;
    --no-agents)
      INSTALL_AGENTS=false
      shift
      ;;
    --skills-only)
      INSTALL_CLAUDE=false
      INSTALL_COMMANDS=false
      INSTALL_AGENTS=false
      INSTALL_SKILLS=true
      shift
      ;;
    --agents-only)
      INSTALL_CLAUDE=false
      INSTALL_SKILLS=false
      INSTALL_COMMANDS=false
      INSTALL_AGENTS=true
      shift
      ;;
    --lang|--language)
      LANGUAGES="$2"
      shift 2
      ;;
    --with-opencode)
      INSTALL_OPENCODE=true
      shift
      ;;
    --opencode-only)
      INSTALL_CLAUDE=false
      INSTALL_SKILLS=false
      INSTALL_COMMANDS=false
      INSTALL_AGENTS=false
      INSTALL_OPENCODE=true
      shift
      ;;
    --version)
      VERSION="$2"
      shift 2
      ;;
    --target)
      if [ -z "${2-}" ]; then
        echo -e "${RED}Error: --target requires a value (home, project, or an absolute path)${NC}"
        exit 1
      fi
      if [ -z "${2-}" ]; then
        echo -e "${RED}Error: --target requires a value (home, project, or an absolute path)${NC}"
        exit 1
      fi
      case "$2" in
        home)
          INSTALL_DIR="$HOME/.claude"
          ;;
        project)
          INSTALL_DIR="$PWD/.claude"
          ;;
        /*)
          # Absolute path
          TARGET_PARENT="$(dirname "$2")"
          if [ ! -d "$TARGET_PARENT" ]; then
            echo -e "${RED}Error: Parent directory '$TARGET_PARENT' does not exist for target '$2'${NC}"
            exit 1
          fi
          if [ ! -w "$TARGET_PARENT" ]; then
            echo -e "${RED}Error: Parent directory '$TARGET_PARENT' is not writable. Cannot install to '$2'${NC}"
            exit 1
          fi
          INSTALL_DIR="$2"
          ;;
        *)
          echo -e "${RED}Error: --target requires 'home', 'project', or an absolute path (starting with /)${NC}"
          exit 1
          ;;
      esac
      shift 2
      ;;
    --help|-h)
      cat << EOF
Install CLAUDE.md development framework

Usage:
  $0 [OPTIONS]

Options:
  --target TARGET      Installation target (default: home)
                       home    - Install to ~/.claude/ (global)
                       project - Install to ./.claude/ (current directory)
                       /path   - Install to custom absolute path
  --claude-only        Install only CLAUDE.md
  --no-agents          Install without agents
  --skills-only        Install only skills
  --agents-only        Install only agents
  --lang LANGUAGES     Install only specific language(s) + core skills
                       Languages: typescript, go, rust, csharp, unity
                       Use comma to separate multiple: --lang go,rust
                       Note: unity automatically includes csharp
  --with-opencode      Also install OpenCode configuration
  --opencode-only      Install only OpenCode configuration
  --version VERSION    Install specific version (default: main)
  --help, -h           Show this help message

Environment Variables:
  CLAUDE_INSTALL_DIR   Override default installation directory (overridden by --target if both are set)

Supported Languages:
  typescript (ts)      TypeScript/JavaScript + React
  go                   Go/Golang
  rust                 Rust
  csharp (cs)          C#/.NET
  unity                Unity game engine (includes C# support)

Examples:
  # Install everything (all languages) to ~/.claude/
  $0

  # Install to current project directory
  $0 --target project

  # Install to custom path
  $0 --target /opt/claude

  # Install only Go support
  $0 --lang go

  # Install Go and Rust support
  $0 --lang go,rust

  # Install Unity support (automatically includes C#)
  $0 --lang unity

  # Install specific version
  $0 --version v3.3.0

  # One-liner installation (all languages)
  curl -fsSL https://raw.githubusercontent.com/intinig/claude.md/main/install-claude.sh | bash

  # One-liner for project-local install
  curl -fsSL https://raw.githubusercontent.com/intinig/claude.md/main/install-claude.sh | bash -s -- --target project

  # One-liner for specific language
  curl -fsSL https://raw.githubusercontent.com/intinig/claude.md/main/install-claude.sh | bash -s -- --lang csharp

EOF
      exit 0
      ;;
    *)
      echo -e "${RED}Error: Unknown option $1${NC}"
      echo "Run '$0 --help' for usage information"
      exit 1
      ;;
  esac
done

# Normalize language names and handle aliases
normalize_languages() {
  local input="$1"
  local normalized=""

  # Convert to lowercase and split by comma
  IFS=',' read -ra LANG_ARRAY <<< "${input,,}"

  for lang in "${LANG_ARRAY[@]}"; do
    # Trim whitespace
    lang=$(echo "$lang" | xargs)

    case "$lang" in
      ts|typescript)
        normalized="${normalized}typescript,"
        ;;
      go|golang)
        normalized="${normalized}go,"
        ;;
      rust|rs)
        normalized="${normalized}rust,"
        ;;
      cs|csharp|c#|dotnet|.net)
        normalized="${normalized}csharp,"
        ;;
      unity|unity3d)
        # Unity includes C# automatically
        normalized="${normalized}unity,csharp,"
        ;;
      all|"")
        normalized="all,"
        ;;
      *)
        echo -e "${RED}Error: Unknown language '$lang'${NC}"
        echo "Supported languages: typescript, go, rust, csharp, unity"
        exit 1
        ;;
    esac
  done

  # Remove trailing comma and duplicates
  echo "$normalized" | tr ',' '\n' | sort -u | tr '\n' ',' | sed 's/,$//'
}

# Check if a language should be installed
should_install_lang() {
  local lang="$1"

  # If no specific language selected, install all
  if [[ -z "$LANGUAGES" || "$LANGUAGES" == "all" ]]; then
    return 0
  fi

  # Check if language is in the list
  if [[ ",$LANGUAGES," == *",$lang,"* ]]; then
    return 0
  fi

  return 1
}

# Normalize languages if specified
if [[ -n "$LANGUAGES" ]]; then
  LANGUAGES=$(normalize_languages "$LANGUAGES")
fi

# Build language display string
get_lang_display() {
  if [[ -z "$LANGUAGES" || "$LANGUAGES" == "all" ]]; then
    echo "all languages"
  else
    echo "$LANGUAGES" | tr ',' ' + ' | sed 's/ + $//'
  fi
}

# Prepare display value for INSTALL_DIR, truncating if too long to keep banner aligned
TARGET_DISPLAY="$INSTALL_DIR"
if ((${#TARGET_DISPLAY} > 50)); then
  TARGET_DISPLAY="${TARGET_DISPLAY:0:47}..."
fi

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  CLAUDE.md Development Framework Installer                 ║${NC}"
printf "${BLUE}║  Version: %-49s║${NC}\n" "$VERSION"
printf "${BLUE}║  Target: %-50s║${NC}\n" "$TARGET_DISPLAY"
printf "${BLUE}║  Languages: %-47s║${NC}\n" "$(get_lang_display)"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to download a file
download_file() {
  local url="$1"
  local dest="$2"
  local description="$3"

  echo -e "${YELLOW}→${NC} Downloading $description..."

  if curl -fsSL "$url" -o "$dest"; then
    echo -e "${GREEN}✓${NC} $description installed"
    return 0
  else
    echo -e "${RED}✗${NC} Failed to download $description"
    return 1
  fi
}

# Function to backup existing file
backup_file() {
  local file="$1"

  if [[ -f "$file" ]]; then
    local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
    echo -e "${YELLOW}→${NC} Backing up existing file to $backup"
    mv "$file" "$backup"
  fi
}

# Create directories
echo -e "${BLUE}Creating directories...${NC}"
mkdir -p "$INSTALL_DIR/agents" "$INSTALL_DIR/skills" "$INSTALL_DIR/commands"

# Core skills directories (always needed)
mkdir -p "$INSTALL_DIR/skills/tdd"
mkdir -p "$INSTALL_DIR/skills/testing"
mkdir -p "$INSTALL_DIR/skills/functional"
mkdir -p "$INSTALL_DIR/skills/refactoring"
mkdir -p "$INSTALL_DIR/skills/expectations"
mkdir -p "$INSTALL_DIR/skills/planning"
mkdir -p "$INSTALL_DIR/skills/mutation-testing"

# TypeScript directories
if should_install_lang "typescript"; then
  mkdir -p "$INSTALL_DIR/skills/typescript-strict"
  mkdir -p "$INSTALL_DIR/skills/front-end-testing"
  mkdir -p "$INSTALL_DIR/skills/react-testing"
fi

# Go directories
if should_install_lang "go"; then
  mkdir -p "$INSTALL_DIR/skills/go-strict"
  mkdir -p "$INSTALL_DIR/skills/go-testing"
  mkdir -p "$INSTALL_DIR/skills/go-error-handling"
  mkdir -p "$INSTALL_DIR/skills/go-concurrency"
fi

# Rust directories
if should_install_lang "rust"; then
  mkdir -p "$INSTALL_DIR/skills/rust-strict"
  mkdir -p "$INSTALL_DIR/skills/rust-testing"
  mkdir -p "$INSTALL_DIR/skills/rust-error-handling"
  mkdir -p "$INSTALL_DIR/skills/rust-concurrency"
fi

# C# directories
if should_install_lang "csharp"; then
  mkdir -p "$INSTALL_DIR/skills/csharp-strict"
  mkdir -p "$INSTALL_DIR/skills/csharp-testing"
  mkdir -p "$INSTALL_DIR/skills/csharp-error-handling"
  mkdir -p "$INSTALL_DIR/skills/csharp-concurrency"
fi

# Unity directories
if should_install_lang "unity"; then
  mkdir -p "$INSTALL_DIR/skills/unity-strict"
  mkdir -p "$INSTALL_DIR/skills/unity-testing"
  mkdir -p "$INSTALL_DIR/skills/unity-patterns"
  mkdir -p "$INSTALL_DIR/skills/unity-performance"
fi

echo -e "${GREEN}✓${NC} Directories created"
echo ""

# Install CLAUDE.md
if [[ "$INSTALL_CLAUDE" == true ]]; then
  echo -e "${BLUE}Installing CLAUDE.md...${NC}"
  backup_file "$INSTALL_DIR"/CLAUDE.md
  download_file \
    "$BASE_URL/$VERSION/claude/.claude/CLAUDE.md" \
    "$INSTALL_DIR"/CLAUDE.md \
    "CLAUDE.md"
  echo ""
fi

# Install skills
if [[ "$INSTALL_SKILLS" == true ]]; then
  echo -e "${BLUE}Installing skills...${NC}"

  # Core skills (always installed)
  core_skills=(
    "tdd/SKILL.md"
    "testing/SKILL.md"
    "functional/SKILL.md"
    "refactoring/SKILL.md"
    "expectations/SKILL.md"
    "planning/SKILL.md"
    "mutation-testing/SKILL.md"
  )

  echo -e "${PURPLE}  Core skills (language-agnostic)${NC}"
  for skill in "${core_skills[@]}"; do
    backup_file "$INSTALL_DIR"/skills/"$skill"
    download_file \
      "$BASE_URL/$VERSION/claude/.claude/skills/$skill" \
      "$INSTALL_DIR"/skills/"$skill" \
      "skills/$skill"
  done

  # TypeScript skills
  if should_install_lang "typescript"; then
    echo ""
    echo -e "${YELLOW}  TypeScript skills${NC}"
    ts_skills=(
      "typescript-strict/SKILL.md"
      "front-end-testing/SKILL.md"
      "react-testing/SKILL.md"
    )
    for skill in "${ts_skills[@]}"; do
      backup_file "$INSTALL_DIR"/skills/"$skill"
      download_file \
        "$BASE_URL/$VERSION/claude/.claude/skills/$skill" \
        "$INSTALL_DIR"/skills/"$skill" \
        "skills/$skill"
    done
  fi

  # Go skills
  if should_install_lang "go"; then
    echo ""
    echo -e "${CYAN}  Go skills${NC}"
    go_skills=(
      "go-strict/SKILL.md"
      "go-testing/SKILL.md"
      "go-error-handling/SKILL.md"
      "go-concurrency/SKILL.md"
    )
    for skill in "${go_skills[@]}"; do
      backup_file "$INSTALL_DIR"/skills/"$skill"
      download_file \
        "$BASE_URL/$VERSION/claude/.claude/skills/$skill" \
        "$INSTALL_DIR"/skills/"$skill" \
        "skills/$skill"
    done
  fi

  # Rust skills
  if should_install_lang "rust"; then
    echo ""
    echo -e "${RED}  Rust skills${NC}"
    rust_skills=(
      "rust-strict/SKILL.md"
      "rust-testing/SKILL.md"
      "rust-error-handling/SKILL.md"
      "rust-concurrency/SKILL.md"
    )
    for skill in "${rust_skills[@]}"; do
      backup_file "$INSTALL_DIR"/skills/"$skill"
      download_file \
        "$BASE_URL/$VERSION/claude/.claude/skills/$skill" \
        "$INSTALL_DIR"/skills/"$skill" \
        "skills/$skill"
    done
  fi

  # C# skills
  if should_install_lang "csharp"; then
    echo ""
    echo -e "${PURPLE}  C# skills${NC}"
    csharp_skills=(
      "csharp-strict/SKILL.md"
      "csharp-testing/SKILL.md"
      "csharp-error-handling/SKILL.md"
      "csharp-concurrency/SKILL.md"
    )
    for skill in "${csharp_skills[@]}"; do
      backup_file "$INSTALL_DIR"/skills/"$skill"
      download_file \
        "$BASE_URL/$VERSION/claude/.claude/skills/$skill" \
        "$INSTALL_DIR"/skills/"$skill" \
        "skills/$skill"
    done
  fi

  # Unity skills
  if should_install_lang "unity"; then
    echo ""
    echo -e "${CYAN}  Unity skills${NC}"
    unity_skills=(
      "unity-strict/SKILL.md"
      "unity-testing/SKILL.md"
      "unity-patterns/SKILL.md"
      "unity-performance/SKILL.md"
    )
    for skill in "${unity_skills[@]}"; do
      backup_file "$INSTALL_DIR"/skills/"$skill"
      download_file \
        "$BASE_URL/$VERSION/claude/.claude/skills/$skill" \
        "$INSTALL_DIR"/skills/"$skill" \
        "skills/$skill"
    done
  fi

  echo ""
fi

# Install commands
if [[ "$INSTALL_COMMANDS" == true ]]; then
  echo -e "${BLUE}Installing commands (slash commands)...${NC}"

  commands=(
    "pr.md"
  )

  for cmd in "${commands[@]}"; do
    backup_file "$INSTALL_DIR"/commands/"$cmd"
    download_file \
      "$BASE_URL/$VERSION/claude/.claude/commands/$cmd" \
      "$INSTALL_DIR"/commands/"$cmd" \
      "commands/$cmd"
  done
  echo ""
fi

# Install agents
if [[ "$INSTALL_AGENTS" == true ]]; then
  echo -e "${BLUE}Installing Claude Code agents...${NC}"

  # Core agents (always installed)
  core_agents=(
    "tdd-guardian.md"
    "refactor-scan.md"
    "docs-guardian.md"
    "adr.md"
    "learn.md"
    "use-case-data-patterns.md"
    "progress-guardian.md"
    "pr-reviewer.md"
    "README.md"
  )

  echo -e "${PURPLE}  Core agents${NC}"
  for agent in "${core_agents[@]}"; do
    backup_file "$INSTALL_DIR"/agents/"$agent"
    download_file \
      "$BASE_URL/$VERSION/claude/.claude/agents/$agent" \
      "$INSTALL_DIR"/agents/"$agent" \
      "agents/$agent"
  done

  # TypeScript enforcer
  if should_install_lang "typescript"; then
    echo ""
    echo -e "${YELLOW}  TypeScript enforcer${NC}"
    backup_file "$INSTALL_DIR"/agents/ts-enforcer.md
    download_file \
      "$BASE_URL/$VERSION/claude/.claude/agents/ts-enforcer.md" \
      "$INSTALL_DIR"/agents/ts-enforcer.md \
      "agents/ts-enforcer.md"
  fi

  # Go enforcer
  if should_install_lang "go"; then
    echo ""
    echo -e "${CYAN}  Go enforcer${NC}"
    backup_file "$INSTALL_DIR"/agents/go-enforcer.md
    download_file \
      "$BASE_URL/$VERSION/claude/.claude/agents/go-enforcer.md" \
      "$INSTALL_DIR"/agents/go-enforcer.md \
      "agents/go-enforcer.md"
  fi

  # Rust enforcer
  if should_install_lang "rust"; then
    echo ""
    echo -e "${RED}  Rust enforcer${NC}"
    backup_file "$INSTALL_DIR"/agents/rust-enforcer.md
    download_file \
      "$BASE_URL/$VERSION/claude/.claude/agents/rust-enforcer.md" \
      "$INSTALL_DIR"/agents/rust-enforcer.md \
      "agents/rust-enforcer.md"
  fi

  # C# enforcer
  if should_install_lang "csharp"; then
    echo ""
    echo -e "${PURPLE}  C# enforcer${NC}"
    backup_file "$INSTALL_DIR"/agents/csharp-enforcer.md
    download_file \
      "$BASE_URL/$VERSION/claude/.claude/agents/csharp-enforcer.md" \
      "$INSTALL_DIR"/agents/csharp-enforcer.md \
      "agents/csharp-enforcer.md"
  fi

  # Unity enforcer
  if should_install_lang "unity"; then
    echo ""
    echo -e "${CYAN}  Unity enforcer${NC}"
    backup_file "$INSTALL_DIR"/agents/unity-enforcer.md
    download_file \
      "$BASE_URL/$VERSION/claude/.claude/agents/unity-enforcer.md" \
      "$INSTALL_DIR"/agents/unity-enforcer.md \
      "agents/unity-enforcer.md"
  fi

  echo ""
fi

# Install OpenCode configuration
if [[ "$INSTALL_OPENCODE" == true ]]; then
  echo -e "${BLUE}Installing OpenCode configuration...${NC}"
  mkdir -p ~/.config/opencode
  backup_file ~/.config/opencode/opencode.json
  download_file \
    "$BASE_URL/$VERSION/opencode/.config/opencode/opencode.json" \
    ~/.config/opencode/opencode.json \
    "opencode.json"
  echo ""
fi

# Success message
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Installation complete! ✓                                  ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Show what was installed
echo -e "${BLUE}Installed to ${INSTALL_DIR}/${NC}"
echo ""

if [[ "$INSTALL_CLAUDE" == true ]]; then
  echo -e "  ${GREEN}✓${NC} CLAUDE.md (lean core principles, v3.3.0)"
fi

if [[ "$INSTALL_SKILLS" == true ]]; then
  echo -e "  ${GREEN}✓${NC} Core skills: tdd, testing, functional, refactoring, expectations, planning, mutation-testing"

  if should_install_lang "typescript"; then
    echo -e "  ${GREEN}✓${NC} ${YELLOW}TypeScript${NC}: typescript-strict, front-end-testing, react-testing"
  fi

  if should_install_lang "go"; then
    echo -e "  ${GREEN}✓${NC} ${CYAN}Go${NC}: go-strict, go-testing, go-error-handling, go-concurrency"
  fi

  if should_install_lang "rust"; then
    echo -e "  ${GREEN}✓${NC} ${RED}Rust${NC}: rust-strict, rust-testing, rust-error-handling, rust-concurrency"
  fi

  if should_install_lang "csharp"; then
    echo -e "  ${GREEN}✓${NC} ${PURPLE}C#${NC}: csharp-strict, csharp-testing, csharp-error-handling, csharp-concurrency"
  fi

  if should_install_lang "unity"; then
    echo -e "  ${GREEN}✓${NC} ${CYAN}Unity${NC}: unity-strict, unity-testing, unity-patterns, unity-performance"
  fi
fi

if [[ "$INSTALL_COMMANDS" == true ]]; then
  echo -e "  ${GREEN}✓${NC} commands/ (slash command: /pr)"
fi

if [[ "$INSTALL_AGENTS" == true ]]; then
  echo -e "  ${GREEN}✓${NC} Core agents: tdd-guardian, refactor-scan, docs-guardian, adr, learn, pr-reviewer, etc."

  if should_install_lang "typescript"; then
    echo -e "  ${GREEN}✓${NC} ${YELLOW}ts-enforcer${NC} (TypeScript best practices)"
  fi

  if should_install_lang "go"; then
    echo -e "  ${GREEN}✓${NC} ${CYAN}go-enforcer${NC} (Go best practices)"
  fi

  if should_install_lang "rust"; then
    echo -e "  ${GREEN}✓${NC} ${RED}rust-enforcer${NC} (Rust best practices)"
  fi

  if should_install_lang "csharp"; then
    echo -e "  ${GREEN}✓${NC} ${PURPLE}csharp-enforcer${NC} (C# best practices)"
  fi

  if should_install_lang "unity"; then
    echo -e "  ${GREEN}✓${NC} ${CYAN}unity-enforcer${NC} (Unity best practices)"
  fi
fi

if [[ "$INSTALL_OPENCODE" == true ]]; then
  echo ""
  echo -e "${BLUE}Installed to ~/.config/opencode/${NC}"
  echo -e "  ${GREEN}✓${NC} opencode.json (OpenCode rules configuration)"
fi

echo ""
echo -e "${BLUE}Architecture (v3.3.0):${NC}"
echo ""
echo -e "  ${YELLOW}CLAUDE.md${NC}  → Core principles (~200 lines, always loaded)"
echo -e "  ${YELLOW}skills/${NC}    → Detailed patterns (loaded on-demand when relevant)"
echo -e "  ${YELLOW}commands/${NC}  → Slash commands (manually invoked)"
echo -e "  ${YELLOW}agents/${NC}    → Complex multi-step workflows"
echo ""

echo -e "${BLUE}Supported Languages:${NC}"
echo ""
echo -e "  ${YELLOW}TypeScript${NC}  → typescript-strict, react-testing, front-end-testing"
echo -e "  ${CYAN}Go${NC}          → go-strict, go-testing, go-error-handling, go-concurrency"
echo -e "  ${RED}Rust${NC}        → rust-strict, rust-testing, rust-error-handling, rust-concurrency"
echo -e "  ${PURPLE}C#${NC}          → csharp-strict, csharp-testing, csharp-error-handling, csharp-concurrency"
echo -e "  ${CYAN}Unity${NC}       → unity-strict, unity-testing, unity-patterns, unity-performance (+ C#)"
echo ""

echo -e "${BLUE}Next steps:${NC}"
echo ""
echo -e "  1. Verify installation:"
echo -e "     ${YELLOW}ls -la ${INSTALL_DIR}/${NC}"
echo ""
echo -e "  2. Test with Claude Code:"
echo -e "     Open any project and use: ${YELLOW}/memory${NC}"
echo ""

if [[ "$INSTALL_AGENTS" == true ]]; then
  echo -e "  3. Learn about agents:"
  echo -e "     ${YELLOW}cat ${INSTALL_DIR}/agents/README.md${NC}"
  echo ""
fi

echo -e "${BLUE}Install specific language support:${NC}"
echo ""
echo -e "  ${YELLOW}$0 --lang go${NC}         # Go only"
echo -e "  ${YELLOW}$0 --lang unity${NC}      # Unity + C#"
echo -e "  ${YELLOW}$0 --lang go,rust${NC}    # Multiple languages"
echo ""

echo -e "${BLUE}For help or issues:${NC}"
echo -e "  ${YELLOW}https://github.com/intinig/claude.md${NC}"
echo ""
