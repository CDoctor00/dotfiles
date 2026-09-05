-- ~/.config/hypr/hyprland.lua
-- Migration from hyprland.conf (hyprlang) to hyprland.lua (Hyprland >= 0.55)
-- Structured in levels, from most foundational to most cosmetic. See the
-- points to verify with hyprctl reload discussed in the session.

------------------
---- MONITORS ----
------------------

-- https://wiki.hypr.land/Configuring/Basics/Monitors/
hl.monitor({
    output   = "",
    mode     = "3440x1440@144",
    position = "auto",
    scale    = "auto",
})


---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "kitty"
local fileManager  = "thunar"
local menu        = os.getenv("HOME") .. "/.config/rofi/launchers/type-2/launcher.sh"
local powerMenu   = os.getenv("HOME") .. "/.config/rofi/powermenu/type-2/powermenu.sh"


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("HYPRSHOT_DIR", os.getenv("HOME") .. "/Pictures/Screenshots")


-------------------
---- AUTOSTART ----
-------------------

-- https://wiki.hypr.land/Configuring/Basics/Autostart/
hl.on("hyprland.start", function()
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("waybar")
    hl.exec_cmd("dunst")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("dconf load /org/gnome/desktop/interface/ < " .. os.getenv("HOME") .. "/.config/hypr/dconf/interface.conf")
    hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/xdg.sh")
    hl.exec_cmd("dropbox start -i")
    hl.exec_cmd("clipse -listen")

    hl.exec_cmd("[workspace 1 silent] discord")
    hl.exec_cmd("[workspace 1 silent] spotify")
    hl.exec_cmd("[workspace 2 silent] code")
    hl.exec_cmd("[workspace 2 silent] firefox")
end)


----------------------------------------------------------------
-- CORE WM BEHAVIOR (general, decoration, misc, dwindle, input)
----------------------------------------------------------------

-- https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 10,

        border_size = 2,

        col = {
            active_border   = { colors = { "rgba(88C0D0ff)", "rgba(81A1C1ff)" }, angle = 45 },
            inactive_border = "rgba(2E3440aa)",
        },

        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding = 15,

        active_opacity   = 1.0,
        inactive_opacity = 0.95,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = "rgba(1a1a1aee)",
        },

        blur = {
            enabled  = true,
            size     = 3,
            passes   = 1,
            vibrancy = 0.1696,
        },
    },

    misc = {
        force_default_wallpaper  = 0,
        disable_splash_rendering = true,
        disable_hyprland_logo    = true,
    },

    -- https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/
    dwindle = {
        preserve_split = true,
        smart_split    = false,
        smart_resizing = true,
        force_split    = 0,
    },

    input = {
        kb_layout  = "us",
        kb_variant = "intl",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0,

        touchpad = {
            natural_scroll = false,
        },
    },
})


------------------------------------------------------------
-- MAIN KEYBINDINGS
------------------------------------------------------------

-- https://wiki.hypr.land/Configuring/Basics/Binds/
local mainMod = "SUPER"

--------------------
-- GENERAL / APPS --
--------------------

hl.bind(mainMod .. " + T",      hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + A",      hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + ESCAPE", hl.dsp.exec_cmd(powerMenu))
hl.bind(mainMod .. " + F",      hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V",      hl.dsp.exec_cmd("kitty --class clipse -e clipse"))

-- Windows
hl.bind(mainMod .. " + W", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind("ALT + F4",        hl.dsp.window.close())
hl.bind("ALT + RETURN", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))

-- Dwindle layout
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))

-- Screenshots
hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd("hyprshot -m output"))
hl.bind("PRINT",               hl.dsp.exec_cmd("hyprshot -m region"))


-----------
-- FOCUS --
-----------

hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left"  }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up"    }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down"  }))


-------------
-- WINDOWS --
-------------

-- Move with keyboard
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left"  }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up"    }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down"  }))

-- Resize with keyboard (repeating while held, equivalent to the old "binde")
hl.bind(mainMod .. " + CTRL + left",  hl.dsp.window.resize({ x = -30, y = 0,   relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.resize({ x = 30,  y = 0,   relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + up",    hl.dsp.window.resize({ x = 0,   y = -30, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + down",  hl.dsp.window.resize({ x = 0,   y = 30,  relative = true }), { repeating = true })

-- Move/resize with mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true }) -- left click
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true }) -- right click


----------------
-- WORKSPACES --
----------------

-- Switch / move window to workspace (1-9, then 0 = workspace 10)
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i, follow = true }))
end

-- Scroll through workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))


------------------------------------------------------------
-- MEDIA KEYS
------------------------------------------------------------

-- Volume (bindel = locked + repeating in the old hyprlang)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),      { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),    { locked = true, repeating = true })

-- Brightness
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl s 10%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 10%-"), { locked = true, repeating = true })

-- Playerctl (bindl = locked, no repeat in the old hyprlang)
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })


------------------------------------------------------------
-- ANIMATIONS
------------------------------------------------------------

hl.config({ animations = { enabled = true } })

-- Bezier curves
-- https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.25, 1},    {0.30, 1}   } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.35, 1}   } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}      } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1.0} } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}    } })

-- Windows and workspaces
hl.animation({ leaf = "windows",    enabled = true, speed = 4, bezier = "easeOutQuint", style = "gnomed" })
hl.animation({ leaf = "windowsIn",  enabled = true, speed = 4, bezier = "easeOutQuint", style = "gnomed" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 4, bezier = "linear",       style = "gnomed" })

hl.animation({ leaf = "workspaces",    enabled = true, speed = 3, bezier = "almostLinear", style = "slidefade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 3, bezier = "almostLinear", style = "slidefade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 3, bezier = "almostLinear", style = "slidefade" })

-- Others
hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5,  bezier = "easeOutQuint" })

-- Fades
hl.animation({ leaf = "fadeIn",  enabled = true, speed = 2, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 2, bezier = "almostLinear" })
hl.animation({ leaf = "fade",    enabled = true, speed = 3, bezier = "quick" })

-- Layers
hl.animation({ leaf = "layers",        enabled = true, speed = 4,   bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,   bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5, bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 2,   bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.5, bezier = "almostLinear" })


------------------------------------------------------------
-- WINDOW RULES
------------------------------------------------------------

-- https://wiki.hypr.land/Configuring/Basics/Window-Rules/

-- Prevents all applications from requesting/responding to maximize events.
hl.window_rule({
    name = "prevent-maximize",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Fixes XWayland focus issues during drag-and-drop.
hl.window_rule({
    name = "fix-drag-and-drop",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- Opens clipse in a centered, pinned floating window.
hl.window_rule({
    name = "clipse-floating",
    match = { class = "^clipse$" },
    float  = true,
    size   = "700 500",
    center = true,
    pin    = true,
})