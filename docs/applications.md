# Applications

Complete list of applications used in this setup, grouped by category.

---

## Desktop Environment

| Application         | Package           | Description                                         |
| ------------------- | ----------------- | --------------------------------------------------- |
| Window Manager      | `hyprland`        | Wayland compositor with tiling and floating support |
| Status Bar          | `waybar`          | Modular status bar for Wayland                      |
| App Launcher        | `rofi-wayland`    | Application launcher using adi1090x type-2 style-1  |
| Power Menu          | `rofi-wayland`    | Power menu using adi1090x type-2 style-7            |
| Notification Daemon | `dunst`           | Lightweight notification manager                    |
| Wallpaper           | `hyprpaper`       | Wallpaper manager for Hyprland                      |
| Night Light         | `hyprsunset`      | Blue light filter (similar to redshift)             |
| Authentication      | `hyprpolkitagent` | Polkit authentication agent for Hyprland            |
| Display Manager     | `sddm`            | Login manager with silent theme                     |
| Logout Menu         | `rofi-wayland`    | Logout/power menu replacing wlogout                 |

---

## Terminal & Shell

| Application       | Package | Description                                             |
| ----------------- | ------- | ------------------------------------------------------- |
| Terminal          | `kitty` | GPU-accelerated terminal with Nerd Font support         |
| Shell             | `bash`  | Default shell with custom `.bashrc` and `.bash_profile` |
| Text Editor (TUI) | `nano`  | Terminal text editors                                   |

---

## Development

| Application     | Package                     | Description                        |
| --------------- | --------------------------- | ---------------------------------- |
| Code Editor     | `vscode`                    | Primary editor, synced via account |
| Database Client | `dbeaver`                   | Universal database client          |
| SQLite Browser  | `sqlitebrowser`             | Lightweight SQLite viewer          |
| Containers      | `docker` + `docker-compose` | Containerization                   |
| Go              | `go`                        | Go programming language toolchain  |
| API Client      | `insomnia` (AUR)            | HTTP and GraphQL client            |
| Version Control | `git`                       | Source control                     |

---

## System Tools

| Application       | Package        | Description                              |
| ----------------- | -------------- | ---------------------------------------- |
| File Manager      | `thunar`       | Graphical file manager                   |
| Archive Manager   | `unzip`        | Archive extraction                       |
| Clipboard Manager | `clipse` (AUR) | TUI clipboard manager with image preview |
| Screenshot        | `hyprshot`     | Screenshot tool for Hyprland             |

---

## Applications

| Application      | Package            | Description                    |
| ---------------- | ------------------ | ------------------------------ |
| Browser          | `firefox`          | Primary web browser            |
| Discord          | `discord`          | Voice and text chat            |
| Telegram         | `telegram-desktop` | Messaging client               |
| Password Manager | `bitwarden`        | Password manager client        |
| Notes            | `obsidian`         | Knowledge base and note-taking |

---

## Multimedia

| Application   | Package           | Description                             |
| ------------- | ----------------- | --------------------------------------- |
| Video Player  | `vlc`             | Primary video player with codec support |
| Image Viewer  | `loupe`           | Image Viewer by GNOME suite             |
| Music         | Spotify (AUR)     | Music streaming                         |
| Spotify Theme | `spicetify` (AUR) | Spotify customization via Marketplace   |
| Audio Control | `pavucontrol`     | PulseAudio/Pipewire volume control      |

---

## System & Utilities

| Application          | Package                                     | Description                       |
| -------------------- | ------------------------------------------- | --------------------------------- |
| System Monitor       | `btop`                                      | Resource monitor with graph view  |
| System Monitor (TUI) | `htop`                                      | Classic process viewer            |
| Disk Health          | `smartmontools`                             | Disk health monitoring            |
| Font Manager         | `font-manager`                              | Graphical font browser            |
| Network              | `networkmanager` + `network-manager-applet` | Network management                |
| Bluetooth            | `bluez` + `bluetui` (AUR)                   | Bluetooth support and TUI manager |
| Dotfiles             | `stow`                                      | Symlink manager for dotfiles      |
| Audio Routing        | `wireplumber`                               | Session manager for Pipewire      |
| Audio Server         | `pipewire`                                  | Modern audio server               |
