{
  pkgs,
  # In flake.nix it is configured with pkgs-unstable
  pkgs-unstable,
  lib,
  flake-inputs,
  ...
}:
let
  # ── Keymap helpers ──────────────────────────────────────────────
  mkKeymap = mode: key: action: desc: {
    inherit mode key action;
    options = {
      silent = true;
      inherit desc;
    };
  };
  mkN = mkKeymap "n";
  mkNX =
    key: action: desc:
    mkKeymap [ "n" "x" ] key action desc;
  mkLua = mode: key: lua: desc: {
    inherit mode key;
    action.__raw = lua;
    options = {
      silent = true;
      inherit desc;
    };
  };
  mkNLua = mkLua "n";
in
{
  imports = [
    flake-inputs.nixvim.homeModules.nixvim
  ];

  # Other dependencies
  home.packages = with pkgs; [
    unzip
  ];

  programs.nixvim = {
    enable = true;
    # Use pkgs-unstable (has allowUnfree) for nixvim's package resolution
    nixpkgs.pkgs = pkgs-unstable;
    viAlias = true;
    vimAlias = true;
    defaultEditor = true;
    waylandSupport = lib.mkIf pkgs-unstable.stdenv.hostPlatform.isLinux true;

    extraPlugins = with pkgs-unstable.vimPlugins; [
      vim-nix
      (pkgs-unstable.vimUtils.buildVimPlugin {
        name = "output-panel.nvim";
        src = pkgs-unstable.fetchFromGitHub {
          owner = "mhanberg";
          repo = "output-panel.nvim";
          rev = "a600798";
          hash = "sha256-OONTXn0+MB+nj+piFW4Lb6Sne7dG4MhXLwl0hhl9aeY=";
        };
      })
      (pkgs-unstable.vimUtils.buildVimPlugin {
        name = "spring-boot.nvim";
        src = pkgs-unstable.fetchFromGitHub {
          owner = "JavaHello";
          repo = "spring-boot.nvim";
          rev = "main";
          hash = "sha256-ioGlxjZIqtNlPedwI/HX3xA3HOWJ50WmWFyYIQPHDrg=";
        };
      })
    ];

    extraConfigLua = ''
      require("output_panel").setup({ max_buffer_size = 10000 })

      -- Better defaults
      vim.diagnostic.config({
        virtual_text = {
          severity = {
            min = vim.diagnostic.severity.ERROR,
          },
        },
        severity_sort = true,
        float = {
          border = "rounded", -- 'single', 'double', 'shadow', etc.
          header = "Diagnostics:", -- Header text
          prefix = "● ", -- Prefix for each line
          scope = "cursor", -- Show diagnostics for 'cursor' or 'line'
          focusable = true, -- Allow focusing the window
          source = "always",
          close_events = { "CursorMoved", "BufLeave", "WinLeave", "InsertEnter" }
        },
      })
      -- automatically show diagnostic in float win for current line
      vim.api.nvim_create_autocmd("CursorHold", {
        pattern = "*",
        callback = function()
          if vim.diagnostic.get(0) == 0 then
            return
          end

          if not vim.b.diagnostics_pos then
            vim.b.diagnostics_pos = { nil, nil }
          end

          local cursor_pos = api.nvim_win_get_cursor(0)

          if not vim.deep_equal(cursor_pos, vim.b.diagnostics_pos) then
            diagnostic.open_float {}
          end

          vim.b.diagnostics_pos = cursor_pos
        end,
      })

      -- Rotate between verbosity
      _G.diagnostic_vt_state = 0 -- 0: Errors, 1: All, 2: Off
      function _G.cycle_diagnostic_vt()
        _G.diagnostic_vt_state = (_G.diagnostic_vt_state + 1) % 3
        local state = _G.diagnostic_vt_state

        if state == 0 then
          vim.diagnostic.config({ virtual_text = { severity = { min = vim.diagnostic.severity.ERROR } } })
          vim.notify("Diagnostics: Errors Only")
        elseif state == 1 then
          vim.diagnostic.config({ virtual_text = true })
          vim.notify("Diagnostics: All")
        else
          vim.diagnostic.config({ virtual_text = false })
          vim.notify("Diagnostics: Virtual Text Off")
        end
      end

      -- Match float border background with the float background
      vim.api.nvim_set_hl(0, "FloatBorder", { link = "NormalFloat" })

      -- Make window separators visually distinct
      vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#fc9867", bold = true })
      vim.opt.fillchars:append({ vert = "▊", horiz = "▄", horizup = "▊", horizdown = "▊", vertleft = "▊", vertright = "▊", verthoriz = "▊" })

      -- Disable macros
      vim.keymap.set('n', 'q', '<Nop>', { noremap = true, silent = true, desc = 'Disable q key' })

      -- Show underscore lines
      vim.opt.guicursor = ""

      -- Suppress inlay hint 'col out of range' errors (Neovim 0.11 bug with completion)
      -- Only targets the inlay_hint namespace to avoid masking errors in other plugins
      local ih_ns = vim.api.nvim_get_namespaces()["nvim.lsp.inlayhint"] or -1
      local orig_set_extmark = vim.api.nvim_buf_set_extmark
      vim.api.nvim_buf_set_extmark = function(buf, ns, line, col, opts)
        if ns == ih_ns then
          local ok, result = pcall(orig_set_extmark, buf, ns, line, col, opts)
          if ok then return result end
          return 0
        end
        return orig_set_extmark(buf, ns, line, col, opts)
      end

      -- Trouble integration with Snacks picker (<a-t> to send results to Trouble)
      Snacks.config.picker.actions.trouble_open = function(...)
        return require("trouble.sources.snacks").actions.trouble_open.action(...)
      end

      -- Snacks explorer default colors are too dim
      vim.api.nvim_set_hl(0, "SnacksPickerDir", { link = "Text" })
      vim.api.nvim_set_hl(0, "SnacksPickerDirectory", { link = "Text" })
      vim.api.nvim_set_hl(0, "SnacksPickerPathHidden", { link = "Text" })
      vim.api.nvim_set_hl(0, "SnacksPickerPathIgnored", { link = "Text" })
      vim.api.nvim_set_hl(0, "SnacksPickerGitStatusUntracked", { link = "Text" })
      vim.api.nvim_set_hl(0, "SnacksPickerGitStatusIgnored", { link = "Text" })

      -- Dot-repeatable window resize helpers (step 10)
      -- Uses operatorfunc so that pressing "." repeats the last resize
      local function make_resize_op(cmd)
        return function()
          vim.cmd(cmd)
          vim.cmd("stopinsert")
        end
      end
      _G._resize_h_inc = make_resize_op("resize +10")
      _G._resize_h_dec = make_resize_op("resize -10")
      _G._resize_w_dec = make_resize_op("vertical resize -10")
      _G._resize_w_inc = make_resize_op("vertical resize +10")
    '';

    opts = {
      mouse = "a";
      smoothscroll = true;
      number = true; # Show line numbers
      relativenumber = true; # Show relative line numbers
      shiftwidth = 2; # Tab width should be 2
      expandtab = true;

      # Confirm before quitting
      confirm = true;

      # case-insensitive search
      ignorecase = true;
      smartcase = true;
    };

    keymaps = [
      # ── Personal: start/end of line ──
      {
        mode = [
          ""
          "l"
          "i"
        ];
        key = "<c-e>";
        action = "<Esc>$";
        options = {
          noremap = true;
          silent = true;
        };
      }
      {
        mode = [
          ""
          "l"
          "i"
        ];
        key = "<c-a>";
        action = "<Esc>^";
        options = {
          noremap = true;
          silent = true;
        };
      }

      # ── General ──
      (mkKeymap [ "i" "x" "n" "s" ] "<C-s>" "<cmd>w<cr><esc>" "Save File")
      (mkKeymap [ "i" "n" ] "<esc>" "<cmd>noh<cr><esc>" "Escape and Clear hlsearch")
      (mkN "<leader>qq" "<cmd>qa<cr>" "Quit All")
      (mkN "<leader>fn" "<cmd>enew<cr>" "New File")
      (mkN "<leader>xl" "<cmd>lopen<cr>" "Location List")
      (mkN "<leader>xq" "<cmd>copen<cr>" "Quickfix List")
      (mkN "[q" "<cmd>cprev<cr>" "Previous Quickfix")
      (mkN "]q" "<cmd>cnext<cr>" "Next Quickfix")

      # ── Buffer Navigation ──
      (mkN "<S-h>" "<cmd>bprevious<cr>" "Prev Buffer")
      (mkN "<S-l>" "<cmd>bnext<cr>" "Next Buffer")
      (mkN "[b" "<cmd>bprevious<cr>" "Prev Buffer")
      (mkN "]b" "<cmd>bnext<cr>" "Next Buffer")
      (mkNLua "<leader>bb" ''function() vim.cmd("e #") end'' "Switch to Other Buffer")
      (mkNLua "<leader>bd" "function() Snacks.bufdelete() end" "Delete Buffer")
      (mkNLua "<leader>bo" "function() Snacks.bufdelete.other() end" "Delete Other Buffers")
      (mkNLua "<leader>bD" ''
        function()
          Snacks.bufdelete()
          vim.cmd("close")
        end
      '' "Delete Buffer and Window")

      # ── Window Navigation (handled by tmux-navigator) ──

      # ── Window Splits (tmux-style) ──
      (mkN "<leader>w\"" "<C-w>s" "Split Window Below")
      (mkN "<leader>w%" "<C-w>v" "Split Window Right")
      (mkN "<leader>wd" "<C-w>c" "Delete Window")

      # ── Resize Windows (dot-repeatable, step 10) ──
      # Uses operatorfunc + g@l so "." repeats the last resize
      # stopinsert prevents terminal windows from entering insert/terminal mode
      (mkNLua "<leader>w+"
        "function() vim.o.operatorfunc = 'v:lua._resize_h_inc' vim.api.nvim_feedkeys('g@l', 'n', false) end"
        "Increase Window Height"
      )
      (mkNLua "<leader>w-"
        "function() vim.o.operatorfunc = 'v:lua._resize_h_dec' vim.api.nvim_feedkeys('g@l', 'n', false) end"
        "Decrease Window Height"
      )
      (mkNLua "<leader>w<"
        "function() vim.o.operatorfunc = 'v:lua._resize_w_dec' vim.api.nvim_feedkeys('g@l', 'n', false) end"
        "Decrease Window Width"
      )
      (mkNLua "<leader>w>"
        "function() vim.o.operatorfunc = 'v:lua._resize_w_inc' vim.api.nvim_feedkeys('g@l', 'n', false) end"
        "Increase Window Width"
      )

      # ── Tabs ──
      (mkN "<leader><tab>l" "<cmd>tablast<cr>" "Last Tab")
      (mkN "<leader><tab>o" "<cmd>tabonly<cr>" "Close Other Tabs")
      (mkN "<leader><tab>f" "<cmd>tabfirst<cr>" "First Tab")
      (mkN "<leader><tab><tab>" "<cmd>tabnew<cr>" "New Tab")
      (mkN "<leader><tab>]" "<cmd>tabnext<cr>" "Next Tab")
      (mkN "<leader><tab>d" "<cmd>tabclose<cr>" "Close Tab")
      (mkN "<leader><tab>[" "<cmd>tabprevious<cr>" "Previous Tab")

      # ── Diagnostics Navigation ──
      (mkNLua "]d" "function() vim.diagnostic.jump({ count = 1 }) end" "Next Diagnostic")
      (mkNLua "[d" "function() vim.diagnostic.jump({ count = -1 }) end" "Prev Diagnostic")
      (mkNLua "]e"
        "function() vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR }) end"
        "Next Error"
      )
      (mkNLua "[e"
        "function() vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR }) end"
        "Prev Error"
      )
      (mkNLua "]w"
        "function() vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.WARN }) end"
        "Next Warning"
      )
      (mkNLua "[w"
        "function() vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.WARN }) end"
        "Prev Warning"
      )
      (mkNLua "<leader>x<tab>" "function() _G.cycle_diagnostic_vt() end" "Cycle Diagnostic Text")

      # ── Trouble (LazyVim layout) ──
      (mkN "<leader>xx" "<cmd>Trouble diagnostics toggle<cr>" "Diagnostics (Trouble)")
      (mkN "<leader>xX" "<cmd>Trouble diagnostics toggle filter.buf=0<cr>" "Buffer Diagnostics (Trouble)")
      (mkN "<leader>cs" "<cmd>Trouble symbols toggle<cr>" "Symbols (Trouble)")
      (mkN "<leader>cS" "<cmd>Trouble lsp toggle<cr>" "LSP references/definitions/... (Trouble)")
      (mkN "<leader>xL" "<cmd>Trouble loclist toggle<cr>" "Location List (Trouble)")
      (mkN "<leader>xQ" "<cmd>Trouble qflist toggle<cr>" "Quickfix List (Trouble)")

      # ── Explorer (Snacks — replaces Neo-tree) ──
      (mkNLua "<leader>e" "function() Snacks.explorer() end" "Explorer (Root)")
      (mkNLua "<leader>E" "function() Snacks.explorer({ cwd = vim.fn.expand('%:p:h') }) end"
        "Explorer (cwd)"
      )

      # ── Terminal (Snacks) ──
      (mkNLua "<leader>ft" "function() Snacks.terminal() end" "Terminal (Root)")
      (mkNLua "<leader>fT" ''
        function() Snacks.terminal(nil, { cwd = vim.fn.expand("%:p:h") }) end
      '' "Terminal (cwd)")
      (mkLua [ "n" "t" ] "<c-/>" "function() Snacks.terminal() end" "Terminal (Root)")

      # ── Terminal keymaps ──
      # Esc returns to normal mode instead of being sent to the terminal
      (mkKeymap "t" "<Esc>" "<C-\\><C-n>" "Exit Terminal Mode")
      # Send a literal Esc to the terminal (e.g. for sidekick/opencode)
      (mkKeymap "t" "<C-\\><Esc>" "<cmd>lua vim.api.nvim_feedkeys('\\x1b', 'n', true)<cr>"
        "Send Esc to Terminal"
      )
      # Shift+Enter sends the correct escape sequence to the terminal
      (mkKeymap "t" "<S-Enter>" "<cmd>lua vim.api.nvim_feedkeys('\\x1b[13;2u', 'n', true)<cr>"
        "Shift+Enter"
      )

      # ── Toggle (LazyVim layout: <leader>u*) ──
      # Most toggles come from mini-basics with prefix <leader>u
      (mkNLua "<leader>ud" ''
        function()
          vim.diagnostic.enable(not vim.diagnostic.is_enabled())
        end
      '' "Toggle Diagnostics")
      (mkNLua "<leader>uh" ''
        function()
          vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
        end
      '' "Toggle Inlay Hints")
      (mkNLua "<leader>uT" ''
        function()
          if vim.b.ts_highlight then
            vim.treesitter.stop()
          else
            vim.treesitter.start()
          end
        end
      '' "Toggle Treesitter Highlight")

      # ── Code ──
      (mkN "<leader>co" "<cmd>OutputPanel<cr>" "Toggle Output Panel")
      (mkNLua "<leader>cd" "function() vim.diagnostic.open_float() end" "Line Diagnostics")

      # ── LSP (LazyVim layout — via Snacks Picker) ──
      (mkNLua "gd" "function() Snacks.picker.lsp_definitions() end" "Goto Definition")
      (mkNLua "gr" "function() Snacks.picker.lsp_references() end" "References")
      (mkNLua "gI" "function() Snacks.picker.lsp_implementations() end" "Goto Implementation")
      (mkNLua "gy" "function() Snacks.picker.lsp_type_definitions() end" "Goto Type Definition")
      (mkNLua "gD" "function() Snacks.picker.lsp_declarations() end" "Goto Declaration")
      # K for hover/signature help
      (mkNLua "K" "function() vim.lsp.buf.hover() end" "Hover (LSP)")
      (mkNLua "gK" "function() vim.lsp.buf.signature_help() end" "Signature Help")
      (mkNX "<leader>ca" "<cmd>lua vim.lsp.buf.code_action()<cr>" "Code Action")
      (mkNLua "<leader>cc" "function() vim.lsp.codelens.run() end" "Run Codelens")
      (mkNLua "<leader>cC" "function() vim.lsp.codelens.refresh() end" "Refresh Codelens")
      (mkNLua "<leader>cA" ''
        function()
          vim.lsp.buf.code_action({ context = { only = { "source" }, diagnostics = {} } })
        end
      '' "Source Action")

      # ── Rename (inc-rename) ──
      {
        mode = "n";
        key = "<leader>cr";
        action.__raw = ''
          function()
            local inc_rename = require("inc_rename")
            return ":" .. inc_rename.config.cmd_name .. " " .. vim.fn.expand("<cword>")
          end
        '';
        options = {
          expr = true;
          silent = true;
          desc = "Rename (inc-rename)";
        };
      }

      # ── Format (conform) ──
      (mkNX "<leader>cf"
        "<cmd>lua require('conform').format({ timeout_ms = 3000, lsp_format = 'fallback' })<cr>"
        "Format"
      )
      (mkNX "<leader>cF"
        "<cmd>lua require('conform').format({ formatters = { 'injected' }, timeout_ms = 3000 })<cr>"
        "Format Injected Langs"
      )

      # ── Flash ──
      (mkLua [ "n" "x" "o" ] "s" "function() require('flash').jump() end" "Flash")
      (mkLua [ "n" "x" "o" ] "S" "function() require('flash').treesitter() end" "Flash Treesitter")
      (mkLua "o" "r" "function() require('flash').remote() end" "Remote Flash")
      (mkLua [ "o" "x" ] "R" "function() require('flash').treesitter_search() end" "Treesitter Search")
      (mkLua "c" "<c-s>" "function() require('flash').toggle() end" "Toggle Flash Search")

      # ── Todo Comments ──
      (mkNLua "]t" "function() require('todo-comments').jump_next() end" "Next Todo Comment")
      (mkNLua "[t" "function() require('todo-comments').jump_prev() end" "Prev Todo Comment")
      (mkN "<leader>xt" "<cmd>Trouble todo toggle<cr>" "Todo (Trouble)")
      (mkN "<leader>xT" "<cmd>Trouble todo toggle filter = {tag = {TODO,FIX,FIXME}}<cr>"
        "Todo/Fix/Fixme (Trouble)"
      )
      (mkNLua "<leader>st" "function() Snacks.picker.todo_comments() end" "Todo")
      (mkNLua "<leader>sT"
        ''function() Snacks.picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME" } }) end''
        "Todo/Fix/Fixme"
      )

      # ── Grug-far (Search and Replace) ──
      (mkNLua "<leader>sr" ''
        function()
          local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
          require("grug-far").open({
            transient = true,
            prefills = { filesFilter = ext and ext ~= "" and "*." .. ext or nil },
          })
        end
      '' "Search and Replace")

      # ── Yanky ──
      (mkNX "<leader>p" "<cmd>YankyRingHistory<cr>" "Open Yank History")
      {
        mode = [
          "n"
          "x"
        ];
        key = "y";
        action = "<Plug>(YankyYank)";
        options = {
          silent = true;
          desc = "Yank Text";
        };
      }
      {
        mode = [
          "n"
          "x"
        ];
        key = "p";
        action = "<Plug>(YankyPutAfter)";
        options = {
          silent = true;
          desc = "Put Text After Cursor";
        };
      }
      {
        mode = [
          "n"
          "x"
        ];
        key = "P";
        action = "<Plug>(YankyPutBefore)";
        options = {
          silent = true;
          desc = "Put Text Before Cursor";
        };
      }
      (mkN "[y" "<Plug>(YankyCycleForward)" "Cycle Forward Through Yank History")
      (mkN "]y" "<Plug>(YankyCycleBackward)" "Cycle Backward Through Yank History")

      # ── Noice ──
      (mkNLua "<leader>snl" "function() require('noice').cmd('last') end" "Noice Last Message")
      (mkNLua "<leader>snh" "function() require('noice').cmd('history') end" "Noice History")
      (mkNLua "<leader>sna" "function() require('noice').cmd('all') end" "Noice All")
      (mkNLua "<leader>snd" "function() require('noice').cmd('dismiss') end" "Dismiss All")
      (mkNLua "<leader>snt" "function() require('noice').cmd('pick') end" "Noice Picker")
      (mkLua [ "i" "n" "s" ] "<c-f>"
        "function() if not require('noice.lsp').scroll(4) then return '<c-f>' end end"
        "Scroll Forward"
      )
      (mkLua [ "i" "n" "s" ] "<c-b>"
        "function() if not require('noice.lsp').scroll(-4) then return '<c-b>' end end"
        "Scroll Backward"
      )
      (mkN "<leader>un" "<cmd>NoiceDismiss<cr>" "Dismiss All Notifications")

      # ── Snacks: Scratch ──
      (mkNLua "<leader>." "function() Snacks.scratch() end" "Toggle Scratch Buffer")
      (mkNLua "<leader>S" "function() Snacks.scratch.select() end" "Select Scratch Buffer")

      # ── Snacks: Notifier ──
      (mkNLua "<leader>n" "function() Snacks.notifier.show_history() end" "Notification History")

      # ── Snacks: Git ──
      (mkNLua "<leader>gb" "function() Snacks.git.blame_line() end" "Git Blame Line")
      (mkLua [ "n" "x" ] "<leader>gB" "function() Snacks.gitbrowse() end" "Git Browse (open)")
      (mkLua [ "n" "x" ] "<leader>gY" ''
        function()
          Snacks.gitbrowse({ open = function(url) vim.fn.setreg("+", url) end, notify = false })
        end
      '' "Git Browse (copy)")
      # ── Snacks: Git (pickers) ──
      (mkNLua "<leader>gc" "function() Snacks.picker.git_log() end" "Git Commits")
      (mkNLua "<leader>gs" "function() Snacks.picker.git_status() end" "Git Status")
      (mkNLua "<leader>gS" "function() Snacks.picker.git_stash() end" "Git Stash")
      (mkNLua "<leader>gd" "function() Snacks.picker.git_diff() end" "Git Diff")
      (mkNLua "<leader>gf" "function() Snacks.picker.git_log_file() end" "Git Log (File)")

      # ── Snacks: Picker (replaces fzf-lua keymaps) ──
      # Top-level shortcuts
      (mkNLua "<leader><space>" "function() Snacks.picker.files() end" "Find Files (Root)")
      (mkNLua "<leader>/" "function() Snacks.picker.grep() end" "Grep (Root)")
      (mkNLua "<leader>," "function() Snacks.picker.buffers() end" "Buffers")
      (mkNLua "<leader>:" "function() Snacks.picker.command_history() end" "Command History")
      # Find
      (mkNLua "<leader>ff" "function() Snacks.picker.files() end" "Find Files (Root)")
      (mkNLua "<leader>fF" "function() Snacks.picker.files({ cwd = vim.fn.expand('%:p:h') }) end"
        "Find Files (cwd)"
      )
      (mkNLua "<leader>fb" "function() Snacks.picker.buffers() end" "Buffers")
      (mkNLua "<leader>fg" "function() Snacks.picker.git_files() end" "Git Files")
      (mkNLua "<leader>fr" "function() Snacks.picker.recent() end" "Recent Files")
      (mkNLua "<leader>fp" "function() Snacks.picker.projects() end" "Projects")
      # Search
      (mkNLua "<leader>sg" "function() Snacks.picker.grep() end" "Grep (Root)")
      (mkNLua "<leader>sG" "function() Snacks.picker.grep({ cwd = vim.fn.expand('%:p:h') }) end"
        "Grep (cwd)"
      )
      (mkNLua "<leader>sw" "function() Snacks.picker.grep_word() end" "Grep Word (Root)")
      (mkNLua "<leader>sW" "function() Snacks.picker.grep_word({ cwd = vim.fn.expand('%:p:h') }) end"
        "Grep Word (cwd)"
      )
      (mkNLua "<leader>sb" "function() Snacks.picker.lines() end" "Buffer Lines")
      (mkNLua "<leader>sB" "function() Snacks.picker.grep_buffers() end" "Grep Open Buffers")
      (mkNLua "<leader>ss" "function() Snacks.picker.lsp_symbols() end" "LSP Symbols")
      (mkNLua "<leader>sS" "function() Snacks.picker.lsp_workspace_symbols() end" "LSP Workspace Symbols")
      (mkNLua "<leader>sd" "function() Snacks.picker.diagnostics_buffer() end" "Diagnostics (Buffer)")
      (mkNLua "<leader>sD" "function() Snacks.picker.diagnostics() end" "Diagnostics (Workspace)")
      (mkNLua "<leader>sh" "function() Snacks.picker.help() end" "Help Pages")
      (mkNLua "<leader>sk" "function() Snacks.picker.keymaps() end" "Keymaps")
      (mkNLua "<leader>sm" "function() Snacks.picker.marks() end" "Marks")
      (mkNLua "<leader>s\"" "function() Snacks.picker.registers() end" "Registers")
      (mkNLua "<leader>sR" "function() Snacks.picker.resume() end" "Resume Last Picker")
      (mkNLua "<leader>su" "function() Snacks.picker.undo() end" "Undo Tree")
      (mkNLua "<leader>uC" "function() Snacks.picker.colorschemes() end" "Colorschemes")

      # ── Snacks: Toggle ──
      (mkNLua "<leader>uZ" "function() Snacks.toggle.zoom():toggle() end" "Toggle Zoom")
      (mkNLua "<leader>uz" "function() Snacks.toggle.zen():toggle() end" "Toggle Zen Mode")
      (mkNLua "<leader>uD" "function() Snacks.toggle.dim():toggle() end" "Toggle Dim")
      (mkNLua "<leader>ua" "function() Snacks.toggle.animate():toggle() end" "Toggle Animations")
      (mkNLua "<leader>ug" "function() Snacks.toggle.indent():toggle() end" "Toggle Indent Guides")
      (mkNLua "<leader>uS" ''
        function()
          Snacks.toggle({
            name = "Smooth Scroll",
            get = function() return Snacks.scroll.enabled end,
            set = function(state) Snacks.scroll.enabled = state end,
          }):toggle()
        end
      '' "Toggle Smooth Scroll")

      # ── Sidekick (AI) ──
      (mkLua [
        "n"
        "t"
        "i"
        "x"
      ] "<c-.>" "function() require('sidekick.cli').toggle() end" "Sidekick Toggle")
      (mkNLua "<leader>aa" "function() require('sidekick.cli').toggle() end" "Sidekick Toggle CLI")
      (mkNLua "<leader>as" "function() require('sidekick.cli').select() end" "Select CLI")
      (mkNLua "<leader>ad" "function() require('sidekick.cli').close() end" "Detach CLI Session")
      (mkLua [
        "n"
        "x"
      ] "<leader>at" "function() require('sidekick.cli').send({ msg = '{this}' }) end" "Send This")
      (mkNLua "<leader>af" "function() require('sidekick.cli').send({ msg = '{file}' }) end" "Send File")
      (mkLua "x" "<leader>av" "function() require('sidekick.cli').send({ msg = '{selection}' }) end"
        "Send Visual Selection"
      )
      (mkLua [ "n" "x" ] "<leader>ap" "function() require('sidekick.cli').prompt() end" "Select Prompt")

      # ── Neotest ──
      (mkNLua "<leader>tt" "function() require('neotest').run.run() end" "Run Nearest")
      (mkNLua "<leader>tT" "function() require('neotest').run.run(vim.fn.expand('%')) end" "Run File")
      (mkNLua "<leader>tr" "function() require('neotest').run.run_last() end" "Run Last")
      (mkNLua "<leader>ts" "function() require('neotest').summary.toggle() end" "Toggle Summary")
      (mkNLua "<leader>to"
        "function() require('neotest').output.open({ enter = true, auto_close = true }) end"
        "Show Output"
      )
      (mkNLua "<leader>tO" "function() require('neotest').output_panel.toggle() end"
        "Toggle Output Panel"
      )
      (mkNLua "<leader>tS" "function() require('neotest').run.stop() end" "Stop")
      (mkNLua "<leader>tw" "function() require('neotest').watch.toggle(vim.fn.expand('%')) end"
        "Toggle Watch"
      )
      (mkNLua "<leader>td" "function() require('neotest').run.run({ strategy = 'dap' }) end"
        "Debug Nearest"
      )

      # ── Persistence (Session) ──
      (mkNLua "<leader>qs" "function() require('persistence').load() end" "Restore Session")
      (mkNLua "<leader>qS" "function() require('persistence').select() end" "Select Session")
      (mkNLua "<leader>ql" "function() require('persistence').load({ last = true }) end"
        "Restore Last Session"
      )
      (mkNLua "<leader>qd" "function() require('persistence').stop() end" "Don't Save Current Session")

      # ── Neogen (Annotations) ──
      (mkNLua "<leader>cn" "function() require('neogen').generate() end" "Generate Annotations")
    ];

    # Core
    editorconfig.enable = true;
    clipboard.register = "unnamedplus";

    # theme
    colorschemes.monokai-pro = {
      enable = true;
      settings = {
        devicons = true;
        filter = "spectrum";
      };
    };

    # Mini packages
    plugins.mini-ai = {
      enable = true;
      settings = {
        n_lines = 500;
        search_method = "cover_or_nearest";
        # Requires plugins.treesitter-textobjects
        custom_textobjects = {
          f = {
            __raw = "require('mini.ai').gen_spec.treesitter({ a = '@function.outer', i = '@function.inner' })";
          };
          c = {
            __raw = "require('mini.ai').gen_spec.treesitter({ a = '@class.outer', i = '@class.inner' })";
          };
          o = {
            __raw = ''
              require('mini.ai').gen_spec.treesitter({
                a = { '@conditional.outer', '@loop.outer' },
                i = { '@conditional.inner', '@loop.inner' },
              })
            '';
          };
        };
      };
      luaConfig.post = ''
        -- mini-ai
        -- Default van, vin keymappings in mini-ai conflict with lsp mappings
        -- Change lsp mappings to <leader>l[sS]
        local map_lsp_selection = function(lhs, desc)
          local s = vim.startswith(desc, 'Increase') and 1 or -1
          local rhs = function() vim.lsp.buf.selection_range(s * vim.v.count1) end
          vim.keymap.set('x', lhs, rhs, { desc = desc })
        end
        map_lsp_selection('<leader>cls', 'Increase selection')
        map_lsp_selection('<leader>clS', 'Decrease selection')
      '';
    };
    plugins.mini-align.enable = true;
    plugins.mini-comment.enable = true;

    # ── Completion (blink-cmp) ──────────────────────────────────────
    plugins.luasnip.enable = true;
    plugins.blink-ripgrep.enable = true;
    plugins.blink-cmp = {
      enable = true;
      # Inject blink capabilities into all LSP servers (needed for vim.lsp.config)
      luaConfig.post = ''
        vim.lsp.config('*', {
          capabilities = require('blink.cmp').get_lsp_capabilities()
        })
      '';
      settings = {
        # ── Keymap ──
        keymap = {
          preset = "none";
          "<C-space>" = [
            "show"
            "show_documentation"
            "hide_documentation"
          ];
          "<Tab>" = [
            "select_next"
            "snippet_forward"
            "fallback"
          ];
          "<S-Tab>" = [
            "select_prev"
            "snippet_backward"
            "fallback"
          ];
          "<CR>" = [
            "accept"
            "fallback"
          ];
          "<C-u>" = [
            "scroll_documentation_up"
            "fallback"
          ];
          "<C-d>" = [
            "scroll_documentation_down"
            "fallback"
          ];
          "<C-e>" = [
            "hide"
            "fallback"
          ];
          "<C-n>" = [
            "select_next"
            "show"
          ];
          "<C-p>" = [
            "select_prev"
            "show"
          ];
          "<Up>" = [
            "select_prev"
            "fallback"
          ];
          "<Down>" = [
            "select_next"
            "fallback"
          ];
        };

        # ── Completion ──
        completion = {
          list = {
            selection = {
              preselect = true;
              auto_insert = false;
            };
          };

          menu = {
            border = "single";
            winhighlight = "Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection,Search:None";
            draw = {
              padding = [
                1
                1
              ];
              columns = [
                {
                  __unkeyed-1 = "kind_icon";
                }
                {
                  __unkeyed-1 = "label";
                  __unkeyed-2 = "label_description";
                  gap = 1;
                }
                {
                  __unkeyed-1 = "source_name";
                }
              ];
              treesitter = [ "lsp" ];
            };
          };

          documentation = {
            auto_show = true;
            auto_show_delay_ms = 200;
            window = {
              border = "single";
              winhighlight = "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,CursorLine:BlinkCmpDocCursorLine,Search:None";
            };
          };

          ghost_text = {
            enabled = true;
          };
        };

        # ── Signature ──
        signature = {
          enabled = true;
          window = {
            border = "single";
            winhighlight = "Normal:BlinkCmpSignatureHelp,FloatBorder:BlinkCmpSignatureHelpBorder";
          };
        };

        # ── Snippets (LuaSnip) ──
        snippets = {
          preset = "luasnip";
        };

        # ── Sources ──
        sources = {
          default = [
            "lsp"
            "path"
            "snippets"
            "buffer"
            "ripgrep"
          ];
          providers = {
            ripgrep = {
              module = "blink-ripgrep";
              name = "Ripgrep";
              async = true;
              score_offset = -3;
              opts = {
                prefix_min_len = 3;
                context_size = 5;
                max_filesize = "1M";
                search_casing = "--ignore-case";
              };
            };
          };
        };

        # ── Cmdline ──
        cmdline = {
          enabled = true;
          keymap = {
            preset = "cmdline";
          };
          sources = [
            "cmdline"
          ];
          completion = {
            menu = {
              auto_show = true;
            };
            list = {
              selection = {
                preselect = true;
                auto_insert = true;
              };
            };
            ghost_text = {
              enabled = true;
            };
          };
        };

        # ── Fuzzy (prefer Rust implementation) ──
        fuzzy = {
          implementation = "prefer_rust";
          prebuilt_binaries = {
            download = false;
          };
        };

        # ── Appearance ──
        appearance = {
          use_nvim_cmp_as_default = false;
          nerd_font_variant = "mono";
        };
      };
    };

    plugins.mini-keymap = {
      enable = true;
      luaConfig.post = ''
        local map_multistep = require('mini.keymap').map_multistep
        map_multistep('i', '<BS>',    { 'minipairs_bs' })
      '';
    };
    plugins.mini-move = {
      enable = true;
      settings = {
        mappings = {
          # visual mode
          down = "<C-j>";
          left = "<C-h>";
          right = "<C-l>";
          up = "<C-k>";

          # normal mode (disabled)
          line_down = "";
          line_left = "";
          line_right = "";
          line_up = "";
        };
      };
    };
    plugins.mini-basics = {
      enable = true;
      settings = {
        options = {
          basic = true;
          extra_ui = true;
          win_borders = "auto";
        };
        mappings = {
          basic = true;
          option_toggle_prefix = "<leader>u";
          windows = true;
          move_with_alt = false;
        };
        autocommands = {
          basic = true;
          relnum_in_visual_mode = false;
        };
        silent = false;
      };
    };

    # Snacks
    plugins.snacks = {
      enable = true;
      settings = {
        input = {
          enabled = true;
        };
        terminal = {
          enabled = true;
        };
        notifier = {
          enabled = true;
          timeout = 3000;
        };
        scratch = {
          enabled = true;
        };
        toggle = {
          enabled = true;
        };
        bigfile = {
          enabled = true;
        };
        bufdelete = {
          enabled = true;
        };
        git = {
          enabled = true;
        };
        gitbrowse = {
          enabled = true;
        };
        quickfile = {
          enabled = true;
        };
        scroll = {
          enabled = true;
        };

        # ── Snacks Picker (replaces fzf-lua) ──
        picker = {
          enabled = true;
          # Override vim.ui.select with snacks picker UI
          ui_select = true;
          sources = {
            explorer = {
              # Show dotfiles and gitignored (like neo-tree was configured)
              hidden = true;
              ignored = true;
            };
          };
          # Flash integration for jump labels in picker list
          actions = {
            flash = {
              __raw = ''
                function(picker)
                  require("flash").jump({
                    pattern = "^",
                    label = { after = { 0, 0 } },
                    search = {
                      mode = "search",
                      exclude = {
                        function(win)
                          return vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "snacks_picker_list"
                        end,
                      },
                    },
                    action = function(match)
                      local idx = picker.list:row2idx(match.pos[1])
                      picker.list:_move(idx, true, true)
                    end,
                  })
                end
              '';
            };
          };
          win = {
            input = {
              keys = {
                # Flash jump in picker
                "<a-s>" = {
                  __unkeyed-1 = "flash";
                  mode = [
                    "n"
                    "i"
                  ];
                };
                s = {
                  __unkeyed-1 = "flash";
                };
                # Send to Trouble
                "<a-t>" = {
                  __unkeyed-1 = "trouble_open";
                  mode = [
                    "n"
                    "i"
                  ];
                };
              };
            };
          };
        };

        # ── Snacks Explorer (replaces neo-tree) ──
        explorer = {
          enabled = true;
        };
      };
    };

    # Core
    plugins.tmux-navigator.enable = true;
    plugins.trouble = {
      enable = true;
    };
    plugins.treesitter = {
      enable = true;
      highlight.enable = true;
      indent.enable = true;
      # folding.enable = true;
    };
    plugins.treesitter-textobjects.enable = true;

    # UI
    plugins.lualine.enable = true;
    plugins.bufferline = {
      enable = true;
      settings.options.diagnostics = false;
      settings.options.name_formatter.__raw = ''
        -- Add a space between icon and filename
        function(buf)
          return " " .. buf.name
        end
      '';
      settings.options.offsets = [
        {
          filetype = "snacks_layout_box";
        }
      ];
    };

    # VCS
    plugins.neogit.enable = true;
    plugins.gitsigns = {
      enable = true;
      settings = {
        on_attach.__raw = ''
          function(buffer)
            local gs = require('gitsigns')

            local function map(mode, l, r, desc)
              vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
            end

            -- Navigation
            map("n", "]h", function()
              if vim.wo.diff then
                vim.cmd.normal({ "]c", bang = true })
              else
                gs.nav_hunk("next")
              end
            end, "Next Hunk")

            map("n", "[h", function()
              if vim.wo.diff then
                vim.cmd.normal({ "[c", bang = true })
              else
                gs.nav_hunk("prev")
              end
            end, "Prev Hunk")

            map("n", "]H", function() gs.nav_hunk("last") end, "Last Hunk")
            map("n", "[H", function() gs.nav_hunk("first") end, "First Hunk")

            -- Actions
            map("n", "<leader>ghs", gs.stage_hunk, "Stage Hunk")
            map("n", "<leader>ghr", gs.reset_hunk, "Reset Hunk")
            map("v", "<leader>ghs", function() gs.stage_hunk {vim.fn.line("."), vim.fn.line("v")} end, "Stage Hunk")
            map("v", "<leader>ghr", function() gs.reset_hunk {vim.fn.line("."), vim.fn.line("v")} end, "Reset Hunk")
            map("n", "<leader>ghS", gs.stage_buffer, "Stage Buffer")
            map("n", "<leader>ghu", gs.undo_stage_hunk, "Undo Stage Hunk")
            map("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")
            map("n", "<leader>ghp", gs.preview_hunk_inline, "Preview Hunk Inline")
            map("n", "<leader>ghb", function() gs.blame_line({ full = true }) end, "Blame Line")
            map("n", "<leader>ghB", function() gs.blame() end, "Blame Buffer")
            map("n", "<leader>ghd", gs.diffthis, "Diff This")
            map("n", "<leader>ghD", function() gs.diffthis("~") end, "Diff This ~")
            map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")
          end
        '';
      };
    };
    plugins.diffview.enable = true;
    plugins.web-devicons.enable = true;

    # Formatting
    plugins.conform-nvim = {
      enable = true;
      settings = {
        default_format_opts = {
          timeout_ms = 3000;
          async = false;
          lsp_format = "fallback";
        };
        formatters_by_ft = {
          lua = [ "stylua" ];
          fish = [ "fish_indent" ];
          sh = [ "shfmt" ];
          nix = [ "nixfmt" ];
        };
      };
    };

    # Rename with preview
    plugins.inc-rename = {
      enable = true;
      settings = {
        input_buffer_type = "dressing";
      };
    };

    # Flash (jump/search navigation)
    plugins.flash = {
      enable = true;
      settings = {
        modes = {
          char = {
            jump_labels = true;
          };
          search = {
            enabled = false; # don't hijack / search by default
          };
        };
        label = {
          uppercase = false;
        };
      };
    };

    # Surround (gsa/gsd/gsr)
    plugins.mini-surround = {
      enable = true;
      settings = {
        mappings = {
          add = "gsa";
          delete = "gsd";
          find = "gsf";
          find_left = "gsF";
          highlight = "gsh";
          replace = "gsr";
          update_n_lines = "gsn";
        };
      };
    };

    # Todo Comments
    plugins.todo-comments = {
      enable = true;
    };

    # Search and Replace
    plugins.grug-far = {
      enable = true;
      settings = {
        headerMaxWidth = 80;
      };
    };

    # Yank History
    plugins.yanky = {
      enable = true;
    };

    # Noice (cmdline, messages, notifications)
    plugins.noice = {
      enable = true;
      settings = {
        cmdline = {
          view = "cmdline_popup"; # or use cmdline
        };
        lsp = {
          override = {
            "vim.lsp.util.convert_input_to_markdown_lines" = true;
            "vim.lsp.util.stylize_markdown" = true;
          };
          documentation = {
            view = "hover";
            opts = {
              format = [
                "{message}"
              ];
              lang = "markdown";
              render = "plain";
              replace = true;
              win_options = {
                concealcursor = "n";
                conceallevel = 3;
              };
            };
          };
        };
        routes = [
          # Skip short file-written messages
          {
            filter = {
              event = "msg_show";
              any = [
                { find = "%d+L, %d+B"; }
                { find = "; after #%d+"; }
                { find = "; before #%d+"; }
              ];
            };
            view = "mini";
          }
        ];
        presets = {
          bottom_search = false; # use classic bottom search
          command_palette = true; # position cmdline and popupmenu together
          inc_rename = true;
          long_message_to_split = true; # long messages sent to split
          lsp_doc_border = true; # borders for hover/signature help
        };
      };
    };

    # Indent Guides
    plugins.indent-blankline = {
      enable = true;
      settings = {
        indent = {
          char = "│";
        };
        scope = {
          enabled = true;
        };
        exclude = {
          filetypes = [
            "help"
            "neo-tree"
            "Trouble"
            "trouble"
            "lazy"
            "notify"
            "toggleterm"
          ];
        };
      };
    };

    # AI (Sidekick)
    plugins.sidekick = {
      enable = true;
      settings = {
        nes = {
          enabled = false;
        };
        cli = {
          keys = {
            prompt = false; # Unbind <C-p> (default prompt select) so it passes through to the terminal
          };
          mux = {
            backend = "tmux";
            enabled = true;
            create = "split";
          };
        };
      };
    };

    # Test Runner
    plugins.neotest = {
      enable = true;
      settings = {
        output = {
          enabled = true;
          open_on_run = true;
        };
        output_panel = {
          enabled = true;
          open = "botright split | resize 15";
        };
        quickfix = {
          enabled = false;
        };
      };
      adapters = {
        python.enable = true;
        # Rust is handled by rustaceanvim.neotest
      };
    };

    # Generate Annotations
    plugins.neogen = {
      enable = true;
      settings = {
        snippet_engine = "luasnip";
      };
    };

    # Session Management
    plugins.persistence = {
      enable = true;
    };

    # LSP
    plugins.lsp.enable = true;
    plugins.dap.enable = true;
    plugins.dap-lldb.enable = true;
    lsp = {
      inlayHints.enable = true;
      servers = {
        basedpyright.enable = true;
        bashls.enable = true;
        bufls.enable = true;
        clangd.enable = true;
        gitlab_ci_ls.enable = true;
        hls.enable = true;
        html.enable = true;
        jsonls.enable = true;
        just.enable = true;
        nixd.enable = true;
        rust-analyzer.enable = true;
        sqls.enable = true;
        ts_ls.enable = true;
        # required by sidekick even though NES is disabled
        copilot = {
          enable = true;
          activate = false;
        };
      };
    };

    # nvim-java plugin
    # this manages the jdtls, and associated plugins
    # Also needs spring-boot
    plugins.java = {
      enable = true;
      # spring-boot is already enabled above
      # require('java').setup() will be called by nixvim
      # https://github.com/nvim-java/nvim-java?tab=readme-ov-file
      luaConfig.post = ''
        vim.lsp.enable('jdtls')
      '';
    };

    # Rust
    plugins.rustaceanvim = {
      enable = true;
      settings = {
        server = {
          load_vscode_settings = true;
          standalone = false;
        };
        tools = {
          test_executor = "neotest";
        };
        default_settings = {
          rust-analyzer = {
            inlayHints = {
              lifetimeElisionHints = {
                enable = "always";
              };
            };
          };
        };
      };
    };

    # Misc
    # plugins.neo-tree = {
    #   enable = true;
    #   settings = {
    #     close_if_last_window = false;
    #     filesystem = {
    #       filtered_items = {
    #         visible = true;
    #         hide_dotfiles = false;
    #         hide_gitignored = false;
    #       };
    #       follow_current_file = {
    #         enabled = true;
    #         leave_dirs_open = true;
    #       };
    #     };
    #   };
    # };
    plugins.which-key = {
      enable = true;
      settings = {
        spec = [
          {
            __unkeyed-1 = "<leader><tab>";
            group = "Tabs";
          }
          {
            __unkeyed-1 = "<leader>b";
            group = "Buffers";
            expand = {
              __raw = ''
                function()
                  return require("which-key.extras").expand.buf()
                end
              '';
            };
          }
          {
            __unkeyed-1 = "<leader>c";
            group = "Code";
          }
          {
            __unkeyed-1 = "<leader>d";
            group = "Debug";
          }
          {
            __unkeyed-1 = "<leader>f";
            group = "File/Find";
            icon = " ";
          }
          {
            __unkeyed-1 = "<leader>g";
            group = "Git";
          }
          {
            __unkeyed-1 = "<leader>gh";
            group = "Hunks";
          }
          {
            __unkeyed-1 = "<leader>q";
            group = "Quit/Session";
          }
          {
            __unkeyed-1 = "<leader>s";
            group = "Search";
          }
          {
            __unkeyed-1 = "<leader>u";
            group = "UI/Toggle";
          }
          {
            __unkeyed-1 = "<leader>w";
            group = "Windows";
            proxy = "<C-w>";
            expand = {
              __raw = ''
                function()
                  return require("which-key.extras").expand.win()
                end
              '';
            };
          }
          {
            __unkeyed-1 = "<leader>x";
            group = "Diagnostics/Quickfix";
          }
          {
            __unkeyed-1 = "gs";
            group = "Surround";
          }
          {
            __unkeyed-1 = "<leader>sn";
            group = "Noice";
          }
          {
            __unkeyed-1 = "<leader>a";
            group = "AI";
            mode = [
              "n"
              "x"
            ];
          }
          {
            __unkeyed-1 = "<leader>t";
            group = "Test";
          }
          # DAP breakpoint
          {
            __unkeyed-1 = "<leader>db";
            __unkeyed-2 = {
              __raw = ''
                function()
                  require("dap").toggle_breakpoint()
                end
              '';
            };
            desc = "Breakpoint toggle";
            mode = "n";
            silent = true;
          }
        ];
      };
    };
    plugins.harpoon.enable = true;
  };
}
