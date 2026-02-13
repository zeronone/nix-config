{
  username,
  ...
}:
{
  # JP IME on mac
  homebrew.casks = [
    # Karabiner Driver is necessary on Mac for Kanata to run
    "karabiner-elements"
  ];

  home-manager.users.${username} =
    { ... }:
    {
      home.file.".config/karabiner/karabiner.json".source = ../../config/karabiner/karabiner.json;
    };
}
