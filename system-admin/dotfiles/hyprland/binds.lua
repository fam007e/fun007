-- binds.lua
return function(script)
    hyprland.bind = {
        -- Launchers
        "SUPER, R, exec, rofi -show drun -show-icons",
        "CTRL, E, exec, rofi -show emoji",
        "SUPER, C, exec, rofi -show calc",
        "SUPER, S, exec, rofi -show drun",

        -- Terminal & Apps
        "SUPER, Return, exec, alacritty",
        "SUPER, B, exec, brave-origin-nightly",
        "SUPER SHIFT, B, exec, brave-origin-nightly --incognito",
        "SUPER, E, exec, thunar",
        "SUPER, V, exec, vlc",
        "SUPER, Z, exec, ~/.local/bin/zed",

        -- System
        "SUPER, L, exec, slock",
        "SUPER ALT, P, exec, " .. script("powermenu"),
        "SUPER, P, exec, /usr/bin/securepasswd_gui",

        -- Screenshots
        "SUPER SHIFT, P, exec, flameshot gui",
        "SUPER CTRL, P, exec, flameshot full",

        -- Media
        ", XF86AudioRaiseVolume, exec, amixer -D pulse sset Master 5%+",
        ", XF86AudioLowerVolume, exec, amixer -D pulse sset Master 5%-",
        ", XF86AudioMute, exec, amixer -D pulse sset Master toggle",
        ", XF86AudioPlay, exec, playerctl play-pause",
        ", XF86AudioNext, exec, playerctl next",
        ", XF86AudioPrev, exec, playerctl previous",

        -- Brightness
        ", XF86MonBrightnessUp, exec, brightnessctl set +10%",
        ", XF86MonBrightnessDown, exec, brightnessctl set 10%-",

        -- Window Management (dwm style)
        "SUPER, Q, killactive",
        "SUPER SHIFT, Q, exit",
        "SUPER, F, fullscreen",
        "SUPER, Space, togglefloating",
        "SUPER, Tab, cyclenext",
        "SUPER SHIFT, Tab, cyclenext, prev",

        -- Focus (Vim-like)
        "SUPER, H, movefocus, l",
        "SUPER, L, movefocus, r",
        "SUPER, J, movefocus, d",
        "SUPER, K, movefocus, u",

        -- Move windows
        "SUPER SHIFT, H, movewindow, l",
        "SUPER SHIFT, L, movewindow, r",
        "SUPER SHIFT, J, movewindow, d",
        "SUPER SHIFT, K, movewindow, u",

        -- Resize
        "SUPER CTRL, H, resizeactive, -40 0",
        "SUPER CTRL, L, resizeactive, 40 0",
        "SUPER CTRL, J, resizeactive, 0 40",
        "SUPER CTRL, K, resizeactive, 0 -40",

        -- Misc
        "SUPER, G, togglegroup",
        "SUPER, grave, togglespecialworkspace",
    }

    -- Workspaces (1-9) — dwm style
    for i = 1, 9 do
        table.insert(hyprland.bind, string.format("SUPER, %d, workspace, %d", i, i))
        table.insert(hyprland.bind, string.format("SUPER SHIFT, %d, movetoworkspace, %d", i, i))
    end

    hyprland.bindm = {
        "SUPER, mouse:272, movewindow",
        "SUPER, mouse:273, resizewindow",
    }
end
