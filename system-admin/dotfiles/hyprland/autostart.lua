return function(script)
    hyprland.exec_once = {
        "xset s off && xset s noblank && xset -dpms",
        "dbus-update-activation-environment --systemd --all",
        "/usr/lib/mate-polkit/polkit-mate-authentication-agent-1",
        "dunst",
        "picom --vsync --animations -b",
        "flameshot",
        script("wallpapersSS"),
        script("status"),
        "slstatus",
        "alacritty -e tmux",
    }
end
