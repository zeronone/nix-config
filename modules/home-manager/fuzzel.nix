{ pkgs, ... }:
{
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        font = "PlemolJP Console NF:style=Medium:size=14";
        terminal = "ghostty";
        lines = 10;
        width = 50;
        horizontal-pad = 40;
        vertical-pad = 16;
        line-height = 24;
        fields = "name,generic,comment,categories,filename,keywords";
        show-actions = "yes";
      };

      border = {
        width = 2;
        radius = 10;
      };

      dmenu = {
        exit-immediately-if-empty = "yes";
      };
    };
  };
}
