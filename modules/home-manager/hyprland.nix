inputs: {
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [./hyprland/configuration.nix];
  # Defer Hyprland package ownership to the NixOS layer. The omarchy-nix
  # NixOS module is the SOLE owner of `programs.hyprland.package` and
  # `programs.hyprland.portalPackage`; this module must not select a
  # competing package from a user profile. Setting both options to
  # `lib.mkDefault null` is the documented NixOS+HM integration pattern
  # and lets HM keep managing the user config (bindings, monitors,
  # autostart, etc.) without claiming the package.
  wayland.windowManager.hyprland = {
    enable = true;
    package = lib.mkDefault null;
    portalPackage = lib.mkDefault null;
    # Pin the configType to "hyprlang" so the eval warning emitted by
    # nixpkgs (<26.05) about the upcoming config migration is suppressed
    # and the current behavior is preserved. Drop this line once 26.05
    # becomes the stable nixpkgs default.
    configType = "hyprlang";
  };
  services.hyprpolkitagent.enable = true;
}
