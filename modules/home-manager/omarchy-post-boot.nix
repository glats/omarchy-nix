{
  config,
  pkgs,
  lib,
  ...
}: {
  systemd.user.services.omarchy-post-boot = {
    Unit = {
      Description = "Run omarchy post-boot hooks";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${config.home.homeDirectory}/.local/share/omarchy/bin/omarchy-hook post-boot";
      RemainAfterExit = true;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
