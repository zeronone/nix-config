{
  pkgs,
  pkgs-unstable,
  lib,
  ...
}:
let
  muvm-fex-overlay = final: prev: {
    # 1. Update libkrunfw to 5.1.0 (Required for libkrun 1.17.0)
    libkrunfw = prev.libkrunfw.overrideAttrs (old: rec {
      version = "5.1.0";
      src = final.fetchFromGitHub {
        owner = "containers";
        repo = "libkrunfw";
        tag = "v${version}";
        hash = "sha256-x9HQP+EqCteoCq2Sl/TQcfdzQC5iuE4gaSKe7tN5dAA=";
      };

      # libkrunfw 5.1.0 rebases on kernel 6.12.62
      kernelSrc = final.fetchurl {
        url = "mirror://kernel/linux/kernel/v6.x/linux-6.12.62.tar.xz";
        hash = "sha256-E+LGhayPq13Zkt0QVzJVTa5RSu81DCqMdBjnt062LBM=";
      };
    });

    # 2. Update libkrun to 1.17.0
    libkrun = prev.libkrun.overrideAttrs (old: rec {
      version = "1.17.0";
      src = final.fetchFromGitHub {
        owner = "containers";
        repo = "libkrun";
        tag = "v${version}";
        hash = "sha256-6HBSL5Zu29sDoEbZeQ6AsNIXUcqXVVGMk0AR2X6v1yU=";
      };

      # Cargo dependencies will change with the new version
      cargoDeps = final.rustPlatform.fetchCargoVendor {
        inherit src;
        hash = "sha256-UIzbtBJH6aivoIxko1Wxdod/jUN44pERX9Hd+v7TC3Q=";
      };

      # Ensure we link against the NEW libkrunfw defined above
      buildInputs = [ final.libkrunfw ] ++ final.lib.filter (i: i != prev.libkrunfw) old.buildInputs;
    });

    # Mesa from pkgs-stable
    # Mesa for inside the MicroVM container
    mesa-x86_64-linux = final.pkgsCross.gnu64.mesa;
    # Still need this Asahi fork of virglrenderer
    virglrenderer = prev.virglrenderer.overrideAttrs (old: {
      src = final.fetchurl {
        url = "https://gitlab.freedesktop.org/asahi/virglrenderer/-/archive/asahi-20250424/virglrenderer-asahi-20250806.tar.bz2";
        hash = "sha256-96qatlyDxn8IA8/WLH58XUwThDIzNOGpgXvDQ9/cqjA=";
      };
      mesonFlags = old.mesonFlags ++ [ (final.lib.mesonOption "drm-renderers" "asahi-experimental") ];
    });

    fex = pkgs-unstable.fex;

    # Override muvm: Remove default wrappers and inject updated deps
    # Default wrappers adds:
    # --add-flags "--execute-pre=... to mount opengl drivers
    # We already prepare a custom rootfs
    muvm = (
      pkgs-unstable.muvm.override {
        libkrun = final.libkrun;
      }
    );

    fex-emu-rootfs-fedora = pkgs.stdenv.mkDerivation rec {
      pname = "fex-emu-rootfs-fedora";
      version = "1.1.2-fc43";

      src = pkgs.fetchurl {
        url = "https://riscv-kojipkgs.fedoraproject.org//packages/fex-emu-rootfs-fedora/42%5E1.1/2.fc43/noarch/fex-emu-rootfs-fedora-42%5E1.1-2.fc43.noarch.rpm";
        sha256 = "sha256-xyN2yWi+1ErbCT/gynZFxrXjYdyUvEE76nfddotOPAQ=";
      };

      # Required tools
      nativeBuildInputs = [
        final.rpm
        final.cpio
        final.autoPatchelfHook
      ];

      unpackPhase = ''
        # Extract the RPM content
        rpm2cpio $src | cpio -idmv
      '';

      installPhase = ''
        # Copy files to the Nix store
        mkdir -p $out
        cp -r usr/share/fex-emu/RootFS $out/
      '';
    };

  };
  # The Init Script
  # This script runs INSIDE the VM as root.
  vmInitScript = pkgs.writeShellApplication {
    name = "muvm-guest-init.sh";
    runtimeInputs = [
      pkgs.coreutils
    ];
    text = ''
      set -x

      # Host Paths (Nix Store Paths)
      # HOST_MESA="${pkgs.mesa-x86_64-linux}"

      # Guest Paths (Prefix with /run/muvm-host)
      # GUEST_MESA="/run/muvm-host$HOST_MESA"

      # MESA_SRC="$GUEST_MESA"

      # 1. Setup OpenGL Driver
      # # We symlink the host's cross-compiled mesa to /run/opengl-driver
      # mkdir -p /run/opengl-driver
      # ln -sf "$MESA_SRC" /run/opengl-driver
    '';
  };

  # --- 3. The Runner ---
  muvm-x86-runner = pkgs.writeShellScriptBin "muvm-x86-runner" ''
    echo ":: Launching muvm..."
    echo ":: Will run: $@"
    echo ":: FEX RootFS at: ${pkgs.fex-emu-rootfs-fedora}/RootFS/default.erofs"

    exec ${pkgs.muvm}/bin/muvm \
      --execute-pre "${lib.getExe vmInitScript}" \
      --fex-image "${pkgs.fex-emu-rootfs-fedora}/RootFS/default.erofs" \
      $@
  '';
in
{
  # Background
  # https://docs.fedoraproject.org/en-US/fedora-asahi-remix/x86-support/

  # What does muvm do?
  # 1. Creates a MicroVM: Launches a libkrun-based virtual machine running a 4K-page Linux kernel to
  #    bypass the 16K-page incompatibility of the Apple Silicon host.
  # 2. Mirrors Host Filesystem: Mounts the host's root filesystem inside the VM (sharing /usr, /home, etc.)
  #    while keeping specific directories like /dev and /run private to the guest.
  # 3. Enables Emulation: Configures the guest's binfmt_misc to automatically run x86/x86-64 binaries
  #    using FEX-emu (leveraging hardware TSO for performance).
  # 4. Manages RootFS: Mounts a custom FEX root filesystem and overlays at /run/fex-emu/
  #    to provide necessary x86/x86-64 shared libraries.
  # 5. Bridges Hardware/Audio: Implements pass-through for the GPU (native context), X11,
  #    PulseAudio, and input devices to integrate seamlessly with the host desktop.

  # Virtualization: Host (aarch64) -> muvm (4k kernel) -> FEX -> x86 binary

  # Debugging
  # Checking if muvm works
  #   muvm -- ls -l /run/muvm-host            # run aarch64 binaries inside muvm 4k kernel
  #   muvm -- ls -l /proc/sys/fs/binfmt_misc  # Check binfmt is configured to FEX inside muvm

  # Checking x86 binaries with FEX running inside muvm
  #   muvm-x86-runner -- $(nix build nixpkgs#legacyPackages.x86_64-linux.hello --print-out-paths --no-link)/bin/hello
  #   muvm-x86-runner -- env

  # Running Flatpak apps (currently not working)
  #   muvm-x86-runner -- flatpak run --verbose --arch=x86_64 com.discordapp.Discord
     

  # Overlay on pkgs-stable, as our mesa driver comes from there
  nixpkgs.overlays = [ muvm-fex-overlay ];

  # Install necessary deps
  environment.systemPackages = with pkgs; [
    # Needed by FEXRootFSFetcher
    fuse
    squashfuse
    squashfsTools

    # Main deps
    muvm
    fex

    # Helper script
    muvm-x86-runner
  ];
}
