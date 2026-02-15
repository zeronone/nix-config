{ pkgs, ... }:
{
  programs.ghostty = {
    enable = true;
    package = if pkgs.system == "aarch64-darwin" then null else pkgs.ghostty;
    enableZshIntegration = true;
    settings = {
      theme = "tokyonight-moon";
      # to make zellij work
      macos-option-as-alt = true;
      keybind = [
        # Both mac and linux
        "performable:ctrl+c=copy_to_clipboard"
        "performable:super+c=copy_to_clipboard"
        "super+v=paste_from_clipboard"
      ];
    };
    themes = {
      # https://github.com/catppuccin/ghostty/blob/main/themes/catppuccin-mocha.conf
      catppuccin-mocha = {
        background = "1e1e2e";
        foreground = "cdd6f4";
        cursor-color = "f5e0dc";
        cursor-text = "11111b";
        selection-background = "353749";
        selection-foreground = "cdd6f4";
        split-divider-color = "313244";
        palette = [
          "0=#45475a"
          "1=#f38ba8"
          "2=#a6e3a1"
          "3=#f9e2af"
          "4=#89b4fa"
          "5=#f5c2e7"
          "6=#94e2d5"
          "7=#a6adc8"
          "8=#585b70"
          "9=#f38ba8"
          "10=#a6e3a1"
          "11=#f9e2af"
          "12=#89b4fa"
          "13=#f5c2e7"
          "14=#94e2d5"
          "15=#bac2de"
        ];
      };

      # https://github.com/folke/tokyonight.nvim/blob/main/extras/ghostty/tokyonight_moon
      tokyonight-moon = {
        background = "#222436";
        foreground = "#c8d3f5";
        cursor-color = "#c8d3f5";
        selection-background = "#2d3f76";
        selection-foreground = "#c8d3f5";
        palette = [

          "0=#1b1d2b"
          "1=#ff757f"
          "2=#c3e88d"
          "3=#ffc777"
          "4=#82aaff"
          "5=#c099ff"
          "6=#86e1fc"
          "7=#828bb8"
          "8=#444a73"
          "9=#ff8d94"
          "10=#c7fb6d"
          "11=#ffd8ab"
          "12=#9ab8ff"
          "13=#caabff"
          "14=#b2ebff"
          "15=#c8d3f5"
        ];
      };

      monokai-pro-spectrum = {
        background = "222222";
        cursor-color = "bab6c0";
        foreground = "f7f1ff";
        palette = [
          "0=#222222"
          "1=#fc618d"
          "2=#7bd88f"
          "3=#fce566"
          "4=#fd9353"
          "5=#948ae3"
          "6=#5ad4e6"
          "7=#f7f1ff"
          "8=#69676c"
          "9=#fc618d"
          "10=#7bd88f"
          "11=#fce566"
          "12=#fd9353"
          "13=#948ae3"
          "14=#5ad4e6"
          "15=#f7f1ff"
        ];
        selection-background = "525053";
        selection-foreground = "f7f1ff";
      };
    };
  };
}
