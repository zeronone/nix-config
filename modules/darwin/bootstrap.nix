{
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./mac-nix.nix
  ];

  # Set the host platform to aarch64-darwin
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Allow nix-darwin to manage Nix
  nix.enable = true;
  nix.settings = {
    extra-platforms = lib.mkIf (pkgs.stdenv.hostPlatform.system == "aarch64-darwin") [
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  };

  # Needed for nix-darwin
  programs.zsh.enable = true;

  # Set Git commit hash for darwin-version.
  # system.configurationRevision = self.rev or self.dirtyRev or null;

  # enable touch ID for sudo auth
  # It gets too annoying in Ansible runs
  # security.pam.services.sudo_local.touchIdAuth = true;

  # Keyboard
  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToControl = true;
  system.defaults.NSGlobalDomain.InitialKeyRepeat = 15;
  system.defaults.NSGlobalDomain.KeyRepeat = 2;
  system.defaults.NSGlobalDomain.ApplePressAndHoldEnabled = false;
  system.defaults.WindowManager.EnableStandardClickToShowDesktop = false;
  system.defaults.NSGlobalDomain."com.apple.swipescrolldirection" = false;

  # Networking
  networking.dns = [
    "1.1.1.1" # Cloudflare
    "8.8.8.8" # Google
  ];

  # Dock and Mission Control
  system.defaults.dock = {
    autohide = true;
  };

  # Trackpad
  system.defaults.trackpad = {
    Clicking = true;
    TrackpadRightClick = true;
  };

  # Finder
  system.defaults.finder = {
    FXEnableExtensionChangeWarning = true;
    NewWindowTarget = "Home";
    ShowPathbar = true;
    AppleShowAllFiles = true;
  };

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;
}
