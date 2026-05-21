-- options.lua
return function(theme)
    -- Monitor
    hyprland.monitor = ",preferred,auto,1"

    -- Input
    hyprland.input = {
        kb_layout = "us",
        follow_mouse = 1,
        sensitivity = 0,
    }

    -- General
    hyprland.general = {
        gaps_in = 6,
        gaps_out = 8,
        border_size = 2,
        no_border_on_floating = true,
        layout = "dwindle",
        resize_on_border = true,
    }

    -- Decoration using your dwm colors
    hyprland.decoration = {
        rounding = 8,

        active_opacity = 1.0,
        inactive_opacity = 0.96,

        blur = {
            enabled = true,
            size = 6,
            passes = 3,
            new_optimizations = true,
            ignore_opacity = true,
        },

        drop_shadow = true,
        shadow_ignore_window = true,
        shadow_offset = "2 2",
        shadow_range = 8,
        shadow_render_power = 3,
        col = {
            shadow = "0x66000000",
            border_active   = theme.selborder,
            border_inactive = theme.normborder,
        },
    }

    -- Animations
    hyprland.animations = {
        enabled = true,
        bezier = {
            "overshot, 0.05, 0.9, 0.1, 1.05",
            "smoothOut, 0.36, 0, 0.66, -0.56",
        },
        animation = {
            "windows, 1, 5, overshot, slide",
            "windowsOut, 1, 4, smoothOut, slide",
            "border, 1, 8, default",
            "fade, 1, 8, smoothIn",
            "workspaces, 1, 6, default",
        },
    }

    -- Layouts
    hyprland.dwindle = {
        pseudotile = true,
        preserve_split = true,
    }

    hyprland.master = {
        mfact = 0.75,
    }

    -- Misc
    hyprland.misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        mouse_move_enables_dpms = true,
        enable_swallow = true,
        swallow_regex = "^(Alacritty|kitty|st)$",
        focus_on_activate = true,
    }
end
