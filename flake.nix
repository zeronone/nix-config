{
  description = "Nix config for my machines, copied from all over the internet.";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Flake Utils
    flake-utils.url = "github:numtide/flake-utils";

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

    # latest version of cluade-code
    claude-code-nix.url = "github:sadjow/claude-code-nix";

    # antigravity-nix
    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      treefmt-nix,
      ...
    }@inputs:
    let
      # Library of shared functions
      mylib = import ./lib/default.nix {
        inherit inputs;
      };

      # Host configurations
      myhosts = import ./hosts.nix {
        inherit inputs mylib;
      };
    in
    # --- System Specific Outputs (formatter, checks) ---
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        # Eval the treefmt modules from ./treefmt.nix
        treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
      in
      {
        # for `nix fmt`
        formatter = treefmtEval.config.build.wrapper;
        # for `nix flake check`
        checks = {
          formatting = treefmtEval.config.build.check self;
        };
      }
    )
    //
      # --- System Agnostic Outputs (NixOS/Darwin Configurations) ---
      myhosts;
}
