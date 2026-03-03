# dotfiles — Arch + Hyprland

Personal configuration for Arch Linux with Hyprland as Wayland compositor based on the Nordic palette.

![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=flat&logo=arch-linux&logoColor=white)
![Hyprland](https://img.shields.io/badge/Hyprland-58E1FF?style=flat&logoColor=black)

---

## Screenshots

**Clean**
![Clean](assets/screenshots/clean.png)

**Dirty**
![Dirty](assets/screenshots/dirty.png)

**Rofi**
![Rofi](assets/screenshots/rofi.png)

**Wlogout**
![Wlogout](assets/screenshots/wlogout.png)

**Lock**
![Lock](assets/screenshots/lock.png)

---

## Quick install

> ⚠️ Read the full guide before running. The script installs packages and modifies system files.

```bash
git clone https://github.com/cdoctor/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
chmod +x install.sh sync.sh
./install.sh
```

---

## Repository structure

```
dotfiles/
│
├── configs/                        # Stow packages — all symlinked to $HOME
│   ├── bash/                       # → $HOME/.bashrc, $HOME/.bash_profile
│   ├── dunst/                      # → $HOME/.config/dunst/
│   ├── face/                       # → $HOME/.face
│   ├── fontconfig/                 # → $HOME/.config/fontconfig/
│   ├── gtk/                        # → $HOME/.config/gtk-3.0/, gtk-4.0/
│   ├── hypr/                       # → $HOME/.config/hypr/
│   ├── kitty/                      # → $HOME/.config/kitty/
│   ├── rofi/                       # → $HOME/.config/rofi/
│   ├── spicetify/                  # → $HOME/.config/spicetify/
│   ├── waybar/                     # → $HOME/.config/waybar/
│   └── wlogout/                    # → $HOME/.config/wlogout/
│
├── system/                         # Files requiring root — installed via install.sh
│   ├── sddm/
│   │   └── sddm.conf               → /etc/sddm.conf
│   └── sddm-theme/
│       └── silent/                 → /usr/share/sddm/themes/silent/ (modified files only)
│
├── scripts/
│   ├── system-files.conf           # Shared map: repo path ↔ system path
│   ├── install.sh                  # Full installer
│   └── sync.sh                     # Sync system state back into the repo
│
├── packages/
│   ├── packages.txt                # Official pacman packages
│   └── aur-packages.txt            # AUR packages
│
├── docs/
│   ├── keybindings.md
│   ├── setup-guide.md
│   └── theming.md
│
├── assets/
│   ├── screenshots/
│   └── wallpapers/
│
└── .gitignore
```

---

## Managed configurations

Configurations are managed in two different ways depending on where they live on the system. User-space configs (under `$HOME`) are handled with **GNU Stow**, which creates symlinks so that any edit is immediately reflected in the repo. System-level files (under `/etc` or `/usr/share`) require root access and cannot be symlinked, so they are managed via **install/sync scripts** that copy files in both directions.

### Inventory

#### Stow packages

| Package    | Source in repo                             | Links to                         |
| ---------- | ------------------------------------------ | -------------------------------- |
| bash       | `configs/bash/.bashrc`, `.bash_profile`    | `~/.bashrc`, `~/.bash_profile`   |
| dunst      | `configs/dunst/.config/dunst/`             | `~/.config/dunst/`               |
| face       | `configs/face/.face`                       | `~/.face`                        |
| fontconfig | `configs/fontconfig/.config/fontconfig/`   | `~/.config/fontconfig/`          |
| gtk        | `configs/gtk/.config/gtk-3.0/`, `gtk-4.0/` | `~/.config/gtk-3.0/`, `gtk-4.0/` |
| hypr       | `configs/hypr/.config/hypr/`               | `~/.config/hypr/`                |
| kitty      | `configs/kitty/.config/kitty/`             | `~/.config/kitty/`               |
| rofi       | `configs/rofi/.config/rofi/`               | `~/.config/rofi/`                |
| spicetify  | `configs/spicetify/.config/spicetify/`     | `~/.config/spicetify/`           |
| waybar     | `configs/waybar/.config/waybar/`           | `~/.config/waybar/`              |
| wlogout    | `configs/wlogout/.config/wlogout/`         | `~/.config/wlogout/`             |

#### System files

Managed via `scripts/system-files.conf`. Only modified files are tracked — the base SDDM theme is installed via AUR.

| File             | Source in repo                                 | Installed to                             |
| ---------------- | ---------------------------------------------- | ---------------------------------------- |
| SDDM config      | `system/sddm/sddm.conf`                        | `/etc/sddm.conf`                         |
| SDDM custom.conf | `system/sddm-theme/silent/configs/custom.conf` | `/usr/share/sddm/themes/silent/configs/` |
| SDDM metadata    | `system/sddm-theme/silent/metadata.desktop`    | `/usr/share/sddm/themes/silent/`         |

---

## Packages

Full lists in [`packages/packages.txt`](packages/packages.txt) and [`packages/aur-packages.txt`](packages/aur-packages.txt).

To install manually:

```bash
sudo pacman -S --needed - < packages/packages.txt
yay -S --needed - < packages/aur-packages.txt
```

---

## Documentation

- [`docs/keybindings.md`](docs/keybindings.md) — all Hyprland keybindings
- [`docs/managing.md`](docs/managing.md) — how to add, remove and maintain configurations
- [`docs/setup-guide.md`](docs/setup-guide.md) — step-by-step post Arch install guide
- [`docs/theming.md`](docs/theming.md) — colors, fonts, GTK theme choices

---

## Workflow

### Editing configs

Since configs are symlinked, just edit normally and commit:

```bash
# Edit any config file as usual, then:
cd ~/coding/dotfiles
git add -A
git commit -m "feat(hypr): adjust border radius"
git push
```

### Syncing packages and system files

```bash
./sync.sh                  # update package lists + copy system files into repo
./sync.sh --packages-only  # only update package lists
./sync.sh --system-only    # only copy system files into repo

git add -A && git commit -m "chore: sync"
```
