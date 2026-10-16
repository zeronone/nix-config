# Keep the Mac awake on AC power, lid closed included, until told to sleep with `sleepnow`.
# Use case: lid closed behind a KVM. Switching the KVM to another machine disconnects the external
# display, which macOS treats as a plain lid close and forces a sleep ("Clamshell Sleep").
#
# `pmset -c sleep 0` only stops idle sleep. Lid-close sleep can only be blocked with `pmset
# disablesleep 1`, which is global (no per-power-source variant), so a root daemon turns it on while
# on AC and off on battery.
# While it's on, Apple menu > Sleep and the power button do nothing: use `sleepnow` instead.
# If this module is removed, run `sudo pmset -a disablesleep 0` once, or sleep stays disabled.
{ config, pkgs, ... }:
let
  request = "/tmp/ac-no-sleep.sleepnow";
  user = config.system.primaryUser;
  # Lock this many seconds after the display turns off (Apple menu > Sleep only turns it off here)
  screenLockDelay = 5;
in
{
  system.activationScripts.postActivation.text = ''
    # Idle sleep: never on AC, after 15 minutes on battery
    /usr/bin/pmset -c sleep 0
    /usr/bin/pmset -b sleep 15

    # Screen lock (System Settings > Lock Screen > "Require password after screen saver begins or
    # display is turned off"). The old `defaults` keys are ignored by current macOS and setting it
    # needs the user's password, so only prompt when it has drifted.
    if ! sudo -u ${user} /usr/sbin/sysadminctl -screenLock status 2>&1 | grep -q "screenLock delay is ${toString screenLockDelay} seconds"; then
      if [ -t 0 ]; then
        echo "screen lock is not ${toString screenLockDelay}s; enter the login password of ${user} to fix it:"
        sudo -u ${user} /usr/sbin/sysadminctl -screenLock ${toString screenLockDelay} -password - \
          || echo "warning: failed to set screen lock" >&2
      else
        echo "warning: screen lock is not ${toString screenLockDelay}s; rerun the switch from a terminal to fix it" >&2
      fi
    fi
  '';

  # Asks the daemon (root) to allow sleep and sleep now
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "sleepnow" ''
      touch ${request}
    '')
  ];

  launchd.daemons.ac-no-sleep = {
    path = [
      "/bin"
      "/usr/bin"
      "/usr/sbin"
    ];
    # Event driven: blocks on `pmset -g pslog` (prints a line on every power source change) and only
    # uses shell builtins between events, so it forks nothing while idle. The only polling is the HID
    # idle counter, and only while paused on AC.
    script = ''
      # Paused: allow sleep. Set on battery or after `sleepnow`; cleared on AC on the next user input
      # (HID idle counter going down), so dark wakes (Power Nap, plugging in while asleep) don't keep
      # the Mac awake.
      paused=0
      src=""
      last_src=""
      last_idle=""

      hid_idle() {
        local out
        out=$(ioreg -c IOHIDSystem -d 4)
        [[ $out =~ \"HIDIdleTime\"\ =\ ([0-9]+) ]] && echo "''${BASH_REMATCH[1]}"
      }

      while true; do
        # Power source change (line read) or 2s timeout to check for a `sleepnow` request
        if IFS= read -r -t 2 line; then
          case $line in
            *"drawing from 'AC Power'"*) src=ac ;;
            *"drawing from "*) src=battery ;;
            *) continue ;;
          esac
        elif [ $? -le 128 ]; then
          exit 1 # pmset exited; launchd restarts us
        fi

        if [ -e ${request} ]; then
          rm -f ${request}
          paused=1
          last_idle=""
          pmset -a disablesleep 0
          pmset sleepnow
        elif [ "$src" != "$last_src" ]; then
          if [ "$src" = battery ]; then
            paused=1
            pmset -a disablesleep 0
            # Unplugged with the lid already closed: sleep now rather than stay awake in the bag
            if [ "$last_src" = ac ] && ioreg -r -k AppleClamshellState -d 1 | grep -q '"AppleClamshellState" = Yes'; then
              pmset sleepnow
            fi
          elif [ "$paused" = 0 ]; then
            pmset -a disablesleep 1
          fi
          last_src=$src
        elif [ "$src" = ac ] && [ "$paused" = 1 ]; then
          idle=$(hid_idle)
          if [ -n "$last_idle" ] && [ -n "$idle" ] && [ "$idle" -lt "$last_idle" ]; then
            paused=0
            pmset -a disablesleep 1
          fi
          last_idle=$idle
        fi
      done < <(pmset -g pslog)
    '';
    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = true;
    };
  };
}
