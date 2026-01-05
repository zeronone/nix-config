{
  pkgs,
  globalPackages,
  lib,
  ...
}:
let
  username = "arif";
in
{
  imports = [ ../../modules/home-manager/shell.nix ];
  home.username = "${username}";
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "25.11";

  home.sessionPath = [ "/home/arif/.nix-profile/bin" ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Global packages + machine-specific packages
  home.packages =
    (globalPackages pkgs)
    ++ (with pkgs; [
      vlc
      firefox
      chromium
    ]);

  # Set zsh as default shell on activation
  home.activation.make-zsh-default-shell = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # if zsh is not the current shell
      PATH="/usr/bin:/bin:$PATH"
      ZSH_PATH="/home/${username}/.nix-profile/bin/zsh"
      if [[ $(getent passwd ${username}) != *"$ZSH_PATH" ]]; then
        echo "setting zsh as default shell (using chsh). password might be necessay."
        if grep -q $ZSH_PATH /etc/shells; then
          echo "adding zsh to /etc/shells"
          run echo "$ZSH_PATH" | sudo tee -a /etc/shells
        fi
        echo "running chsh to make zsh the default shell"
        run chsh -s $ZSH_PATH ${username}
        echo "zsh is now set as default shell !"
      fi
  '';

}
