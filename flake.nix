{
  description = "Nix config for my machines, copied from all over the internet.";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Pinned separately: Immich DB migrations are one-way, so bump this deliberately
    # (`nix flake update nixpkgs-immich`), never as a side effect of a bulk update.
    nixpkgs-immich.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Declarative disk partitioning (used by nixos-anywhere for momiji-homelab)
    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secrets (sops-nix), loaded on all NixOS and Darwin hosts
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nix Darwin (for MacOS machines)
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Followin nixpkgs-unstable
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # Apple Silicon support for NixOS
    nixos-apple-silicon = {
      url = "github:nix-community/nixos-apple-silicon";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # Private repo for Apple Silicon firmware (non-distributable)
    asahi-firmware = {
      url = "git+ssh://git@github.com/zeronone/asahi-firmware.git?dir=m1pro";
      flake = false;
    };

    # treefmt
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # vscode
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";

    # niri+noctalia
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    bacon-ls = {
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      url = "github:crisidev/bacon-ls";
    };

    dolphin-overlay.url = "github:rumboon/dolphin-overlay";

    # latest stable release
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    # AI coding agents (claude-code, opencode, antigravity-cli, ...), updated daily upstream.
    # No `inputs.nixpkgs.follows`: upstream builds against its own pinned nixpkgs, so we get
    # the exact combination its CI tested and hits cache.numtide.com instead of rebuilding.
    llm-agents.url = "github:numtide/llm-agents.nix";

    # Browser-based git diff reviewer
    diffle = {
      url = "github:moritzwilksch/diffle";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # Weekly updated nix-index database for nix-locate and command-not-found
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
      ...
    }@inputs:
    let
      lib = nixpkgs.lib;

      # Library of shared functions
      mylib = import ./lib/default.nix {
        inherit inputs;
      };

      # Host configurations
      myhosts = import ./hosts.nix {
        inherit inputs mylib;
      };

      allHosts = (myhosts.nixosConfigurations or { }) // (myhosts.darwinConfigurations or { });
      hostSystem = host: host.pkgs.stdenv.hostPlatform.system;

      # Eval the treefmt modules from ./treefmt.nix
      treefmtEval = system: treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} ./treefmt.nix;

      forAllSystems = lib.genAttrs [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
    in
    # --- System Specific Outputs (formatter, checks, devShells) ---
    {
      # for `nix fmt`
      formatter = forAllSystems (system: (treefmtEval system).config.build.wrapper);

      # for `nix flake check`
      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          formatting = (treefmtEval system).config.build.check self;

          # Evaluates every host (any platform) without building anything
          eval-hosts = pkgs.writeText "eval-hosts" (
            lib.concatLines (
              lib.mapAttrsToList (
                name: host:
                "${name} ${builtins.unsafeDiscardStringContext host.config.system.build.toplevel.drvPath}"
              ) allHosts
            )
          );
        }
        # Full system closures of the hosts native to this system
        // lib.mapAttrs' (name: host: lib.nameValuePair "host-${name}" host.config.system.build.toplevel) (
          lib.filterAttrs (_: host: hostSystem host == system) allHosts
        )
      );

      # `nix develop`, or automatically via direnv (.envrc)
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShellNoCC {
            packages = with pkgs; [
              sops
              age
              just
              jq
              nix-output-monitor
              nvd
              nixd
              nixos-rebuild
              nixos-anywhere
              (treefmtEval system).config.build.wrapper
            ];
            shellHook = ''
              export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt.age"
            '';
          };
        }
      );
    }
    //
      # --- System Agnostic Outputs (NixOS/Darwin Configurations) ---
      myhosts;
}
