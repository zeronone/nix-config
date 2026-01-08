{ lib, ... }:
{
  # work machine ~/.zshrc is populated with necessary env vars
  programs.zsh = {
    envExtra = ''
      export PATH="/opt/homebrew/bin:$PATH"
      if [ -f "$HOME/.zshrc" ]; then
          source "$HOME/.zshrc"
      fi
    '';
    # Need to be added to /etc/zshrc.local for work stuff to work
    # initContent adds it to ~/.config/zsh/.zshrc
    # initContent = lib.mkOrder 1000 ''
    #   # Restore standard macOS paths that Nix-Darwin might have deprioritized

    #   # 1. Capture the multi-line output of path_helper
    #   PH_RAW=$(/usr/libexec/path_helper -s)

    #   # 2. Iterate through each line to find PATH
    #   # We set the Internal Field Separator to newline to handle lines correctly
    #   while IFS= read -r line; do
    #       # Check if the line starts with PATH=
    #       if [[ "$line" =~ ^PATH= ]]; then
    #           # Use Bash Parameter Expansion to strip everything before and after the quotes
    #           # ''${line#*\"} removes everything up to the first "
    #           # ''${line%\"*} removes everything from the last " to the end
    #           TEMP_VAL="''${line#*\"}"
    #           SYSTEM_PATH="''${TEMP_VAL%\"*}"
    #
    #           # 3. Append to existing PATH
    #           export PATH="$PATH:$SYSTEM_PATH"
    #
    #           # We found it, so we can stop looking
    #           break
    #       fi
    #   done <<< "$PH_RAW"

    #   # 4. Optional: Clean up any double colons (::) that might result from empty variables
    #   export PATH="''${PATH//::/:}"

    # '';
  };
}
