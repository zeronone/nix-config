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
          # "com.visualstudio.code".Context = {
          #   filesystems = [
          #     "xdg-config/git:ro" # Expose user Git config
          #     "/run/current-system/sw/bin:ro" # Expose NixOS managed software
          #   ];
          # };
        };

        packages = [
          # "us.zoom.Zoom"
          "org.libreoffice.LibreOffice"
          "md.obsidian.Obsidian"
          "org.gnome.Calculator"
          "org.videolan.VLC"

          # x86 only available
          "com.discordapp.Discord/x86_64"
          "com.valvesoftware.Steam/x86_64"

          # Doesn't install
          # "com.spotify.Client/x86_64"
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
    };
}
