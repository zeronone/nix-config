{ pkgs, pkgs-unstable, ... }:
{
  # Import JP IME
  imports = [ ./jp-ime.nix ];

  # To easily inspect keyboard input in the terminal
  # wev | grep sym
  environment.systemPackages = with pkgs; [
    wev
  ];

  # mozc keymap needs to be customized for the following to work
  # 1. Select MS-IME
  # 2. Sort by key and delete all existing keybindings for muhenkan
  # 3. Add entries for muhenkan -> Deactive IME for each mode
  #    Precomposition, composition, conversion
  services.kanata = {
    enable = true;
    # Use latest version
    package = pkgs-unstable.kanata;

    keyboards.default = {
      extraDefCfg = "process-unmapped-keys yes";
      # I would like to map <CapsLock + SHIFT> -> SUPER
      config = ''
        ;; fn not supported
        (defsrc
          esc  f1   f2   f3   f4   f5   f6   f7   f8   f9   f10  f11  f12
          grv  1    2    3    4    5    6    7    8    9    0    -    =    bspc
          tab  q    w    e    r    t    y    u    i    o    p    [    ]    \
          caps a    s    d    f    g    h    j    k    l    ;    '    ret
          lsft z    x    c    v    b    n    m    ,    .    /         rsft
          lctl lalt lmet           spc            rmet ralt      up lft down rght
        )

        (defvar
          tap-timeout   200
          hold-timeout  200
          tt            $tap-timeout
          ht            $hold-timeout
        )

        (defalias
          ;;    --------------------------------------------------------------
          ;;    Left Cmd (Tap) -> muhenkan (switch to English)
          ;;    Left Cmd (Hold)-> lctl
          ;;    --------------------------------------------------------------
          cmd_l (tap-hold-press $tt $ht muhenkan lctl)

          ;;    --------------------------------------------------------------
          ;;    Right Cmd (Tap)  -> kana (switch to composition mode)
          ;;    Right Cmd (Hold) -> rctl
          ;;    --------------------------------------------------------------
          cmd_r (tap-hold-press $tt $ht kana rctl)

          ;; 2. Tab Logic:
          ;;    Tap  = Tab
          ;;    Hold = Super (lmet) for window management
          tab_super (tap-hold-press $tt $ht tab lmet)
        )

        ;; ---------------------------------------------------------------------------
        ;; DEFLAYERMAP: Sparse mapping
        ;; Keys NOT listed here will default to their defsrc behavior (pass-through).
        ;; ---------------------------------------------------------------------------
        (deflayermap (base-layer)
          ;; 1. Caps Lock -> Left Control
          caps lctl

          ;; 2. Tab -> Tab/Super alias
          tab  @tab_super

          ;; 3. Command Keys -> IME/Ctrl aliases
          lmet @cmd_l
          rmet @cmd_r
        )
      '';
    };
  };
}
