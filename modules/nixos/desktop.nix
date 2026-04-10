{
  username,
  ...
}:
{
  services.udisks2.enable = true;
  home-manager.users.${username} =
    {
      ...
    }:
    {
      # auto-mount USB devices
      services.udiskie.enable = true; # Adds udiskie to the system
    };
}
