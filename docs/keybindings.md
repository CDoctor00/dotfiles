# Keybindings — Hyprland

Complete keybinding reference for the Hyprland window manager setup.

---

## Modifier Keys

| Modifier   | Key                   |
| ---------- | --------------------- |
| `$mainMod` | `SUPER` (Windows key) |
| `ALT`      | Alt key               |
| `SHIFT`    | Shift key             |

---

## Window Management

### Focus & Navigation

| Binding                          | Action      | Description                |
| -------------------------------- | ----------- | -------------------------- |
| `$mainMod + ←` / `↑` / `↓` / `→` | `movefocus` | Move focus between windows |
| `$mainMod + left/right/up/down`  | `movefocus` | Move focus with arrow keys |

### Window Actions

| Binding        | Action           | Description                       |
| -------------- | ---------------- | --------------------------------- |
| `$mainMod + Q` | `killactive`     | Close active window               |
| `ALT + F4`     | `killactive`     | Close active window (alternative) |
| `$mainMod + W` | `togglefloating` | Toggle floating/tiling mode       |
| `ALT + Return` | `fullscreen`     | Toggle fullscreen                 |

### Layout Management

| Binding        | Action        | Description                      |
| -------------- | ------------- | -------------------------------- |
| `$mainMod + P` | `pseudo`      | Toggle pseudo-tiling (dwindle)   |
| `$mainMod + J` | `togglesplit` | Toggle split direction (dwindle) |

---

## Workspace Management

### Switch Workspaces

| Binding                  | Action           | Description                  |
| ------------------------ | ---------------- | ---------------------------- |
| `$mainMod + 1`-`9`       | `workspace`      | Switch to workspace 1-9      |
| `$mainMod + 0`           | `workspace 10`   | Switch to workspace 10       |
| `$mainMod + scroll up`   | `workspace, e+1` | Switch to next workspace     |
| `$mainMod + scroll down` | `workspace, e-1` | Switch to previous workspace |

### Move Window to Workspace

| Binding                    | Action               | Description                  |
| -------------------------- | -------------------- | ---------------------------- |
| `$mainMod + SHIFT + 1`-`9` | `movetoworkspace`    | Move window to workspace 1-9 |
| `$mainMod + SHIFT + 0`     | `movetoworkspace 10` | Move window to workspace 10  |

### Special Workspace (Scratchpad)

| Binding                | Action                           | Description               |
| ---------------------- | -------------------------------- | ------------------------- |
| `$mainMod + S`         | `togglespecialworkspace, magic`  | Toggle scratchpad         |
| `$mainMod + SHIFT + S` | `movetoworkspace, special:magic` | Move window to scratchpad |

---

## Applications

### Launchers & Programs

| Binding        | Action              | Description                    |
| -------------- | ------------------- | ------------------------------ |
| `$mainMod + T` | `exec $terminal`    | Launch terminal (Kitty)        |
| `$mainMod + A` | `exec $menu`        | Launch application menu (Rofi) |
| `$mainMod + F` | `exec $fileManager` | Launch file manager (Thunar)   |

### Clipboard & Utilities

| Binding        | Action     | Description                              |
| -------------- | ---------- | ---------------------------------------- |
| `$mainMod + V` | `cliphist` | Open clipboard history (Rofi + Cliphist) |

---

## Screenshots

| Binding            | Action               | Description                     |
| ------------------ | -------------------- | ------------------------------- |
| `$mainMod + PRINT` | `hyprshot -m output` | Screenshot entire screen        |
| `PRINT`            | `hyprshot -m region` | Screenshot region (interactive) |

---

## Media & System

### Volume Control

| Binding                | Action                  | Description            |
| ---------------------- | ----------------------- | ---------------------- |
| `XF86AudioRaiseVolume` | `wpctl set-volume`      | Increase volume by 5%  |
| `XF86AudioLowerVolume` | `wpctl set-volume`      | Decrease volume by 5%  |
| `XF86AudioMute`        | `wpctl set-mute toggle` | Toggle mute            |
| `XF86AudioMicMute`     | `wpctl set-mute toggle` | Toggle microphone mute |

### Brightness Control

| Binding                 | Action                 | Description                |
| ----------------------- | ---------------------- | -------------------------- |
| `XF86MonBrightnessUp`   | `brightnessctl s 10%+` | Increase brightness by 10% |
| `XF86MonBrightnessDown` | `brightnessctl s 10%-` | Decrease brightness by 10% |

### Media Playback (requires `playerctl`)

| Binding          | Action                 | Description    |
| ---------------- | ---------------------- | -------------- |
| `XF86AudioNext`  | `playerctl next`       | Next track     |
| `XF86AudioPrev`  | `playerctl previous`   | Previous track |
| `XF86AudioPlay`  | `playerctl play-pause` | Play/pause     |
| `XF86AudioPause` | `playerctl play-pause` | Play/pause     |

---

## Mouse Bindings

### Window Manipulation

| Binding               | Action         | Description                           |
| --------------------- | -------------- | ------------------------------------- |
| `$mainMod + LMB drag` | `movewindow`   | Move window with left mouse button    |
| `$mainMod + RMB drag` | `resizewindow` | Resize window with right mouse button |

---

## Quick Reference

### Most Used Shortcuts

```
$mainMod + T       → Open Terminal
$mainMod + A       → Open App Launcher
$mainMod + F       → Open File Manager
$mainMod + Q       → Close Window
$mainMod + W       → Toggle Floating
ALT + F4           → Close Window
$mainMod + 1-9     → Switch Workspace
$mainMod + SHIFT + 1-9 → Move to Workspace
$mainMod + arrow   → Move Focus
PRINT              → Take Screenshot
$mainMod + V       → Clipboard History
```

---

## Notes

- All `bindel` bindings repeat when held (volume, brightness)
- All `bindl` bindings only trigger on key release (media keys)
- The setup uses **Dwindle layout** as default
- **Floating toggle** allows windows to float freely over the tiling layout
- **Scratchpad** (`special:magic`) is useful for temporary floating windows
