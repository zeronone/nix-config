{
  pkgs,
  flake-inputs,
  username,
  ...
}:
{
  imports = [ flake-inputs.nix-homebrew.darwinModules.nix-homebrew ];

  # Homebrew is used for apps where we don't care too much abour versioning
  # For example desktop apps

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
