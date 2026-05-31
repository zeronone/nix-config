{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    tmuxp.enable = true;

    plugins = with pkgs.tmuxPlugins; [
      vim-tmux-navigator
    ];

    extraConfig = ''
      set -g default-terminal "tmux-256color"
      # Tell tmux that Ghostty supports True Color (RGB/Tc)
      set -as terminal-features ",xterm-ghostty:RGB"
      # Enable synchronized updates (reduces flickering in Ghostty)
      set -as terminal-features ",xterm-ghostty:sync"

      # Enable undercurl support
      set -as terminal-overrides ',xterm-ghostty:Smulx=\E[4::%p1%dm'
      # Enable undercurl colors
      set -as terminal-overrides ',xterm-ghostty:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'

      # Enable mouse support
      set -g mouse on
      # Make scrolling speed in tmux copy-mode slightly more natural
      bind -T copy-mode-vi WheelUpPane select-pane \; send-keys -X -N 2 scroll-up
      bind -T copy-mode-vi WheelDownPane select-pane \; send-keys -X -N 2 scroll-down

      set -g focus-events on

      # Start windows index at 1
      set -g base-index 1
      # Start panes index at 1
      setw -g pane-base-index 1

      # make Shift-Enter work in terminal
      # Enable extended keys
      set -s extended-keys on
      set -as terminal-features 'xterm*:extkeys'
      # Manual passthrough (if the above doesn't work for your specific term)
      bind -n S-Enter send-keys Escape "[13;2u"

      # Enable automatic renaming
      set-option -g automatic-rename on
      # Update the status line every 5 seconds to keep the name current
      set-option -g status-interval 5
      # Rename to CWD (basename) if the command is 'bash' or 'zsh', else show the command
      set-option -g automatic-rename-format "#{?#{or:#{==:#{pane_current_command},bash},#{==:#{pane_current_command},zsh}},#{b:pane_current_path},#{pane_current_command}}"

      # enable clipboard (paste image to CLI tool)
      set -s set-clipboard on

      # Allow programs in tmux to bypass tmux and send graphics to the terminal (e.g. Kitty Graphics Protocol)
      set -g allow-passthrough on

      # Update Wayland display and terminal program environment variables when attaching to tmux
      set -g update-environment "WAYLAND_DISPLAY XDG_RUNTIME_DIR TERM_PROGRAM TERM_PROGRAM_VERSION"
    '';

    # It changes <Esc>+j to <A-j> and thus moving lines in nvim
    escapeTime = 0;
    keyMode = "vi";
    prefix = "C-a";
    historyLimit = 50000;
    resizeAmount = 10;
    terminal = "tmux-256color";
    mouse = true;
    # create new session if not existing
    newSession = true;
    clock24 = true;
  };
}
