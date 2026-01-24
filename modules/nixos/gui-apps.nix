{
  username,
  ...
}:
{
  # Ensure XDG_DATA_DIRS dirs etc are properly configured
  # The home-manager module below doesn't configure it
  services.flatpak.enable = true;

  home-manager.users.${username} =
    {
      pkgs,
      username,
      flake-inputs,
      ...
    }:
    {
      # Two types of GUI apps
      # Nix-managed (properly versioned and configured)
      # Flatpak-managed (don't care about versioning)

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
        uninstallUnused = false;
        update = {
          onActivation = false;
          auto = {
            enable = true;
            onCalendar = "weekly";
          };
        };

        overrides = {
          global = {
            # Force Wayland by default
            Context.sockets = [
              "wayland"
              "!x11"
              "!fallback-x11"
            ];

            Environment = {
              # Force correct theme for some GTK apps
              GTK_THEME = "Adwaita:dark";
            };
          };

          # example overrides
          # "org.onlyoffice.desktopeditors".Context.sockets = ["x11"]; # No Wayland support
          # "com.visualstudio.code".Context = {
          #   filesystems = [
          #     "xdg-config/git:ro" # Expose user Git config
          #     "/run/current-system/sw/bin:ro" # Expose NixOS managed software
          #   ];
          #   sockets = [
          #     "gpg-agent" # Expose GPG agent
          #     "pcsc" # Expose smart cards (i.e. YubiKey)
          #   ];
          # };
        };

        packages = [
          # "us.zoom.Zoom"
          "org.libreoffice.LibreOffice"
          "md.obsidian.Obsidian"
          "org.gnome.Calculator"
          "com.discordapp.Discord/x86_64"
          # "org.videolan.VLC"
          # "com.valvesoftware.Steam"
          # "com.spotify.Client"
        ];
      };

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
    };
}
