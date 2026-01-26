{ username, homeDirectory, ... }:
{
  nix.settings = {
    substituters = [
      "https://cache.nixos.org/"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];

    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://zeronone.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "zeronone.cachix.org-1:PbaDDNg+I3i0ykG67L2SBt7Z5wtS52kH8l+CEJCnqro="
    ];

    trusted-users = [
      "@admin"
      username
    ];

    # https://github.com/NixOS/nix/issues/7273
    auto-optimise-store = false;

    experimental-features = [
      "nix-command"
      "flakes"
    ];

    # Recommended when using `direnv` etc.
    keep-derivations = true;
    keep-outputs = true;
  };

  # Run: echo "access-tokens = github.com=$(gh auth login)" > ~/.secrets/github-token.conf
  nix.extraOptions = ''
    !include ${homeDirectory}/.secrets/github-token.conf
  '';

  # Don't need channels since I use flakes
  nix.channel.enable = false;
}
