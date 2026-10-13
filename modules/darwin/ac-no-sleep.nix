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
      "/usr/bin"
      "/usr/sbin"
    ];
    script = ''
      interval=2
      # Paused: allow sleep. Set on battery or after `sleepnow`; cleared on AC on the next user input
      # (HID idle counter going down), so dark wakes (Power Nap, plugging in while asleep) don't keep
      # the Mac awake.
      paused=0
      last_src=""
      last_idle=0
      while true; do
        if pmset -g ps | head -1 | grep -q "AC Power"; then src=ac; else src=battery; fi
        idle=$(ioreg -c IOHIDSystem -d 4 | awk '/HIDIdleTime/ { print $NF; exit }')
        idle=''${idle:-0}

        if [ -e ${request} ]; then
          rm -f ${request}
          paused=1
          pmset -a disablesleep 0
          pmset sleepnow
        elif [ "$src" = battery ]; then
          paused=1
          if [ "$last_src" != battery ]; then
            pmset -a disablesleep 0
            # Unplugged with the lid already closed: sleep now rather than stay awake in the bag
            if [ "$last_src" = ac ] && ioreg -r -k AppleClamshellState -d 1 | grep -q '"AppleClamshellState" = Yes'; then
              pmset sleepnow
            fi
          fi
        else
          [ "$paused" = 1 ] && [ "$idle" -lt "$last_idle" ] && paused=0
          if [ "$paused" = 0 ] && ! pmset -g | grep -q "SleepDisabled[[:space:]]*1"; then
            pmset -a disablesleep 1
          fi
        fi

        last_src=$src
        last_idle=$idle
        sleep $interval
      done
    '';
    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = true;
    };
  };
}
