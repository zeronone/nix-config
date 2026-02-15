{ _, ... }:
{
  programs.tmux = {
    enable = true;
    tmuxp.enable = true;

    # It changes <Esc>+j to <A-j> and thus moving lines in nvim
    escapeTime = 0;
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
