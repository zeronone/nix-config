# HDD pool: sda2 + sdb2 (ST4000VN006) -> mdadm RAID1 (UUID 73c2a38c:53e10d22:cc381e84:106cfb82)
#   -> LVM ug_A56BC9_1789909458_pool3/volume1 -> ext4 (UUID below), mounted at /volume3.
# Created by UGOS; its proprietary ext4 feature `ugacl` was removed, so it is plain ext4 now.
# ZFS plan: add 2 HDDs as a mirror, copy the data over, then add this pair as a second mirror
# (networking.hostId is already set; add cockpit-zfs in dashboard.nix).
{ ... }:
{
  # Assemble md arrays (incremental, via udev). Shows up as /dev/md127 (foreign homehost);
  # harmless since we mount by filesystem UUID.
  boot.swraid.enable = true;
  # LVM (services.lvm) is on by default and auto-activates the LV once md is assembled.

  fileSystems."/volume3" = {
    device = "/dev/disk/by-uuid/d955c9fb-98dd-453e-8db1-e3482c2fa455";
    fsType = "ext4";
    # nofail: a missing/degraded pool must not drop the box into emergency mode (remote access stays up).
    # Immich has RequiresMountsFor on it, so it never writes into an empty mount point on the SSD.
    options = [
      "noatime"
      "nofail"
      "x-systemd.device-timeout=60s"
    ];
  };
}
