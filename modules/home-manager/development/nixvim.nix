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

    globals.mapleader = " ";
    globals.maplocalleader = " ";

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
      vim.keymap.set("n", "<leader>o", ":OutputPanel<CR>", { desc = "Toggle Output Panel" })
    '';

    opts = {
      number = true; # Show line numbers
      relativenumber = true; # Show relative line numbers
      shiftwidth = 2; # Tab width should be 2
      expandtab = true;

      # https://nvim-mini.org/mini.nvim/doc/mini-completion.html#module-suggestedoptionvalues
      # Ensure the first item is selected in completion-menu
      completeopt = "menu,menuone,noinsert,fuzzy,nosort";
      # fallback completion, where to look
      complete = [
        "." # current buffer
        "w" # other windows
        "b" # loaded buffers
        "u" # unloaded buffers
      ];

      # case-insensitive search
      ignorecase = true;
      smartcase = true;
    };

    keymaps = [
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
        key = "<leader>sf";
        action = "<cmd>Pick files<cr>";
        options = {
          silent = true;
          desc = "Pick files";
        };
      }
      {
        mode = "n";
        key = "<leader>sg";
        action = "<cmd>Pick grep_live<cr>";
        options = {
          silent = true;
          desc = "Pick grep_live";
        };
      }
      {
        mode = "n";
        key = "<leader>sb";
        action = "<cmd>Pick buffers<cr>";
        options = {
          silent = true;
          desc = "Pick buffers";
        };
      }
      {
        mode = "n";
        key = "<leader>se";
        action = "<cmd>Pick diagnostic<cr>";
        options = {
          silent = true;
          desc = "Pick diagnostic";
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

          # normal mode
          line_down = "<C-j>";
          line_left = "<C-h>";
          line_right = "<C-l>";
          line_up = "<C-k>";
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
          option_toggle_prefix = "\\";
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
    plugins.trouble.enable = true;
    plugins.treesitter = {
      enable = true;
      highlight.enable = true;
      indent.enable = true;
      # folding.enable = true;
    };
    plugins.treesitter-textobjects.enable = true;

    # UI
    plugins.lualine.enable = true;

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
    plugins.neo-tree.enable = true;
    plugins.which-key.enable = true;
    plugins.harpoon.enable = true;
  };
}
