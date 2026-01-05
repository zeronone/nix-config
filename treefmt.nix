{ pkgs, ... }:
{
  # Used to find the project root
  projectRootFile = "flake.nix";
  # Enable the nix formatter
  programs.nixfmt.enable = true;
  # Enable markdown formatter
  programs.mdformat.enable = true;
}
