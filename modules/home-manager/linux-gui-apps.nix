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
    package = pkgs.vscodium;
    profiles.defualt.extensions = with pkgs.vscode-extensions; [
      dracula-theme.theme-dracula
      vscodevim.vim
      yzhang.markdown-all-in-one
    ];
  };
}
