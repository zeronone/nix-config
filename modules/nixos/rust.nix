{ pkgs, flake-inputs, ... }:
{
  nixpkgs.overlays = [
    flake-inputs.rust-overlay.overlays.default
    (final: prev: {
      rust-stable = prev.rust-bin.stable.latest.default.override {
        extensions = [
          "rustc"
          "cargo"
          "rust-std"
          "rust-src"
          "rust-docs"
          "clippy"
          "rustfmt"
          "rust-analyzer"
          "llvm-tools"
        ];
      };
    })
  ];
  environment.systemPackages = [
    pkgs.rust-stable
  ];
}
