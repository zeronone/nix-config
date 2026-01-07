{ pkgs, inputs, ... }:
{
  imports = [
    inputs.nixvim.homeModules.nixvim
  ];

  programs.nixvim = {
    enable = true;
    viAlias = true;
    vimAlias = true;

    extraPlugins = with pkgs.vimPlugins; [
      vim-nix
    ];

    opts = {
      number = true; # Show line numbers
      relativenumber = true; # Show relative line numbers
      shiftwidth = 2; # Tab width should be 2
      expandtab = true;
    };

    colorschemes.catppuccin = {
      settings = {
        flavours = "mocha";
        transparent_background = true;
      };
    };

    editorconfig.enable = true;
    clipboard.register = "unnamedplus";

    plugins.lightline.enable = true;
    plugins.lualine.enable = true;
  };

}
