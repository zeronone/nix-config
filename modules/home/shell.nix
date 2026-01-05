{ pkgs, ... }: {
  programs.zsh = {
    enable = true;
    shellAliases = {
      ll = "ls -l";
      gs = "git status";
      # Now you can just type 'apply' from anywhere in your repo
      apply = "just switch";
    };
  };
  programs.git = {
    enable = true;
    settings.init.defaultBranch = "main";
  };
}
