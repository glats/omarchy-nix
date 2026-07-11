{ pkgs, lib, ... }:
{
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "omarchy-system-lock";
        before_sleep_cmd = "OMARCHY_LOCK_ONLY=true omarchy-system-lock";
        after_sleep_cmd = "hyprctl dispatch dpms on";
        ignore_dbus_inhibit = false;
        inhibit_sleep = 3;
      };
      listener = [
        {
          timeout = 150;
          on-timeout = "omarchy-toggle-enabled idle-off || pidof hyprlock || omarchy-launch-screensaver";
        }
        {
          timeout = 151;
          on-timeout = "omarchy-toggle-enabled idle-off || omarchy-system-lock";
          on-resume = "omarchy-system-wake";
        }
        {
          timeout = 330;
          on-timeout = "omarchy-toggle-enabled idle-off || hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on && brightnessctl -r";
        }
      ];
    };
  };

  # Clear stale screensaver-off flag when hypridle starts.
  # This preserves the idle-off flag (managed by toggle-idle).
  systemd.user.services.hypridle.Service.ExecStartPre = [
    "${pkgs.coreutils}/bin/rm -f %h/.local/state/omarchy/toggles/screensaver-off"
  ];

  systemd.user.services.hypridle.Service.Restart = lib.mkForce "on-failure";
}
