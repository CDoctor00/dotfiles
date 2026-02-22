#!/usr/bin/env bash
# =============================================================================
#  sync.sh — Update package lists from the current system
#
#  With Stow, config files are already symlinked into the repo — no need
#  to copy them. This script only regenerates the package lists.
#
#  Usage: ./sync.sh
# =============================================================================

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGES_DIR="$DOTFILES_DIR/packages"
SCRIPTS_DIR="$DOTFILES_DIR/scripts"
SYSTEM_FILES_CONF="$SCRIPTS_DIR/system-files.conf"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[ OK ]${NC}  $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log()  { echo -e "${CYAN}[INFO]${NC}  $*"; }
step() { echo -e "\n${BOLD}${CYAN}▶ $*${NC}"; }

# ── Flags ─────────────────────────────────────────────────────────────────────
PACKAGES_ONLY=false
SYSTEM_ONLY=false

for arg in "$@"; do
  case $arg in
    --packages-only) PACKAGES_ONLY=true ;;
    --system-only)   SYSTEM_ONLY=true ;;
    --help|-h)
      echo "Usage: ./sync.sh [--packages-only] [--system-only]"
      exit 0 ;;
    *)
      echo -e "${YELLOW}Unknown argument: $arg${NC}"; exit 1 ;;
  esac
done

# ── Load system files map ─────────────────────────────────────────────────────
load_system_files() {
  if [[ ! -f "$SYSTEM_FILES_CONF" ]]; then
    warn "system-files.conf not found: $SYSTEM_FILES_CONF"
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
    ok "packages/packages.txt updated ($(wc -l < "$PACKAGES_DIR/packages.txt") packages)"
  else
    warn "Failed to generate packages.txt"
  fi

  log "Generating packages/aur-packages.txt..."
  if pacman -Qqem > "$PACKAGES_DIR/aur-packages.txt"; then
    ok "packages/aur-packages.txt updated ($(wc -l < "$PACKAGES_DIR/aur-packages.txt") packages)"
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
    # Fix ownership so git can track it
    sudo chown "$USER:$USER" "$full_dest"
    ok "$system_path → $repo_path"
  done
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  echo -e "\n${BOLD}${CYAN}▶ Dotfiles sync${NC}\n"

  if $PACKAGES_ONLY; then
    sync_packages
  elif $SYSTEM_ONLY; then
    sync_system_files
  else
    sync_packages
    sync_system_files
  fi

  echo ""
  echo -e "${BOLD}${GREEN}Done!${NC}"
  echo -e "Run: ${BOLD}git add -A && git commit -m 'chore: sync'${NC}"
  echo ""
}

main