-- theme.lua — Matches your dwm config.def.h

local theme = {}

theme.normbg     = "rgb(242933)"   -- #242933
theme.normfg     = "rgb(d8dee9)"
theme.normborder = "rgb(434c5e)"

theme.selbg      = "rgb(3b4252)"
theme.selfg      = "rgb(eceff4)"
theme.selborder  = "rgb(81a1c1)"   -- Frost accent

theme.black   = "rgb(2e3440)"
theme.red     = "rgb(bf616a)"
theme.green   = "rgb(a3be8c)"
theme.yellow  = "rgb(ebcb8b)"
theme.blue    = "rgb(81a1c1)"
theme.magenta = "rgb(b48ead)"
theme.cyan    = "rgb(88c0d0)"
theme.white   = "rgb(eceff4)"

theme.accent  = theme.selborder
theme.bg      = theme.normbg
theme.fg      = theme.normfg

return theme
