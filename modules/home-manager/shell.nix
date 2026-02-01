{
  pkgs,
  lib,
  config,
  ...
}:
let
  binds = [
    "--bind='ctrl-d:preview-down'"
    "--bind='ctrl-u:preview-up'"
    "--bind='ctrl-space:toggle'"
    "--bind='ctrl-s:toggle-sort'"
    "--bind='ctrl-y:yank'"
    "--bind='ctrl-alt-p:change-preview-window(down|hidden|)'"
  ];
  sortFilesCmd = "${lib.getExe pkgs.eza} -s modified -1 --no-quotes --reverse";
in
{
  home.packages = with pkgs; [
    # Manually installing bash instead of home-manager
    # It messes up muvm
    # programs.bash.enable = true;
    bashInteractive

    fzf-preview
  ];

  programs.zsh = {
    enable = true;
    # To avoid conflict with ~/.zshrc modified by other means in work machines
    dotDir = "${config.home.homeDirectory}/.config/zsh";
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;

    history = {
      append = true;
      share = true;
      size = 50000;
    };

    plugins = [
      {
        name = "fzf-vi-mode";
        src = "${pkgs.zsh-vi-mode}/share/zsh-vi-mode";
      }
      {
        name = "fzf-tab";
        src = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
      }
    ];

    initContent = ''
      # needed instead of fzf.enableZshIntegration = true so zsh-vi-mode and fzf do not conflict
      zvm_after_init_commands+=(eval "$(fzf --zsh)")

      # We have set EDITOR=nvim, which enables vi keybindings
      # However the following two from emacs are useful, so we add it manually
      bindkey '^a' beginning-of-line
      bindkey '^e' end-of-line
    '';
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
  programs.nix-index = {
    enable = true;
    # messes up VM shells
    # enableBashIntegration = true;
    enableZshIntegration = true;
  };
  programs.nix-init = {
    enable = true;
  };
  programs.nix-your-shell = {
    enable = true;
    enableZshIntegration = true;
    nix-output-monitor.enable = true;
  };
  programs.nnn.enable = true;

  # eza
  programs.eza = {
    enable = true;
    colors = "auto";
    git = true;
    icons = "auto";
    extraOptions = [
      "--group"
      "--header"
      "--smart-group"
      "--classify=auto"
      "--group-directories-first"
    ];
  };
  # confire aliases for all shells
  home.shellAliases = rec {
    ls = "eza -al -s modified --reverse";
    lt = "${ls} --tree";
    tree = "${lt}";
    vim = "nvim";
    gs = "git status";
    gl = " git log --graph --decorate --pretty=oneline --abbrev-commit";
    gll = "git log --graph --abbrev-commit --decorate --date=relative --all";
  };

  # fzf
  programs.fd = {
    enable = true;
    hidden = true;
  };
  home.shellAliases.fzfp = "${lib.getExe pkgs.fzf} --preview='${lib.getExe pkgs.fzf-preview} {}'";

  programs.fzf = {
    enable = true;
    defaultCommand = "fd -t f";
    changeDirWidgetCommand = "fd -t d";
    fileWidgetCommand = "fd -t f -X ${sortFilesCmd}";
    fileWidgetOptions = binds ++ [ "--preview='${lib.getExe pkgs.fzf-preview} {}'" ];
    changeDirWidgetOptions = binds ++ [ "--preview='${lib.getExe pkgs.eza} -T {}'" ];
    # conflicts with zsh-vi-mode
    # Enabled explicitly in programs.zsh.initExtra
    # enableZshIntegration = true;
  };
}
