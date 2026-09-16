inputs:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.omarchy.quattro;
  system = pkgs.stdenv.hostPlatform.system;
  runtime = inputs.self.packages.${system}.omarchy-runtime;
  quickshell = inputs.quickshell.packages.${system}.default;
in
{
  config = lib.mkIf cfg.enable {
    # The package and Quickshell are consumed from the same pinned v4 input
    # boundary. Existing v3 packages and services remain installed until the
    # runtime acceptance phase removes them deliberately.
    environment.systemPackages = [
      runtime
      quickshell
    ];

    # The selected Quattro Hyprland package supplies `hyprctl`; the Quickshell
    # package supplies both `quickshell` and `qs`. The runtime package wraps its
    # helpers with the small shell-tool closure, while these compositor tools
    # remain module-owned to avoid duplicating their large build closures.

    # Quattro scripts resolve their immutable defaults through OMARCHY_PATH.
    # The HM module provides the user-facing writable override directory.
    environment.sessionVariables.OMARCHY_PATH = lib.mkForce "${runtime}/share/omarchy";

    # Do not translate Quattro's Arch PAM files here. The pinned source uses
    # `account include system-local-login`; this portable module has not yet
    # proved an equivalent NixOS service stack. Existing v3 PAM services stay
    # authoritative until that mapping is validated.
  };
}
