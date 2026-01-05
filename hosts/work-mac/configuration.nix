{ pkgs, ... }: {
  # 1. Define the system-level user
  users.users.arezai = {
    name = "arezai";
    home = "/Users/arezai";
  };

  security.pam.services.sudo_local.touchIdAuth = true;

  system.stateVersion = 4;
}
