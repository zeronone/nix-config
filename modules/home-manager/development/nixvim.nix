{
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

      -- Disable virtual_text diagnostics by default
      -- Can be enabled by <leader>cd, <leader>cD
      vim.diagnostic.config({ virtual_text = false })

      -- Disable macros
      vim.keymap.set('n', 'q', '<Nop>', { noremap = true, silent = true, desc = 'Disable q key' })

      -- <Esc> to go to normal mode in terminal
      vim.keymap.set('t', '<Esc>', [[<C-\><C-n>]])
    '';

    opts = {
      number = true; # Show line numbers
      relativenumber = true; # Show relative line numbers
      shiftwidth = 2; # Tab width should be 2
      expandtab = true;

      # https://nvim-mini.org/mini.nvim/doc/mini-completion.html#module-suggestedoptionvalues
      # Ensure the first item is selected in completion-menu
      completeopt = "menu,menuone,noinsert,fuzzy,nosort,popup";
      # fallback completion, where to look
      complete = [
        "." # current buffer
        "w" # other windows
        "b" # loaded buffers
        "u" # unloaded buffers
      ];

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

      # ── Window Navigation ──
      (mkN "<C-h>" "<C-w>h" "Go to Left Window")
      (mkN "<C-j>" "<C-w>j" "Go to Lower Window")
      (mkN "<C-k>" "<C-w>k" "Go to Upper Window")
      (mkN "<C-l>" "<C-w>l" "Go to Right Window")

      # ── Window Splits ──
      (mkN "<leader>-" "<C-w>s" "Split Window Below")
      (mkN "<leader>|" "<C-w>v" "Split Window Right")
      (mkN "<leader>wd" "<C-w>c" "Delete Window")

      # ── Resize Windows ──
      (mkN "<C-Up>" "<cmd>resize +2<cr>" "Increase Window Height")
      (mkN "<C-Down>" "<cmd>resize -2<cr>" "Decrease Window Height")
      (mkN "<C-Left>" "<cmd>vertical resize -2<cr>" "Decrease Window Width")
      (mkN "<C-Right>" "<cmd>vertical resize +2<cr>" "Increase Window Width")

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

      # ── Trouble (LazyVim layout) ──
      (mkN "<leader>xx" "<cmd>Trouble diagnostics toggle<cr>" "Diagnostics (Trouble)")
      (mkN "<leader>xX" "<cmd>Trouble diagnostics toggle filter.buf=0<cr>" "Buffer Diagnostics (Trouble)")
      (mkN "<leader>cs" "<cmd>Trouble symbols toggle<cr>" "Symbols (Trouble)")
      (mkN "<leader>cS" "<cmd>Trouble lsp toggle<cr>" "LSP references/definitions/... (Trouble)")
      (mkN "<leader>xL" "<cmd>Trouble loclist toggle<cr>" "Location List (Trouble)")
      (mkN "<leader>xQ" "<cmd>Trouble qflist toggle<cr>" "Quickfix List (Trouble)")

      # ── Neo-tree (LazyVim layout) ──
      (mkN "<leader>e" "<cmd>Neotree source=filesystem action=show toggle<cr>" "Explorer (Root)")
      (mkN "<leader>E" "<cmd>Neotree source=filesystem action=show toggle dir=%:p:h<cr>" "Explorer (cwd)")

      # ── Terminal (Snacks) ──
      (mkNLua "<leader>ft" "function() Snacks.terminal() end" "Terminal (Root)")
      (mkNLua "<leader>fT" ''
        function() Snacks.terminal(nil, { cwd = vim.fn.expand("%:p:h") }) end
      '' "Terminal (cwd)")
      (mkLua [ "n" "t" ] "<c-/>" "function() Snacks.terminal() end" "Terminal (Root)")

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

      # ── LSP (LazyVim layout) ──
      (mkNLua "gd" "function() vim.lsp.buf.definition() end" "Goto Definition")
      (mkNLua "gr" "function() vim.lsp.buf.references() end" "References")
      (mkNLua "gI" "function() vim.lsp.buf.implementation() end" "Goto Implementation")
      (mkNLua "gy" "function() vim.lsp.buf.type_definition() end" "Goto Type Definition")
      (mkNLua "gD" "function() vim.lsp.buf.declaration() end" "Goto Declaration")
      (mkNLua "K" "function() vim.lsp.buf.hover() end" "Hover")
      (mkNLua "gK" "function() vim.lsp.buf.signature_help() end" "Signature Help")
      (mkLua "i" "<c-k>" "function() vim.lsp.buf.signature_help() end" "Signature Help")
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
      (mkN "<leader>st" "<cmd>TodoFzfLua<cr>" "Todo")
      (mkN "<leader>sT" "<cmd>TodoFzfLua keywords=TODO,FIX,FIXME<cr>" "Todo/Fix/Fixme")

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
      # Git log keymaps handled by fzf-lua (<leader>gc, <leader>gS)

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
        map_lsp_selection('ls', 'Increase selection')
        map_lsp_selection('lS', 'Decrease selection')
      '';
    };
    plugins.mini-align.enable = true;
    plugins.mini-comment.enable = true;
    plugins.mini-icons.enable = true;
    plugins.mini-snippets.enable = true;
    plugins.mini-completion.enable = true;
    plugins.mini-keymap = {
      enable = true;
      luaConfig.post = ''
        -- For mini-completion
        local map_multistep = require('mini.keymap').map_multistep
        map_multistep('i', '<Tab>',   { 'pmenu_next' })
        map_multistep('i', '<S-Tab>', { 'pmenu_prev' })
        map_multistep('i', '<CR>',    { 'pmenu_accept', 'minipairs_cr' })
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
        # disabled
        # picer: we use fzf-lua
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
      };
    };
    plugins.smear-cursor.enable = true;

    # Core
    plugins.fzf-lua = {
      enable = true;
      keymaps = {
        "<leader><space>" = {
          action = "files";
          options.desc = "Find Files (Root)";
        };
        "<leader>/" = {
          action = "live_grep";
          options.desc = "Grep (Root)";
        };
        "<leader>," = {
          action = "buffers";
          options.desc = "Buffers";
        };
        "<leader>:" = {
          action = "command_history";
          options.desc = "Command History";
        };
        "<leader>ff" = {
          action = "files";
          options.desc = "Find Files (Root)";
        };
        "<leader>fF" = {
          action = "files";
          settings.cwd = "%:p:h";
          options.desc = "Find Files (cwd)";
        };
        "<leader>fb" = {
          action = "buffers";
          options.desc = "Buffers";
        };
        "<leader>fg" = {
          action = "git_files";
          options.desc = "Git Files";
        };
        "<leader>fr" = {
          action = "oldfiles";
          options.desc = "Recent Files";
        };
        "<leader>sg" = {
          action = "live_grep";
          options.desc = "Grep (Root)";
        };
        "<leader>sG" = {
          action = "live_grep";
          settings.cwd = "%:p:h";
          options.desc = "Grep (cwd)";
        };
        "<leader>sw" = {
          action = "grep_cword";
          options.desc = "Grep Word (Root)";
        };
        "<leader>sW" = {
          action = "grep_cword";
          settings.cwd = "%:p:h";
          options.desc = "Grep Word (cwd)";
        };
        "<leader>ss" = {
          action = "lsp_document_symbols";
          options.desc = "LSP Symbols";
        };
        "<leader>sS" = {
          action = "lsp_workspace_symbols";
          options.desc = "LSP Workspace Symbols";
        };
        "<leader>sd" = {
          action = "diagnostics_document";
          options.desc = "Diagnostics (Buffer)";
        };
        "<leader>sD" = {
          action = "diagnostics_workspace";
          options.desc = "Diagnostics (Workspace)";
        };
        "<leader>sh" = {
          action = "help_tags";
          options.desc = "Help Pages";
        };
        "<leader>sk" = {
          action = "keymaps";
          options.desc = "Keymaps";
        };
        "<leader>sm" = {
          action = "marks";
          options.desc = "Marks";
        };
        "<leader>s\"" = {
          action = "registers";
          options.desc = "Registers";
        };
        "<leader>gc" = {
          action = "git_commits";
          options.desc = "Git Commits";
        };
        "<leader>gS" = {
          action = "git_status";
          options.desc = "Git Status";
        };
      };
    };
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
    plugins.bufferline.enable = true;

    # VCS
    plugins.neogit.enable = true;
    plugins.gitsigns.enable = true;
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
      adapters = {
        python.enable = true;
        # Rust is handled by rustaceanvim.neotest
      };
    };

    # Generate Annotations
    plugins.neogen = {
      enable = true;
      settings = {
        snippet_engine = "mini";
      };
    };

    # Session Management
    plugins.persistence = {
      enable = true;
    };

    # LSP
    plugins.lsp.enable = true;
    plugins.dap.enable = true;
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
    plugins.dap-lldb.enable = true;

    # Misc
    plugins.neo-tree = {
      enable = true;
      settings = {
        close_if_last_window = false;
        filesystem = {
          filtered_items = {
            visible = true;
            hide_dotfiles = false;
            hide_gitignored = false;
          };
          follow_current_file = {
            enabled = true;
            leave_dirs_open = true;
          };
        };
      };
    };
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
