# Immich: native server + Postgres, ML in the official OpenVINO container, library on the HDD pool.
{
  config,
  lib,
  pkgs,
  flake-inputs,
  ...
}:
let
  mediaLocation = "/volume3/immich-library";

  # Immich gets its own nixpkgs pin (newer than stable, bumped deliberately because DB migrations
  # are one-way). Package AND module come from it so they match.
  pkgs-immich = import flake-inputs.nixpkgs-immich {
    inherit (pkgs.stdenv.hostPlatform) system;
  };

  # nixpkgs' native ML build is CPU-only; the OpenVINO image uses the Intel iGPU.
  # The tag follows the server version so they can't drift.
  mlImage = "ghcr.io/immich-app/immich-machine-learning:v${config.services.immich.package.version}-openvino";
  mlPort = 3003;
in
{
  disabledModules = [ "services/web-apps/immich.nix" ];
  imports = [ "${flake-inputs.nixpkgs-immich}/nixos/modules/services/web-apps/immich.nix" ];

  services.immich = {
    enable = true;
    package = pkgs-immich.immich;
    inherit mediaLocation;
    # LAN: http://192.168.100.3:2283
    host = "0.0.0.0";
    openFirewall = true;
    # Intel iGPU for hardware transcoding (QSV/VA-API); pick it in Admin > Video Transcoding
    accelerationDevices = [ "/dev/dri/renderD128" ];
    environment = {
      LIBVA_DRIVER_NAME = "iHD";
      # 127.0.0.1, not localhost: the container port is published on IPv4 only
      IMMICH_MACHINE_LEARNING_URL = lib.mkForce "http://127.0.0.1:${toString mlPort}";
    };
    # Replaced by the OpenVINO container below
    machine-learning.enable = false;
    # `settings = null` (default): admin settings live in the DB, editable in the web UI
  };

  users.users.immich.extraGroups = [
    "render"
    "video"
  ];

  # Pinned explicitly: a Postgres major upgrade needs a dump/restore, never let it change silently.
  services.postgresql.package = pkgs.postgresql_17;

  # Never start against an unmounted HDD pool (it would write into the empty mount point)
  systemd.services.immich-server.unitConfig.RequiresMountsFor = [ mediaLocation ];

  virtualisation.oci-containers = {
    backend = "podman";

    containers.immich-machine-learning = {
      image = mlImage;
      ports = [ "127.0.0.1:${toString mlPort}:3003" ];
      volumes = [ "/var/cache/immich-ml:/cache" ];
      environment.TZ = config.time.timeZone;
      devices = [ "/dev/dri:/dev/dri" ];
      # The box has 8G RAM
      extraOptions = [ "--memory=2500m" ];
    };
  };

  # https://immich.<tailnet>
  tailscaleNodes.immich = config.services.immich.port;

  systemd.tmpfiles.rules = [ "d /var/cache/immich-ml 0750 root root -" ];
}
