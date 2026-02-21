# Nix Configuration Refactoring Plan

## 1. Extract Library Logic (`lib/default.nix`)

- Create `lib/default.nix` to house shared logic.
- Move `mkNixosHost`, `mkDarwinHost`, `mkHomeManager` functions from `flake.nix`.
- Move `globalPackages` and `sharedHomeModules` variables.
- Add `myNixModules`, `myHmModules`, `myDarwinModules` to `specialArgs` and `extraSpecialArgs` for absolute imports.

## 2. Refactor Host Modules

- **IT-JPN-31519**: Move modules from `flake.nix` to `machines/darwin/IT-JPN-31519/system.nix`.
- **arif-mac**: Move modules from `flake.nix` to `machines/darwin/arif-mac/system.nix`.
- **asahi-nixos**: Move system modules to `machines/nixos/asahi-nixos/system.nix`.
- **asahi-nixos**: Create `machines/nixos/asahi-nixos/home.nix` and move Home Manager modules there.

## 3. Create `hosts.nix`

- Create `hosts.nix` in the root.
- Import `lib`.
- Define `nixosConfigurations` and `darwinConfigurations` using the `mkHost` functions.

## 4. Simplify `flake.nix`

- Rewrite `flake.nix` to only contain `inputs` and `outputs`.
- The `outputs` function will import `hosts.nix` and merge the results.

## Status

Ready to execute. Waiting for user approval.
