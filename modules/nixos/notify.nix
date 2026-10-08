# Push notifications via the ntfy server on momiji-homelab (machines/nixos/momiji-homelab/ntfy.nix).
#   notify [-p min|low|default|high|urgent] [-t tag,...] <title> <message...>
# Also logged to the journal (`journalctl -t notify`), so nothing is lost while ntfy is down.
# Every system service that fails sends one too (OnFailure drop-in for all services).
# Publishes with the write-only token `ntfy-publish-token` (sops).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  url = "http://127.0.0.1:2586";
  topic = "homelab";

  notify = pkgs.writeShellApplication {
    name = "notify";
    runtimeInputs = with pkgs; [
      curl
      util-linux
    ];
    text = ''
      priority=default
      tags=""
      while getopts p:t: opt; do
        case "$opt" in
          p) priority="$OPTARG" ;;
          t) tags="$OPTARG" ;;
          *) echo "usage: notify [-p priority] [-t tags] <title> <message...>" >&2; exit 2 ;;
        esac
      done
      shift $((OPTIND - 1))
      title="$1"
      shift
      message="$*"

      logger -t notify -p user.warning "$title: $message"
      # Retries cover ntfy still starting (e.g. a unit failing at boot)
      if ! curl -fsS -o /dev/null --max-time 10 --retry 5 --retry-connrefused --retry-delay 5 \
        -H "Authorization: Bearer $(< ${config.sops.secrets.ntfy-publish-token.path})" \
        -H "Title: $title" -H "Priority: $priority" -H "Tags: $tags" \
        --data-binary "$message" "${url}/${topic}"; then
        logger -t notify -p user.err "ntfy delivery failed: $title"
      fi
    '';
  };
in
{
  options.notify.package = lib.mkOption {
    type = lib.types.package;
    readOnly = true;
    description = "The `notify` command";
  };

  config = {
    notify.package = notify;
    environment.systemPackages = [ notify ];

    # wheel: `notify` works without sudo for admins
    sops.secrets.ntfy-publish-token = {
      mode = "0440";
      group = "wheel";
    };

    systemd.services."notify-failure@" = {
      description = "Push notification for the failed unit %i";
      path = [
        notify
        config.systemd.package
      ];
      scriptArgs = "%i";
      # Skips units that only didn't start because a dependency failed (Result stays "success"),
      # and repeats for a restart-looping unit within an hour
      script = ''
        unit="$1"
        [ "$(systemctl show -P Result "$unit")" = success ] && exit 0
        stamp="/run/notify-failure/$unit"
        if [ -n "$(find "$stamp" -mmin -60 2>/dev/null)" ]; then
          exit 0
        fi
        mkdir -p /run/notify-failure
        touch "$stamp"
        notify -p high -t rotating_light "$unit failed" \
          "$(systemctl status --full --no-pager --lines=10 "$unit")"
      '';
      serviceConfig.Type = "oneshot";
    };

    systemd.packages = [
      (pkgs.writeTextDir "etc/systemd/system/service.d/10-notify-failure.conf" ''
        [Unit]
        OnFailure=notify-failure@%n.service
      '')
      # The notifier itself must not trigger itself
      (pkgs.writeTextDir "etc/systemd/system/notify-failure@.service.d/10-notify-failure.conf" ''
        [Unit]
        OnFailure=
      '')
    ];
  };
}
