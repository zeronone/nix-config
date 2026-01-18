{ pkgs, ... }:
{

  fonts.enableDefaultPackages = true;
  fonts.packages = with pkgs; [
    nerd-fonts.hack
    nerd-fonts.jetbrains-mono
    noto-fonts-color-emoji
    # JP fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    plemoljp-nf
    ipafont
    kochi-substitute
  ];

  i18n.defaultLocale = "en_US.UTF-8";
}
