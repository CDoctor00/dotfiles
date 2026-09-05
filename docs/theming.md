# Theming — Colors, Fonts, GTK

Visual choices and how to replicate them across the entire setup.

## Contents

- [Color Scheme](#color-scheme)
- [Fonts](#fonts)
- [GTK Theme](#gtk-theme)
- [Hyprland](#hyprland)
- [Waybar](#waybar)
- [Rofi](#rofi)
- [Dunst (Notifications)](#dunst-notifications)
- [Kitty (Terminal)](#kitty-terminal)
- [Wallpaper](#wallpaper)
- [Environment Variables](#environment-variables)

---

## Color Scheme

**Current theme:** **Nord**

| Role          | Hex       | Used in                                        |
| ------------- | --------- | ---------------------------------------------- |
| Background    | `#2E3440` | Hyprland, Waybar, Rofi, Dunst, Kitty           |
| Surface       | `#3B4252` | Windows, popups, Waybar groups                 |
| Overlay       | `#4C566A` | Borders, separators, Rofi inputbar             |
| Text          | `#D8DEE9` | Primary text (Waybar, Rofi, Dunst)             |
| Text Alt      | `#ECEFF4` | Alternative text                               |
| Subtext       | `#E5E9F0` | Secondary text                                 |
| Frost 1       | `#8FBCBB` | Calendar weeks (Waybar)                        |
| Frost 2       | `#88C0D0` | Focus border, Dunst frame, highlights          |
| Frost 3       | `#81A1C1` | Secondary accents, calendar days               |
| Frost 4       | `#5E81AC` | Tertiary accents                               |
| Aurora Red    | `#BF616A` | Errors, critical notifications, calendar today |
| Aurora Orange | `#D08770` | Warning states                                 |
| Aurora Yellow | `#EBCB8B` | Info, calendar weekdays                        |
| Aurora Green  | `#A3BE8C` | Success states, calendar weeks                 |
| Aurora Purple | `#B48EAD` | Alternate accent                               |

> This table is the single source of truth for colors. Sections below reference colors by name (e.g. "Frost 2") — look up the hex value here rather than re-deriving it, so a future palette change only needs updating in one place.

---

## Fonts

| Component             | Font               | Size |
| --------------------- | ------------------ | ---- |
| GTK (UI general)      | Inter              | 11pt |
| Waybar                | Hack               | 14px |
| Rofi                  | FiraCode Nerd Font | 12px |
| Kitty (Terminal)      | FiraCode Nerd Font | 14pt |
| Dunst (Notifications) | FiraCode Nerd Font | 11px |

## Icon Themes

| Component                  | Icon theme         | Source                                   |
| -------------------------- | ------------------ | ---------------------------------------- |
| Dunst                      | Papirus-Dark       | explicit (`icon_theme` in dunstrc)       |
| GTK (system-wide)          | Papirus-Dark       | explicit (`settings.ini` + dconf)        |
| Rofi (taskbar)             | Papirus-Dark       | inherited from GTK/dconf                 |
| Rofi (powermenu)           | Icomoon-Feather    | explicit (icon set, not GTK-inherited)   |
| Waybar (taskbar apps)      | Papirus-Dark       | explicit (`icon-theme` in `wlr/taskbar`) |
| Waybar (system indicators) | Font Awesome 6 Pro | explicit (glyph font, not an icon theme) |

Icomoon-Feather is not available on pacman or AUR — it is tracked directly in the repo under `configs/fonts/.local/share/fonts/` and linked via stow.

> These tables are the source of truth for fonts, sizes, and icon themes. Per-application sections below restate the relevant values for convenience, but if a font, size, or icon theme ever needs changing, these tables are the ones to update first.

---

## GTK Theme

**Theme:** Arc  
**Icons:** Papirus-Dark  
**Cursor:** Adwaita

GTK theming is managed entirely via configuration files — no GUI tool required.

- `configs/gtk/.config/gtk-3.0/settings.ini` — GTK3 settings
- `configs/gtk/.config/gtk-4.0/settings.ini` — GTK4 settings
- `configs/hypr/.config/hypr/dconf/interface.conf` — dconf profile loaded at Hyprland startup

The dconf profile is necessary because gsettings takes precedence over `settings.ini`. Without it, GTK falls back to the Adwaita default on a fresh install. It's loaded automatically at every Hyprland startup — see the autostart block in `configs/hypr/.config/hypr/hyprland.lua` for the exact command.

---

## Hyprland

Visual identity is expressed through borders, rounding, opacity, and animation feel — not raw numeric values, which live in `configs/hypr/.config/hypr/hyprland.lua` and are better read there than duplicated here (this doc's numeric values have already drifted out of sync with the real config once in the past).

- **Borders**: active windows use a Frost 2 → Frost 3 gradient (`#88C0D0` → `#81A1C1`), inactive windows use a translucent Background (`#2E3440aa`) — see [Color Scheme](#color-scheme).
- **Corners & depth**: windows are rounded with a soft drop shadow; unfocused windows dim very slightly rather than staying fully opaque.
- **Blur**: enabled on floating/layered surfaces at a subtle level — not a heavy frosted-glass look.
- **Animations**: fast, minimal easing curves (no bounce/spring effects) across window open/close, workspace switches, and layers, favoring a snappy feel over decorative motion.

For exact values (gaps, border width, opacity, animation speeds, monitor resolution/refresh rate) or to change any of the above, edit `hyprland.lua` directly.

---

## Waybar

Positioned at the top with a 30px height. Layout and visual styling are driven directly by `configs/waybar/.config/waybar/config` and `style.css`.

- **Layout & Structure**: includes modular pill-like groups for workspaces, window taskbar, clock, resources, inputs, connections, and system power stats.
- **Icon Themes**: uses **Papirus-Dark** for the taskbar module (`wlr/taskbar`) and **Font Awesome 6 Pro** glyphs for system status indicators.
- **Styling**: background and individual module groups use rounded pills (`border-radius: 10px`) in Surface/Background shades, with active elements highlighted in Frost 2 / Frost 3 — see [Color Scheme](#color-scheme).

For exact CSS selectors, padding, margins, and palette `@define-color` bindings, inspect `configs/waybar/.config/waybar/style.css` directly.

---

## Rofi

**Theme:** Arc-inspired Nordic

> Unlike Hyprland and Waybar above, Rofi's full `.rasi` theme file isn't reproduced here — it's long and mostly boilerplate. See `configs/rofi/.config/rofi/` in the repo for the actual file; the settings below are the ones most likely to need tweaking.

**Key settings:**

- Font: FiraCode Nerd Font 12
- Powermenu icons: Icomoon-Feather 32
- Window width: 700px
- Border radius: 15px
- Lines visible: 8
- Icon size: 20px
- Icon theme: none set explicitly in any `.rasi` file — Rofi inherits the system GTK/dconf icon theme, which resolves to **Papirus-Dark**

**Color scheme:** Background, Surface, Overlay, Text, and Frost 2 (highlight) from the [Color Scheme](#color-scheme) table — `#2E3440`, `#3B4252`, `#4C566A`, `#D8DEE9`, `#88C0D0` respectively.

---

## Dunst (Notifications)

Colors below map to Background, Overlay, Frost 2, and Aurora Orange/Red in the [Color Scheme](#color-scheme) table.

**Key settings:**

- Position: top-right with 20px offset
- Size: 380x300px max
- Font: FiraCode Nerd Font 11
- Corner radius: 12px
- Frame: 2px with `#4C566A` (inactive), `#88C0D0` for critical
- Gap between notifications: 8px
- Background: semitransparent `#2E3440ee`
- Timeout: 10s (5s for low urgency, 0s for critical)
- Icon theme: **Papirus-Dark**

**Format:** `<small>%a</small>\n<b>%s</b>\n%b` — the `%a` token shows the originating app name above the notification title, useful for browser-generated notifications (e.g. WhatsApp Web via Firefox) where the title would otherwise only show the contact name.

**Urgency levels:**

- **Low:** Background `#2E3440ee`, text `#D8DEE9`, frame `#3B4252`, timeout 5s
- **Normal:** Background `#2E3440ee`, text `#D8DEE9`, frame `#4C566A`, timeout 10s
- **Critical:** Background `#BF616Aee`, text `#ECEFF4`, frame `#D08770`, timeout infinite

---

## Kitty (Terminal)

**Font:** FiraCode Nerd Font 14.0

**Colors:** Background and Text use the same Background/Text pair as everywhere else (see [Color Scheme](#color-scheme)); selection uses Surface/Text, and the active border uses Frost 2.

```
Background: #2E3440
Foreground: #D8DEE9
Cursor: #D8DEE9 (text on cursor: #2E3440)

Selection background: #3B4252
Selection foreground: #D8DEE9

Active border: #88C0D0
Inactive border: #3B4252
Window padding: 10px
```

**ANSI Palette (Nord):**

| Color   | Normal    | Bright    |
| ------- | --------- | --------- |
| Black   | `#3B4252` | `#4C566A` |
| Red     | `#BF616A` | `#BF616A` |
| Green   | `#A3BE8C` | `#A3BE8C` |
| Yellow  | `#EBCB8B` | `#EBCB8B` |
| Blue    | `#81A1C1` | `#81A1C1` |
| Magenta | `#B48EAD` | `#B48EAD` |
| Cyan    | `#88C0D0` | `#8FBCBB` |
| White   | `#E5E9F0` | `#ECEFF4` |

---

## Wallpaper

Managed with `hyprpaper`, autostarted at every Hyprland session from `hyprland.lua`.

---

## Environment Variables

| Variable          | Value                    | Why it matters here                               |
| ----------------- | ------------------------ | ------------------------------------------------- |
| `XCURSOR_SIZE`    | `24`                     | Cursor size, paired with the Adwaita cursor theme |
| `HYPRCURSOR_SIZE` | `24`                     | Same, for the Hyprcursor protocol                 |
| `HYPRSHOT_DIR`    | `~/Pictures/Screenshots` | Not theming-related, but set here for convenience |

Set in `hyprland.lua` via `hl.env(...)` — see the file for the exact calls if they ever need changing.
