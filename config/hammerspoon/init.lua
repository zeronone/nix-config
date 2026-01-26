
local hyper = {"cmd", "alt"}
local hyperctrl = {"cmd", "alt", "ctrl"}
local hypershift = {"cmd", "alt", "shift"}
local hypershiftctrl = {"cmd", "alt", "ctrl", "shift"}


hs.window.animationDuration = 0 -- disable animations
hs.loadSpoon("SpoonInstall")

---------------------------------
-- Helper Function: Issue #135 Fix
-- Moves window to a specific display and registers it with PaperWM
---------------------------------
local function moveWindowToDisplay(direction)
    local PaperWM = hs.loadSpoon("PaperWM")
    local win = hs.window.focusedWindow()
    if not win then return end

    local screen = win:screen()
    local nextScreen = nil

    if direction == "West" then
        nextScreen = screen:toWest()
    elseif direction == "East" then
        nextScreen = screen:toEast()
    elseif direction == "North" then
        nextScreen = screen:toNorth()
    elseif direction == "South" then
        nextScreen = screen:toSouth()
    end

    if nextScreen then
        -- Detach from current PaperWM strip
        if PaperWM.window_list[win:id()] then
            PaperWM.window_filter:allowWindow(win) -- ensure it's tracked
        end
        
        -- Move using standard HS API
        win:moveToScreen(nextScreen)
        
        -- Re-register with PaperWM on the new screen
        -- A short delay ensures the move completes before PaperWM grabs it
        hs.timer.doAfter(0.1, function()
            PaperWM:addWindow(win)
            win:focus()
        end)
    end
end

---------------------------------
-- Windows
---------------------------------

-- ActiveSpace (Optional if strictly no workspaces, but harmless to keep for focus)
ActiveSpace = hs.loadSpoon("ActiveSpace")
ActiveSpace.compact = true
ActiveSpace:start()

-- MouseFollowsFocus
MouseFollowsFocus = hs.loadSpoon("MouseFollowsFocus")
MouseFollowsFocus:start()

local function initPaperWM(PaperWM)
    -- Apps to Ignore
    PaperWM.window_filter:rejectApp("Karabiner-Elements")
    PaperWM.window_filter:rejectApp("Zoom Workplace")
    PaperWM.window_filter:rejectApp("Finder")
    PaperWM.window_filter:rejectApp("System Settings")
    PaperWM.window_filter:rejectApp("Activity Monitor")

    -- Display Logic
    local allScreens = hs.screen.allScreens()
    if #allScreens == 1 then
        PaperWM.window_filter:setScreens({})
        return
    end

    local screens = {}
    for _, screen in ipairs(allScreens) do
        local name = screen:name()
        if not name:find("^DELL") then
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
        window_gap = 2,
        center_mouse = true,
        window_ratios = { 1/3, 1/2, 2/3, 1 },
        
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
        -- Removed j/k swap

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

---------------------------------
-- Manual Bindings (Monitors & Custom Logic)
---------------------------------

-- 1. Monitor Focus (Mod + Arrows)
hs.hotkey.bind(hyper, "left", function() 
    hs.focus(); hs.window.filter.defaultCurrentSpace:focusScreenWest() 
end)
hs.hotkey.bind(hyper, "right", function() 
    hs.focus(); hs.window.filter.defaultCurrentSpace:focusScreenEast() 
end)
hs.hotkey.bind(hyper, "up", function() 
    hs.focus(); hs.window.filter.defaultCurrentSpace:focusScreenNorth() 
end)
hs.hotkey.bind(hyper, "down", function() 
    hs.focus(); hs.window.filter.defaultCurrentSpace:focusScreenSouth() 
end)

-- 2. Move Window to Monitor (Mod + Ctrl + Arrows)
-- Uses the Issue #135 logic defined at the top
hs.hotkey.bind(hyperctrl, "left", function() moveWindowToDisplay("West") end)
hs.hotkey.bind(hyperctrl, "right", function() moveWindowToDisplay("East") end)
hs.hotkey.bind(hyperctrl, "up", function() moveWindowToDisplay("North") end)
hs.hotkey.bind(hyperctrl, "down", function() moveWindowToDisplay("South") end)

-- 3. App Launcher (Matches Niri Mod+Space)
-- Note: Requires an external launcher or use Spotlight
hs.hotkey.bind(hyper, "space", function() hs.application.launchOrFocus("Raycast") end)
