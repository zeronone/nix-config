{ pkgs-unstable }:
with pkgs-unstable.vscode-marketplace;
[
  # Core & Vim
  vscodevim.vim
  mkhl.direnv

  # Nix Development
  jnoortheen.nix-ide
  arrterian.nix-env-selector
  pinage404.nix-extension-pack

  # Rust Development
  rust-lang.rust-analyzer
  tamasfe.even-better-toml
  fill-labs.dependi
  swellaby.vscode-rust-test-adapter
  pinage404.rust-extension-pack
  vadimcn.vscode-lldb

  # Java
  redhat.java
  vscjava.vscode-java-debug
  vscjava.vscode-java-test
  vscjava.vscode-gradle

  # Testing Utilities
  hbenl.vscode-test-explorer
  ms-vscode.test-adapter-converter

  # Misc
  monokai.theme-monokai-pro-vscode
  yzhang.markdown-all-in-one

]
