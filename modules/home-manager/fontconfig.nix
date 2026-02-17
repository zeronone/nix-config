{ _, ... }:
{
  fonts.fontconfig = {
    enable = true;
    antialiasing = true;
    hinting = "medium";
    subpixelRendering = "rgb";

    # Run fc-list
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
        "IosevkaTerm Nerd Font Mono"
        "JetBrainsMonoNL Nerd Font"
        # 日本語
        "PlemolJP Console NF"
        "Noto Color Emoji"
      ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
}
