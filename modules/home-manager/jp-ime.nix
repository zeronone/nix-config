{ pkgs, inputs, ... }:
{

  # programs.plasma = {
  #   configFile.kwinrc = {
  #     Wayland.InputMethod.value = "/run/current-system/sw/share/applications/org.fcitx.Fcitx5.desktop";
  #     Wayland.InputMethod.shellExpand = true;
  #     # Wayland.InputMethod.immutable = true;
  #   };
  # };

  # Src: https://zenn.dev/mityu/articles/nixos-fcitx5-mozc
  # Config can be verified from fcitx-configtool
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      fcitx5-with-addons = pkgs.qt6Packages.fcitx5-with-addons;
      addons = with pkgs; [
        fcitx5-mozc
      ];
      settings.inputMethod = {
        GroupOrder = {
          "0" = "Default";
        };
        "Groups/0" = {
          Name = "Default";
          "Default Layout" = "us";
          DefaultIM = "mozc";
        };
        "Groups/0/Items/0" = {
          Name = "keyboard-us";
          Layout = "";
        };
        "Groups/0/Items/1" = {
          Name = "mozc";
          Layout = "";
        };

      };
    };
  };
}
