{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.omarchy.wayvnc;
in
{
  config = lib.mkIf cfg.enable {
    programs.wayvnc.enable = true;
    # wayvnc is not in omarchy-nix's overlay by default; install it
    # explicitly so the PAM stack + `pkgs.wayvnc` resolve cleanly.
    environment.systemPackages = [ pkgs.wayvnc ];
  };
}
