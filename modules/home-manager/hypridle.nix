{
  config,
  pkgs,
  lib,
  ...
}:
let
  quattroShell = config.omarchy.quattro.shell.enable or false;
  quattroBin = "${config.home.homeDirectory}/.local/share/omarchy/quattro/bin";
  lock =
    if quattroShell then "env PATH=${quattroBin}:$PATH omarchy-system-lock" else "omarchy-system-lock";
  lockOnly = if quattroShell then lock else "OMARCHY_LOCK_ONLY=true omarchy-system-lock";
  stayAwake = "$HOME/.local/state/omarchy/indicators/stay-awake";
in
{
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = lock;
        before_sleep_cmd = lockOnly;
        after_sleep_cmd = "hyprctl dispatch dpms on";
        ignore_dbus_inhibit = false;
        inhibit_sleep = 3;
      };
      # Under the Quattro shell, omarchy.idle owns the screensaver and lock
      # timers; hypridle keeps display power and the before-sleep lock.
      listener =
        lib.optionals (!quattroShell) [
          {
            timeout = 150;
            on-timeout = "omarchy-toggle-enabled idle-off || pidof hyprlock || omarchy-launch-screensaver";
          }
          {
            timeout = 151;
            on-timeout = "omarchy-toggle-enabled idle-off || ${lock}";
            on-resume = "omarchy-system-wake";
          }
        ]
        ++ [
          {
            timeout = 330;
            on-timeout =
              if quattroShell then
                "[ -f ${stayAwake} ] || hyprctl dispatch dpms off"
              else
                "omarchy-toggle-enabled idle-off || hyprctl dispatch dpms off";
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
