{
  pkgs,
  flake-inputs,
  username,
  ...
}:
{
  # Pre-requisites
  # Must have enabled xdg-portal.nix
  imports = [
    flake-inputs.nix-flatpak.homeManagerModules.nix-flatpak
  ];

  # Like homebrew, fetches the latest version
  # We don't care much about versioning these
  services.flatpak = {
    enable = true;
    uninstallUnmanaged = false;
    uninstallUnused = true;
    update = {
      onActivation = false;
      auto = {
        enable = true;
        onCalendar = "weekly";
      };
    };
  };
  services.flatpak.packages = [
    "com.discordapp.Discord"
    "org.videolan.VLC"
    "com.valvesoftware.Steam"
    "com.spotify.Client"
    "md.obsidian.Obsidian"
    "org.libreoffice.LibreOffice"
    "us.zoom.Zoom"
    "org.gnome.Calculator"
  ];

  # The following are directly managed by Nix
  # We want more control on them, with proper versioning
  programs.firefox.enable = true;
  programs.chromium = {
    enable = true;
    extensions = [
      # Vimium extension ID
      { id = "dbepggeogbaibhgnhhndojpepiihcmeb"; }
    ];
  };
  programs.ghostty.enable = true;
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
