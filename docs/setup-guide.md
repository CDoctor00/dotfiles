# Setup Guide — Post Arch Installation

Step-by-step guide to go from a fresh Arch install to a working Hyprland desktop.

---

## 1. Fresh Arch install

You can follow the [official Arch installation guide](https://wiki.archlinux.org/title/Installation_guide) until you have a bootable system with a non-root user, or use `archinstall` as described below.

### Using archinstall

The principle: install a **minimal** system and let `install.sh` build the whole desktop on top of it. Menu entries vary slightly between archinstall versions; these are the choices that matter for this repo.

| Option                       | Choice                                                                                                                                                                                                                  |
| ---------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Mirrors and repositories     | Your region. No optional repositories needed — `install.sh` enables `multilib` itself.                                                                                                                                  |
| Locales                      | Keyboard layout and language as you prefer, UTF-8 encoding.                                                                                                                                                             |
| Hostname / Timezone          | Your choice. Keep time synchronization (NTP) on.                                                                                                                                                                        |
| Disk configuration           | Best-effort partitioning on the right disk (**it will be wiped**). `ext4` is the simple choice, `btrfs` if you want snapshots. On a laptop, enable disk encryption (LUKS).                                              |
| Swap                         | Keep zram (the default). A disk swap is only needed for hibernation.                                                                                                                                                    |
| Bootloader                   | `systemd-boot` on UEFI without dual boot, `GRUB` otherwise.                                                                                                                                                             |
| Root password / User account | Set a root password (`install.sh` also installs a `.bashrc` for root). Create your user and answer **yes** to sudo — the installer, pacman and the AUR helper need it.                                                  |
| Profile → Type               | **Minimal.** Do _not_ pick the Hyprland profile or any other desktop: it installs its own packages and configuration, which conflict with this repo's SDDM setup and `hyprland.lua`.                                    |
| Graphics driver              | The package lists in this repo target **AMD** (`amd-ucode`, `vulkan-radeon`, `xf86-video-amdgpu`, …). On Intel or Nvidia, edit `packages/packages.txt` before running the installer. Nvidia needs extra Hyprland setup. |
| Kernel                       | `linux` (default).                                                                                                                                                                                                      |
| Audio                        | `pipewire`.                                                                                                                                                                                                             |
| Network configuration        | **NetworkManager** — a requirement of this setup, and it gives you Wi-Fi.                                                                                                                                               |
| Additional packages          | `git stow base-devel vim` — `git` and `stow` for the clone, `base-devel` to build AUR packages.                                                                                                                         |

When archinstall finishes it offers three choices: pick **Reboot system**. The chroot option is only for manual changes to the new system, which this setup doesn't need. Remove the USB stick as soon as the machine powers off (if you enabled LUKS, the next boot asks for the passphrase).

After the reboot you land on a TTY with no desktop — that is expected. Log in with your user and make sure you have:

```bash
# Network (on Wi-Fi: nmcli device wifi connect "<SSID>" password "<password>")
ping -c 3 archlinux.org

# NetworkManager running (archinstall already enables it)
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

# Preview first: prints every command without applying anything
./scripts/install.sh --dry-run

# Full install (packages + symlinks + system files + services)
./scripts/install.sh

# Or selectively:
./scripts/install.sh --packages-only    # only install packages
./scripts/install.sh --symlinks-only    # just the Stow symlinks
./scripts/install.sh --system-only      # only install /etc and /usr files
./scripts/install.sh --services-only    # only enable systemd services
```

See [`docs/scripts.md`](scripts.md) for exactly what each flag does and what `install.sh` touches on the system.

The full install runs, in order: **multilib check** (enabled in `/etc/pacman.conf` if needed) → system update and **official packages** (the run stops here if this fails) → **AUR packages** (a failing package is recorded and the run continues) → **Stow symlinks** → root `.bashrc` → **system files** → **services** (enabled, started at the next boot) → personal scripts → font cache.

At the end the installer prints a summary. A green banner means nothing failed. A yellow `Installation complete with N issue(s)` banner lists what needs attention (for example `AUR: <package>` or `Service: <unit>`): fix the cause, then simply re-run `./scripts/install.sh` — packages that are already installed are skipped. See [Troubleshooting](#troubleshooting) for the usual suspects.

> **Note:** If the scripts lose their executable bit (e.g. after cloning on some systems), restore it and make git track it permanently:
>
> ```bash
> chmod +x scripts/install.sh scripts/sync.sh scripts/status.sh
> git update-index --chmod=+x scripts/install.sh scripts/sync.sh scripts/status.sh
> git commit -m "CHORE: restore executable bit on scripts"
> ```

> After the installation, a log file is saved to `logs/install/install_<timestamp>.log`. Check it if any step reported warnings or errors — it also contains the full output of every AUR build, while the terminal only shows the last lines of a failed one.

Once the install finishes, run the health-check before rebooting — it's much easier to fix a broken symlink or a missing binary now than to debug it after logging into a fresh Hyprland session:

```bash
./scripts/status.sh
```

---

## 3. Services

`install.sh` enables the services the desktop relies on, so there is normally nothing to do here. They are only _enabled_, not started: they come up at the next boot (see [Reboot](#6-reboot)).

| Scope  | Services                                    | Notes                                                                                             |
| ------ | ------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| system | `bluetooth`, `cups`                         |                                                                                                   |
| user   | `pipewire`, `pipewire-pulse`, `wireplumber` | need a normal login session (a TTY login is fine)                                                 |
| system | `sddm`                                      | not started on purpose: starting it from the TTY running the installer would take over the screen |

These are all required: if one of the units doesn't exist (package not installed) or can't be enabled, it appears in the final summary as an issue. To check or redo this step:

```bash
./scripts/install.sh --services-only

systemctl is-enabled sddm bluetooth cups
systemctl --user is-enabled pipewire pipewire-pulse wireplumber
```

Doing it by hand:

```bash
sudo systemctl enable sddm bluetooth cups
systemctl --user enable pipewire pipewire-pulse wireplumber
```

> `avahi-daemon` and SSD trim are **not** enabled by the installer — they are optional or depend on the machine. See [Manual steps](#5-manual-steps) and [Optional hardening](#4-optional-hardening).

> `/etc/nsswitch.conf` is installed by `install.sh --system-only` and adds `mdns_minimal [NOTFOUND=return]` to the `hosts:` line, which lets the system resolve `.local` names via Avahi (needed to discover the network printer/scanner — it only works once `avahi-daemon` is running, see [Manual steps](#5-manual-steps)).

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
```

### SSD trim

```bash
sudo systemctl enable --now fstrim.timer
```

Only useful on an SSD/NVMe. **On an encrypted (LUKS) disk it does nothing unless discards are allowed through the encryption layer** (the `discard` option / `--allow-discards`), which is off by default. Allowing it makes trim work but reveals to someone with access to the disk which blocks are unused — a trade-off to decide consciously. To check whether trim can reach the disk:

```bash
lsblk --discard          # DISC-GRAN and DISC-MAX must be non-zero on the encrypted device too
sudo fstrim -v /         # reports how much was trimmed, or an error if discard isn't supported
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
- **Printer and scanner (HP Envy 6400)** — `cups` (print server) is already enabled by the installer. Find the printer IP, then:
  ```bash
  hp-setup -i <printer_ip>
  ```
  When asked for a location description, press Enter (answering `q` aborts the setup without creating the queue). Creating the queue only needs the IP. To make `scanimage -L` find the scanner you also need Avahi (mDNS), which is **optional** and not enabled by the installer, because it announces this machine's name and address on the local network — enable it only on machines that use the scanner, and think twice on public Wi-Fi:
  ```bash
  sudo systemctl enable --now avahi-daemon
  ```

---

## 6. Reboot

```bash
sudo reboot
# SDDM should appear — select Hyprland and log in
```

If SDDM itself doesn't appear (boots straight to a text login or a black screen with no login prompt), the display manager service most likely isn't enabled or failed to start — check its status before assuming Hyprland is the problem:

```bash
systemctl is-enabled sddm
systemctl status sddm
journalctl -u sddm -b --no-pager | tail -50
```

If it reports `disabled`, enable it and start it right away (it also covers the case where the installer's services step was interrupted):

```bash
sudo systemctl enable --now sddm      # or: ./scripts/install.sh --services-only, then reboot
```

You can still reach the desktop without SDDM: log in on the TTY and run `Hyprland`.

If SDDM is running but Hyprland fails after you log in, see **Black screen after launching Hyprland** below.

---

## Troubleshooting

Before digging into a specific symptom, run the health-check script — it catches the most common causes of a broken setup (missing binaries, broken Stow symlinks, out-of-sync system files):

```bash
./scripts/status.sh
```

See [`docs/scripts.md`](scripts.md) for details on what it checks.

### `error: target not found: lib32-…` / `steam` — nothing gets installed

Symptom: the "Installing official packages" step prints a few `error: target not found` lines (`lib32-mesa`, `lib32-vulkan-radeon`, `steam`) between a wall of `is up to date -- skipping` warnings, and no package is actually installed.

Cause: the `multilib` repository is disabled (a fresh `archinstall` ships without it). pacman aborts the **whole** transaction when a single target is unknown, so the other packages are not installed either. `install.sh` now enables `multilib` before installing anything; if you run `pacman` by hand, enable it yourself — uncomment these two lines in `/etc/pacman.conf`:

```
[multilib]
Include = /etc/pacman.d/mirrorlist
```

Then `sudo pacman -Syu` and re-run `./scripts/install.sh`. Check with `pacman -Sl multilib | head`.

### An AUR package failed

The installer keeps going and lists the failed package in the final summary (`AUR: <package>`). To see the actual reason, build it by hand and read the output:

```bash
yay -S <package>
```

Common causes: a temporary network or mirror problem (just re-run `./scripts/install.sh`), a missing dependency or conflict (yay says which), or a package that was removed or renamed in the AUR (`target not found`). The full output of every build is also in `logs/install/install_<timestamp>.log`.

> **Tip:** if you want to inspect or edit a PKGBUILD (`yay -G <package>`), do it in `/tmp` or `~/.cache`, never inside `~/.dotfiles` — the downloaded folder would end up in the repo.

### Black screen after launching Hyprland

SDDM started fine, but the screen goes black after selecting Hyprland. Usually a wrong or stale monitor name in `hyprland.lua`. Find the correct name and update the `hl.monitor({...})` call:

```bash
hyprctl monitors    # find your monitor name, e.g. "DP-1" or "eDP-1"
```

Edit `~/.config/hypr/hyprland.lua`, update the `output` field in the `hl.monitor({...})` call with the name found above (e.g. `output = "DP-1"`), then reload with `hyprctl reload` or restart Hyprland. An empty `output = ""` makes Hyprland auto-detect the monitor, which is fine on most machines.

`hyprctl monitors` needs a running Hyprland, so from a TTY it can't help; the connector names can be read from the kernel instead:

```bash
for s in /sys/class/drm/card*-*/status; do echo "$s: $(cat $s)"; done
# e.g. /sys/class/drm/card2-eDP-1/status: connected  →  monitor name "eDP-1"
```

> **Note:** since the Lua migration, `hyprland.lua` is the file Hyprland actually loads.

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

Add to `hyprland.lua`:

```lua
hl.config({
    misc = {
        vfr = true,
    },
})
```

### Stow conflict error

Stow refuses to overwrite existing real files. Back up the conflicting file and retry:

```bash
mv ~/.config/hypr ~/.config/hypr.bak
stow --no-folding --dir=/home/<user>/.dotfiles/configs --target=/home/<user> hypr
```

`install.sh` already backs up conflicting real files to `~/.dotfiles-backup/<timestamp>/` before stowing, so this mostly happens when you run `stow` by hand.

See [`docs/managing.md`](managing.md#resolving-conflicts) for more on resolving Stow conflicts, [`docs/managing.md`](managing.md#the-stow-command) for why the full absolute path is required here instead of `~`, and [`docs/managing.md`](managing.md#tree-folding---no-folding) for why `--no-folding` is always used (it keeps apps' runtime data, like the clipboard history, out of the repo).
