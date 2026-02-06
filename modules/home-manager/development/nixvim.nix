{ pkgs, flake-inputs, ... }:
{
  imports = [
    flake-inputs.nixvim.homeModules.nixvim
  ];

  programs.nixvim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    defaultEditor = true;

    globals.mapleader = ",";

    extraPlugins = with pkgs.vimPlugins; [
      vim-nix
    ];

    opts = {
      number = true; # Show line numbers
      relativenumber = true; # Show relative line numbers
      shiftwidth = 2; # Tab width should be 2
      expandtab = true;
    };

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

    # UI
    plugins.lualine.enable = true;

    # VCS
    plugins.neogit.enable = true;
    plugins.gitsigns.enable = true;
    plugins.diffview.enable = true;
    plugins.web-devicons.enable = true;

    # LSP
    plugins.lspconfig.enable = true;
    plugins.dap.enable = true;

    # Rust
    plugins.rustaceanvim.enable = true;
    plugins.dap-lldb.enable = true;

    # Misc
    plugins.neo-tree.enable = true;
    plugins.which-key.enable = true;
    plugins.harpoon.enable = true;
  };
}
