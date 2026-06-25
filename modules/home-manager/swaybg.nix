{
  config,
  pkgs,
  lib,
  ...
}:
{
  # Create state directory structure
  home.file.".config/omarchy/current/.keep" = {
    text = "";
  };

  # Auto-start swaybg with first wallpaper from current theme
  # omarchy-theme-bg-next reads from ~/.config/omarchy/current/theme/backgrounds/
  wayland.windowManager.hyprland.settings.exec-once = [
    "omarchy-theme-bg-next"
  ];
}
