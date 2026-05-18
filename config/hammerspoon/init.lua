
local hyper = {"cmd", "alt"}
local hyperctrl = {"cmd", "alt", "ctrl"}
local hypershift = {"cmd", "alt", "shift"}
local hypershiftctrl = {"cmd", "alt", "ctrl", "shift"}


hs.window.animationDuration = 0 -- disable animations
hs.loadSpoon("SpoonInstall")

---------------------------------
-- Windows
---------------------------------

-- ActiveSpace (Optional if strictly no workspaces, but harmless to keep for focus)
spoon.SpoonInstall:andUse("ActiveSpace", {
    start = true,
    config = {
        compact = true
    }
})

-- MouseFollowsFocus
if hs.loadSpoon("MouseFollowsFocus") then
    MouseFollowsFocus = spoon.MouseFollowsFocus
    MouseFollowsFocus:start()
else
    print("Warning: MouseFollowsFocus Spoon could not be loaded.")
end

local function initPaperWM(PaperWM)
    -- Only tile standard windows (filters out dialogs, sheets, file pickers, etc.)
    PaperWM.window_filter:setDefaultFilter({ allowRoles = "AXStandardWindow" })

    -- Apps to Ignore
    PaperWM.window_filter:rejectApp("Karabiner-Elements")
    PaperWM.window_filter:rejectApp("Zoom Workplace")
    PaperWM.window_filter:rejectApp("Finder")
    PaperWM.window_filter:rejectApp("System Settings")
    PaperWM.window_filter:rejectApp("Activity Monitor")
    PaperWM.window_filter:rejectApp("DevTools")
    PaperWM.window_filter:rejectApp("qemu-system-aarch64")

    -- Display Logic
    local allScreens = hs.screen.allScreens()
    if #allScreens == 1 then
        PaperWM.window_filter:setScreens({})
        return
    end

    local screens = {}
    for _, screen in ipairs(allScreens) do
        local name = screen:name()
        if name:find("^LG") then
            table.insert(screens, screen:id())
        end
    end
    PaperWM.window_filter:setScreens(screens)
end

local function watchDisplays()
    local PaperWM = hs.loadSpoon("PaperWM")
    initPaperWM(PaperWM)
    PaperWM:start()
end

local screenWatcher = hs.screen.watcher.new(watchDisplays)
screenWatcher:start()

-- SpoonInstall
spoon.SpoonInstall.repos.PaperWM = {
    url = "https://github.com/mogenson/PaperWM.spoon",
    desc = "PaperWM.spoon repository",
    branch = "release",
}

spoon.SpoonInstall:andUse("PaperWM", {
    repo = "PaperWM",
    fn = initPaperWM,
    config = {
        screen_margin = 16,
        window_gap = 4,
        center_mouse = true,
        window_ratios = { 1/3, 1/2, 2/3, 0.9, 1 },
        
        -- Niri-style "Move" = Ctrl
        drag_window = hyperctrl,
        lift_window = hypershift
    },
    start = true,
    hotkeys = {
        --------------------------------------------------
        -- CONVENTIONS
        -- Mod   = cmd + alt
        -- Move  = Mod + ctrl
        -- Size  = Mod + shift
        -- Monitor = Mod + Arrows
        --------------------------------------------------

        -- --- FOCUS (H/L only, no J/K) ---
        focus_left  = {hyper, "h"},
        focus_right = {hyper, "l"},
        -- Removed j/k because "Columns are single windows" (1D strip)

        -- --- MOVE WINDOW IN STRIP (Mod + Ctrl + H/L) ---
        swap_left  = {hyperctrl, "h"},
        swap_right = {hyperctrl, "l"},

        -- --- MOVE WINDOW TO MONITOR ---
        move_window_l        = { hyperctrl, "left" },
        move_window_r        = { hyperctrl, "right" },
        move_window_u        = { hyperctrl, "up" },
        move_window_d        = { hyperctrl, "down" },

        -- --- MONITOR FOCUS (Mod + Arrows) ---
        -- PaperWM doesn't have native monitor focus keys in the map,
        -- so we rely on the manual binds below or HS defaults.
        -- We leave this empty here to avoid conflicts and define manually below.

        -- --- SIZING (Mod + Shift) ---
        cycle_width      = {hyper, "r"},
        -- Height cycle removed if columns are single windows (usually implies full height)
        
        -- Finer adjustments
        increase_width = {hyper, "="}, 
        decrease_width = {hyper, "-"},
        
        -- --- UTILITY ---
        center_window    = {hyper, "c"},
        full_width       = {hyper, "f"}, -- Maximize
        
        -- --- SLURP / BARF (Brackets) ---
        slurp_in         = {hyper, "["}, 
        barf_out         = {hyper, "]"},

        -- --- FLOATING ---
        toggle_floating = {hyper, "v"},
        focus_floating  = {hypershift, "v"},
    }
})

-- App Launcher (Matches Niri Mod+Space)
-- Note: Requires an external launcher or use Spotlight
hs.hotkey.bind(hyper, "space", function() hs.application.launchOrFocus("Spotlight") end)
