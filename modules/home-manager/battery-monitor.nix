{
  config,
  pkgs,
  lib,
  ...
}:
{
  systemd.user.services.omarchy-battery-monitor = {
    Unit = {
      Description = "Omarchy Battery Monitor";
      After = [ "graphical-session.target" ];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${config.home.homeDirectory}/.local/share/omarchy/bin/omarchy-battery-monitor";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  systemd.user.timers.omarchy-battery-monitor = {
    Unit = {
      Description = "Omarchy Battery Monitor Timer";
    };

    Timer = {
      OnUnitActiveSec = "30s";
      Unit = "omarchy-battery-monitor.service";
    };

    Install = {
      WantedBy = [ "timers.target" ];
    };
  };
}
