{
  pkgs,
  ...
}:
let
  muvm-fex-overlay = final: prev: {
    # Mesa for inside the MicroVM container
    mesa-x86_64-linux = final.pkgsCross.gnu64.mesa;
    # Still need this Asahi fork of virglrenderer
    virglrenderer = prev.virglrenderer.overrideAttrs (old: {
      src = final.fetchurl {
        url = "https://gitlab.freedesktop.org/asahi/virglrenderer/-/archive/asahi-20250424/virglrenderer-asahi-20250424.tar.bz2";
        hash = "sha256-9qFOsSv8o6h9nJXtMKksEaFlDP1of/LXsg3LCRL79JM=";
      };
      mesonFlags = old.mesonFlags ++ [ (final.lib.mesonOption "drm-renderers" "asahi-experimental") ];
    });
  };
in
{
  # Background
  # https://docs.fedoraproject.org/en-US/fedora-asahi-remix/x86-support/

  # Default nixos emulation uses qemu-user-static (i.e: qeumu-x86_64-static for emulation)
  # But apple silicon requires 16K pages, but most x86 apps don't work well with it.

  # FEX is a fast x86 emulator
  # FEX also supports 4K pages only, and most programs don't support 16K pages well
  # muvm launches a microVM (with 4K kernel) and then uses FEX emulator to run x86 programs

  # Virtualization: muvm -> FEX -> x86 binary

  # Run x86 binaries inside muvm and interpret with FEX
  # muvm -- FEXBash -c 'nix run nixpkgs#legacyPackages.x86_64-linux.hello'

  # Run flatpak apps
  # muvm -- flatpak run org.example.AppName
  # muvm -- FEXBash -c 'flatpak run org.example.AppName'

  # Overlay on pkgs-stable, as our mesa driver comes from there
  nixpkgs.overlays = [ muvm-fex-overlay ];

  # Enable virtualization (check if really needed ?)
  # virtualisation.libvirtd.enable = true;

  # Install necessary deps
  # muvm is already installed with a wrapper that adds --execute-pre
  # and loads the necessary GPU drivers
  environment.systemPackages = with pkgs; [
    mesa-x86_64-linux
    muvm
    fex
  ];
}
