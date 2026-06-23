{ lib, ... }:
{
  # work machine: source ~/.zprofile before ~/.zshrc so work env loads correctly
  # (dotDir below redirects ZDOTDIR, so these are not read automatically)
  programs.zsh = {
    envExtra = ''
      export PATH="/opt/homebrew/bin:$PATH"
      if [ -f "$HOME/.zprofile" ]; then
          source "$HOME/.zprofile"
      fi
      if [ -f "$HOME/.zshrc" ]; then
          source "$HOME/.zshrc"
      fi
    '';
  };
}
