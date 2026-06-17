{
  config,
  pkgs,
  ...
}: {
  programs.alacritty = {
    enable = true;
    settings = {
      # Load theme from runtime config (allows dynamic theme switching).
      # The generated file at `~/.config/omarchy/current/theme/alacritty.toml`
      # is produced by `modules/home-manager/theme-generator.nix` and
      # updated when the user switches theme via `omarchy-theme-set`.
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
