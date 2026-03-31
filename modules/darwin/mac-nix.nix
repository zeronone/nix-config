{ lib, config, ... }:
{
  # nix-darwin specific settings
  nix.optimise = lib.mkIf config.nix.enable {
    automatic = true;
    interval.Hour = 4;
  };
}
