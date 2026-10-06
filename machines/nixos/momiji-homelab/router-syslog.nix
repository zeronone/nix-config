# Syslog from the RTX1300 router (UDP 514) into the journal: `journalctl -t rtx1300`, or Cockpit's Logs.
# A dedicated rsyslogd, not services.rsyslogd (that one takes over the system's own syslog).
{
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
    template(name="journal" type="list") {
      property(name="msg" outname="MESSAGE")
      property(name="syslogseverity" outname="PRIORITY")
      constant(value="rtx1300" outname="SYSLOG_IDENTIFIER")
    }
    ruleset(name="router") {
      if $fromhost-ip == "${lan.gateway}" then action(type="omjournal" template="journal")
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

  # Only the router may send
  networking.firewall.extraInputRules = "ip saddr ${lan.gateway} udp dport 514 accept";
}
