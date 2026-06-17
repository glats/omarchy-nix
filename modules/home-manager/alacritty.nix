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
  programs.alacritty = {
    enable = true;
    settings = {
      # Load theme from runtime config (allows dynamic theme switching).
      # The `general.import` below takes precedence at runtime, so when the
      # user switches theme via `omarchy-theme-set` the colors update without
      # a rebuild. The `colors` block here is the rebuild-time default and
      # matches what the runtime per-theme file produces.
      colors = {
        primary = {
          background = "#${palette.base00}";
          foreground = "#${palette.base05}";
          dim_foreground = "#${palette.base03}";
        };
        cursor = {
          text = "#${palette.base00}";
          cursor = "#${palette.base05}";
        };
        vi_mode_cursor = {
          text = "#${palette.base00}";
          cursor = "#${palette.base05}";
        };
        selection = {
          text = "CellForeground";
          background = "#${palette.base02}";
        };
        normal = {
          black = "#${palette.base00}";
          red = "#${palette.base08}";
          green = "#${palette.base0B}";
          yellow = "#${palette.base0A}";
          blue = "#${palette.base0D}";
          magenta = "#${palette.base0E}";
          cyan = "#${palette.base0C}";
          white = "#${palette.base05}";
        };
        bright = {
          black = "#${palette.base03}";
          red = "#${palette.base09}";
          green = "#${palette.base0B}";
          yellow = "#${palette.base0A}";
          blue = "#${palette.base0D}";
          magenta = "#${palette.base0E}";
          cyan = "#${palette.base0C}";
          white = "#${palette.base07}";
        };
      };

      general.import = [ "~/.config/omarchy/current/theme/alacritty.toml" ];

      env.TERM = "xterm-256color";

      terminal.osc52 = "CopyPaste";

      font = {
        size = 9;
        normal = {
          family = "JetBrainsMono Nerd Font";
          style = "Regular";
        };
        bold = {
          family = "JetBrainsMono Nerd Font";
          style = "Bold";
        };
        italic = {
          family = "JetBrainsMono Nerd Font";
          style = "Italic";
        };
      };

      window = {
        padding = {
          x = 14;
          y = 14;
        };
        decorations = "None";
      };

      # Universal copy/paste (works with Hyprland's Super+C/V → Ctrl/Shift+Insert mapping)
      keyboard.bindings = [
        {
          key = "Insert";
          mods = "Shift";
          action = "Paste";
        }
        {
          key = "Insert";
          mods = "Control";
          action = "Copy";
        }
        {
          key = "Return";
          mods = "Shift";
          chars = "\\u001B\\r";
        }
      ];
    };
  };
}
