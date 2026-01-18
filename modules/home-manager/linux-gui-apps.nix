{ pkgs, ... }:
{
  home.packages = with pkgs; [
    wezterm
  ];
  programs.firefox.enable = true;
  programs.chromium = {
    enable = true;
    extensions = [
      # Vimium extension ID
      { id = "dbepggeogbaibhgnhhndojpepiihcmeb"; }
    ];
  };
  programs.vscode = {
    enable = true;
    # some extensions expect these programs to be available
    package = pkgs.vscodium.fhsWithPackages (
      ps: with ps; [
        rustup
        zlib
      ]
    );

    profiles.default.extensions = with pkgs.vscode-marketplace; [

      # Core & Vim
      vscodevim.vim
      mkhl.direnv

      # Nix Development
      jnoortheen.nix-ide
      arrterian.nix-env-selector
      pinage404.nix-extension-pack

      # Rust Development
      rust-lang.rust-analyzer
      tamasfe.even-better-toml
      fill-labs.dependi
      swellaby.vscode-rust-test-adapter
      pinage404.rust-extension-pack

      # Testing Utilities
      hbenl.vscode-test-explorer
      ms-vscode.test-adapter-converter

      # Misc
      dracula-theme.theme-dracula
      yzhang.markdown-all-in-one
    ];
  };
}
