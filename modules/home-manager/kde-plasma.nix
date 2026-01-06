{ pkgs, inputs, ... }:
{
  imports = [ inputs.plasma-manager.homeModules.plasma-manager ];

  programs.plasma = {
    enable = true;
    workspace = {
      clickItemTo = "select";
    };
    hotkeys.commands."launch-term" = {
      name = "Launch terminal";
      key = "Meta+Alt+K";
      command = "ghostty";
    };
    configFile = {
      kxkbrc.Layout.Options = "ctrl:nocaps,ctrl:swap_lwin_lctl,ctrl:swap_rwin_rctl";

      kcminputrc.Keyboard.RepeatDelay = 350;
      kcminputrc.Keyboard.RepeatRate = 40;
      kcminputrc."Libinput/1452/834/Apple SPI Trackpad".NaturalScroll = false;
      kcminputrc."Libinput/1452/834/Apple SPI Trackpad".PointerAcceleration = 0.400;
      kcminputrc."Libinput/1452/834/Apple SPI Trackpad".PointerAccelerationProfile = 2;
      kcminputrc."Libinput/1452/834/Apple SPI Trackpad".ScrollFactor = 0.75;
      kcminputrc."Libinput/1452/834/Apple SPI Trackpad".TapToClick = true;
      kdeglobals.General.BrowserApplication = "chromium-browser.desktop";
      kdeglobals.General.XftHintStyle = "hintslight";
      kdeglobals.General.XftSubPixel = "rgb";
      kdeglobals.General.fixed = "Noto Sans Mono,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1";
      kdeglobals.General.font = "Noto Sans,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1";
      kdeglobals.General.menuFont = "Noto Sans,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1";
      kdeglobals.General.smallestReadableFont = "Noto Sans,9,-1,5,400,0,0,0,0,0,0,0,0,0,0,1";
      kdeglobals.General.toolBarFont = "Noto Sans,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1";
      kdeglobals.KDE.AnimationDurationFactor = 0.5;
    };
  };
}
