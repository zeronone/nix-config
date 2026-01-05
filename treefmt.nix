{ pkgs, ... }:
{
  # Used to find the project root
  projectRootFile = "flake.nix";
  # Enable the nix formatter
  programs.nixfmt.enable = true;
}
