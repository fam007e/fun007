-- =============================================
-- Hyprland Lua Config — Nordic-Darker (dwm-inspired)
-- =============================================

local home = os.getenv("HOME")

local function script(name)
    return home .. "/dwm/scripts/" .. name
end

-- Load theme first
local theme = require("theme")

-- Load modules (pass dependencies where needed)
require("options")(theme)
require("autostart")(script)
require("rules")()
require("binds")(script)

print("✅ Nordic-Darker Hyprland Lua config loaded successfully!")
