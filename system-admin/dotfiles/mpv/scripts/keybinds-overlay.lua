-- keybinds-overlay.lua
-- Nord Themed Grid Overlay with Stats Toggle and Menu

local help_visible = false

local help_content = {
    {
        category = "NAVIGATION",
        binds = {
            {key = "Space", desc = "Play / Pause"},
            {key = "Left/Right", desc = "Seek 5s"},
            {key = "Up/Down", desc = "Volume +/-"},
            {key = "PgUp/PgDn", desc = "Next/Prev Chapter"},
            {key = "i / I", desc = "Stats (Show / Toggle)"},
            {key = "q", desc = "Stop Video & Browse"},
            {key = "Shift+q", desc = "Quit Player"},
        }
    },
    {
        category = "QUALITY & MENUS",
        binds = {
            {key = "m", desc = "Tracks Menu (Audio/Sub)"},
            {key = "Ctrl+o", desc = "File Browser (Browse)"},
            {key = "Shift+Enter", desc = "Playlist Manager"},
            {key = "Ctrl+f", desc = "Video Qual (Stream/YT)"},
            {key = "Alt+f", desc = "Audio Qual (Stream/YT)"},
            {key = "k / j", desc = "Subtitle Size +/-"},
            {key = "s / S", desc = "Screenshot (w/o subs)"},
        }
    },
    {
        category = "ASPECT & ZOOM",
        binds = {
            {key = "A", desc = "Cycle Aspect Ratio"},
            {key = "E", desc = "Fill 16:9 (Zoom In)"},
            {key = "W", desc = "Reset Zoom (1:1)"},
            {key = "w / e", desc = "Manual PanScan +/-"},
            {key = "Ctrl+1-7", desc = "Toggle Shaders"},
            {key = "Ctrl+0", desc = "Show Active Shaders"},
            {key = "h", desc = "Toggle this guide"},
        }
    }
}

function generate_ass()
    local ass = ""

    -- Nord Color Palette (BGR format for ASS)
    local nord_blue  = "&HC1A181&" -- #81a1c1 (Nord9)
    local nord_gray  = "&HE9DED8&" -- #d8dee9 (Nord4)
    local nord_white = "&HF4EFEC&" -- #eceff4 (Nord6)
    local nord_base  = "&H332924&" -- #242933 (Custom Dark)

    -- Formatting constants for 1920x1080 canvas
    local header_style = "{\\b1\\fs45\\c" .. nord_blue .. "\\3c" .. nord_base .. "\\bord2\\an7}"
    local key_style    = "{\\b1\\fs28\\c" .. nord_white .. "\\3c" .. nord_base .. "\\bord1.5\\an7}"
    local desc_style   = "{\\b0\\fs28\\c" .. nord_gray .. "\\3c" .. nord_base .. "\\bord1.5\\an7}"

    for c, cat in ipairs(help_content) do
        -- Column positions on 1920x1080 canvas
        local x = (c - 1) * 620 + 80
        local y = 100

        -- Draw Header
        ass = ass .. "{\\pos(" .. x .. "," .. y .. ")}" .. header_style .. cat.category .. "\n"

        y = y + 70
        for _, bind in ipairs(cat.binds) do
            ass = ass .. "{\\pos(" .. x .. "," .. y .. ")}"
                      .. key_style .. bind.key
                      .. desc_style .. ": " .. bind.desc .. "\n"
            y = y + 45
        end
    end

    return ass
end

local overlay = mp.create_osd_overlay("ass-events")
-- Fixed virtual canvas
overlay.res_x = 1920
overlay.res_y = 1080

function toggle_help()
    if help_visible then
        overlay:remove()
        help_visible = false
    else
        overlay.data = generate_ass()
        overlay:update()
        help_visible = true
    end
end

mp.add_key_binding("h", "toggle", toggle_help)
