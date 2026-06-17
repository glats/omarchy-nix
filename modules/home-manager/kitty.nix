{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.omarchy;
  palette = config.colorScheme.palette;
in
{
  programs.kitty = {
    enable = lib.mkDefault true;

    font = {
      name = lib.mkDefault "JetBrainsMono Nerd Font";
      size = lib.mkDefault 12;
    };

    # Colors are set from the active theme's palette so the rebuilt config
    # is correct even before any per-theme include is loaded. The `include`
    # below still loads `~/.config/omarchy/current/theme/kitty.conf` at
    # runtime, which overrides these defaults when the user switches theme
    # via the symlink mechanism (`omarchy-theme-set`).
    settings = lib.mkDefault {
      background = "#${palette.base00}";
      foreground = "#${palette.base05}";
      cursor = "#${palette.base05}";
      selection_background = "#${palette.base02}";
      selection_foreground = "#${palette.base05}";
      url_color = "#${palette.base0C}";

      # Tabs
      active_tab_background = "#${palette.base0D}";
      active_tab_foreground = "#${palette.base00}";
      inactive_tab_background = "#${palette.base01}";
      inactive_tab_foreground = "#${palette.base03}";

      # Windows
      active_border_color = "#${palette.base0D}";
      inactive_border_color = "#${palette.base01}";

      # normal
      color0 = "#${palette.base00}";
      color1 = "#${palette.base08}";
      color2 = "#${palette.base0B}";
      color3 = "#${palette.base0A}";
      color4 = "#${palette.base0D}";
      color5 = "#${palette.base0E}";
      color6 = "#${palette.base0C}";
      color7 = "#${palette.base05}";

      # bright
      color8 = "#${palette.base03}";
      color9 = "#${palette.base09}";
      color10 = "#${palette.base0B}";
      color11 = "#${palette.base0A}";
      color12 = "#${palette.base0D}";
      color13 = "#${palette.base0E}";
      color14 = "#${palette.base0C}";
      color15 = "#${palette.base07}";

      # extended colors
      color16 = "#${palette.base0F}";
      color17 = "#${palette.base08}";

      # Load theme from runtime config (allows dynamic theme switching)
      include = "~/.config/omarchy/current/theme/kitty.conf";

      # Window appearance
      window_padding_width = 10;
      background_opacity = "0.95";

      # Performance
      repaint_delay = 10;
      input_delay = 3;
      sync_to_monitor = "yes";
    };

    keybindings = {
      # Universal copy/paste (works with Hyprland's Super+C/V → Ctrl/Shift+Insert mapping)
      "ctrl+insert" = "copy_to_clipboard";
      "shift+insert" = "paste_from_clipboard";
    };
  };
}
