{ pkgs, ... }:
{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    shellAliases = {
      ll = "ls -l";
      gs = "git status";
    };
  };
  programs.git = {
    enable = true;
    settings.init.defaultBranch = "main";
  };
}
