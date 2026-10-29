#!/usr/bin/env bash
# =============================================================================
#  install.sh — Dotfiles installer for Arch + Hyprland
#
#  Usage:
#    ./install.sh                     Full installation
#    ./install.sh --packages-only     Install packages only
#    ./install.sh --symlinks-only     Stow configs/ only (just the symlinks)
#    ./install.sh --root-bashrc-only  Copy configs/bash/.bashrc to /root/.bashrc only
#    ./install.sh --link-scripts-only Link scripts/*.sh into ~/.local/bin only
#    ./install.sh --fonts-only        Refresh the font cache only
#    ./install.sh --system-only       Install system files only (needs sudo)
#    ./install.sh --services-only     Enable systemd services only (needs sudo)
#    ./install.sh --unstow-only       Remove all Stow symlinks (undo, repo files untouched)
#    ./install.sh --dry-run           Preview actions without applying them
#
#  The *-only flags can be combined, e.g:
#    ./install.sh --symlinks-only --fonts-only
#  --unstow-only is the exception: it undoes --symlinks-only, so combining
#  the two in the same run is contradictory and not a supported use case.
#  With no flags, every step runs (packages, symlinks, root bashrc, system
#  files, services, script links, font cache).
# =============================================================================

set -euo pipefail

# ── Paths ─────────────────────────────────────────────────────────────────────
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIGS_DIR="$DOTFILES_DIR/configs"
SCRIPTS_DIR="$DOTFILES_DIR/scripts"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d_%H%M%S)"
PACKAGES_FILE="$DOTFILES_DIR/packages/packages.txt"
AUR_PACKAGES_FILE="$DOTFILES_DIR/packages/aur-packages.txt"
SYSTEM_FILES_CONF="$SCRIPTS_DIR/system-files.conf"
PACMAN_CONF="/etc/pacman.conf"
LOG_DIR="$DOTFILES_DIR/logs/install"
LOG_FILE="$LOG_DIR/install_$(date +%Y%m%d_%H%M%S).log"

# ── Shared libs ───────────────────────────────────────────────────────────────
# shellcheck source=scripts/lib/colors.sh
source "$SCRIPTS_DIR/lib/colors.sh"
# shellcheck source=scripts/lib/logging.sh
source "$SCRIPTS_DIR/lib/logging.sh"
# shellcheck source=scripts/lib/rotation.sh
source "$SCRIPTS_DIR/lib/rotation.sh"

# Stow packages — Automatically detect all Stow packages by reading the folders inside configs/
STOW_PACKAGES=()
for dir in "$CONFIGS_DIR"/*; do
  if [[ -d "$dir" ]]; then
    STOW_PACKAGES+=("$(basename "$dir")")
  fi
done

# Stow flags. --no-folding makes Stow always link individual files instead of
# collapsing a whole directory into a single symlink when the target directory
# doesn't exist yet. Without it, apps that write runtime data next to their
# config (e.g. clipse history/log) would write straight into the repo on a
# fresh machine. See docs/managing.md ("Tree folding").
STOW_FLAGS=(--no-folding)

# Services (see enable_services). Units are only ENABLED, never started: they
# come up at the next boot, and starting the display manager now would take
# over the TTY the installer is running in. All of them are required by the
# setup: a missing unit (package not installed) is reported as an issue.
# avahi-daemon (announces the machine on the LAN) and fstrim.timer are NOT here
# on purpose: they are optional steps documented in docs/setup-guide.md.
SYSTEM_SERVICES=(bluetooth cups)
DISPLAY_MANAGER="sddm"
USER_SERVICES=(pipewire pipewire-pulse wireplumber)

# Everything that failed but did not abort the run (AUR packages, stow
# packages, services). Reported in the final summary.
FAILURES=()

# ── Flags ─────────────────────────────────────────────────────────────────────
PACKAGES_ONLY=false
SYMLINKS_ONLY=false
ROOT_BASHRC_ONLY=false
LINK_SCRIPTS_ONLY=false
FONTS_ONLY=false
SYSTEM_ONLY=false
SERVICES_ONLY=false
UNSTOW_ONLY=false
DRY_RUN=false

for arg in "$@"; do
  case $arg in
    --packages-only)     PACKAGES_ONLY=true ;;
    --symlinks-only)     SYMLINKS_ONLY=true ;;
    --root-bashrc-only)  ROOT_BASHRC_ONLY=true ;;
    --link-scripts-only) LINK_SCRIPTS_ONLY=true ;;
    --fonts-only)        FONTS_ONLY=true ;;
    --system-only)       SYSTEM_ONLY=true ;;
    --services-only)     SERVICES_ONLY=true ;;
    --unstow-only)       UNSTOW_ONLY=true ;;
    --dry-run)           DRY_RUN=true ;;
    --help|-h)
      echo "Usage: ./install.sh [--packages-only] [--symlinks-only] [--root-bashrc-only]"
      echo "                    [--link-scripts-only] [--fonts-only] [--system-only]"
      echo "                    [--services-only] [--unstow-only] [--dry-run]"
      echo ""
      echo "The *-only flags can be combined, e.g: ./install.sh --symlinks-only --fonts-only"
      echo "With no flags, every step runs."
      exit 0 ;;
    *)
      echo -e "${RED}Unknown argument: $arg${NC}"; exit 1 ;;
  esac
done

# ── Command runner ────────────────────────────────────────────────────────────
run() {
  if $DRY_RUN; then
    echo -e "  ${YELLOW}dry-run:${NC} $*"
  else
    "$@"
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
  mapfile -t SYSTEM_FILES < <(command grep -v '^\s*#' "$SYSTEM_FILES_CONF" | command grep -v '^\s*$')
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
  run bash -c "cd /tmp/yay-install && makepkg -si --noconfirm"
  run command rm -rf /tmp/yay-install
  AUR_HELPER="yay"
  ok "yay installed."
}

# ── Packages ──────────────────────────────────────────────────────────────────

# Enable the [multilib] repo in pacman.conf if it's still commented out.
# Must run before the first `pacman -Syu`: a fresh archinstall ships without
# multilib, and a single unknown target (lib32-*, steam) makes pacman abort the
# WHOLE transaction. Idempotent. The repo's own pacman.conf is installed later
# by install_system_files and replaces this one.
ensure_multilib() {
  step "Checking multilib repository"

  if [[ ! -f "$PACMAN_CONF" ]]; then
    warn "$PACMAN_CONF not found, cannot check multilib."
    return
  fi

  if command grep -q '^\[multilib\]' "$PACMAN_CONF"; then
    ok "multilib already enabled."
    return
  fi

  if ! command grep -q '^#\[multilib\]' "$PACMAN_CONF"; then
    warn "No [multilib] section in $PACMAN_CONF — lib32-* packages and steam will fail to install."
    return
  fi

  # Uncomment the header and the Include line right below it, nothing else.
  run sudo sed -i '/^#\[multilib\]/{s/^#//;n;s/^#Include/Include/}' "$PACMAN_CONF"
  ok "multilib enabled in $PACMAN_CONF."
}

install_packages() {
  ensure_multilib

  step "Updating system"
  run sudo pacman -Syu --noconfirm

  step "Installing official packages"
  if [[ -f "$PACKAGES_FILE" ]]; then
    if run bash -c "command grep -v '^\s*#' '$PACKAGES_FILE' | command grep -v '^\s*\$' | sudo pacman -S --needed --noconfirm -"; then
      ok "Official packages installed."
    else
      # One unknown package aborts the whole pacman transaction, so nothing
      # was installed. Everything after this depends on it: stop here.
      error "pacman failed — a single missing package (e.g. lib32-* without multilib) aborts the whole transaction. See the output above."
      exit 1
    fi
  else
    warn "packages.txt not found, skipping."
  fi

  step "Installing AUR packages"
  detect_or_install_aur_helper
  if [[ ! -f "$AUR_PACKAGES_FILE" ]]; then
    warn "aur-packages.txt not found, skipping."
    return
  fi

  # A failing AUR package never stops the run: it is recorded and reported in
  # the final summary, and the remaining packages are still attempted.
  local failed_aur=()
  mapfile -t aur_pkgs < <(command grep -v '^\s*#' "$AUR_PACKAGES_FILE" | command grep -v '^\s*$')
  for pkg in "${aur_pkgs[@]}"; do
    if $DRY_RUN; then
      run "$AUR_HELPER" -S --needed --noconfirm "$pkg"
      continue
    fi

    local out
    out="$(mktemp)"
    if "$AUR_HELPER" -S --needed --noconfirm "$pkg" > "$out" 2>&1; then
      ok "AUR: $pkg"
    else
      warn "AUR: $pkg — failed (continuing). Last lines of its output:"
      command tail -n 8 "$out" | command sed 's/^/        | /' >&2
      failed_aur+=("$pkg")
      FAILURES+=("AUR: $pkg")
    fi
    { echo "--- $AUR_HELPER -S $pkg ---"; cat "$out"; echo; } >> "$LOG_FILE"
    command rm -f "$out"
  done

  if (( ${#failed_aur[@]} > 0 )); then
    warn "AUR packages: ${#failed_aur[@]} failed: ${failed_aur[*]}"
  else
    ok "AUR packages: done."
  fi
}

# ── Stow ──────────────────────────────────────────────────────────────────────
backup_if_real() {
  local target="$1"
  local rel_path="$2"  # e.g. hypr/.config/hypr/hyprland.lua

  # If the target doesn't exist, there's nothing to back up
  [[ -e "$target" ]] || return 0

  # If the target is already a direct symlink, let Stow handle it
  [[ -L "$target" ]] && return 0

  # Resolve the real absolute path of the file.
  # If the file lives inside our repository (e.g. reached through a
  # symlinked parent directory), skip it so we don't move it out of git!
  local real_target
  real_target="$(readlink -f "$target")"
  if [[ "$real_target" == "$DOTFILES_DIR"* ]]; then
    return 0
  fi

  # At this point we're sure it's a real file unrelated to the repo.
  local backup_dest="$BACKUP_DIR/$rel_path"
  warn "Backing up: $target → $backup_dest"
  run mkdir -p "$(dirname "$backup_dest")"
  run command mv "$target" "$backup_dest"
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
      # Also pass the package-relative path, used to lay out the backup
      backup_if_real "$target" "$pkg/$rel"
    done < <(command find "$pkg_dir" -not -type d -print0)

    # Check stow's exit code so a failed package doesn't pass as OK
    if run stow "${STOW_FLAGS[@]}" --dir="$CONFIGS_DIR" --target="$HOME" "$pkg"; then
      ok "Stowed: $pkg"
    else
      error "Stow FAILED for package: $pkg (see log)"
      FAILURES+=("Stow: $pkg")
    fi
  done
}

# ── Root bashrc ───────────────────────────────────────────────────────────────
install_root_bashrc() {
  step "Installing bashrc for root user"
  
  local src="$CONFIGS_DIR/bash/.bashrc"
  if [[ ! -f "$src" ]]; then
    warn "Source bashrc not found, skipping: $src"
    return
  fi

  # Back up existing /root/.bashrc if it exists
  if [[ -f /root/.bashrc ]]; then
    run sudo cp /root/.bashrc "/root/.bashrc.bak.$(date +%Y%m%d_%H%M%S)"
    warn "Backed up existing: /root/.bashrc"
  fi

  run sudo cp "$src" /root/.bashrc
  run sudo chmod 644 /root/.bashrc
  ok "Installed: $src → /root/.bashrc"
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

# ── Services ──────────────────────────────────────────────────────────────────

# enable_unit <system|user> <unit>
# Enables a unit (it starts at the next boot / login). A missing unit or a
# failed `enable` is recorded in FAILURES but never aborts the run.
enable_unit() {
  local scope="$1" unit="$2"
  [[ "$unit" == *.* ]] || unit="${unit}.service"

  local -a ctl=(systemctl)
  if [[ "$scope" == "user" ]]; then ctl+=(--user); fi

  if ! $DRY_RUN && ! "${ctl[@]}" cat "$unit" &>/dev/null; then
    warn "Unit not found: $unit ($scope) — is its package installed?"
    FAILURES+=("Service: $unit not found (package missing?)")
    return 0
  fi

  local -a cmd=("${ctl[@]}" enable "$unit")
  if [[ "$scope" == "system" ]]; then cmd=(sudo "${cmd[@]}"); fi

  if $DRY_RUN; then
    run "${cmd[@]}"
    return 0
  fi

  if "${cmd[@]}" >> "$LOG_FILE" 2>&1; then
    ok "Enabled: $unit ($scope)"
  else
    warn "Could not enable: $unit ($scope) — see $LOG_FILE"
    FAILURES+=("Service: $unit")
  fi
}

enable_services() {
  step "Enabling services"

  local svc
  for svc in "${SYSTEM_SERVICES[@]}"; do
    enable_unit system "$svc"
  done

  # User services need a login session (a TTY login is fine).
  for svc in "${USER_SERVICES[@]}"; do
    enable_unit user "$svc"
  done

  enable_unit system "$DISPLAY_MANAGER"

  ok "Services: done (they start at the next boot)."
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
  if (( ${#FAILURES[@]} == 0 )); then
    echo -e "${BOLD}${GREEN}════════════════════════════════════════${NC}"
    echo -e "${BOLD}${GREEN}  Installation complete!${NC}"
    echo -e "${BOLD}${GREEN}════════════════════════════════════════${NC}"
  else
    echo -e "${BOLD}${YELLOW}════════════════════════════════════════${NC}"
    echo -e "${BOLD}${YELLOW}  Installation complete with ${#FAILURES[@]} issue(s)${NC}"
    echo -e "${BOLD}${YELLOW}════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${YELLOW}Needs attention:${NC}"
    echo "" >> "$LOG_FILE"
    echo "=== ${#FAILURES[@]} issue(s) ===" >> "$LOG_FILE"
    local f
    for f in "${FAILURES[@]}"; do
      echo -e "  ${YELLOW}•${NC} $f"
      echo "  - $f" >> "$LOG_FILE"
    done
    echo ""
    echo -e "  Fix the cause (details in the log), then re-run ${BOLD}./scripts/install.sh${NC}:"
    echo -e "  packages already installed are skipped."
  fi
  echo ""
  echo -e "  ${CYAN}Next steps:${NC}"
  echo -e "  • Reboot (SDDM is enabled and starts at boot), or from a TTY run: ${BOLD}exec Hyprland${NC}"
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

  init_log "DRY_RUN=$DRY_RUN"
  if $DRY_RUN; then
    warn "DRY-RUN mode — no changes will be applied."
  else
    rotate_logs
  fi

  check_arch
  check_not_root

  # If any *-only flag was passed, run exactly the requested steps (in a
  # fixed, sensible order) instead of the full install.
  if $PACKAGES_ONLY || $SYMLINKS_ONLY || $ROOT_BASHRC_ONLY || $LINK_SCRIPTS_ONLY || $FONTS_ONLY || $SYSTEM_ONLY || $SERVICES_ONLY || $UNSTOW_ONLY; then
    if $PACKAGES_ONLY;     then install_packages;     fi
    if $SYMLINKS_ONLY;     then stow_packages;        fi
    if $ROOT_BASHRC_ONLY;  then install_root_bashrc;  fi
    if $SYSTEM_ONLY;       then install_system_files; fi
    if $SERVICES_ONLY;     then enable_services;      fi
    if $LINK_SCRIPTS_ONLY; then install_scripts;      fi
    if $FONTS_ONLY;        then refresh_fonts;        fi
    if $UNSTOW_ONLY;       then unstow_packages;      fi
  else
    install_packages
    stow_packages
    install_root_bashrc
    install_system_files
    enable_services
    install_scripts
    refresh_fonts
  fi

  summary
}

main