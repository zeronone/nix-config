# Work machine
{
  lib,
  myDarwinModules,
  ...
}:
{
  imports = [
    myDarwinModules.nix-homebrew
    myDarwinModules.macbook-us-ansi
    myDarwinModules.hammerspoon
    myDarwinModules.desktop-ui
    myDarwinModules.local-llm
    myDarwinModules.fonts
  ];

  networking.knownNetworkServices = [
    "Wi-Fi"
    "USB 10/100/1000 LAN"
  ];

  # Needed for work machine
  environment.etc."zprofile.local" = {
    text = ''
      # System-wide profile for interactive zsh(1) login shells.

      # Setup user specific overrides for this in ~/.zprofile. See zshbuiltins(1)
      # and zshoptions(1) for more details.

      if [ -z "$LANG" ]; then
              export LANG=C.UTF-8
      fi

      if [ -x /usr/libexec/path_helper ]; then
              eval `/usr/libexec/path_helper -s`
      fi
    '';
  };

  # Don't delete other brews installed on this machine
  homebrew.onActivation.cleanup = lib.mkForce "none";
  homebrew.taps = [ "atlassian/acli" ];
  homebrew.brews = [
    "openssl"
    "readline"
    "coreutils"
    "ed"
    "findutils"
    "gnu-indent"
    "gnu-sed"
    "gnu-tar"
    "gettext"
    "gnu-which"
    "gnutls"
    "grep"
    "glab"
    "atlassian/acli/acli"
  ];
}
