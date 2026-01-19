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
          chord-timeout 50
          tt            $tap-timeout
          ht            $hold-timeout
        )

        (defalias
          ;; Define lmet's standalone behavior: 
          ;; Hold = lctl, Tap = muhenkan (as per your original config)
          lmet_alone (tap-hold-press $tt $ht muhenkan lctl)
          ;; The alias for the chorded result
          combined_super lmet

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

        (defchords my-chords $chord-timeout
          ;; 1. The Combination: lalt + lmet = Super (lmet)
          (lalt lmet) lmet

          ;; 2. The Fallbacks: What happens if only ONE is pressed
          (lalt) lalt
          (lmet) @lmet_alone
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
          lalt (chord my-chords lalt)
          lmet (chord my-chords lmet)
          rmet @cmd_r
        )
      '';
    };
  };
}
