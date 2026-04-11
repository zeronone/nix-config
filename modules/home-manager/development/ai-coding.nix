{ lib, pkgs, pkgs-unstable, ... }:
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

  # ClaudeCode
  nix.settings = {
    extra-substituters = [ "https://claude-code.cachix.org" ];
    extra-trusted-public-keys = [ "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk=" ];
  };
  programs.claude-code = {
    enable = true;
    # From claude-code overlay, latest version
    package = pkgs.claude-code;
    # enableMcpIntegration = true;
    # Settings managed via activation script below so the file is writable at runtime
    # (Claude Code needs to write to settings.json for commands like /effort)
  };

  # Generate settings as a Nix store file, then copy (not symlink) so Claude Code can modify it at runtime
  home.activation.claude-code-settings =
    let
      settingsFile = (pkgs.formats.json { }).generate "claude-code-settings.json" {
        "$schema" = "https://json.schemastore.org/claude-code-settings.json";
        model = "opus";
        env = {
          CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
        };
        preferences = {
          tmuxSplitPanes = true;
        };
      };
    in
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "$HOME/.claude"
      install -m 644 "${settingsFile}" "$HOME/.claude/settings.json"
    '';

  # Opencode
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
  xdg.configFile."opencode/opencode.json" = {
    force = true;
    text = ''
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
  };
}
