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
  };
}
