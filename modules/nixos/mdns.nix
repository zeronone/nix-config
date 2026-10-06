# Announce <hostname>.local on the LAN and resolve other .local names (mDNS via Avahi).
{ ... }:
{
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };
}
