# Disk health for NAS-style hosts: SMART monitoring, mdadm event alerts, monthly RAID scrub, SSD TRIM.
# Alerts are push notifications (./notify.nix), also in the journal: `journalctl -t notify`.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  notify = lib.getExe config.notify.package;

  # smartd `-M exec` passes the details via environment variables
  smartdNotify = pkgs.writeShellScript "smartd-notify" ''
    exec ${notify} -p high -t warning,floppy_disk "$SMARTD_SUBJECT" "$SMARTD_FULLMESSAGE"
  '';

  # mdadm PROGRAM is called as: <event> <md-device> [<component-device>]
  # RebuildFinished also fires when a scrub ("check") completes, so report its mismatch count.
  mdadmNotify = pkgs.writeShellScript "mdadm-notify" ''
    case "$1" in
      NewArray|RebuildStarted|SparesMissing) exit 0 ;;
      Fail|FailSpare|DegradedArray) priority=urgent ;;
      *) priority=default ;;
    esac
    md="$(basename "$(readlink -f "$2")")"
    mismatches="$(cat "/sys/block/$md/md/mismatch_cnt" 2>/dev/null || echo "?")"
    exec ${notify} -p "$priority" -t floppy_disk "mdadm: $1 on $2" \
      "event=$1 array=$2 component=''${3:-} mismatch_cnt=$mismatches"
  '';
in
{
  imports = [ ./notify.nix ];

  environment.systemPackages = [
    pkgs.smartmontools
    pkgs.nvme-cli
    pkgs.hdparm
  ];

  services.smartd = {
    enable = true;
    autodetect = true;
    # Use our own notifier instead of the module's wall/mail/x11 ones
    notifications.wall.enable = false;
    # -a: all checks; -n standby,q: don't wake sleeping disks just to poll;
    # short self-test every Saturday 03:00, long test on the 1st of each month 04:00;
    # -W: warn on +4C change, log at 45C, alert at 55C.
    defaults.autodetected = lib.concatStringsSep " " [
      "-a"
      "-n standby,q"
      "-s (S/../../6/03|L/../01/./04)"
      "-W 4,45,55"
      "-m <nomailer>"
      "-M exec ${smartdNotify}"
    ];
  };

  # mdadm --monitor (mdmonitor.service) needs PROGRAM or MAILADDR to run
  boot.swraid.mdadmConf = lib.mkIf config.boot.swraid.enable ''
    PROGRAM ${mdadmNotify}
  '';

  # Monthly consistency check of all md arrays (first Sunday, 02:00).
  # Read-only verify ("check", not "repair"); progress in /proc/mdstat.
  systemd.services.md-scrub = lib.mkIf config.boot.swraid.enable {
    description = "Start a consistency check of all md RAID arrays";
    serviceConfig.Type = "oneshot";
    script = ''
      for action in /sys/block/md*/md/sync_action; do
        [ -e "$action" ] || continue
        if [ "$(cat "$action")" = idle ]; then
          echo "starting check on $action"
          echo check > "$action"
        fi
      done
    '';
  };
  systemd.timers.md-scrub = lib.mkIf config.boot.swraid.enable {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Sun *-*-01..07 02:00";
      Persistent = true;
    };
  };

  services.fstrim.enable = true;
}
