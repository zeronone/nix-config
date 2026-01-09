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
}
