#!/usr/bin/env bash
# =============================================================================
#  sync.sh — Sync system state back into the repo
#
#  With Stow, config files are already symlinked — no need to copy them.
#  This script regenerates package lists, copies system-level files,
#  and updates component versions in the README.
#
#  Usage:
#    ./sync.sh                  Full sync (packages + system files + versions)
#    ./sync.sh --packages-only  Only regenerate package lists
#    ./sync.sh --system-only    Only copy system files into repo
#    ./sync.sh --versions-only  Only update component versions in README
#
#  The *-only flags can be combined, e.g:
#    ./sync.sh --packages-only --versions-only
#  With no flags, every step runs.
# =============================================================================

set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── Paths ─────────────────────────────────────────────────────────────────────
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGES_DIR="$DOTFILES_DIR/packages"
SCRIPTS_DIR="$DOTFILES_DIR/scripts"
SYSTEM_FILES_CONF="$SCRIPTS_DIR/system-files.conf"
LOG_DIR="$DOTFILES_DIR/logs"
LOG_FILE="$LOG_DIR/sync_$(date +%Y%m%d_%H%M%S).log"
README="$DOTFILES_DIR/README.md"

# AUR packages installed by the bootstrap process — excluded from aur-packages.txt
AUR_EXCLUDE=(yay yay-bin paru paru-bin)

# ── Flags ─────────────────────────────────────────────────────────────────────
PACKAGES_ONLY=false
SYSTEM_ONLY=false
VERSIONS_ONLY=false

for arg in "$@"; do
  case $arg in
    --packages-only) PACKAGES_ONLY=true ;;
    --system-only)   SYSTEM_ONLY=true ;;
    --versions-only) VERSIONS_ONLY=true ;;
    --help|-h)
      echo "Usage: ./sync.sh [--packages-only] [--system-only] [--versions-only]"
      echo ""
      echo "The *-only flags can be combined, e.g: ./sync.sh --packages-only --versions-only"
      echo "With no flags, every step runs."
      exit 0 ;;
    *)
      echo -e "${YELLOW}Unknown argument: $arg${NC}"; exit 1 ;;
  esac
done

# ── Logging ───────────────────────────────────────────────────────────────────
init_log() {
  mkdir -p "$LOG_DIR"
  echo "=== sync.sh — $(date '+%Y-%m-%d %H:%M:%S') ===" > "$LOG_FILE"
  echo "" >> "$LOG_FILE"
}

# ── Helpers ───────────────────────────────────────────────────────────────────
ok()    { local msg="[ OK ]  $*"; echo -e "${GREEN}${msg}${NC}";   echo "$msg" >> "$LOG_FILE"; }
warn()  { local msg="[WARN]  $*"; echo -e "${YELLOW}${msg}${NC}";  echo "$msg" >> "$LOG_FILE"; }
error() { local msg="[ERR ]  $*"; echo -e "${RED}${msg}${NC}" >&2; echo "$msg" >> "$LOG_FILE"; }
log()   { local msg="[INFO]  $*"; echo -e "${BLUE}${msg}${NC}";    echo "$msg" >> "$LOG_FILE"; }
step()  { local msg="▶ $*";       echo -e "\n${BOLD}${CYAN}${msg}${NC}"; echo -e "\n${msg}" >> "$LOG_FILE"; }

# ── System files ──────────────────────────────────────────────────────────────
load_system_files() {
  if [[ ! -f "$SYSTEM_FILES_CONF" ]]; then
    error "system-files.conf not found: $SYSTEM_FILES_CONF"
    exit 1
  fi
  mapfile -t SYSTEM_FILES < <(command grep -v '^\s*#' "$SYSTEM_FILES_CONF" | command grep -v '^\s*$')
}

# ── Package lists ─────────────────────────────────────────────────────────────
# IMPORTANT: never write directly to the destination file with a bare `>`.
# A redirection truncates the target the instant the command is launched,
# *before* its success/failure is known — so a failed command still leaves
# the destination empty. Always stage output in a temp file first and `mv`
# it into place only once we've confirmed it's good.
sync_packages() {
  step "Syncing package lists"
  mkdir -p "$PACKAGES_DIR"
  local tmp

  log "Generating packages/packages.txt..."
  tmp="$(mktemp)"
  if pacman -Qqen > "$tmp"; then
    command mv -f "$tmp" "$PACKAGES_DIR/packages.txt"
    ok "packages.txt updated ($(wc -l < "$PACKAGES_DIR/packages.txt") packages)"
  else
    command rm -f "$tmp"
    warn "Failed to generate packages.txt — existing file left untouched"
  fi

  log "Generating packages/aur-packages.txt..."
  local exclude_pattern pacman_rc raw
  exclude_pattern=$(printf '^%s$\n' "${AUR_EXCLUDE[@]}" | paste -sd'|')
  raw="$(mktemp)"

  # Query pacman on its own first, so we can tell "pacman actually failed"
  # apart from "grep found zero matching lines" (grep -v exits 1 when it
  # filters out everything, which is a legitimate outcome, not an error).
  set +e
  pacman -Qqem > "$raw"
  pacman_rc=$?
  set -e

  if [[ $pacman_rc -ne 0 ]]; then
    command rm -f "$raw"
    warn "Failed to generate aur-packages.txt (pacman -Qqem failed) — existing file left untouched"
  else
    tmp="$(mktemp)"
    command grep -Ev "$exclude_pattern" "$raw" > "$tmp" || true
    command rm -f "$raw"
    command mv -f "$tmp" "$PACKAGES_DIR/aur-packages.txt"
    ok "aur-packages.txt updated ($(wc -l < "$PACKAGES_DIR/aur-packages.txt") packages)"
  fi
}

# ── System files ──────────────────────────────────────────────────────────────
sync_system_files() {
  step "Syncing system files (system → repo)"
  load_system_files

  for entry in "${SYSTEM_FILES[@]}"; do
    local repo_path="${entry%%:*}"
    local system_path="${entry##*:}"
    local full_dest="$DOTFILES_DIR/$repo_path"

    if [[ ! -e "$system_path" ]]; then
      warn "Not found on system, skipping: $system_path"
      continue
    fi

    mkdir -p "$(dirname "$full_dest")"
    sudo cp "$system_path" "$full_dest"
    sudo chown "$USER:$USER" "$full_dest"
    ok "$system_path → $repo_path"
  done
}

# ── Component versions ────────────────────────────────────────────────────────
update_versions() {
  step "Updating component versions in README"

  if [[ ! -f "$README" ]]; then
    warn "README.md not found at $README, skipping"
    return
  fi

  local hyprland hyprlock waybar kitty rofi dunst kernel

  hyprland=$(hyprctl version 2>/dev/null | command grep -oP 'Hyprland \K[0-9.]+' | head -1)
  hyprlock=$(hyprlock --version 2>&1 | command grep -oP 'v\K[0-9.]+' | head -1)
  waybar=$(waybar --version 2>&1 | command grep -oP 'v\K[0-9.]+' | head -1)
  kitty=$(kitty --version 2>/dev/null | command grep -oP '[0-9.]+' | head -1)
  rofi=$(rofi -version 2>/dev/null | command grep -oP 'Version: \K[0-9.]+' | head -1)
  dunst=$(dunst --version 2>/dev/null | command grep -oP '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
  kernel=$(uname -r | command grep -oP '^[0-9]+\.[0-9]+\.[0-9]+')

  log "Detected versions — Kernel: ${kernel:-n/a}, Hyprland: ${hyprland:-n/a}, Hyprlock: ${hyprlock:-n/a}, Waybar: ${waybar:-n/a}, Kitty: ${kitty:-n/a}, Rofi: ${rofi:-n/a}, Dunst: ${dunst:-n/a}"

  [[ -n "$kernel"   ]] && sed -i "s/^| Kernel    |.*$/| Kernel    | $(printf '%-7s' "$kernel") |/"   "$README" && ok "Kernel → $kernel"     || warn "Kernel version not detected, skipping"
  [[ -n "$hyprland" ]] && sed -i "s/^| Hyprland  |.*$/| Hyprland  | $(printf '%-7s' "$hyprland") |/" "$README" && ok "Hyprland → $hyprland" || warn "Hyprland version not detected, skipping"
  [[ -n "$hyprlock" ]] && sed -i "s/^| Hyprlock  |.*$/| Hyprlock  | $(printf '%-7s' "$hyprlock") |/" "$README" && ok "Hyprlock → $hyprlock" || warn "Hyprlock version not detected, skipping"
  [[ -n "$waybar"   ]] && sed -i "s/^| Waybar    |.*$/| Waybar    | $(printf '%-7s' "$waybar") |/"   "$README" && ok "Waybar → $waybar"     || warn "Waybar version not detected, skipping"
  [[ -n "$kitty"    ]] && sed -i "s/^| Kitty     |.*$/| Kitty     | $(printf '%-7s' "$kitty") |/"    "$README" && ok "Kitty → $kitty"       || warn "Kitty version not detected, skipping"
  [[ -n "$rofi"     ]] && sed -i "s/^| Rofi      |.*$/| Rofi      | $(printf '%-7s' "$rofi") |/"     "$README" && ok "Rofi → $rofi"         || warn "Rofi version not detected, skipping"
  [[ -n "$dunst"    ]] && sed -i "s/^| Dunst     |.*$/| Dunst     | $(printf '%-7s' "$dunst") |/"    "$README" && ok "Dunst → $dunst"       || warn "Dunst version not detected, skipping"
}

# ── Summary ───────────────────────────────────────────────────────────────────
summary() {
  echo ""
  echo -e "${BOLD}${GREEN}════════════════════════════════════════${NC}"
  echo -e "${BOLD}${GREEN}  Sync complete!${NC}"
  echo -e "${BOLD}${GREEN}════════════════════════════════════════${NC}"
  echo ""
  echo -e "  ${CYAN}Next step:${NC}"
  echo -e "  • ${BOLD}git add -A && git commit -m 'CHORE: sync'${NC}"
  echo -e "  • Log saved to: ${YELLOW}$LOG_FILE${NC}"
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

  # If any *-only flag was passed, run exactly the requested steps instead
  # of the full sync.
  if $PACKAGES_ONLY || $SYSTEM_ONLY || $VERSIONS_ONLY; then
    if $PACKAGES_ONLY; then sync_packages;      fi
    if $SYSTEM_ONLY;   then sync_system_files;  fi
    if $VERSIONS_ONLY; then update_versions;    fi
  else
    sync_packages
    sync_system_files
    update_versions
  fi

  summary
}

main