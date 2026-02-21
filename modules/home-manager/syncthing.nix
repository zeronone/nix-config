{ tailscaleIpAddr, ... }:
{
  # Sync directory at ~/Sync
  # Access UI at: http://127.0.0.1:8384/
  services.syncthing = {
    enable = true;
    guiAddress = "${tailscaleIpAddr}:8384";
    settings = {
      options = {
        relaysEnabled = false;
        localAnnounceEnabled = false;
      };
    };

    folders.keepass = {
      enable = true;
      label = "KeepassXC DB";
      path = "~/Sync/keepassxc_db";
    };
  };
}
