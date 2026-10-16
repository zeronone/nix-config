# Personal macbook
{ myDarwinModules, ... }:
{
  imports = [
    myDarwinModules.nix-homebrew
    myDarwinModules.macbook-us-ansi
    myDarwinModules.ac-no-sleep
    myDarwinModules.spotlight-off
    myDarwinModules.desktop-ui
    myDarwinModules.brightness-sync
  ];

  networking.knownNetworkServices = [
    "Wi-Fi"
    "USB 10/100/1000 LAN"
  ];
}
