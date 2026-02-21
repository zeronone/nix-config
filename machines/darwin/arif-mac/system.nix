# Personal macbook
{ myDarwinModules, ... }:
{
  imports = [
    myDarwinModules.nix-homebrew
    myDarwinModules.macbook-us-ansi
  ];

  networking.knownNetworkServices = [
    "Wi-Fi"
    "USB 10/100/1000 LAN"
  ];
}
