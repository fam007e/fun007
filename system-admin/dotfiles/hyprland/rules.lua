-- rules.lua
return function()
    hyprland.windowrule = {
        "float, title:^(Event Tester)$",
        "float, class:^(Rofi|Lxappearance|pavucontrol|blueman-manager)$",
        "float, title:^(Volume Control|Picture-in-Picture)$",
        "size 800 600, title:^(Volume Control)$",
        "idleinhibit focus, class:^(mpv)$",
        "idleinhibit fullscreen, class:^(firefox)$",
        "animation none, class:^(Rofi)$",
    }
end
