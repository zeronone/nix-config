{ ... }:
{
  services.envfs.enable = true;
  environment.sessionVariables.ENVFS_RESOLVE_ALWAYS = "1";

  programs.nix-ld.enable = lib.mkDefault true;
  # These libararies doesn't need to be configured in NIX_LD_LIBRARY_PATH
  # and auto-configured
  programs.nix-ld.libraries =
    with pkgs;
    [
      acl
      attr
      bzip2
      dbus
      expat
      fontconfig
      freetype
      fuse3
      icu
      libnotify
      libsodium
      libssh
      libunwind
      libusb1
      libuuid
      nspr
      nss
      stdenv.cc.cc
      util-linux
      zlib
      zstd
    ]
    ++ lib.optionals (config.hardware.graphics.enable) [
      pipewire
      cups
      libxkbcommon
      pango
      mesa
      libdrm
      libglvnd
      libpulseaudio
      atk
      cairo
      alsa-lib
      at-spi2-atk
      at-spi2-core
      gdk-pixbuf
      glib
      gtk3
      libGL
      libappindicator-gtk3
      vulkan-loader
    ];
}
