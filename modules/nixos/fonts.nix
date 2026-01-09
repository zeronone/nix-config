{ pkgs, ... }:
{

  fonts.enableDefaultFonts = true;
  fonts.packages = with pkgs; [
    noto-fonts
    fira-code
    # JP fonts
    noto-fonts-cjk-sans
    ipafont
    kochi-substitute
  ];

  i18n.defaultLocale = "en_US.UTF-8";
}
