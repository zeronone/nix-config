{ pkgs, ... }:
{
  home.packages = with pkgs; [
    fnm
  ];

  programs.zsh = {
    envExtra = ''
      eval "$(fnm env --use-on-cd --shell zsh)"
    '';
  };

}
