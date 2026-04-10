{ ... }:
let
  instantSpaceSwitcherBundleId = "com.interversehq.InstantSpaceSwitcher";
  instantSpaceSwitcherApp = ../../vendor/InstantSpaceSwitcher.app;
in
{
  # Dock
  system.defaults.dock.mru-spaces = false;

  # Spaces
  # one space spans across all displays
  # Use it together with InstantSpaceSwitcher
  system.defaults.spaces.spans-displays = true;

  # InstantSpaceSwitcher - install to /Applications and configure permissions
  # Configure <hyper> + <left|right> for space change to have similar keybindings with noctalia
  system.activationScripts.postActivation.text = ''
    # Copy InstantSpaceSwitcher to /Applications
    rsync -a --delete "${instantSpaceSwitcherApp}/" "/Applications/InstantSpaceSwitcher.app/"

    # Remove Gatekeeper quarantine (equivalent to "Open Anyway")
    xattr -dr com.apple.quarantine "/Applications/InstantSpaceSwitcher.app" 2>/dev/null || true
    spctl --add "/Applications/InstantSpaceSwitcher.app" 2>/dev/null || true

    # Grant accessibility permissions via TCC database
    # This requires Full Disk Access for the nix-daemon or running as root
    currentUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )
    if [[ "$currentUser" != "loginwindow" ]]; then
      sudo -u "$currentUser" tccutil --insert "${instantSpaceSwitcherBundleId}" -s kTCCServiceAccessibility 2>/dev/null || true
    fi
  '';
}
