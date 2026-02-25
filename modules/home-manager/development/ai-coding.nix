{ pkgs-unstable, ... }:
let
  sharedExtensions = import ./vscode-extensions.nix { inherit pkgs-unstable; };
in
{
  home.packages = with pkgs-unstable; [
    gemini-cli
    (vscode-with-extensions.override {
      vscode = antigravity;
      vscodeExtensions = sharedExtensions;
    })
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
