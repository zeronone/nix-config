{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  flake-inputs,
  ...
}:
let
  llm-agents = flake-inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
  sharedExtensions = import ./vscode-extensions.nix { inherit pkgs-unstable; };
  tmux = lib.getExe config.programs.tmux.package;

  # Claude Code hook: when Claude waits on me and its pane isn't in front of me,
  # ring the bell on Claude's terminal (tmux flags the window, also through ssh)
  # and, on macOS, have Ghostty post a notification (OSC 777).
  claude-notify = pkgs.writeShellApplication {
    name = "claude-notify";
    runtimeInputs = [
      pkgs.jq
    ]
    ++ lib.optional pkgs.stdenv.isLinux pkgs.procps;
    text = ''
      message=$(jq -r '.message // "Finished"')

      # Hooks have no controlling terminal: use the tty of the nearest ancestor (claude)
      tty=
      pid=$PPID
      while [ "''${pid:-0}" -gt 1 ]; do
        t=$(ps -o tty= -p "$pid" | tr -d ' ')
        case $t in
          "" | "?" | "??") ;;
          *)
            tty=/dev/$t
            break
            ;;
        esac
        pid=$(ps -o ppid= -p "$pid" | tr -d ' ')
      done
      [ -n "$tty" ] || exit 0

      pane=''${TMUX_PANE:-}
      if [ -n "$pane" ]; then
        visible=$(${tmux} display -p -t "$pane" '#{&&:#{pane_active},#{window_active}}')
        clients=$(${tmux} list-clients -t "$pane" -F '#{client_flags}')
        if [ "$visible" = 1 ] && [[ $clients == *focused* ]]; then
          exit 0
        fi
      fi

      printf '\a' >"$tty"
    ''
    + lib.optionalString pkgs.stdenv.isDarwin ''
      # Inside tmux, write to the client's terminal: tmux drops escape sequences from hidden panes
      title=Claude
      target=$tty
      if [ -n "$pane" ]; then
        title="Claude: $(${tmux} display -p -t "$pane" '#S:#I #W')"
        target=$(${tmux} display -p -t "$pane" '#{client_tty}')
      fi
      body=$(printf '%s' "$message" | tr -d '\000-\037')
      if [ -n "$target" ]; then
        printf '\e]777;notify;%s;%s\a' "''${title//;/,}" "$body" >"$target"
      fi
    '';
  };
in
{
  home.packages = [
    pkgs-unstable.antigravity-ide
    llm-agents.antigravity-cli
  ];
  programs.mcp = {
    enable = true;
  };

  # ClaudeCode
  programs.claude-code = {
    enable = true;
    package = llm-agents.claude-code;
    # enableMcpIntegration = true;
    # Settings managed via activation script below so the file is writable at runtime
    # (Claude Code needs to write to settings.json for commands like /effort)
  };

  # Generate settings as a Nix store file, then copy (not symlink) so Claude Code can modify it at runtime
  home.activation.claude-code-settings =
    let
      settingsFile = (pkgs.formats.json { }).generate "claude-code-settings.json" {
        "$schema" = "https://json.schemastore.org/claude-code-settings.json";
        model = "opus";
        env = {
          CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
        };
        preferences = {
          tmuxSplitPanes = true;
        };
        hooks =
          let
            notify = [
              {
                type = "command";
                command = lib.getExe claude-notify;
              }
            ];
          in
          {
            Notification = [
              {
                matcher = "permission_prompt|elicitation_dialog";
                hooks = notify;
              }
            ];
            Stop = [ { hooks = notify; } ];
          };
      };
    in
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "$HOME/.claude"
      install -m 644 "${settingsFile}" "$HOME/.claude/settings.json"
    '';

  # Opencode
  programs.opencode = {
    enable = true;
    package = llm-agents.opencode;
    enableMcpIntegration = true;
    settings = {
      share = "disabled";
      autoshare = false;
      autoupdate = true;
    };
    tui = {
      theme = "system";
    };
  };
  xdg.configFile."opencode/opencode.json" = {
    force = true;
    text = ''
      {
        "$schema": "https://opencode.ai/config.json",
        "plugin": [
          "opencode-gemini-auth@latest",
          "@tarquinen/opencode-dcp@latest",
          "opencode-pty",
          "octto",
          "@nick-vi/opencode-type-inject"
        ]
      }
    '';
  };
}
