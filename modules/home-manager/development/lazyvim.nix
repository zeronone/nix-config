{
  pkgs,
  pkgs-unstable,
  flake-inputs,
  ...
}:
let
  langEnableFull = {
    enable = true;
    installDependencies = true;
    installRuntimeDependencies = true;
  };
in
{
  imports = [ flake-inputs.lazyvim.homeManagerModules.default ];

  home.packages = with pkgs; [
    lazygit
  ];

  programs.lazyvim = {
    enable = true;
    ignoreBuildNotifications = true;

    config = {
      # ~/.config/nvim/lua/config/options.lua
      options = ''
        -- Common
        vim.opt.wrap = true
        vim.opt.winborder = "single"

        -- Disable inline diagnostics by default
        -- Can be enabled by <leader>cd, <leader>cD
        vim.diagnostic.config({ virtual_text = false })

        -- Use basedpyright
        vim.g.lazyvim_python_lsp = "basedpyright"

        -- TODO: revert back when bacon-ls aarch64 build is ready
        -- use bacon-ls only for diagnostics (faster on large projects)
        -- vim.g.lazyvim_rust_diagnostics = "bacon-ls"
      '';

      autocmds = ''
        -- Disable inline diagnostics by default
        vim.api.nvim_create_autocmd("BufEnter", {
          callback = function()
            vim.diagnostic.config({ virtual_text = false })
          end,
        })
      '';

      keymaps = ''
        vim.keymap.set(
          "n",
          "<leader>cD",
          "<cmd>Trouble diagnostics toggle filter.buf=0 focus=true<cr>",
          { desc = "Current Buffer diagnostics" }
        )
      '';
    };

    # Plugin Configuration
    plugins = {
      colorscheme = ''
        return {
          -- Configure LazyVim to load gruvbox
          {
            "LazyVim/LazyVim",
            opts = {
              colorscheme = "tokyonight-moon",
            },
          },
          -- Configure the catppuccin plugin itself
          {
            "catppuccin/nvim",
            name = "catppuccin",
            opts = {
              flavour = "mocha",
            },
          },
          -- more color themes
          { "bluz71/vim-moonfly-colors", name = "moonfly", lazy = false, priority = 1000 },
          { "bluz71/vim-nightfly-colors", name = "nightfly", lazy = false, priority = 1000 },
          { "ellisonleao/gruvbox.nvim", name = "gruvbox", lazy = false },
          { "vague-theme/vague.nvim", name = "vague", lazy = false },
          { "savq/melange-nvim", name = "melange", lazy = false },
        }
      '';

      noice = ''
        return {
          {
            "folke/noice.nvim",
            opts = {
              cmdline = {
                view = "cmdline",
              },
              presets = {
                lsp_doc_border = true,
              },
            },
          },
        }
      '';

      lsp = ''
        return {
          {
            "neovim/nvim-lspconfig",
            opts = {
              diagnostics = {
                virtual_text = false, -- Disables inline text by default
              },
            },
          },
        }
      '';
    };

    # https://github.com/pfassina/lazyvim-nix/blob/main/data/extras.json
    extras = {
      coding = {
        # <leader>cn
        neogen.enable = true;
        mini_surround.enable = true;
        # gc, gcc, dgc
        mini_comment.enable = true;
        luasnip.enable = true;
        # [y, ]y
        yanky.enable = true;
      };
      editor = {
        # <leader>h, <leader>H
        harpoon2.enable = true;
        illuminate.enable = true;
        # <leader>cr
        inc_rename.enable = true;
        # s, S, gs
        leap.enable = true;
        # <leader>go
        mini_diff.enable = true;
        mini_move = {
          enable = true;
          config = ''
            return {
              "nvim-mini/mini.move",
              opts = {
                mappings = {
                  -- Move visual selection in Visual mode. Defaults are Alt (Meta) + hjkl.
                  left = "<C-h>",
                  right = "<C-l>",
                  down = "<C-j>",
                  up = "<C-k>",
                  -- Disable in normal mode
                  line_left = "",
                  line_right = "",
                  line_down = "",
                  line_up = "",
                }
              }
            }
          '';
        };
        # <leader>cs
        outline.enable = true;
        # <leader>r
        refactoring.enable = true;
      };

      ui = {
        # alpha.enable = true;
      };

      ai = {
        sidekick = {
          enable = true;
          # Make it work with tmux
          config = ''
            return {
              "folke/sidekick.nvim",
              opts = {
                cli = {
                  mux = {
                    backend = "tmux",
                    enabled = true,
                  },
                },
              },
            }
          '';
        };
      };

      lang = {
        docker = langEnableFull;
        java = langEnableFull;
        json = langEnableFull;
        kotlin = langEnableFull;
        markdown = langEnableFull;
        nix = langEnableFull;
        python = langEnableFull;
        rust = langEnableFull;
        terraform = langEnableFull;
        typescript = langEnableFull;
        yaml = langEnableFull;
      };

      linting = {
        eslint.enable = true;
      };

      lsp = {
        # :Neoconf
        # .neoconf.json (project-local config)
        neoconf.enable = true;
        # Use Neovim as a language server to inject LSP diagnostics, code actions, and more via Lua.
        none_ls.enable = true;
      };

      test = {
        # neotest
        # <leader>t
        core.enable = true;
      };

      ui = {
        # <leader>ue
        edgy.enable = true;
        smear_cursor.enable = true;
        treesitter_context.enable = true;
      };

      util = {
        mini_hipatterns.enable = true;
        # <leader>R, <leader>Rb
        rest.enable = true;
      };
    };

    # Not covered by LazyVim
    extraPackages = with pkgs-unstable; [
      # lazy.nvim
      lua51Packages.lua
      lua51Packages.luarocks
      lua51Packages.jsregexp

      # nix
      nixfmt
      statix # Nix linter

      # terraform
      tflint

      # nvim-treesitter
      tree-sitter # unlikely needed

      # null-ls
      packer
      fish
      stylua
      shfmt

      # markdown
      markdownlint-cli2
      markdown-toc

      # grug-far
      ast-grep

      # kulala (rest)
      websocat
      openssl_3
      kulala-fmt

      # snacks.image
      ghostscript
      tectonic-unwrapped
      mermaid-cli

      # rust
      # bacon-ls # added in rust.nix, overlay in pkgs

      # lsp
      copilot-language-server
      docker-compose-language-service
      docker-language-server
      vscode-langservers-extracted
      kotlin-language-server # replace with kotlin-lsp
      lua-language-server
      marksman # for makrdown
      nixd # or nil
      basedpyright # or ruff, pyright
      terraform-ls
      vtsls # for typescript
      yaml-language-server
    ];
  };
}
