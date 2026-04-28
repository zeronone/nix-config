{
  pkgs,
  pkgs-unstable,
  lib,
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
    let
      # Build a chromium native-messaging-host package: drops <name>.json into
      # etc/chromium/native-messaging-hosts/, which the home-manager chromium
      # module symlinks into ~/.config/chromium/NativeMessagingHosts/.
      mkChromiumNativeMessagingHost =
        manifest:
        pkgs.runCommand "${manifest.name}-chromium-native-messaging-host"
          {
            manifestJson = builtins.toJSON manifest;
            passAsFile = [ "manifestJson" ];
          }
          ''
            install -Dm644 "$manifestJsonPath" \
              "$out/etc/chromium/native-messaging-hosts/${manifest.name}.json"
          '';

      claudeChromeExtensionId = "fcoeoabgfenejglbffodgkkbkcdhcgfn";
      # Claude Code creates the native host binary at runtime when /chrome runs.
      # We only ship the manifest pointing at that path so chromium can find it.
      claudeCodeNativeMessagingHost = mkChromiumNativeMessagingHost {
        name = "com.anthropic.claude_code_browser_extension";
        description = "Claude Code Browser Extension Native Messaging Host";
        path = "/home/${username}/.claude/chrome/chrome-native-host";
        type = "stdio";
        allowed_origins = [
          "chrome-extension://${claudeChromeExtensionId}/"
        ];
      };

      keepassxcChromeExtensionId = "oboonakemofpalcgghocfoadofidjkkk";
      # pkgs.keepassxc only ships the Mozilla manifest, so build the chromium
      # one ourselves pointing at the same keepassxc-proxy binary.
      keepassxcChromiumNativeMessagingHost = mkChromiumNativeMessagingHost {
        name = "org.keepassxc.keepassxc_browser";
        description = "KeePassXC integration with native messaging support";
        path = "${pkgs.keepassxc}/bin/keepassxc-proxy";
        type = "stdio";
        allowed_origins = [
          "chrome-extension://${keepassxcChromeExtensionId}/"
        ];
      };
    in
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

      # The following GUI apps are directly managed by Nix
      # We want more control on them, with proper versioning
      programs.firefox = {
        enable = true;
        # KeePassXC ships the Firefox manifest under lib/mozilla/native-messaging-hosts/
        nativeMessagingHosts = [ pkgs.keepassxc ];
      };
      programs.chromium = {
        enable = true;
        # Use latest from unstable
        # Enable DRM support to run Spotify, Netflix
        package = pkgs-unstable.chromium.override { enableWideVine = true; };
        commandLineArgs = [
          "--ignore-gpu-blocklist"
          "--ozone-platform=wayland"
        ];
        extensions = [
          # Vimium extension ID
          { id = "dbepggeogbaibhgnhhndojpepiihcmeb"; }
          # keepassxc
          { id = keepassxcChromeExtensionId; }
          # Claude for Chrome
          { id = claudeChromeExtensionId; }
        ];
        nativeMessagingHosts = [
          claudeCodeNativeMessagingHost
          keepassxcChromiumNativeMessagingHost
        ];
      };
    };
}
