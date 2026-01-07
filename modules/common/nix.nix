{ ... }:
{
  nix.settings = {
    substituters = [
      "https://cache.nixos.org/"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];

    trusted-users = [ "@admin" ];

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

  # Don't need channels since I use flakes
  nix.channel.enable = false;
}
