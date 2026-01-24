{ pkgs, flake-inputs, ... }:
{
  nixpkgs.overlays = [
    flake-inputs.nixos-muvm-fex.overlays.default
  ];

  environment.systemPackages = with pkgs; [ muvm ];
}
