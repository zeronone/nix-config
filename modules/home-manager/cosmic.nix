{ ... }:
{
  xdg.configFile = {
    "cosmic/com.system76.CosmicComp/v1/xkb_config".text = ''
      (
          rules: "",
          model: "pc104",
          layout: "us",
          variant: "",
          options: Some("terminate:ctrl_alt_bksp,compose:ralt,caps:ctrl_modifier,ctrl:swap_lwin_lctl"),
          repeat_delay: 200,
          repeat_rate: 60,
      )'';
    # Autotile configuration for COSMIC Comp
    "cosmic/com.system76.CosmicComp/v1/autotile".text = "true";
    "cosmic/com.system76.CosmicComp/v1/autotile".force = true;
    "cosmic/com.system76.CosmicComp/v1/autotile_behavior".text = "PerWorkspace";
    "cosmic/com.system76.CosmicComp/v1/autotile_behavior".force = true;

    # Active hint configuration for COSMIC Comp
    "cosmic/com.system76.CosmicComp/v1/active_hint".text = "true";
    "cosmic/com.system76.CosmicComp/v1/active_hint".force = true;

    # Cursor follow
    "cosmic/com.system76.CosmicComp/v1/focus_follows_cursor".text = "true";
    "cosmic/com.system76.CosmicComp/v1/focus_follows_cursor".force = true;
    "cosmic/com.system76.CosmicComp/v1/cursor_follows_focus".text = "true";
    "cosmic/com.system76.CosmicComp/v1/cursor_follows_focus".force = true;

    "cosmic/com.system76.CosmicComp/v1/input_touchpad".text = ''
      (
          state: Enabled,
          acceleration: Some((
              profile: Some(Adaptive),
              speed: 0.3920930561448168,
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
  };

}
