{ ... }:
{
  fonts.fontconfig = {
    enable = true;
    antialiasing = true;
    hinting = "medium";
    subpixelRendering = "rgb";

    defaultFonts = {
      serif = [
        "Noto Serif CJK JP"
        "Noto Color Emoji"
      ];
      sansSerif = [
        "Noto Sans CJK JP"
        "Noto Color Emoji"
      ];
      monospace = [
        "PlemolJP Console NF"
        "Noto Color Emoji"
      ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
}
