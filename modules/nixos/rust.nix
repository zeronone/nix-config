{
  pkgs,
  pkgs-unstable,
  flake-inputs,
  config,
  ...
}:
{
  nixpkgs.overlays = [
    flake-inputs.rust-overlay.overlays.default
    flake-inputs.bacon-ls.overlay.${config.nixpkgs.hostPlatform.system}
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
  environment.systemPackages =
    (with pkgs; [
      rust-stable
      # cargo run requires linker
      # Handy to have for non-nix projects
      gcc
    ])
    ++ (with pkgs-unstable; [
      # TODO: revert when aarch64 build is ready
      # bacon-ls
    ]);
}
