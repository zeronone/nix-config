{ pkgs-unstable, ... }:
{
  home.packages = with pkgs-unstable; [
    gemini-cli
    antigravity
  ];
  programs.mcp = {
    enable = true;
  };
  programs.opencode = {
    enable = true;
    package = pkgs-unstable.opencode;
    enableMcpIntegration = true;
    settings = {
      share = "disabled";
      autoshare = false;
      autoupdate = true;
      theme = "system";
    };
  };

  xdg.configFile."opencode/opencode.json".text = ''
    {
      "$schema": "https://opencode.ai/config.json",
      "plugin": [
        "opencode-gemini-auth@latest",
        "@tarquinen/opencode-dcp@latest",
        "opencode-pty",
        "octto",
        "@nick-vi/opencode-type-inject"
      ]
    }
  '';
}
