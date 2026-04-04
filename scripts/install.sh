#!/usr/bin/env bash
# =============================================================================
#  install.sh — Dotfiles installer for Arch + Hyprland
#
#  Usage:
#    ./install.sh                  Full installation
#    ./install.sh --packages-only  Install packages only (no symlinks)
#    ./install.sh --stow-only      Create symlinks only (no packages)
#    ./install.sh --system-only    Install system files only (needs sudo)
#    ./install.sh --dry-run        Preview actions without applying them
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
CONFIGS_DIR="$DOTFILES_DIR/configs"
SCRIPTS_DIR="$DOTFILES_DIR/scripts"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d_%H%M%S)"
PACKAGES_FILE="$DOTFILES_DIR/packages/packages.txt"
AUR_PACKAGES_FILE="$DOTFILES_DIR/packages/aur-packages.txt"
SYSTEM_FILES_CONF="$SCRIPTS_DIR/system-files.conf"
LOG_DIR="$DOTFILES_DIR/logs"
LOG_FILE="$LOG_DIR/install_$(date +%Y%m%d_%H%M%S).log"

# Stow packages — all directories inside configs/
STOW_PACKAGES=(bash dunst face fontconfig gtk hypr kitty rofi spicetify waybar wlogout)

# AUR packages that are allowed to fail without blocking the installation
NON_BLOCKING_AUR=(spicetify-cli)

# ── Flags ─────────────────────────────────────────────────────────────────────
PACKAGES_ONLY=false
STOW_ONLY=false
SYSTEM_ONLY=false
DRY_RUN=false

for arg in "$@"; do
  case $arg in
    --packages-only) PACKAGES_ONLY=true ;;
    --stow-only)     STOW_ONLY=true ;;
    --system-only)   SYSTEM_ONLY=true ;;
    --dry-run)       DRY_RUN=true ;;
    --help|-h)
      echo "Usage: ./install.sh [--packages-only] [--stow-only] [--system-only] [--dry-run]"
      exit 0 ;;
    *)
      echo -e "${RED}Unknown argument: $arg${NC}"; exit 1 ;;
  esac
done

# ── Logging ───────────────────────────────────────────────────────────────────
init_log() {
  mkdir -p "$LOG_DIR"
  echo "=== install.sh — $(date '+%Y-%m-%d %H:%M:%S') ===" > "$LOG_FILE"
  echo "DRY_RUN=$DRY_RUN" >> "$LOG_FILE"
  echo "" >> "$LOG_FILE"
}

# ── Helpers ───────────────────────────────────────────────────────────────────
ok()    { local msg="[ OK ]  $*"; echo -e "${GREEN}${msg}${NC}";   echo "$msg" >> "$LOG_FILE"; }
warn()  { local msg="[WARN]  $*"; echo -e "${YELLOW}${msg}${NC}";  echo "$msg" >> "$LOG_FILE"; }
error() { local msg="[ERR ]  $*"; echo -e "${RED}${msg}${NC}" >&2; echo "$msg" >> "$LOG_FILE"; }
log()   { local msg="[INFO]  $*"; echo -e "${BLUE}${msg}${NC}";    echo "$msg" >> "$LOG_FILE"; }
step()  { local msg="▶ $*";       echo -e "\n${BOLD}${CYAN}${msg}${NC}"; echo -e "\n${msg}" >> "$LOG_FILE"; }

run() {
  if $DRY_RUN; then
    echo -e "  ${YELLOW}dry-run:${NC} $*"
  else
    eval "$*"
  fi
}

# ── Preflight checks ──────────────────────────────────────────────────────────
check_arch() {
  if ! command -v pacman &>/dev/null; then
    error "pacman not found. This script requires Arch Linux."
    exit 1
  fi
}

check_not_root() {
  if [[ $EUID -eq 0 ]]; then
    error "Do not run as root. The script uses sudo where needed."
    exit 1
  fi
}

check_stow() {
  if ! command -v stow &>/dev/null; then
    warn "GNU Stow not found. Installing..."
    run sudo pacman -S --noconfirm stow
  fi
}

# ── System files ──────────────────────────────────────────────────────────────
load_system_files() {
  if [[ ! -f "$SYSTEM_FILES_CONF" ]]; then
    error "system-files.conf not found: $SYSTEM_FILES_CONF"
    exit 1
  fi
  mapfile -t SYSTEM_FILES < <(grep -v '^\s*#' "$SYSTEM_FILES_CONF" | grep -v '^\s*$')
}

# ── AUR helper ────────────────────────────────────────────────────────────────
AUR_HELPER=""

detect_or_install_aur_helper() {
  if command -v yay &>/dev/null; then
    AUR_HELPER="yay"; ok "AUR helper: yay"; return
  elif command -v paru &>/dev/null; then
    AUR_HELPER="paru"; ok "AUR helper: paru"; return
  fi

  warn "No AUR helper found. Installing yay..."
  run sudo pacman -S --needed --noconfirm git base-devel
  run git clone https://aur.archlinux.org/yay.git /tmp/yay-install
  run "(cd /tmp/yay-install && makepkg -si --noconfirm)"
  run rm -rf /tmp/yay-install
  AUR_HELPER="yay"
  ok "yay installed."
}

# ── Packages ──────────────────────────────────────────────────────────────────
install_packages() {
  step "Updating system"
  run sudo pacman -Syu --noconfirm

  step "Installing official packages"
  if [[ -f "$PACKAGES_FILE" ]]; then
    run "grep -v '^\s*#' '$PACKAGES_FILE' | grep -v '^\s*$' | sudo pacman -S --needed --noconfirm -"
    ok "Official packages installed."
  else
    warn "packages.txt not found, skipping."
  fi

  step "Installing AUR packages"
  detect_or_install_aur_helper
  if [[ ! -f "$AUR_PACKAGES_FILE" ]]; then
    warn "aur-packages.txt not found, skipping."
    return
  fi

  mapfile -t aur_pkgs < <(grep -v '^\s*#' "$AUR_PACKAGES_FILE" | grep -v '^\s*$')
  for pkg in "${aur_pkgs[@]}"; do
    # Check if this package is in the non-blocking list
    local non_blocking=false
    for nb in "${NON_BLOCKING_AUR[@]}"; do
      [[ "$pkg" == "$nb" ]] && non_blocking=true && break
    done

    if $DRY_RUN; then
      run "$AUR_HELPER -S --needed --noconfirm $pkg"
    elif $non_blocking; then
      if $AUR_HELPER -S --needed --noconfirm "$pkg" >> "$LOG_FILE" 2>&1; then
        ok "AUR: $pkg"
      else
        warn "AUR: $pkg — failed (non-blocking). See $LOG_FILE"
      fi
    else
      if $AUR_HELPER -S --needed --noconfirm "$pkg" >> "$LOG_FILE" 2>&1; then
        ok "AUR: $pkg"
      else
        error "AUR: $pkg — failed"
        exit 1
      fi
    fi
  done
  ok "AUR packages: done."
}

# ── Stow ──────────────────────────────────────────────────────────────────────
backup_if_real() {
  local target="$1"
  if [[ -e "$target" && ! -L "$target" ]]; then
    warn "Backing up: $target → $BACKUP_DIR/"
    run mkdir -p "$BACKUP_DIR"
    run mv "$target" "$BACKUP_DIR/"
  fi
}

stow_packages() {
  step "Stowing packages (creating symlinks)"
  check_stow

  for pkg in "${STOW_PACKAGES[@]}"; do
    local pkg_dir="$CONFIGS_DIR/$pkg"

    if [[ ! -d "$pkg_dir" ]]; then
      warn "Package directory not found, skipping: $pkg"
      continue
    fi

    # Back up any real files that would conflict with stow
    while IFS= read -r -d '' file; do
      local rel="${file#$pkg_dir/}"
      local target="$HOME/$rel"
      backup_if_real "$target"
    done < <(find "$pkg_dir" -not -type d -print0)

    run stow --dir="$CONFIGS_DIR" --target="$HOME" "$pkg"
    ok "Stowed: $pkg"
  done
}

unstow_packages() {
  step "Unstowing all packages"
  check_stow
  for pkg in "${STOW_PACKAGES[@]}"; do
    [[ -d "$CONFIGS_DIR/$pkg" ]] || continue
    run stow --dir="$CONFIGS_DIR" --target="$HOME" -D "$pkg"
    ok "Unstowed: $pkg"
  done
}

# ── System files (root) ───────────────────────────────────────────────────────
install_system_files() {
  step "Installing system files (requires sudo)"
  load_system_files

  for entry in "${SYSTEM_FILES[@]}"; do
    local src="${entry%%:*}"
    local dest="${entry##*:}"
    local full_src="$DOTFILES_DIR/$src"

    if [[ ! -e "$full_src" ]]; then
      warn "System source not found, skipping: $src"
      continue
    fi

    if [[ -d "$full_src" ]]; then
      run sudo mkdir -p "$dest"
      run sudo cp -r "$full_src/." "$dest/"
      ok "Copied dir: $src → $dest"
    else
      if [[ -f "$dest" ]]; then
        run sudo cp "$dest" "${dest}.bak"
        warn "Backed up existing: ${dest}.bak"
      fi
      run sudo mkdir -p "$(dirname "$dest")"
      run sudo cp "$full_src" "$dest"
      ok "Copied: $src → $dest"
    fi
  done
}

# ── Scripts ───────────────────────────────────────────────────────────────────
install_scripts() {
  step "Installing personal scripts to ~/.local/bin"
  run mkdir -p "$HOME/.local/bin"

  for script in "$DOTFILES_DIR/scripts"/*.sh; do
    [[ -f "$script" ]] || continue
    run chmod +x "$script"
    run ln -sf "$script" "$HOME/.local/bin/$(basename "$script" .sh)"
    ok "Linked: $(basename "$script" .sh)"
  done
}

# ── Font cache ────────────────────────────────────────────────────────────────
refresh_fonts() {
  step "Refreshing font cache"
  run fc-cache -fv &>/dev/null
  ok "Font cache refreshed."
}

# ── Summary ───────────────────────────────────────────────────────────────────
summary() {
  echo ""
  echo -e "${BOLD}${GREEN}════════════════════════════════════════${NC}"
  echo -e "${BOLD}${GREEN}  Installation complete!${NC}"
  echo -e "${BOLD}${GREEN}════════════════════════════════════════${NC}"
  echo ""
  echo -e "  ${CYAN}Next steps:${NC}"
  echo -e "  • Log out and start Hyprland, or run: ${BOLD}exec Hyprland${NC}"
  if [[ -d "$BACKUP_DIR" ]]; then
    echo -e "  • Old configs backed up to: ${YELLOW}$BACKUP_DIR${NC}"
  fi
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
  $DRY_RUN && warn "DRY-RUN mode — no changes will be applied."

  check_arch
  check_not_root

  if $PACKAGES_ONLY; then
    install_packages
  elif $STOW_ONLY; then
    stow_packages
    install_scripts
    refresh_fonts
  elif $SYSTEM_ONLY; then
    install_system_files
  else
    install_packages
    stow_packages
    install_system_files
    install_scripts
    refresh_fonts
  fi

  summary
}

main