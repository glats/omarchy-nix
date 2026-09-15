inputs:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.omarchy.quattro;
  runtime = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.omarchy-runtime;
in
{
  config = lib.mkIf cfg.enable {
    # This is an opt-in entry point only. Starting omarchy-shell and retiring
    # v3 autostarts is intentionally deferred to the runtime ownership phase.
    xdg.configFile."hypr/hyprland.lua".source = "${runtime}/share/omarchy/config/hypr/hyprland.lua";
  };
}
