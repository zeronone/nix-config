{
  # In flake.nix it is configured with pkgs-unstable
  pkgs-unstable,
  lib,
  flake-inputs,
  ...
}:
{
  imports = [
    flake-inputs.nixvim.homeModules.nixvim
  ];

  programs.nixvim = {
    enable = true;
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
    ];

    extraConfigLua = ''
      require("output_panel").setup({ max_buffer_size = 10000 })
      vim.keymap.set("n", "<leader>to", ":OutputPanel<CR>", { desc = "Toggle Output Panel" })

      -- Enable inline diagnostics
      vim.diagnostic.config({ virtual_text = false })
      vim.keymap.set('n', '<leader>tx', function()
        local new_config = not vim.diagnostic.config().virtual_lines
        vim.diagnostic.config({ virtual_lines = new_config })
      end, { desc = 'Toggle inline diagnostics' })
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
      # start/end of line
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

      # mini-pick
      {
        mode = "n";
        key = "<leader>ff";
        action = "<cmd>Pick files<cr>";
        options = {
          silent = true;
          desc = "Pick files";
        };
      }
      {
        mode = [
          "n"
          "x"
        ];
        key = "<leader>fg";
        action.__raw = ''
          function()
            local query = nil
            if vim.fn.mode():find('[vV\22]') then
              vim.cmd([[normal! "zy]])
              query = vim.fn.getreg('z')
            end
            require('mini.pick').builtin.grep_live({ tool = 'rg' }, { query = query })
          end
        '';
        options = {
          desc = "Find Grep (Live Selection)";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>fb";
        action = "<cmd>Pick buffers<cr>";
        options = {
          silent = true;
          desc = "Pick buffers";
        };
      }

      # trouble
      {
        mode = "n";
        key = "<leader>lx";
        action = "<cmd>Trouble diagnostics toggle filter.buf=0<cr>";
        options = {
          noremap = true;
          silent = true;
          desc = "Current buffer diagnostics";
        };
      }
      {
        mode = "n";
        key = "<leader>lX";
        action = "<cmd>Trouble diagnostics toggle<cr>";
        options = {
          silent = true;
          desc = "Project diagnostics";
        };
      }
      {
        mode = "n";
        key = "<leader>lla";
        action = "<cmd>Trouble lsp<cr>";
        options = {
          silent = true;
          desc = "LSP definitions, implementations, type definitions etc";
        };
      }
      {
        mode = "n";
        key = "<leader>lld";
        action = "<cmd>Trouble lsp_definitions<cr>";
        options = {
          silent = true;
          desc = "LSP definitions";
        };
      }
      {
        mode = "n";
        key = "<leader>lli";
        action = "<cmd>Trouble lsp_implementations<cr>";
        options = {
          silent = true;
          desc = "LSP implementations";
        };
      }
      {
        mode = "n";
        key = "<leader>llr";
        action = "<cmd>Trouble lsp_references<cr>";
        options = {
          silent = true;
          desc = "LSP References";
        };
      }
      {
        mode = "n";
        key = "<leader>llci";
        action = "<cmd>Trouble lsp_incoming_calls<cr>";
        options = {
          silent = true;
          desc = "LSP incoming calls";
        };
      }
      {
        mode = "n";
        key = "<leader>llco";
        action = "<cmd>Trouble lsp_outgoing_calls<cr>";
        options = {
          silent = true;
          desc = "LSP outgoing calls";
        };
      }

      # neo-tree
      {
        mode = "n";
        key = "<leader>tf";
        action = "<cmd>Neotree source=filesystem action=show toggle<cr>";
        options = {
          silent = true;
          desc = "File explorer";
        };
      }
      {
        mode = "n";
        key = "<leader>tb";
        action = "<cmd>Neotree source=buffers position=float toggle<cr>";
        options = {
          silent = true;
          desc = "Buffer explorer";
        };
      }
      {
        mode = "n";
        key = "<leader>tg";
        action = "<cmd>Neotree source=git_status position=float toggle<cr>";
        options = {
          silent = true;
          desc = "Git Status";
        };
      }
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
        # Requires pluigns.treesitter-textobjects
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
    # Testing
    plugins.mini-pick = {
      enable = true;
    };
    plugins.mini-notify.enable = true;
    plugins.mini-extra.enable = true;
    plugins.mini-cmdline.enable = true;
    plugins.mini-move = {
      enable = true;
      settings = {
        mappings = {
          # vissual mode
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
          option_toggle_prefix = "<leader>t";
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

    # Core
    plugins.fzf-lua.enable = true;
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

    # LSP
    plugins.lsp.enable = true;
    plugins.dap.enable = true;
    lsp.servers = {
      basedpyright.enable = true;
      bashls.enable = true;
      bufls.enable = true;
      clangd.enable = true;
      gitlab_ci_ls.enable = true;
      hls.enable = true;
      html.enable = true;
      jdtls.enable = true;
      jsonls.enable = true;
      just.enable = true;
      nixd.enable = true;
      rust-analyzer.enable = true;
      sqls.enable = true;
      ts_ls.enable = true;
    };

    # Rust
    plugins.rustaceanvim.enable = true;
    plugins.dap-lldb.enable = true;

    # Misc
    plugins.neo-tree = {
      enable = true;
      settings = {
        close_if_last_window = true;
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
            __unkeyed-1 = "<leader>f";
            group = "Find";
            icon = " ";
          }
          {
            __unkeyed-1 = "<leader>t";
            group = "Toggle";
          }
          {
            __unkeyed-1 = [
              {
                __unkeyed-1 = "<leader>l";
                group = "List";
              }
              {
                __unkeyed-1 = "<leader>ll";
                group = "LSP";
              }
              {
                __unkeyed-1 = "<leader>llc";
                group = "Call Hierarchy";
              }
            ];
          }
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
