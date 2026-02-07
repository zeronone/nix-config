{
  pkgs,
  config,
  flake-inputs,
  ...
}:
let
  helpers = config.lib.nixvim;
  mkCmdlineMap =
    action: fallback:
    helpers.mkRaw ''
      {
            function (cmp)
              if vim.fn.getcmdtype() ~= ':' then
                return cmp.${action}()
              end
            end,
            "${fallback}",
          }'';
in
{
  imports = [
    flake-inputs.nixvim.homeModules.nixvim
  ];

  programs.nixvim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    defaultEditor = true;
    waylandSupport = true;

    globals.mapleader = "\<space>";
    globals.maplocalleader = "\<space>";

    extraPlugins = with pkgs.vimPlugins; [
      vim-nix
    ];

    opts = {
      number = true; # Show line numbers
      relativenumber = true; # Show relative line numbers
      shiftwidth = 2; # Tab width should be 2
      expandtab = true;
    };

    keymaps = [
      {
        mode = [ "i" ];
        key = "<C-e>";
        action = "<Esc>A";
        options = {
          noremap = true;
          silent = true;
        };
      }
      {
        mode = [ "i" ];
        key = "<C-a>";
        action = "<Esc>I";
        options = {
          noremap = true;
          silent = true;
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

    # Mini package
    plugins.mini.enable = true;

    # Core
    plugins.fzf-lua.enable = true;
    plugins.trouble.enable = true;

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

    # completion
    plugins.blink-cmp = {
      enable = true;
      settings = {
        sources.default = [ "lsp" ];

        completion = {
          documentation.auto_show = true;
          documentation.auto_show_delay_ms = 50;
          menu.auto_show = true;
          ghost_text.show_with_menu = true;

          list.selection.preselect = true;
          list.selection.auto_insert = true;
        };

        keymap = {
          preset = "enter";
          "<c-p>" = mkCmdlineMap "select_prev" "fallback_to_mappings";
          "<c-n>" = mkCmdlineMap "select_next" "fallback_to_mappings";
          "<tab>" = [
            "select_next"
            "fallback"
          ];
          "<s-tab>" = [
            "select_prev"
            "fallback"
          ];
          "<c-b>" = [
            "scroll_documentation_up"
            "fallback"
          ];
          "<c-f>" = [
            "scroll_documentation_down"
            "fallback"
          ];
          "<c-k>" = [
            "show_signature"
            "hide_signature"
            "fallback"
          ];
        };

        signature.enabled = true;
        signature.window.show_documentation = true;

        cmdline.keymap = {
          preset = "inherit";
        };
        cmdline.completion.list.selection.preselect = false;
        cmdline.completion.menu.auto_show = true;
      };
    };
    plugins.blink-ripgrep.enable = true;

    # Rust
    plugins.rustaceanvim.enable = true;
    plugins.dap-lldb.enable = true;

    # Misc
    plugins.neo-tree.enable = true;
    plugins.which-key.enable = true;
    plugins.harpoon.enable = true;
  };
}
