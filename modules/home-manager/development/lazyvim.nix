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

    config = {
      # ~/.config/nvim/lua/config/options.lua
      options = ''
        -- Common
        vim.opt.wrap = true

        -- Use basedpyright
        vim.g.lazyvim_python_lsp = "basedpyright"

        -- use bacon-ls only for diagnostics (faster on large projects)
        vim.g.lazyvim_rust_diagnostics = "bacon-ls"
      '';

      # ~/.config/nvim/lua/config/lazy.lua
      # lazy = ''
      #
      # '';
    };

    # Plugin Configuration
    plugins = {
      colorscheme = ''
        return {
          -- Configure LazyVim to load gruvbox
          {
            "LazyVim/LazyVim",
            opts = {
              colorscheme = "catppuccin",
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
        }
      '';
    };

    # https://github.com/pfassina/lazyvim-nix/blob/main/data/extras.json
    extras = {
      coding = {
        blink.enable = true;
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
      bacon

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
