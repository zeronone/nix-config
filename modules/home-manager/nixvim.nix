{ pkgs, inputs, ... }:
{
  imports = [
    inputs.nixvim.homeModules.nixvim
  ];

  programs.nixvim = {
    enable = true;

    extraPlugins = with pkgs.vimPlugins; [
      vim-nix
    ];

    opts = {
      clipboard = "unnamedplus";
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

    plugins.lightline.enable = true;
    plugins.lualine.enable = true;
  };

}
