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

  # JDTLS wrapped with lombok, debug/test bundles, and .vscode/settings.json support
  jdtls-wrapped = pkgs-unstable.callPackage ../../../packages/jdtls-wrapped {
    inherit (pkgs-unstable)
      jdt-language-server
      lombok
      jq
      gnused
      ;
    inherit (pkgs-unstable.vscode-marketplace.vscjava) vscode-java-debug;
    inherit (pkgs-unstable.vscode-marketplace.vscjava) vscode-java-test;
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
        vim.opt.exrc = true
        vim.opt.secure = true

        -- Disable macros
        vim.keymap.set('n', 'q', '<Nop>', { noremap = true, silent = true, desc = 'Disable q key' })

        -- Disable inline diagnostics by default
        -- Can be enabled by <leader>cd, <leader>cD
        vim.diagnostic.config({ virtual_text = false })

        -- Use basedpyright
        vim.g.lazyvim_python_lsp = "basedpyright"

        -- TODO: revert back when bacon-ls aarch64 build is ready
        -- use bacon-ls only for diagnostics (faster on large projects)
        -- vim.g.lazyvim_rust_diagnostics = "bacon-ls"
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
              routes = {
                -- Disalbe noisy jdtls notifications
                {
                  filter = {
                    event = "lsp",
                    kind = "progress",
                    cond = function(message)
                      return message.opts.progress.client == "jdtls"
                         and (string.find(message.opts.progress.message, "Validate")
                           or string.find(message.opts.progress.message, "Publish"))
                    end,
                  },
                  opts = { skip = true },
                },
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
              -- Disable autoformat on save
              autoformat = true,
              servers = {
                ['*'] = {
                  keys = {
                    {
                      "<leader>co",
                      "<cmd>OutputPanel<cr>",
                      mode = "n",
                      desc = "Toggle Output Panel",
                    },
                  }
                }
              }
            },
          },
          {
            "mhanberg/output-panel.nvim",
            opts = {},
          },
        }
      '';

      snacks = ''
        return {
          {
            "folke/snacks.nvim",
            opts = {
              picker = {
                sources = {
                  explorer = {
                    diagnostics = false,
                    watch = fasle,
                    hidden = true,
                    ignored = true,
                  }
                },
              },
            },
          }
        }
      '';

      dap = ''
        return {
          { "jay-babu/mason-nvim-dap.nvim", enabled = false },
        };
      '';

      java = ''
        return {
         {
           'nvim-java/nvim-java',
           config = function()
             require('java').setup()
             vim.lsp.enable('jdtls')
           end,
         }
        }
      '';

      # java = ''
      #   -- Nix paths (injected at build time)
      #   local share = "${jdtls-wrapped}/share/jdtls-wrapped"
      #
      #   --- Read and parse .vscode/settings.json (JSONC) from the workspace root.
      #   local function read_vscode_settings()
      #     local settings_path = vim.fn.getcwd() .. "/.vscode/settings.json"
      #     if vim.fn.filereadable(settings_path) ~= 1 then return {} end
      #     local lines = vim.fn.readfile(settings_path)
      #     for i, line in ipairs(lines) do
      #       lines[i] = line:gsub("^(%s*)//.*$", "%1"):gsub("([,{%[])%s*//.*$", "%1")
      #     end
      #     local ok, json = pcall(vim.json.decode, table.concat(lines, "\n"))
      #     if not ok then
      #       vim.notify("jdtls: failed to parse .vscode/settings.json: " .. tostring(json), vim.log.levels.WARN)
      #       return {}
      #     end
      #     return json or {}
      #   end
      #
      #   --- Map .vscode/settings.json java.* keys to jdtls server settings.
      #   local function build_java_settings(vs)
      #     local java = {}
      #     local function set_nested(tbl, dotted_key, value)
      #       local keys = vim.split(dotted_key, ".", { plain = true })
      #       local cur = tbl
      #       for i = 1, #keys - 1 do cur[keys[i]] = cur[keys[i]] or {}; cur = cur[keys[i]] end
      #       cur[keys[#keys]] = value
      #     end
      #     local key_map = {
      #       ["java.configuration.runtimes"]              = "configuration.runtimes",
      #       ["java.configuration.updateBuildConfiguration"] = "configuration.updateBuildConfiguration",
      #       ["java.configuration.detectJdksAtStart"]     = "configuration.detectJdksAtStart",
      #       ["java.import.gradle.java.home"]             = "import.gradle.java.home",
      #       ["java.import.gradle.home"]                  = "import.gradle.home",
      #       ["java.import.gradle.wrapper.enabled"]       = "import.gradle.wrapper.enabled",
      #       ["java.import.gradle.offline.enabled"]       = "import.gradle.offline.enabled",
      #       ["java.import.gradle.user.home"]             = "import.gradle.user.home",
      #       ["java.import.maven.java.home"]              = "import.maven.java.home",
      #       ["java.compile.nullAnalysis.mode"]           = "compile.nullAnalysis.mode",
      #       ["java.server.launchMode"]                   = "server.launchMode",
      #       ["java.autobuild.enabled"]                   = "autobuild.enabled",
      #       ["java.completion.enabled"]                  = "completion.enabled",
      #       ["java.completion.filteredTypes"]             = "completion.filteredTypes",
      #       ["java.format.settings.url"]                 = "format.settings.url",
      #       ["java.settings.url"]                        = "settings.url",
      #       ["java.project.outputPath"]                  = "project.outputPath",
      #     }
      #     for vs_key, java_path in pairs(key_map) do
      #       local val = vs[vs_key]
      #       if val ~= nil and val ~= "" then set_nested(java, java_path, val) end
      #     end
      #     return java
      #   end
      #
      #   return {
      #     {
      #       "mfussenegger/nvim-jdtls",
      #
      #       ---  opts is deep-merged with the upstream LazyVim java extra.
      #       ---  Upstream already provides: root_dir, project_name, jdtls_config_dir,
      #       ---  jdtls_workspace_dir, full_cmd, dap, dap_main, test, inlayHints.
      #       ---  We only override cmd (use nix wrapper) and merge .vscode/settings.json.
      #       opts = function(_, opts)
      #         -- Use jdtls-launcher (wraps real jdtls with lombok + .vscode/settings.json vmargs)
      #         opts.cmd = { vim.fn.exepath("jdtls-launcher") }
      #
      #         -- Performance: disable expensive background features for large projects
      #         opts.settings = opts.settings or {}
      #         opts.settings.java = vim.tbl_deep_extend("force", opts.settings.java or {}, {
      #           inlayHints = { parameterNames = { enabled = "none" } },
      #           autobuild = { enabled = false },
      #           referencesCodeLens = { enabled = false },
      #           implementationsCodeLens = { enabled = false },
      #           foldingRange = { enabled = false },
      #           selectionRange = { enabled = false },
      #         })
      #
      #         -- Merge .vscode/settings.json on top (per-project can re-enable features)
      #         local java_settings = build_java_settings(read_vscode_settings())
      #         opts.settings.java = vim.tbl_deep_extend("force", opts.settings.java, java_settings)
      #
      #         return opts
      #       end,
      #
      #       ---  config replaces the upstream entirely (no merge).
      #       ---  We reuse opts helpers (full_cmd, root_dir) provided by the upstream opts.
      #       ---  Only the nix-specific parts differ: bundle discovery and ungated DAP setup.
      #       config = function(_, opts)
      #         -- Discover bundles from nix store (replaces Mason-gated discovery)
      #         local bundles = {}
      #         local debug_jar = vim.fn.glob(share .. "/java-debug-adapter/com.microsoft.java.debug.plugin-*.jar")
      #         if debug_jar ~= "" then table.insert(bundles, debug_jar) end
      #         vim.list_extend(bundles, vim.fn.glob(share .. "/java-test/*.jar", false, true) or {})
      #
      #         -- attach_jdtls: reuses opts.full_cmd() and opts.root_dir() from upstream
      #         local function attach_jdtls()
      #           local fname = vim.api.nvim_buf_get_name(0)
      #           local config = {
      #             cmd = opts.full_cmd(opts),
      #             root_dir = opts.root_dir(fname),
      #             init_options = { bundles = bundles },
      #             settings = opts.settings,
      #             capabilities = vim.tbl_deep_extend("force", {},
      #               vim.lsp.protocol.make_client_capabilities(),
      #               (function()
      #                 local ok, blink = pcall(require, "blink.cmp")
      #                 if ok then return blink.get_lsp_capabilities() end
      #                 local ok2, cmp = pcall(require, "cmp_nvim_lsp")
      #                 if ok2 then return cmp.default_capabilities() end
      #                 return {}
      #               end)()
      #             ),
      #           }
      #           -- Allow user overrides via opts.jdtls
      #           config = vim.tbl_deep_extend("force", config, opts.jdtls or {})
      #           require("jdtls").start_or_attach(config)
      #         end
      #
      #         -- FileType autocmd + immediate attach (same as upstream)
      #         vim.api.nvim_create_autocmd("FileType", { pattern = { "java" }, callback = attach_jdtls })
      #         if vim.bo.filetype == "java" then attach_jdtls() end
      #
      #         -- LspAttach: keymaps + DAP (same as upstream, but DAP is unconditional)
      #         local dap_setup_done = false
      #         vim.api.nvim_create_autocmd("LspAttach", {
      #           callback = function(args)
      #             local client = vim.lsp.get_client_by_id(args.data.client_id)
      #             if not client or client.name ~= "jdtls" then return end
      #
      #             -- DAP setup (unconditional - no Mason gate)
      #             if not dap_setup_done then
      #               dap_setup_done = true
      #               pcall(function()
      #                 require("jdtls").setup_dap(opts.dap)
      #                 require("jdtls.dap").setup_dap_main_class_configs(opts.dap_main)
      #               end)
      #             end
      #
      #             -- Keymaps (identical to upstream LazyVim java extra)
      #             local wk_ok, wk = pcall(require, "which-key")
      #             if wk_ok then
      #               wk.add({
      #                 mode = "n",
      #                 { "<leader>cx", group = "extract" },
      #                 { "<leader>cxv", require("jdtls").extract_variable_all, desc = "Extract Variable" },
      #                 { "<leader>cxc", require("jdtls").extract_constant, desc = "Extract Constant" },
      #                 { "<leader>cgs", require("jdtls").super_implementation, desc = "Goto Super" },
      #                 { "<leader>cgS", require("jdtls.tests").goto_subjects, desc = "Goto Subjects" },
      #                 { "<leader>co", require("jdtls").organize_imports, desc = "Organize Imports" },
      #               })
      #               wk.add({
      #                 mode = "v",
      #                 { "<leader>cxm", function() require("jdtls").extract_method(true) end, desc = "Extract Method" },
      #                 { "<leader>cxv", function() require("jdtls").extract_variable_all(true) end, desc = "Extract Variable" },
      #                 { "<leader>cxc", function() require("jdtls").extract_constant(true) end, desc = "Extract Constant" },
      #               })
      #               -- Test running is handled by neotest-jdtls via <leader>t keymaps
      #             end
      #
      #             -- User-provided on_attach
      #             if opts.on_attach then opts.on_attach(args) end
      #           end,
      #         })
      #
      #         -- DAP: Remote attach configuration
      #         local dap_ok, dap = pcall(require, "dap")
      #         if dap_ok and not dap.configurations.java then
      #           dap.configurations.java = {
      #             { type = "java", name = "Remote Attach", request = "attach", hostName = "127.0.0.1", port = 5005 },
      #           }
      #         end
      #       end,
      #     },
      #   }
      # '';

      test = ''
        return {
          { "nvim-neotest/neotest-python" },
          -- { "atm1020/neotest-jdtls" },
          {
            "nvim-neotest/neotest",
            opts = {
              adapters = {
                "neotest-python",
                "rustaceanvim.neotest",
                -- "neotest-jdtls",
              },
            },
          },
        }
      '';

      tmux = ''
        return {
          "christoomey/vim-tmux-navigator",
          cmd = {
            "TmuxNavigateLeft",
            "TmuxNavigateDown",
            "TmuxNavigateUp",
            "TmuxNavigateRight",
            "TmuxNavigatePrevious",
          },
          keys = {
            { "<c-h>", "<cmd>TmuxNavigateLeft<cr>" },
            { "<c-j>", "<cmd>TmuxNavigateDown<cr>" },
            { "<c-k>", "<cmd>TmuxNavigateUp<cr>" },
            { "<c-l>", "<cmd>TmuxNavigateRight<cr>" },
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
                nes = {
                  enabled = false,
                },
                cli = {
                  mux = {
                    backend = "tmux",
                    enabled = true,
                    create = "split",
                  },
                },
              },
            }
          '';
        };
      };

      lang = {
        docker = langEnableFull;
        # Use nvim-java instead
        # java = langEnableFull;
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

      dap = {
        core.enable = true;
      };

      linting = {
        eslint.enable = true;
      };

      lsp = {
        # :Neoconf
        # .neoconf.json (project-local config)
        neoconf.enable = true;
        # Use Neovim as a language server to inject LSP diagnostics, code actions, and more via Lua.
        # none_ls.enable = true;
      };

      test = {
        # neotest
        # <leader>t
        core.enable = true;
      };

      ui = {
        # <leader>ue
        # edgy.enable = true;
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
    extraPackages = [
      jdtls-wrapped
    ]
    ++ (with pkgs-unstable; [
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
      nil # or nixd
      basedpyright # or ruff, pyright
      terraform-ls
      vtsls # for typescript
      yaml-language-server
    ]);
  };
}
