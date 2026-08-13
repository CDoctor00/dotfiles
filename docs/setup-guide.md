# Setup Guide — Post Arch Installation

Step-by-step guide to go from a fresh Arch install to a working Hyprland desktop.

---

## 1. Fresh Arch install

Follow the [official Arch installation guide](https://wiki.archlinux.org/title/Installation_guide) until you have a bootable system with a non-root user.

Make sure you have:

```bash
# NetworkManager running
systemctl enable --now NetworkManager

# System up to date
sudo pacman -Syu
```

---

## 2. Clone and run

```bash
sudo pacman -S --needed git stow

git clone https://github.com/CDoctor00/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
chmod +x scripts/install.sh scripts/sync.sh scripts/status.sh

# Full install (packages + symlinks + system files)
./scripts/install.sh

# Or selectively:
./scripts/install.sh --packages-only    # only install packages
./scripts/install.sh --symlinks-only    # just the Stow symlinks
./scripts/install.sh --system-only      # only install /etc and /usr files
./scripts/install.sh --dry-run          # preview without applying
```

See [`docs/scripts.md`](scripts.md) for exactly what each flag does and what `install.sh` touches on the system.

> **Note:** If the scripts lose their executable bit (e.g. after cloning on some systems), restore it and make git track it permanently:
>
> ```bash
> chmod +x scripts/install.sh scripts/sync.sh scripts/status.sh
> git update-index --chmod=+x scripts/install.sh scripts/sync.sh scripts/status.sh
> git commit -m "CHORE: restore executable bit on scripts"
> ```

> After the installation, a log file is saved to `logs/install_<timestamp>.log`. Check it if any step reported warnings or errors.

Once the install finishes, run the health-check before rebooting — it's much easier to fix a broken symlink or a missing binary now than to debug it after logging into a fresh Hyprland session:

```bash
./scripts/status.sh
```

---

## 3. Enable services

```bash
# Display manager
sudo systemctl enable sddm

# Bluetooth
sudo systemctl enable --now bluetooth

# Audio (user service)
systemctl --user enable --now pipewire pipewire-pulse wireplumber
```

---

## 4. Optional hardening

These steps harden the system but aren't required for Hyprland to work — skip this section on a first install and come back to it later if you want.

```bash
# Firewall
sudo pacman -S ufw
sudo systemctl enable --now ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable

# SSD trim (if applicable)
sudo systemctl enable fstrim.timer
```

---

## 5. Manual steps

Some things cannot be automated:

- **Browser** — log in and sync your profile
- **SSH keys** — copy `~/.ssh/` from backup or generate new ones
- **GPG keys** — import if needed
- **Git identity**:
  ```bash
  git config --global user.name "your name"
  git config --global user.email "your@email.com"
  ```

---

## 6. Reboot

```bash
sudo reboot
# SDDM should appear — select Hyprland and log in
```

If SDDM itself doesn't appear (boots straight to a text login or a black screen with no login prompt), the display manager service likely isn't enabled or failed to start — check its status before assuming Hyprland is the problem:

```bash
systemctl status sddm
journalctl -u sddm -b --no-pager | tail -50
```

If SDDM is running but Hyprland fails after you log in, see **Black screen after launching Hyprland** below.

---

## Troubleshooting

Before digging into a specific symptom, run the health-check script — it catches the most common causes of a broken setup (missing binaries, broken Stow symlinks, out-of-sync system files):

```bash
./scripts/status.sh
```

See [`docs/scripts.md`](scripts.md) for details on what it checks.

### Black screen after launching Hyprland

SDDM started fine, but the screen goes black after selecting Hyprland. Usually a wrong or stale monitor name in `hyprland.conf`. Find the correct name and update the `monitor=` line:

```bash
hyprctl monitors    # find your monitor name, e.g. "DP-1" or "eDP-1"
```

Edit `~/.config/hypr/hyprland.conf`, update the `monitor=` line with the name found above, then reload with `hyprctl reload` or restart Hyprland.

### Waybar not starting

Run it in the foreground to see the actual error instead of guessing:

```bash
waybar 2>&1 | head -50
```

Most common cause: a syntax error in `~/.config/waybar/config.jsonc` or `style.css` introduced by a recent edit.

### No audio

```bash
systemctl --user status pipewire pipewire-pulse wireplumber
systemctl --user restart pipewire
```

If the services are running but there's still no sound, check the output device with `wpctl status` and make sure the right sink is selected as default.

### Screen tearing

Add to `hyprland.conf`:

```ini
misc {
    vfr = true
}
```

### Stow conflict error

Stow refuses to overwrite existing real files. Back up the conflicting file and retry:

```bash
mv ~/.config/hypr ~/.config/hypr.bak
stow --dir=/home/<user>/.dotfiles/configs --target=/home/<user> hypr
```

See [`docs/managing.md`](managing.md#resolving-conflicts) for more on resolving Stow conflicts, and [`docs/managing.md`](managing.md#the-stow-command) for why the full absolute path is required here instead of `~`.
