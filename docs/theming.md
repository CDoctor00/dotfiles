# Theming — Colors, Fonts, GTK

Visual choices and how to replicate them across the entire setup.

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

---

## Fonts

| Component             | Font               | Size |
| --------------------- | ------------------ | ---- |
| GTK (UI general)      | Inter              | 11pt |
| Waybar                | Hack               | 14px |
| Rofi                  | Fira Code          | 12px |
| Kitty (Terminal)      | Fira Code          | 14.0 |
| Dunst (Notifications) | Inter              | 12px |
| Icons (Waybar)        | Font Awesome 6 Pro | —    |
| Icons (Rofi taskbar)  | Numix-Circle       | —    |

---

## Hyprland

### General Settings & Borders

```ini
general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(88C0D0ff) rgba(81A1C1ff) 45deg
    col.inactive_border = rgba(2E3440aa)
    resize_on_border = true
    allow_tearing = false
    layout = dwindle
}
```

### Decorations

```ini
decoration {
    rounding = 15
    active_opacity = 1.0
    inactive_opacity = 0.9

    shadow {
        enabled = true
        range = 4
        render_power = 3
        color = rgba(1a1a1aee)
    }

    blur {
        enabled = true
        size = 3
        passes = 1
        vibrancy = 0.1696
    }
}
```

### Animations

```ini
animations {
    enabled = true

    bezier = easeOutQuint,0.25,1,0.30,1
    bezier = easeInOutCubic,0.65,0.05,0.35,1
    bezier = linear,0,0,1,1
    bezier = almostLinear,0.5,0.5,0.75,1.0
    bezier = quick,0.15,0,0.1,1

    animation = windows, 1, 4, easeOutQuint, gnomed
    animation = windowsIn, 1, 4, easeOutQuint, gnomed
    animation = windowsOut, 1, 4, linear, gnomed
    animation = workspaces, 1, 3, almostLinear, slidefade
    animation = workspacesIn, 1, 3, almostLinear, slidefade
    animation = workspacesOut, 1, 3, almostLinear, slidefade
    animation = global, 1, 10, default
    animation = border, 1, 5, easeOutQuint
    animation = fadeIn, 1, 2, almostLinear
    animation = fadeOut, 1, 2, almostLinear
    animation = fade, 1, 3, quick
    animation = layers, 1, 4, easeOutQuint
    animation = layersIn, 1, 4, easeOutQuint, fade
    animation = layersOut, 1, 1.5, linear, fade
    animation = fadeLayersIn, 1, 2, almostLinear
    animation = fadeLayersOut, 1, 1.5, almostLinear
}
```

### Monitor & Display

```ini
monitor = ,3440x1440@144,auto,auto
```

---

## Waybar

Position at top with 30px height. Includes modular groups for resources, input, connections, and system stats.

**Key configuration:**

- Margin: `10 10 0 10`
- Taskbar icon theme: Numix-Circle
- Clock format: 24-hour with date

**CSS Styling:**

```css
/* Nordic Palette */
@define-color nord_bg #2E3440;
@define-color nord_fg #D8DEE9;
@define-color nord_bg2 #3B4252;
@define-color nord_hl #88C0D0;
@define-color nord_hl2 #81A1C1;

window#waybar {
  color: @nord_hl;
  background-color: transparent;
}

#workspaces,
#taskbar,
#clock,
#resources,
#input,
#connections,
#system {
  background: @nord_bg;
  border-radius: 10px;
  padding: 0 10px;
}

button {
  color: @nord_bg;
  background: @nord_hl;
  opacity: 0.5;
  border-radius: 10px;
  padding: 0 5px;
  margin: 5px;
}

button.active,
button:hover {
  opacity: 1;
}
```

---

## Rofi

**Theme:** Arc-inspired Nordic

**Key settings:**

- Font: Fira Code 12
- Window width: 700px
- Border radius: 15px
- Lines visible: 8
- Icon size: 20px

**Color scheme:**

```
bg-dark: #2E3440
bg: #3B4252
bg-alt: #4C566A
fg: #D8DEE9
fg-alt: #88C0D0 (highlight)
```

---

## Dunst (Notifications)

**Key settings:**

- Position: top-right with 35px offset
- Size: 400x300px max
- Font: Inter 12
- Corner radius: 10px
- Frame: 2px with Nord blue (`#88C0D0`)
- Gap between notifications: 10px
- Timeout: 10s (5s for low urgency, 0s for critical)

**Urgency levels:**

- **Low:** Background `#2E3440`, text `#D8DEE9`, timeout 5s
- **Normal:** Background `#2E3440`, text `#D8DEE9`, timeout 10s
- **Critical:** Background `#BF616A`, text `#ECEFF4`, frame `#ECEFF4`, timeout infinite

---

## Kitty (Terminal)

**Font:** Fira Code 14.0

**Colors:**

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

Managed with `hyprpaper`.

```bash
# In hyprland.conf autostart:
exec-once = hyprpaper
```

---

## Environment Variables

```bash
env = XCURSOR_SIZE,24
env = HYPRCURSOR_SIZE,24
env = HYPRSHOT_DIR,$HOME/Pictures/Screenshots
```
