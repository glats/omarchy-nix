inputs:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ./hyprland/configuration.nix ];
  wayland.windowManager.hyprland = {
    enable = true;
    package =
      if config.omarchy.quattro.enable then
        inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.quattro-hyprland
      else
        inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    # Hosts with Hyprlang monitor profiles can retain their existing config
    # format while adopting the Quattro runtime independently.
    configType = lib.mkDefault (if config.omarchy.quattro.enable then "lua" else "hyprlang");
  };
  services.hyprpolkitagent.enable = true;
}
