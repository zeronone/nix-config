# Laptop: don't suspend on lid close while on AC power (counterpart of modules/darwin/ac-no-sleep.nix).
# Use case: lid closed behind a KVM. Switching the KVM to another machine disconnects the external
# display; logind then no longer counts the laptop as docked and suspends it on the closed lid.
# Battery: unchanged (suspend on lid close).
{
  services.logind.settings.Login = {
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
  };
}
