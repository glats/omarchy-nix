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
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    # Pin the configType to "hyprlang" so the eval warning emitted by
    # nixpkgs (<26.05) about the upcoming config migration is suppressed
    # and the current behavior is preserved. Drop this line once 26.05
    # becomes the stable nixpkgs default.
    configType = "hyprlang";
  };
  services.hyprpolkitagent.enable = true;
}
