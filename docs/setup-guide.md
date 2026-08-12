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
chmod +x scripts/install.sh scripts/sync.sh

# Full install (packages + symlinks + system files)
./scripts/install.sh

# Or selectively:
./scripts/install.sh --packages-only    # only install packages
./scripts/install.sh --stow-only        # only create symlinks
./scripts/install.sh --system-only      # only install /etc and /usr files
./scripts/install.sh --dry-run          # preview without applying
```

> **Note:** If the scripts lose their executable bit (e.g. after cloning on some systems), restore it and make git track it permanently:
>
> ```bash
> chmod +x scripts/install.sh scripts/sync.sh
> git update-index --chmod=+x scripts/install.sh scripts/sync.sh
> git commit -m "CHORE: restore executable bit on scripts"
> ```

> After the installation, a log file is saved to `logs/install_<timestamp>.log`. Check it if any step reported warnings or errors.

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

---

## Troubleshooting

Before digging into a specific symptom, run the health-check script — it catches the most common causes of a broken setup (missing binaries, broken Stow symlinks, out-of-sync system files):

```bash
./scripts/status.sh
```

See [`docs/scripts.md`](scripts.md) for details on what it checks.

**Black screen after launching Hyprland**
Check your monitor name and update `hyprland.conf`:

```bash
hyprctl monitors    # find your monitor name
```

**Waybar not starting**

```bash
waybar 2>&1 | head -50
```

**No audio**

```bash
systemctl --user status pipewire pipewire-pulse wireplumber
systemctl --user restart pipewire
```

**Screen tearing**
Add to `hyprland.conf`:

```ini
misc {
    vfr = true
}
```

**Stow conflict error**
Stow refuses to overwrite existing real files. Back up the conflicting file and retry:

```bash
mv ~/.config/hypr ~/.config/hypr.bak
cd ~/.dotfiles && stow --dir=configs --target=$HOME hypr
```
