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
}
