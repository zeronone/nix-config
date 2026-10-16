# Follow the Dell's auto-brightness on the Japannext (which has no light sensor), over DDC.
# Displays are matched by name (`m1ddc display list`), so it works on any Mac they're plugged into.
{ pkgs, ... }:
let
  source = "DELL U3225QE";
  target = "JAPANNEXT.MNT";
  offset = 20;
  interval = 15;
in
{
  launchd.user.agents.brightness-sync = {
    path = [
      pkgs.m1ddc
      "/bin" # sleep
    ];
    script = ''
      # Index of the display named $1 in `m1ddc display list` ("[1] NAME (UUID)")
      index() {
        local line
        while IFS= read -r line; do
          if [[ $line == "["*"] $1 ("* ]]; then
            line=''${line%%]*}
            echo "''${line#[}"
            return
          fi
        done < <(m1ddc display list 2>/dev/null)
        return 1
      }

      get() {
        local out
        out=$(m1ddc display "$1" get luminance 2>/dev/null)
        [[ $out =~ ^[0-9]+$ ]] && echo "$out"
      }

      prev=""
      while true; do
        # Resolved and read every time: indexes change on reconnect, and a monitor that reset itself
        # (wake, reconnect) is corrected too
        if s=$(index "${source}") && t=$(index "${target}") && src=$(get "$s") && cur=$(get "$t"); then
          want=$((src - ${toString offset}))
          [ "$want" -lt 0 ] && want=0
          # Only act on a value read twice in a row: DDC reads are occasionally wrong
          if [ "$src" = "$prev" ] && [ "$want" != "$cur" ]; then
            m1ddc display "$t" set luminance "$want" >/dev/null
          fi
          prev=$src
        fi
        sleep ${toString interval}
      done
    '';
    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = true;
    };
  };
}
