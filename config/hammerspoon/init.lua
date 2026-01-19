
hs.window.animationDuration = 0 -- disable animations
hs.loadSpoon("SpoonInstall")

-- Manually downloaded
ActiveSpace = hs.loadSpoon("ActiveSpace")
ActiveSpace.compact = true
ActiveSpace:start()

local function initPaperWM(PaperWM)
  -- Apps
  PaperWM.window_filter:rejectApp("Karabiner-Elements")
  PaperWM.window_filter:rejectApp("Zoom Workplace")

  -- Displays
  local allScreens = hs.screen.allScreens()
  if #allScreens == 1 then
    PaperWM.window_filter:setDefaultFilter()
    return
  end

  local screens = {}

  for _, screen in ipairs(allScreens) do
    local name = screen:name()
    local builtIn = name:find("^Built%-in") ~= nil

    if not builtIn then
      table.insert(screens, screen:id())
      print("using screen: " .. name)
    else
      print("skipping: " .. name)
    end
  end

  PaperWM.window_filter:setScreens(screens)
end

local function watchDisplays()
  local PaperWM = hs.loadSpoon("PaperWM")
  setDisplays(PaperWM)
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
      window_ratios = { 1/3, 1/2, 2/3 },

      swipe_fingers = 4,
      swipe_gain = 1.0,

      drag_window = { "cmd", "alt" },
      lift_window = { "cmd", "alt", "shift" }
    },
    start = true,
    hotkeys = {
      -- Try to keep it similar with Niri config in Linux
      -- Hyper = Mod (Linux) / f19 (Mac)
      -- Focus: Hyper + h/j/k/l
      -- Move Window: Hyper + Shift + h/j/k/l
      -- Switch Workspace: Hyper + 1-9
      -- Move Window to Workspace: Hyper + Shift + 1-9
      -- Cycle Width: Hyper + R
      -- Center: Hyper + C
      -- Focus (Hyper + h/j/k/l)
      focus_left  = {{"cmd", "alt"}, "h"},
      focus_right = {{"cmd", "alt"}, "l"},
      focus_prev  = {{"cmd", "alt"}, "k"}, -- Up/Prev
      focus_next  = {{"cmd", "alt"}, "j"}, -- Down/Next
  
      -- Move Window (Hyper + Shift + h/j/k/l)
      swap_left  = {{"cmd", "alt", "shift"}, "h"},
      swap_right = {{"cmd", "alt", "shift"}, "l"},
      swap_up    = {{"cmd", "alt", "shift"}, "k"},
      swap_down  = {{"cmd", "alt", "shift"}, "j"},
  
      -- Resizing
      -- REMOVED: increase_width on "l" (Conflicts with focus_right)
      -- REMOVED: decrease_width on "h" (Conflicts with focus_left)
      cycle_width          = {{"cmd", "alt"}, "r"},
      cycle_height         = {{"cmd", "alt", "shift"}, "r"},
  
      -- increase/decrease width
      increase_width = {{"cmd", "alt", "shift"}, "="},  -- + sign
      decrease_width = {{"cmd", "alt"}, "-"},
      
      -- Utility
      center_window        = {{"cmd", "alt"}, "c"},
      full_width           = {{"cmd", "alt"}, "f"}, -- Maximize equivalent
      
      -- Slurp/Barf 
      -- Mapped to brackets to match Niri
      slurp_in             = {{"cmd", "alt"}, "["}, 
      barf_out             = {{"cmd", "alt"}, "]"},
  
      -- Workspaces (Hyper + #)
      switch_space_1 = {{"cmd", "alt"}, "1"},
      switch_space_2 = {{"cmd", "alt"}, "2"},
      switch_space_3 = {{"cmd", "alt"}, "3"},
      switch_space_4 = {{"cmd", "alt"}, "4"},
      switch_space_5 = {{"cmd", "alt"}, "5"},
      switch_space_6 = {{"cmd", "alt"}, "6"},
      switch_space_7 = {{"cmd", "alt"}, "7"},
      switch_space_8 = {{"cmd", "alt"}, "8"},
      switch_space_9 = {{"cmd", "alt"}, "9"},
  
      -- Move Window to Workspace (Hyper + Shift + #)
      -- Note: Ensure "move_window_X" is supported in your specific spoon version
      -- otherwise these map to native space moving
      move_window_1 = {{"cmd", "alt", "shift"}, "1"},
      move_window_2 = {{"cmd", "alt", "shift"}, "2"},
      move_window_3 = {{"cmd", "alt", "shift"}, "3"},
      move_window_4 = {{"cmd", "alt", "shift"}, "4"},
      move_window_5 = {{"cmd", "alt", "shift"}, "5"},
      move_window_6 = {{"cmd", "alt", "shift"}, "6"},
      move_window_7 = {{"cmd", "alt", "shift"}, "7"},
      move_window_8 = {{"cmd", "alt", "shift"}, "8"},
      move_window_9 = {{"cmd", "alt", "shift"}, "9"},

      -- move the focused window into / out of the tiling layer
      toggle_floating = {{"cmd", "alt"}, "v"},
      -- raise all floating windows on top of tiled windows
      focus_floating  = {{"cmd", "alt", "shift"}, "v"},
    }
})
