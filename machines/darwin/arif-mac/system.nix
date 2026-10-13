# Personal macbook
{ myDarwinModules, ... }:
{
  imports = [
    myDarwinModules.nix-homebrew
    myDarwinModules.macbook-us-ansi
    myDarwinModules.ac-no-sleep
    myDarwinModules.desktop-ui
  ];

  networking.knownNetworkServices = [
    "Wi-Fi"
    "USB 10/100/1000 LAN"
  ];
}
