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
  mapfile -t SYSTEM_FILES < <(grep -v '^\s*#' "$SYSTEM_FILES_CONF" | grep -v '^\s*$')
}

# ── Package lists ─────────────────────────────────────────────────────────────
sync_packages() {
  step "Syncing package lists"
  mkdir -p "$PACKAGES_DIR"

  log "Generating packages/packages.txt..."
  if pacman -Qqen > "$PACKAGES_DIR/packages.txt"; then
    ok "packages.txt updated ($(wc -l < "$PACKAGES_DIR/packages.txt") packages)"
  else
    warn "Failed to generate packages.txt"
  fi

  log "Generating packages/aur-packages.txt..."
  local exclude_pattern
  exclude_pattern=$(printf '^%s$\n' "${AUR_EXCLUDE[@]}" | paste -sd'|')
  if pacman -Qqem | grep -Ev "$exclude_pattern" > "$PACKAGES_DIR/aur-packages.txt"; then
    ok "aur-packages.txt updated ($(wc -l < "$PACKAGES_DIR/aur-packages.txt") packages)"
  else
    warn "Failed to generate aur-packages.txt"
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

  hyprland=$(hyprctl version 2>/dev/null | grep -oP 'Hyprland \K[0-9.]+' | head -1)
  hyprlock=$(hyprlock --version 2>&1 | grep -oP 'v\K[0-9.]+' | head -1)
  waybar=$(waybar --version 2>&1 | grep -oP 'v\K[0-9.]+' | head -1)
  kitty=$(kitty --version 2>/dev/null | grep -oP '[0-9.]+' | head -1)
  rofi=$(rofi -version 2>/dev/null | grep -oP 'Version: \K[0-9.]+' | head -1)
  dunst=$(dunst --version 2>/dev/null | grep -oP '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
  kernel=$(uname -r | grep -oP '^[0-9]+\.[0-9]+\.[0-9]+')

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
  echo -e "  • ${BOLD}git add -A && git commit -m 'chore: sync'${NC}"
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

  if $PACKAGES_ONLY; then
    sync_packages
  elif $SYSTEM_ONLY; then
    sync_system_files
  elif $VERSIONS_ONLY; then
    update_versions
  else
    sync_packages
    sync_system_files
    update_versions
  fi

  summary
}

main