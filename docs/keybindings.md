# Keybindings

Complete keybinding reference for the system setup.

## Contents

- [Hyprland](#hyprland)
  - [Applications](#applications)
  - [Windows](#windows)
  - [Workspaces](#workspaces)
  - [Screenshots](#screenshots)
  - [Volume](#volume)
  - [Brightness](#brightness)
  - [Media](#media-requires-playerctl)
- [Kitty](#kitty)
  - [Font size](#font-size)
  - [Tabs](#tabs)
  - [Windows (splits)](#windows-splits)
  - [Basic](#basic)

## Hyprland

### Modifier keys

| Modifier   | Key                   |
| ---------- | --------------------- |
| `$mainMod` | `SUPER` (Windows key) |
| `ALT`      | Alt key               |
| `SHIFT`    | Shift key             |

### Applications

| Binding             | Action                                    |
| ------------------- | ----------------------------------------- |
| `$mainMod + T`      | Launch terminal (Kitty)                   |
| `$mainMod + A`      | Launch app menu (Rofi)                    |
| `$mainMod + ESCAPE` | Power menu (Rofi)                         |
| `$mainMod + F`      | Launch file manager (Thunar)              |
| `$mainMod + V`      | Open clipboard history (Clipse via Kitty) |

### Windows

| Binding                      | Action                            |
| ---------------------------- | --------------------------------- |
| `$mainMod + Q`               | Close active window               |
| `ALT + F4`                   | Close active window (alternative) |
| `ALT + Return`               | Toggle fullscreen                 |
| `$mainMod + W`               | Toggle floating/tiling            |
| `$mainMod + P`               | Toggle pseudo-tiling (dwindle)    |
| `$mainMod + J`               | Toggle split direction (dwindle)  |
| `$mainMod + ←/↑/↓/→`         | Move focus                        |
| `$mainMod + SHIFT + ←/↑/↓/→` | Move window                       |
| `$mainMod + CTRL + ←/↑/↓/→`  | Resize window (±30px)             |
| `$mainMod + LMB drag`        | Move window (mouse)               |
| `$mainMod + RMB drag`        | Resize window (mouse)             |

### Workspaces

| Binding                     | Action                        |
| --------------------------- | ----------------------------- |
| `$mainMod + 1`–`9`          | Switch to workspace 1–9       |
| `$mainMod + 0`              | Switch to workspace 10        |
| `$mainMod + scroll up/down` | Switch to next/prev workspace |
| `$mainMod + SHIFT + 1`–`9`  | Move window to workspace 1–9  |
| `$mainMod + SHIFT + 0`      | Move window to workspace 10   |
| `$mainMod + S`              | Toggle scratchpad             |
| `$mainMod + SHIFT + S`      | Move window to scratchpad     |

### Screenshots

| Binding            | Action                          |
| ------------------ | ------------------------------- |
| `$mainMod + PRINT` | Screenshot entire screen        |
| `PRINT`            | Screenshot region (interactive) |

### Volume

| Binding                | Action                 |
| ---------------------- | ---------------------- |
| `XF86AudioRaiseVolume` | Increase volume by 5%  |
| `XF86AudioLowerVolume` | Decrease volume by 5%  |
| `XF86AudioMute`        | Toggle mute            |
| `XF86AudioMicMute`     | Toggle microphone mute |

### Brightness

| Binding                 | Action                     |
| ----------------------- | -------------------------- |
| `XF86MonBrightnessUp`   | Increase brightness by 10% |
| `XF86MonBrightnessDown` | Decrease brightness by 10% |

### Media (requires `playerctl`)

| Binding          | Action         |
| ---------------- | -------------- |
| `XF86AudioNext`  | Next track     |
| `XF86AudioPrev`  | Previous track |
| `XF86AudioPlay`  | Play/pause     |
| `XF86AudioPause` | Play/pause     |

> Volume and brightness bindings use `{ locked = true, repeating = true }` in `hyprland.lua` (the Lua equivalent of hyprlang's `bindel`), so they repeat while the key is held. Media key bindings use `{ locked = true }` (equivalent to `bindl`) and only trigger once, on key release.

---

## Kitty

### Font size

| Binding    | Action             |
| ---------- | ------------------ |
| `Ctrl + =` | Increase font size |
| `Ctrl + -` | Decrease font size |
| `Ctrl + 0` | Reset font size    |

### Tabs

| Binding                  | Action            |
| ------------------------ | ----------------- |
| `Ctrl + Shift + T`       | New tab           |
| `Ctrl + Shift + Q`       | Close tab         |
| `Ctrl + Shift + →`       | Next tab          |
| `Ctrl + Shift + ←`       | Previous tab      |
| `Ctrl + Shift + L`       | Next layout       |
| `Ctrl + Shift + .`       | Move tab right    |
| `Ctrl + Shift + ,`       | Move tab left     |
| `Ctrl + Shift + Alt + T` | Set tab title     |
| `Ctrl + Shift + 1`–`9`   | Switch to tab 1–9 |

### Windows (splits)

| Binding                | Action                           |
| ---------------------- | -------------------------------- |
| `Ctrl + Shift + Enter` | New window                       |
| `Ctrl + Shift + W`     | Close window                     |
| `Ctrl + Shift + ]`     | Next window                      |
| `Ctrl + Shift + [`     | Previous window                  |
| `Ctrl + Shift + F`     | Move window forward              |
| `Ctrl + Shift + B`     | Move window backward             |
| `Ctrl + Shift + R`     | Resize window (interactive mode) |

### Basic

| Binding            | Action                       |
| ------------------ | ---------------------------- |
| `Ctrl + Shift + /` | Search forward               |
| `Ctrl + Shift + E` | Open URL (keyboard hints)    |
| `Ctrl + Shift + C` | Copy to clipboard            |
| `Ctrl + Shift + V` | Paste from clipboard         |
| `Ctrl + Shift + S` | Paste from selection         |
| `Shift + Insert`   | Paste from primary selection |

---

## Notes

- Hyprland default layout is **Dwindle**
- Kitty scrollback is piped through `bat` for syntax highlighting
- Kitty remote control is enabled via unix socket (`/tmp/kitty`)
