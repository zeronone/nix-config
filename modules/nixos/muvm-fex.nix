{
  pkgs,
  pkgs-unstable,
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

    # Override muvm to inject the mesa-x86_64-linux into the RootFS
    muvm =
      (pkgs-unstable.muvm.override {
        libkrun = final.libkrun;
      }).overrideAttrs
        (oldAttrs: {
          # We overwrite postFixup to replace the default wrapper with our own
          postFixup =
            let
              # We create a new init script that references the custom mesa package
              newInitScript = final.writeShellApplication {
                name = "muvm-init";
                runtimeInputs = [ final.coreutils ];
                text = ''
                  if [[ ! -f /etc/NIXOS ]]; then exit; fi

                  ln -s /run/muvm-host/run/current-system /run/current-system

                  # OVERRIDE: Point opengl-driver to our Cross-Compiled Mesa
                  ln -s ${final.mesa-x86_64-linux} /run/opengl-driver
                '';
              };

              # We must reconstruct the runtime PATH for the wrapper because
              # replacing postFixup removes the original wrapper logic.
              # We pull dependencies from 'final' to ensure they exist.
              binPath = [
                final.dhcpcd
                final.passt
                final.socat
                (placeholder "out")
              ]
              ++ final.lib.optionals final.stdenv.hostPlatform.isAarch64 [ final.fex ];

            in
            ''
              # recreate the binary wrapper
              wrapProgram $out/bin/muvm \
                --prefix PATH : "${final.lib.makeBinPath binPath}" \
                --add-flags "--execute-pre=${final.lib.getExe newInitScript}"
            '';
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
    muvm
    fex
  ];
}
