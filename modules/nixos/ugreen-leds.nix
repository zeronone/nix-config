# Front-panel LEDs of UGREEN DX/DXP NAS (power, network, one per bay), driven over SMBus by
# https://github.com/miskcoo/ugreen_leds_controller. Without a driver the LED controller shows
# its rolling "no OS" pattern.
#   disk LEDs: lit = present (dark flicker on I/O), blue = standby, red = disk gone or SMART failure
#              (red sticks until `systemctl restart ugreen-diskiomon`)
#   netdev:    blinks on traffic of the first active physical NIC
# Bays map by SATA port (ataN -> diskN), so they stay right when disks are swapped.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  version = "0-unstable-2026-09-27";
  src = pkgs.fetchFromGitHub {
    owner = "miskcoo";
    repo = "ugreen_leds_controller";
    rev = "f0fcd8192abdd92244aba9f6f0d10572f5561380";
    hash = "sha256-rhU/1ZPoMvlK1uR0pceA3yLsGYWC6NmLel2Psysbh9c=";
  };

  kmod = config.boot.kernelPackages.callPackage (
    {
      stdenv,
      kernel,
      kernelModuleMakeFlags,
    }:
    stdenv.mkDerivation {
      pname = "led-ugreen";
      inherit version src;
      sourceRoot = "${src.name}/kmod";
      nativeBuildInputs = kernel.moduleBuildDependencies;
      makeFlags = kernelModuleMakeFlags ++ [
        "KERNELRELEASE=${kernel.modDirVersion}"
        "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
        "INSTALL_MOD_PATH=${placeholder "out"}"
      ];
      installTargets = [ "install" ];
    }
  ) { };

  tools = pkgs.stdenv.mkDerivation {
    pname = "ugreen-leds-tools";
    inherit version src;
    nativeBuildInputs = [ pkgs.makeWrapper ];
    # For patchShebangs (#!/usr/bin/bash)
    buildInputs = [ pkgs.bash ];
    buildPhase = ''
      runHook preBuild
      cd scripts
      $CXX -O2 -std=c++17 -o ugreen-blink-disk blink-disk.cpp
      $CXX -O2 -std=c++17 -o ugreen-check-standby check-standby.cpp
      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      install -Dm755 -t $out/bin ugreen-blink-disk ugreen-check-standby \
        ugreen-probe-leds ugreen-diskiomon ugreen-netdevmon-multi ugreen-power-led
      substituteInPlace $out/bin/ugreen-diskiomon --replace-fail /usr/sbin/smartctl smartctl
      for f in probe-leds diskiomon netdevmon-multi power-led; do
        # The system path last, for zpool once the pool is ZFS
        wrapProgram $out/bin/ugreen-$f \
          --prefix PATH : ${
            lib.makeBinPath (
              with pkgs;
              [
                coreutils
                gnugrep
                gnused
                gawk
                util-linux
                kmod
                i2c-tools
                smartmontools
                dmidecode
                which
                iproute2
                ethtool
                bc
              ]
            )
          } \
          --suffix PATH : /run/current-system/sw/bin
      done
      runHook postInstall
    '';
  };

  # See scripts/ugreen-leds.conf upstream for all settings
  conf = pkgs.writeText "ugreen-leds.conf" ''
    MAPPING_METHOD=ata
    BLINK_MON_PATH=${tools}/bin/ugreen-blink-disk
    STANDBY_MON_PATH=${tools}/bin/ugreen-check-standby
    CHECK_SMART=true
    # Turn on once the pool is ZFS
    CHECK_ZPOOL=false
  '';

  # The scripts refuse to start if a lock file survived a hard kill; systemd already ensures one instance
  monitor = name: {
    description = "UGREEN LEDs: ${name}";
    after = [ "ugreen-probe-leds.service" ];
    requires = [ "ugreen-probe-leds.service" ];
    wantedBy = [ "multi-user.target" ];
    restartTriggers = [ conf ];
    serviceConfig = {
      ExecStartPre = "${lib.getExe' pkgs.coreutils "rm"} -f /run/ugreen-${name}.lock";
      ExecStart = "${tools}/bin/ugreen-${name}";
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };
in
{
  boot.extraModulePackages = [ kmod ];
  boot.kernelModules = [
    "i2c-dev"
    "led-ugreen"
    "ledtrig-oneshot"
    "ledtrig-netdev"
  ];

  environment.etc."ugreen-leds.conf".source = conf;

  systemd.services.ugreen-probe-leds = {
    description = "UGREEN LEDs: register the LED controller on the SMBus";
    after = [ "systemd-modules-load.service" ];
    requires = [ "systemd-modules-load.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${tools}/bin/ugreen-probe-leds";
    };
  };
  systemd.services.ugreen-diskiomon = monitor "diskiomon";
  systemd.services.ugreen-netdevmon-multi = monitor "netdevmon-multi";
  systemd.services.ugreen-power-led = {
    description = "UGREEN LEDs: power LED";
    after = [ "ugreen-probe-leds.service" ];
    requires = [ "ugreen-probe-leds.service" ];
    wantedBy = [ "multi-user.target" ];
    restartTriggers = [ conf ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${tools}/bin/ugreen-power-led";
    };
  };
}
