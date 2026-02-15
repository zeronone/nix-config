{ _, ... }:
{
  programs.tmux = {
    enable = true;
    tmuxp.enable = true;

    keyMode = "vi";
    prefix = "C-a";
    historyLimit = 50000;
    resizeAmount = 10;
    terminal = "screen-256color";
    mouse = true;
    # create new session if not existing
    newSession = true;
    clock24 = true;
  };
}
