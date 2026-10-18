{
  config,
  pkgs,
  lib,
  ...
}:
{
  wayland.windowManager.hyprland.settings = {
    exec-once = [
      # "hypridle & mako & waybar & fcitx5"
      # "waybar"
      "uwsm-app -- swaybg -i ~/.config/omarchy/current/background -m fill"
      "systemctl --user start hyprpolkitagent"
      "wl-clip-persist --clipboard regular & clipse -listen"
    ]
    ++ lib.optional (
      !config.omarchy.quattro.shell.enable
    ) "systemctl --user restart waybar || systemctl --user start waybar"
    ++ lib.optional (!config.omarchy.quattro.shell.enable) "uwsm-app -- swayosd-server"
    ++ [
      "omarchy-powerprofiles-init"
      "uwsm-app -- omarchy-hyprland-monitor-watch"
      "uwsm-app -- walker --gapplication-service"

      # "dropbox-cli start"  # Uncomment to run Dropbox
    ];

    exec = lib.optional (!config.omarchy.quattro.shell.enable) "pkill -SIGUSR2 waybar";
  };
}
