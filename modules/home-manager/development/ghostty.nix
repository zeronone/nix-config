{ pkgs, ... }:
{
  programs.ghostty = {
    enable = true;
    package = if pkgs.system == "aarch64-darwin" then null else pkgs.ghostty;
    enableZshIntegration = true;
    settings = {
      theme = "monokai-pro-spectrum";
      keybind = [
        "ctrl+h=goto_split:left"
        "ctrl+l=goto_split:right"

        # Both mac and linux
        "performable:ctrl+c=copy_to_clipboard"
        "performable:super+c=copy_to_clipboard"
        "super+v=paste_from_clipboard"
      ];
    };
    themes = {
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
