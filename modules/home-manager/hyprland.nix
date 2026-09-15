inputs:
{
  config,
  pkgs,
  ...
}:
{
  imports = [ ./hyprland/configuration.nix ];
  wayland.windowManager.hyprland = {
    enable = true;
    package =
      (if config.omarchy.quattro.enable then inputs.quattro-hyprland else inputs.hyprland)
      .packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    # Keep v3 on hyprlang while Quattro selects the upstream Lua entry point.
    # The Lua config imports default.hypr.autostart, which launches exactly one
    # post-login omarchy-shell instance.
    configType = if config.omarchy.quattro.enable then "lua" else "hyprlang";
  };
  services.hyprpolkitagent.enable = true;
}
