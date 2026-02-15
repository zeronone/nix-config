{ pkgs-unstable, ... }:
{
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
      model = "anthropic/claude-opus-4.6";
      theme = "system";
    };
    themes = {
      # nothing yet
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

  # programs.nixvim = {
  #   extraPlugins = [
  #     pkgs-unstable.vimPlugins.opencode-nvim
  #   ];
  # };
}
