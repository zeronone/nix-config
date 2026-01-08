{ lib, ... }:
{
  # work machine ~/.zshrc is populated with necessary env vars
  programs.zsh = {
    envExtra = ''
      export PATH="/opt/homebrew/bin:$PATH"
      if [ -f "$HOME/.zshrc" ]; then
          source "$HOME/.zshrc"
      fi
    '';
    # Need to restore MacOSX path_helper for work machine
    # priority 500 (Early Initialization) /etc/zshrc
    initContent = lib.mkOrder 500 ''
      # Restore standard macOS paths that Nix-Darwin might have deprioritized
      if [ -x /usr/libexec/path_helper ]; then
        eval $(/usr/libexec/path_helper -s)
      fi
    '';
  };
}
