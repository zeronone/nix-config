{ pkgs, config, ... }:
{
  programs.zsh = {
    enable = true;
    # To avoid conflict with ~/.zshrc modified by other means in work machines
    dotDir = "${config.home.homeDirectory}/.config/zsh";
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    shellAliases = {
      vim = "nvim";
      ls = "ls -alGh";
      ll = "ls -alGh";
      gs = "git status";
      gl = " git log --graph --decorate --pretty=oneline --abbrev-commit";
      gll = "git log --graph --abbrev-commit --decorate --date=relative --all";
    };

    history = {
      append = false;
      share = false;
      size = 10000;
    };
  };
  programs.git = {
    enable = true;
    settings.init.defaultBranch = "main";
  };
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "tokyo-night";
      theme_background = true;
      truecolor = true;
    };
  };
}
