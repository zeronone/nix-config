{
  pkgs,
  inputs,
  username,
  ...
}:
{
  imports = [ inputs.nix-homebrew.darwinModules.nix-homebrew ];

  # Install Homebrew
  nix-homebrew = {
    enable = true;
    user = username;
    autoMigrate = true;

    # allow modifications outside of nix
    mutableTaps = true;
  };

  # Configure Homebrew
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;

      cleanup = "none";
      upgrade = true;
      extraFlags = [
        "--verbose"
      ];
    };

    # common casks
    casks = [ ];

    # common brews
    brews = [
      "tccutil"
    ];
  };
}
