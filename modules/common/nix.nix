{
  lib,
  config,
  username,
  homeDirectory,
  ...
}:
{
  nix.settings = {
    substituters = [
      "https://cache.nixos.org/"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];

    # Also configure upstream caches at
    # https://app.cachix.org/cache/zeronone/settings/general
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://ghc.cachix.org"
      "https://zeronone.cachix.org"
      "https://devenv.cachix.org"
      "https://cachix.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "ghc.cachix.org-1:a751hwq9ydeP3Nr6h84iA9zSjxg9Z3uznqi4YBGjsiw="
      "zeronone.cachix.org-1:3BGnunMHKptFrTGL2q2wa8oLBRpsjRaAq6hDri30WGM="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "cachix.cachix.org-1:eWNHQldwUO7G2VkjpnjDbWwy4KQ/HNxht7H4SSoMckM="
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

  nix.gc = lib.mkIf config.nix.enable {
    automatic = true;
    options = "--delete-older-than 7d";
  };

  # Enable parallel builds
  nix.settings.max-jobs = "auto";

  # Run: echo "access-tokens = github.com=$(gh auth token)" > ~/.secrets/nix-github-token.conf
  nix.extraOptions = ''
    !include ${homeDirectory}/.secrets/nix-github-token.conf
  '';

  # Don't need channels since I use flakes
  nix.channel.enable = false;
}
