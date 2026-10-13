{ config, ... }:
{
  # GitHub token for flake fetches (avoids API rate limits), kept in the user's nix.conf
  # rather than the system one. `!include` skips the file if it doesn't exist.
  # Run: (umask 077; echo "access-tokens = github.com=$(gh auth token)" > ~/.secrets/nix-github-token.conf)
  nix.extraOptions = ''
    !include ${config.home.homeDirectory}/.secrets/nix-github-token.conf
  '';
}
