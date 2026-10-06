# NixOS system disk. DESTRUCTIVE if re-run: disko wipes ONLY this disk. Never point it at the
# Phison NVMe (UGOS) or the HDDs. Always use a /dev/disk/by-id path.
{
  disko.devices.disk.system = {
    type = "disk";
    # 238.5G KIOXIA KBG40ZNS256G
    device = "/dev/disk/by-id/nvme-KBG40ZNS256G_KIOXIA_Y3HPCA46Q1UX";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            # ext4 keeps Postgres simple (no CoW tuning needed)
            format = "ext4";
            mountpoint = "/";
            mountOptions = [ "noatime" ];
          };
        };
      };
    };
  };
}
