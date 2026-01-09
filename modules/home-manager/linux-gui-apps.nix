{ pkgs, ... }:
{
  programs.firefox.enable = true;
  programs.chromium = {
    enable = true;
    extensions = [
      # Vimium extension ID
      { id = "dbepggeogbaibhgnhhndojpepiihcmeb"; }
    ];
  };
  programs.ghostty.enable = true;
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium.fhs;
  };
}
