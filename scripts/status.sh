#!/usr/bin/env bash
# =============================================================================
#  status.sh — Health-check for the dotfiles repository (~/.dotfiles)
#
#  Checks:
#    1. Integrity of GNU Stow symlinks (configs/)
#    2. Alignment of system files (system-files.conf vs the real system)
#    3. Presence of critical binaries in PATH
#    4. Stale absolute paths inside configs/ left over from a repo migration
#
#  Usage:
#    ./status.sh                 Run all checks
#    ./status.sh BIN [BIN ...]   Run all checks, override the binaries list
#                                 for check 3, e.g: ./status.sh go stow hyprctl
# =============================================================================

set -uo pipefail
# Note: unlike install.sh/sync.sh, this script does NOT use -e.
# status.sh is diagnostic: a failed check should be reported and the
# script should keep running the remaining checks, not abort early.

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── Paths ─────────────────────────────────────────────────────────────────────
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
CONFIGS_DIR="$DOTFILES_DIR/configs"
SCRIPTS_DIR="$DOTFILES_DIR/scripts"
SYSTEM_FILES_CONF="${SYSTEM_MAP:-$SCRIPTS_DIR/system-files.conf}"
LOG_DIR="$DOTFILES_DIR/logs"
LOG_FILE="$LOG_DIR/status_$(date +%Y%m%d_%H%M%S).log"

# Directories under $HOME known to contain unrelated symlinks (app lock
# files, backup folders, etc.) that should not be reported as broken
# Stow symlinks. Adjust if new noisy locations show up.
IGNORED_SYMLINK_DIRS=(
  "$HOME/.config/discord"
  "$HOME/.config/obsidian"
  "$HOME/.cache/spotify"
  "$HOME/.mozilla"
)

# Critical binaries to check in PATH. Overridable by passing binary names
# as script arguments, e.g: ./status.sh go stow hyprctl rofi
DEFAULT_CRITICAL_BINS=(go stow hyprctl hyprpaper hyprlock waybar rofi kitty dunst)

# ── Flags ─────────────────────────────────────────────────────────────────────
for arg in "$@"; do
  case $arg in
    --help|-h)
      echo "Usage: ./status.sh [BIN ...]"
      echo "  BIN ...   Override the binaries checked in step 3 (defaults: ${DEFAULT_CRITICAL_BINS[*]})"
      exit 0 ;;
  esac
done

# ── Logging ───────────────────────────────────────────────────────────────────
init_log() {
  mkdir -p "$LOG_DIR"
  echo "=== status.sh — $(date '+%Y-%m-%d %H:%M:%S') ===" > "$LOG_FILE"
  echo "" >> "$LOG_FILE"
}

# ── Helpers ───────────────────────────────────────────────────────────────────
ok()    { local msg="[ OK ]  $*"; echo -e "${GREEN}${msg}${NC}";   echo "$msg" >> "$LOG_FILE"; }
warn()  { local msg="[WARN]  $*"; echo -e "${YELLOW}${msg}${NC}";  echo "$msg" >> "$LOG_FILE"; ISSUES_FOUND=1; }
error() { local msg="[ERR ]  $*"; echo -e "${RED}${msg}${NC}" >&2; echo "$msg" >> "$LOG_FILE"; ISSUES_FOUND=1; }
log()   { local msg="[INFO]  $*"; echo -e "${BLUE}${msg}${NC}";    echo "$msg" >> "$LOG_FILE"; }
step()  { local msg="▶ $*";       echo -e "\n${BOLD}${CYAN}${msg}${NC}"; echo -e "\n${msg}" >> "$LOG_FILE"; }

ISSUES_FOUND=0

# Returns 0 (true) if $1 is inside one of IGNORED_SYMLINK_DIRS.
_is_ignored_path() {
  local path="$1"
  local ignored
  for ignored in "${IGNORED_SYMLINK_DIRS[@]}"; do
    if [[ "$path" == "$ignored"* ]]; then
      return 0
    fi
  done
  return 1
}

# ── 1. Stow symlink integrity ────────────────────────────────────────────────
check_stow_symlinks() {
  step "Checking Stow symlink integrity (configs/)"

  if [[ ! -d "$CONFIGS_DIR" ]]; then
    error "configs/ directory not found at $CONFIGS_DIR"
    return
  fi

  local broken_count=0
  local checked_count=0
  local legacy_count=0

  # Find all symlinks under $HOME (up to a reasonable depth), skip known
  # noisy locations (app lock files, etc.), and only act on links whose
  # target resolves inside CONFIGS_DIR (i.e. actual Stow-managed links)
  # or whose unresolved target string still mentions the repo (i.e.
  # broken links that used to point into the repo, e.g. leftovers in
  # .bak directories after a repo path migration).
  while IFS= read -r -d '' link; do
    _is_ignored_path "$link" && continue

    local raw_target target
    raw_target="$(command readlink "$link" 2>/dev/null)"
    target="$(command readlink -f "$link" 2>/dev/null)"

    local points_at_configs=0
    if [[ "$target" == "$CONFIGS_DIR"* ]] || [[ "$raw_target" == *".dotfiles"* ]] || [[ "$raw_target" == *"dotfiles/configs"* ]]; then
      points_at_configs=1
    fi

    [[ "$points_at_configs" -eq 0 ]] && continue

    checked_count=$((checked_count + 1))

    if [[ -z "$target" ]] || [[ ! -e "$target" ]]; then
      if [[ "$link" == *".bak"* ]]; then
        warn "Legacy/backup broken symlink (likely safe to remove): $link -> $raw_target"
        legacy_count=$((legacy_count + 1))
      else
        error "Broken symlink: $link -> $raw_target"
        broken_count=$((broken_count + 1))
      fi
    fi
  done < <(command find "$HOME" -maxdepth 6 -type l -print0 2>/dev/null)

  # Additional check: each package under configs/ should have at least
  # one active symlink in $HOME (detects packages that were never
  # stowed, or got unstowed by mistake).
  local missing_count=0
  for pkg_dir in "$CONFIGS_DIR"/*/; do
    [[ -d "$pkg_dir" ]] || continue
    local pkg
    pkg="$(basename "$pkg_dir")"

    local pkg_has_link=0
    while IFS= read -r -d '' link; do
      _is_ignored_path "$link" && continue
      local target
      target="$(command readlink -f "$link" 2>/dev/null)"
      if [[ "$target" == "$pkg_dir"* ]]; then
        pkg_has_link=1
        break
      fi
    done < <(command find "$HOME" -maxdepth 6 -type l -print0 2>/dev/null)

    if [[ "$pkg_has_link" -eq 0 ]]; then
      warn "Package '$pkg' does not appear to be stowed (no active symlink found)"
      missing_count=$((missing_count + 1))
    fi
  done

  if [[ "$broken_count" -eq 0 && "$missing_count" -eq 0 && "$legacy_count" -eq 0 ]]; then
    ok "No broken symlinks, all packages are stowed ($checked_count Stow symlinks checked)"
  else
    log "$broken_count broken symlinks, $legacy_count legacy/backup leftovers, $missing_count unstowed packages"
  fi
}

# ── 2. System file alignment ─────────────────────────────────────────────────
check_system_alignment() {
  step "Checking system file alignment ($SYSTEM_FILES_CONF)"

  if [[ ! -f "$SYSTEM_FILES_CONF" ]]; then
    warn "system-files.conf not found at $SYSTEM_FILES_CONF (skipping check)"
    return
  fi

  # Mapping file format (one entry per line, same format install.sh and
  # sync.sh read from):
  #   path_relative_to_repo_root:absolute_destination_path
  # e.g. system/pacman/pacman.conf:/etc/pacman.conf
  local diff_count=0
  local missing_count=0
  local checked_count=0

  local entries
  mapfile -t entries < <(command grep -v '^\s*#' "$SYSTEM_FILES_CONF" | command grep -v '^\s*$')

  for entry in "${entries[@]}"; do
    local repo_path="${entry%%:*}"
    local real_path="${entry##*:}"
    local repo_file="$DOTFILES_DIR/$repo_path"
    checked_count=$((checked_count + 1))

    if [[ ! -e "$repo_file" ]]; then
      error "Mapping entry points at a repo file that does not exist: $repo_file"
      missing_count=$((missing_count + 1))
      continue
    fi

    if [[ ! -e "$real_path" ]]; then
      error "Missing system file: $real_path (expected from $repo_path)"
      missing_count=$((missing_count + 1))
      continue
    fi

    if ! command diff -q "$repo_file" "$real_path" >/dev/null 2>&1; then
      warn "Out of sync: $real_path differs from $repo_path"
      diff_count=$((diff_count + 1))
    fi
  done

  if [[ "$checked_count" -eq 0 ]]; then
    warn "No entries found in $SYSTEM_FILES_CONF"
  elif [[ "$diff_count" -eq 0 && "$missing_count" -eq 0 ]]; then
    ok "All system files are in sync ($checked_count entries checked)"
  else
    log "$diff_count out-of-sync files, $missing_count missing/broken entries out of $checked_count checked"
  fi
}

# ── 3. Critical binaries in PATH ─────────────────────────────────────────────
check_critical_binaries() {
  step "Checking critical binaries in PATH"

  local bins=("${DEFAULT_CRITICAL_BINS[@]}")
  if [[ "$#" -gt 0 ]]; then
    bins=("$@")
  fi

  local missing_count=0
  for bin in "${bins[@]}"; do
    if command -v "$bin" >/dev/null 2>&1; then
      ok "$bin -> $(command -v "$bin")"
    else
      error "$bin not found in PATH"
      missing_count=$((missing_count + 1))
    fi
  done

  if [[ "$missing_count" -eq 0 ]]; then
    ok "All critical binaries are available"
  else
    log "$missing_count missing binaries out of ${#bins[@]} checked"
  fi
}

# ── 4. Stale absolute paths inside configs/ ──────────────────────────────────
check_stale_absolute_paths() {
  step "Checking for stale absolute paths inside configs/"

  if [[ ! -d "$CONFIGS_DIR" ]]; then
    warn "configs/ directory not found at $CONFIGS_DIR (skipping check)"
    return
  fi

  # Look for absolute paths that mention "dotfiles" as a path segment
  # but do NOT match the current repo location. This specifically
  # catches leftovers from a repo path migration (e.g. a config file
  # still hardcoding an old ~/coding/dotfiles path after the repo
  # moved to ~/.dotfiles), without flagging every unrelated absolute
  # path in configs/ (wallpapers, other apps' config dirs, user
  # folders like ~/Documents, etc. are expected and not stale).
  local hits_count=0
  local checked_count=0
  local dotfiles_basename
  dotfiles_basename="$(basename "$DOTFILES_DIR")"

  while IFS= read -r -d '' file; do
    # Skip binary files, they would produce noisy/garbled matches.
    case "$(command file -b --mime-encoding "$file" 2>/dev/null)" in
      binary) continue ;;
    esac
    checked_count=$((checked_count + 1))

    # Match any absolute path segment containing "dotfiles", then
    # keep only the ones that don't match the current repo path.
    while IFS= read -r match; do
      [[ -z "$match" ]] && continue
      if [[ "$match" != "$DOTFILES_DIR"* ]] && [[ "$match" != *"/$dotfiles_basename"* ]]; then
        local line_no
        line_no="$(command grep -n -F -- "$match" "$file" 2>/dev/null | command grep -o '^[0-9]*' | head -n1)"
        warn "Stale absolute path in $file:${line_no:-?} -> $match"
        hits_count=$((hits_count + 1))
      fi
    done < <(command grep -oE "$HOME/[A-Za-z0-9_./-]*[Dd]otfiles[A-Za-z0-9_./-]*" "$file" 2>/dev/null | command sort -u)
  done < <(command find "$CONFIGS_DIR" -type f -print0 2>/dev/null)

  if [[ "$hits_count" -eq 0 ]]; then
    ok "No stale absolute paths found ($checked_count files scanned)"
  else
    log "$hits_count stale absolute path(s) found out of $checked_count files scanned"
  fi
}

# ── Summary ───────────────────────────────────────────────────────────────────
summary() {
  echo ""
  if [[ "$ISSUES_FOUND" -eq 0 ]]; then
    echo -e "${BOLD}${GREEN}════════════════════════════════════════${NC}"
    echo -e "${BOLD}${GREEN}  All good, no issues found!${NC}"
    echo -e "${BOLD}${GREEN}════════════════════════════════════════${NC}"
  else
    echo -e "${BOLD}${RED}════════════════════════════════════════${NC}"
    echo -e "${BOLD}${RED}  Issues were found, see above.${NC}"
    echo -e "${BOLD}${RED}════════════════════════════════════════${NC}"
  fi
  echo ""
  echo -e "  ${CYAN}Log saved to:${NC} ${YELLOW}$LOG_FILE${NC}"
  echo ""
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  clear
  echo -e "${BOLD}${CYAN}"
  echo "  ██████╗  ██████╗ ████████╗███████╗██╗██╗     ███████╗███████╗"
  echo "  ██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██║██║     ██╔════╝██╔════╝"
  echo "  ██║  ██║██║   ██║   ██║   █████╗  ██║██║     █████╗  ███████╗"
  echo "  ██║  ██║██║   ██║   ██║   ██╔══╝  ██║██║     ██╔══╝  ╚════██║"
  echo "  ██████╔╝╚██████╔╝   ██║   ██║     ██║███████╗███████╗███████║"
  echo "  ╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝"
  echo -e "${NC}"
  echo -e "  ${BOLD}Arch + Hyprland dotfiles — cdoctor${NC}"
  echo ""

  init_log

  check_stow_symlinks
  check_system_alignment
  check_critical_binaries "$@"
  check_stale_absolute_paths

  summary

  exit "$ISSUES_FOUND"
}

main "$@"