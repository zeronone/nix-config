# Syslog from the RTX1300 router (UDP 514) into the journal: `journalctl -t rtx1300`, or Cockpit's Logs.
# A dedicated rsyslogd, not services.rsyslogd (that one takes over the system's own syslog).
# router-alerts turns notable lines into push notifications (modules/nixos/notify.nix).
{
  config,
  lib,
  pkgs,
  lan,
  ...
}:
let
  conf = pkgs.writeText "router-syslog.conf" ''
    module(load="imudp")
    module(load="omjournal")
    input(type="imudp" port="514" ruleset="router")
    # The router sends no syslog header, so rsyslog takes the first word ("LAN1:", "PP[01]",
    # "Login") as the tag; glue it back on
    template(name="journal" type="list") {
      property(name="$!msg" outname="MESSAGE")
      property(name="syslogseverity" outname="PRIORITY")
      constant(value="rtx1300" outname="SYSLOG_IDENTIFIER")
    }
    ruleset(name="router") {
      if $fromhost-ip == "${lan.gateway}" then {
        set $!msg = $syslogtag & $msg;
        action(type="omjournal" template="journal")
      }
    }
  '';
in
{
  systemd.services.router-syslog = {
    description = "Syslog receiver for the router";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${lib.getExe' pkgs.rsyslog "rsyslogd"} -n -iNONE -f ${conf}";
      DynamicUser = true;
      AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
      CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
      Restart = "on-failure";
    };
  };

  # Patterns are RTX log lines; the same alert is sent at most every 5 minutes
  systemd.services.router-alerts = {
    description = "Push notifications for router events";
    after = [ "router-syslog.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [
      config.notify.package
      config.systemd.package
    ];
    script = ''
      declare -A last
      alert() {
        local now
        now=$(date +%s)
        (( now - ''${last[$2]:-0} < 300 )) && return
        last[$2]=$now
        notify -p "$1" -t globe_with_meridians "router: $2" "$line"
      }
      journalctl -f -n0 -o cat -t rtx1300 | while IFS= read -r line; do
        case "$line" in
          *"[SCHEDULE] Startup:"*) alert high "restarted" ;;
          *[Ll]oop*detect*) alert urgent "loop detected" ;;
          *"link down"*) alert default "link down" ;;
          *"Login failed"*|*"login failed"*) alert high "login failed" ;;
          *FAN*) [[ $line == *"FAN1 OK"*"FAN2 OK"* ]] || alert urgent "fan problem" ;;
        esac
      done
    '';
    serviceConfig = {
      Restart = "always";
      RestartSec = "10s";
    };
  };

  # Only the router may send
  networking.firewall.extraInputRules = "ip saddr ${lan.gateway} udp dport 514 accept";
}
