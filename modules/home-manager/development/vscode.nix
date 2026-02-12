{ pkgs-unstable, ... }:
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
      extensions = with pkgs-unstable.vscode-marketplace; [
        # Core & Vim
        vscodevim.vim
        mkhl.direnv

        # Nix Development
        jnoortheen.nix-ide
        arrterian.nix-env-selector
        pinage404.nix-extension-pack

        # Rust Development
        rust-lang.rust-analyzer
        tamasfe.even-better-toml
        fill-labs.dependi
        swellaby.vscode-rust-test-adapter
        pinage404.rust-extension-pack
        vadimcn.vscode-lldb

        # Java
        # vscjava.vscode-java-pack
        redhat.java
        vscjava.vscode-java-debug
        vscjava.vscode-java-test
        vscjava.vscode-gradle

        # Testing Utilities
        hbenl.vscode-test-explorer
        ms-vscode.test-adapter-converter

        # Misc
        monokai.theme-monokai-pro-vscode
        yzhang.markdown-all-in-one

        # AI
        sourcegraph.amp
        sst-dev.opencode
      ];
    };
  };
}
