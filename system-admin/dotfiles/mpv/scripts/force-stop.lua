-- force-stop.lua
-- Forces 'q' to stop the video and open the browser, overriding any other potential bindings

function handle_q()
    -- Explicitly ensure the player stays open
    mp.set_property("idle", "yes")
    mp.command("stop")
    mp.command("script-binding file_browser/open-browser")
end

-- Use 'forced' binding to ensure it works in all modes and overrides input.conf conflicts
mp.add_forced_key_binding("q", "force-stop-and-browse", handle_q)
