{ pkgs-unstable, ... }:
let
  sharedExtensions = import ./vscode-extensions.nix { inherit pkgs-unstable; };
in
{
  programs.vscode = {
    enable = true;
    package = pkgs-unstable.vscodium;
    mutableExtensionsDir = true;
    profiles.default = {
      keybindings = [
        {
          key = "ctrl+a";
          command = "cursorLineStart";
          when = "textInputFocus && vim.mode == 'Insert'";
        }
        {
          key = "ctrl+e";
          command = "cursorLineEnd";
          when = "textInputFocus && vim.mode == 'Insert'";
        }
      ];
      userSettings = {
        "editor.semanticHighlighting.enabled" = true;
        "terminal.integrated.minimumContrastRatio" = 1;
        "workbench.colorTheme" = "Monokai Pro (Filter Spectrum)";
        "workbench.iconTheme" = "Monokai Pro (Filter Spectrum) Icons";
        "json.schemaDownload.trustedDomains" = {
          "https://schemastore.azurewebsites.net/" = true;
          "https://raw.githubusercontent.com/" = true;
          "https://www.schemastore.org/" = true;
          "https://json.schemastore.org/" = true;
          "https://json-schema.org/" = true;
          "https://static.ampcode.com" = true;
        };
        "redhat.telemetry.enabled" = false;
      };
      extensions =
        sharedExtensions
        ++ (with pkgs-unstable.vscode-marketplace; [
          sourcegraph.amp
          sst-dev.opencode
        ]);
    };
  };
}
