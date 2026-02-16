{ _, ... }:
{
  programs.tmux = {
    enable = true;
    tmuxp.enable = true;

    extraConfig = ''
      set -g focus-events on
      # truecolor support
      set -ga terminal-overrides ",*256col*:Tc"

      # From: https://github.com/christoomey/vim-tmux-navigator/blob/master/README.md#add-a-snippet
      vim_pattern='(\S+/)?g?\.?(view|l?n?vim?x?|fzf)(diff)?(-wrapped)?'
      is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
          | grep -iqE '^[^TXZ ]+ +''${vim_pattern}$'"
      bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h'  'select-pane -L'
      bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j'  'select-pane -D'
      bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k'  'select-pane -U'
      bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l'  'select-pane -R'
      bind-key -T copy-mode-vi 'C-h' select-pane -L
      bind-key -T copy-mode-vi 'C-j' select-pane -D
      bind-key -T copy-mode-vi 'C-k' select-pane -U
      bind-key -T copy-mode-vi 'C-l' select-pane -R
    '';

    # It changes <Esc>+j to <A-j> and thus moving lines in nvim
    escapeTime = 0;
    keyMode = "vi";
    prefix = "C-a";
    historyLimit = 50000;
    resizeAmount = 10;
    terminal = "xterm-256color";
    mouse = true;
    # create new session if not existing
    newSession = true;
    clock24 = true;
  };
}
