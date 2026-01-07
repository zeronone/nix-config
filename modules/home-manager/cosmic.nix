{ ... }:
{
  xdg.configFile."cosmic/com.system76.CosmicComp/v1/xkb_config".text = ''
    (
        rules: "",
        model: "pc104",
        layout: "us,jp",
        variant: ",",
        options: Some("terminate:ctrl_alt_bksp,compose:ralt,caps:ctrl_modifier,ctrl:swap_lwin_lctl,ctrl:swap_rwin_rctl"),
        repeat_delay: 200,
        repeat_rate: 40,
    )
  '';

  xdg.configFile."cosmic/com.system76.CosmicComp/v1/input_touchpad".text = ''
    (
        state: Enabled,
        acceleration: Some((
            profile: Some(Flat),
            speed: 0.2789548861547164,
        )),
        click_method: Some(Clickfinger),
        scroll_config: Some((
            method: Some(TwoFinger),
            natural_scroll: Some(false),
            scroll_button: None,
            scroll_factor: None,
        )),
        tap_config: Some((
            enabled: true,
            button_map: Some(LeftRightMiddle),
            drag: true,
            drag_lock: false,
        )),
    )
  '';

}
