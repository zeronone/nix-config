{ pkgs, flake-inputs, ... }:
{
  # Applying the overlay only for muvm
  environment.systemPackages =
    let
      # Use if you want to overwrite mesaDoCross
      pkgsFex = import pkgs.path {
        system = pkgs.system;

        # Set to false if you have an x86_64 builder available
        # Will default to false if your nixpkgs is new enough
        # config.nixos-muvm-fex.mesaDoCross = false;
        overlays = [ flake-inputs.nixos-muvm-fex.overlays.default ];
      };
    in
    [ pkgsFex.muvm ];
}
