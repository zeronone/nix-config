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

    extraConfig = ''
      keybinds {
          locked {
              bind "Ctrl g" { SwitchToMode "Normal"; }
              bind "Ctrl Tab" { GoToNextTab; }
              bind "Ctrl Shift Tab" { GoToPreviousTab; }
              bind "Ctrl 1" { GoToTab 1; }
              bind "Ctrl 2" { GoToTab 2; }
              bind "Ctrl 3" { GoToTab 3; }
              bind "Ctrl 4" { GoToTab 4; }
              bind "Ctrl 5" { GoToTab 5; }
              bind "Super 1" { GoToTab 1; }
              bind "Super 2" { GoToTab 2; }
              bind "Super 3" { GoToTab 3; }
              bind "Super 4" { GoToTab 4; }
              bind "Super 5" { GoToTab 5; }
          }
      }
    '';
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
