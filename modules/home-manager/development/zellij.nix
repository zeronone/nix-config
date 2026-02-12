{ pkgs, ... }:
{
  home.packages = with pkgs; [ lazygit ];

  programs.zellij = {
    enable = true;
    # Don't enable autostart
    enableZshIntegration = false;

    settings = {
      theme = "molokai-dark";
    };
  };

  home.file.".config/zellij/layouts/default.kdl" = {
    force = true;
    text = ''
      layout {
          // Tab 1 (default tab structure with children)
          default_tab_template {
              children
              pane size=1 borderless=true {
                  plugin location="zellij:compact-bar"
              }
          }

          tab name="Editor" split_direction="vertical" {
              pane command="nvim" {
                  args "."
              }
          }
          tab name="AI" {
              pane command="opencode" {
                  args "."
              }
          }
          tab name="Shell" {
              pane command="zsh"
          }
      }
    '';
  };
}
