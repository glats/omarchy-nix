# Generates per-theme Omarchy config files dynamically from base16 palette.
#
# This replaces the per-theme static-file approach with palette-driven
# generation, so adding a new theme only requires:
#   1. An entry in `modules/themes.nix` (name + base16-theme mapping)
#   2. A base16 scheme (either in `modules/custom-base16-schemes.nix` for
#      custom themes, or any scheme available from `inputs.nix-colors`).
#
# For every theme registered in `modules/themes.nix` we:
#   * Resolve the base16 palette (custom scheme or nix-colors lookup).
#     Both sources return hex strings without a leading `#`, matching the
#     shape of `config.colorScheme.palette` exposed by nix-colors' home-manager
#     module (which strips any user-provided `#`).
#   * Materialize 14 text/config files in `~/.config/omarchy/themes/<theme>/`
#     from the palette (alacritty, ghostty, kitty, btop, mako, swayosd,
#     walker, waybar, hyprland, hyprlock, zellij, plus vscode/chromium/icons).
#   * Copy any `backgrounds/` directory that ships in `config/themes/<theme>/`
#     so wallpapers remain available.
#   * Copy other static extras (previews, neovim.lua, hyprland-preview-share-picker.css)
#     that aren't in the generated set.
#
# A symlink at `~/.config/omarchy/current/theme` points to the active theme.
inputs:
{ config
, pkgs
, lib
, ...
}:
let
  themes = import ../themes.nix;
  customSchemes = import ../custom-base16-schemes.nix;
  themeNames = builtins.attrNames themes;

  # Some themes share a directory in `config/themes/` (e.g. rose-pine-dawn
  # reuses the rose-pine assets for backgrounds and extras).
  themeSourceMap = {
    "rose-pine-dawn" = "rose-pine";
    "rose-pine-moon" = "rose-pine";
    "gruvbox-light" = "gruvbox";
  };

  getThemeSource =
    themeName:
    if builtins.hasAttr themeName themeSourceMap then themeSourceMap.${themeName} else themeName;

  # Resolve the base16 palette for a theme name. Returns a flat attrset
  # with base00..base0F keys (hex strings, no leading `#`).
  # Both branches now return `.palette` so the rest of the generator can
  # treat them uniformly — the custom schemes in
  # `modules/custom-base16-schemes.nix` use the same nix-colors shape
  # (slug/name/author/palette), so the path mirrors the nix-colors side.
  paletteFor =
    themeName:
    let
      t = themes.${themeName};
      useCustom = t ? custom-scheme && t.custom-scheme;
    in
    if useCustom then
      customSchemes.${t.base16-theme}.palette
    else
      inputs.nix-colors.colorSchemes.${t.base16-theme}.palette;

  # Files generated from the palette for every theme.
  generatedFileNames = [
    "alacritty.toml"
    "btop.theme"
    "chromium.theme"
    "ghostty.conf"
    "hyprland.conf"
    "hyprlock.conf"
    "icons.theme"
    "kitty.conf"
    "mako.ini"
    "swayosd.css"
    "vscode.json"
    "walker.css"
    "waybar.css"
    "zellij.kdl"
  ];

  # Static files copied from `config/themes/<theme>/` (not generated).
  # Listed explicitly so a brand-new theme that only ships backgrounds
  # still gets its assets copied without anything else.
  additionalStaticFiles = [
    "neovim.lua"
    "hyprland-preview-share-picker.css"
    "preview.png"
    "preview-unlock.png"
    "unlock.png"
    # `light.mode` is a marker file consumed by `bin/omarchy-theme-picker` and
    # `bin/omarchy-theme-set-gnome` to detect light themes at runtime. Only
    # present in light variants (catppuccin-latte, flexoki-light, rose-pine),
    # but listing it here means it gets copied through whenever it exists.
    "light.mode"
  ];

  # Per-file content generators. Each takes the palette `p` and produces
  # the file body. The 16-color ordering follows the base16 → ANSI mapping
  # used by omarchy.
  mkGhostty = p: ''
    palette = 0=#${p.base00}
    palette = 1=#${p.base08}
    palette = 2=#${p.base0B}
    palette = 3=#${p.base0A}
    palette = 4=#${p.base0D}
    palette = 5=#${p.base0E}
    palette = 6=#${p.base0C}
    palette = 7=#${p.base05}
    palette = 8=#${p.base03}
    palette = 9=#${p.base09}
    palette = 10=#${p.base0B}
    palette = 11=#${p.base0A}
    palette = 12=#${p.base0D}
    palette = 13=#${p.base0E}
    palette = 14=#${p.base0C}
    palette = 15=#${p.base07}

    background = #${p.base00}
    foreground = #${p.base05}
    cursor-color = #${p.base05}
    cursor-text = #${p.base00}
    selection-background = #${p.base02}
    selection-foreground = #${p.base05}
  '';

  mkKitty = p: ''
    background #${p.base00}
    foreground #${p.base05}
    cursor #${p.base05}
    selection_background #${p.base02}
    selection_foreground #${p.base05}
    url_color #${p.base0C}

    # Tabs
    active_tab_background #${p.base0D}
    active_tab_foreground #${p.base00}
    inactive_tab_background #${p.base01}
    inactive_tab_foreground #${p.base03}

    # Windows
    active_border_color #${p.base0D}
    inactive_border_color #${p.base01}

    # normal
    color0 #${p.base00}
    color1 #${p.base08}
    color2 #${p.base0B}
    color3 #${p.base0A}
    color4 #${p.base0D}
    color5 #${p.base0E}
    color6 #${p.base0C}
    color7 #${p.base05}

    # bright
    color8 #${p.base03}
    color9 #${p.base09}
    color10 #${p.base0B}
    color11 #${p.base0A}
    color12 #${p.base0D}
    color13 #${p.base0E}
    color14 #${p.base0C}
    color15 #${p.base07}

    # extended colors
    color16 #${p.base0F}
    color17 #${p.base08}
  '';

  mkAlacritty = p: ''
    [window]
    padding.x = 16
    padding.y = 16

    [font]
    size = 12.0

    [colors.primary]
    background = "#${p.base00}"
    foreground = "#${p.base05}"
    dim_foreground = "#${p.base03}"

    [colors.cursor]
    text = "#${p.base00}"
    cursor = "#${p.base05}"

    [colors.vi_mode_cursor]
    text = "#${p.base00}"
    cursor = "#${p.base05}"

    [colors.selection]
    text = "CellForeground"
    background = "#${p.base02}"

    [colors.normal]
    black = "#${p.base00}"
    red = "#${p.base08}"
    green = "#${p.base0B}"
    yellow = "#${p.base0A}"
    blue = "#${p.base0D}"
    magenta = "#${p.base0E}"
    cyan = "#${p.base0C}"
    white = "#${p.base05}"

    [colors.bright]
    black = "#${p.base03}"
    red = "#${p.base09}"
    green = "#${p.base0B}"
    yellow = "#${p.base0A}"
    blue = "#${p.base0D}"
    magenta = "#${p.base0E}"
    cyan = "#${p.base0C}"
    white = "#${p.base07}"
  '';

  mkBtop = p: ''
    theme[main_bg]="#${p.base00}"
    theme[main_fg]="#${p.base05}"
    theme[title]="#${p.base05}"
    theme[hi_fg]="#${p.base0D}"
    theme[selected_bg]="#${p.base02}"
    theme[selected_fg]="#${p.base07}"
    theme[inactive_fg]="#${p.base03}"
    theme[graph_text]="#${p.base05}"
    theme[proc_misc]="#${p.base05}"
    theme[cpu_box]="#${p.base0D}"
    theme[mem_box]="#${p.base0D}"
    theme[net_box]="#${p.base0D}"
    theme[proc_box]="#${p.base0D}"
    theme[div_line]="#${p.base02}"
    theme[temp_start]="#${p.base08}"
    theme[temp_mid]="#${p.base0A}"
    theme[temp_end]="#${p.base0B}"
    theme[cpu_start]="#${p.base0D}"
    theme[cpu_mid]="#${p.base0E}"
    theme[cpu_end]="#${p.base0B}"
    theme[free_start]="#${p.base0B}"
    theme[free_mid]="#${p.base03}"
    theme[free_end]="#${p.base05}"
    theme[cached_start]="#${p.base0C}"
    theme[cached_mid]="#${p.base03}"
    theme[cached_end]="#${p.base05}"
    theme[available_start]="#${p.base0B}"
    theme[available_mid]="#${p.base03}"
    theme[available_end]="#${p.base05}"
    theme[used_start]="#${p.base08}"
    theme[used_mid]="#${p.base0A}"
    theme[used_end]="#${p.base0B}"
    theme[download_start]="#${p.base0D}"
    theme[download_mid]="#${p.base0C}"
    theme[download_end]="#${p.base0B}"
    theme[upload_start]="#${p.base0E}"
    theme[upload_mid]="#${p.base0C}"
    theme[upload_end]="#${p.base0B}"
  '';

  mkMako = p: ''
    include=~/.local/share/omarchy/default/mako/core.ini

    background-color=#${p.base00}
    text-color=#${p.base05}
    border-color=#${p.base0D}
    progress-color=#${p.base0D}
  '';

  mkSwayosd = p: ''
    @define-color background-color #${p.base00};
    @define-color border-color #${p.base0D};
    @define-color label #${p.base05};
    @define-color image #${p.base05};
    @define-color progress #${p.base05};
  '';

  mkWalker = p: ''
    @define-color background #${p.base00};
    @define-color foreground #${p.base05};
    @define-color text #${p.base05};
    @define-color accent #${p.base0D};
    @define-color selected-text #${p.base0D};
    @define-color border #${p.base01};
    @define-color base #${p.base00};
  '';

  mkWaybar = p: ''
    @define-color foreground #${p.base05};
    @define-color background #${p.base00};
    @define-color warning #${p.base08};
  '';

  mkHyprland = p: ''
    general {
      col.active_border = rgba(${p.base0D}ee)
      col.inactive_border = rgba(${p.base01}aa)
    }

    group {
      col.border_active = rgba(${p.base0D}ee)
      col.border_inactive = rgba(${p.base01}aa)
    }
  '';

  mkHyprlock = p: ''
    $color = rgba(${p.base00}, 1)
    $inner_color = rgba(${p.base00}, 1)
    $outer_color = rgba(${p.base05}, 0.5)
    $font_color = rgba(${p.base05}, 1)
    $placeholder_color = rgba(${p.base05}, 0.6)
    $check_color = rgba(${p.base0A}, 1.0)
  '';

  mkZellij = p: themeName: ''
    themes {
      ${themeName} {
        bg "#${p.base00}"
        fg "#${p.base05}"
        red "#${p.base08}"
        green "#${p.base0B}"
        yellow "#${p.base0A}"
        blue "#${p.base0D}"
        magenta "#${p.base0E}"
        cyan "#${p.base0C}"
        black "#${p.base00}"
        white "#${p.base07}"
        orange "#${p.base09}"
      }
    }
  '';

  mkChromium = _: "0,0,0\n";
  mkIcons = _: "Papirus-Dark\n";

  mkVscode = theme: ''
    {
      "workbench.colorTheme": "${theme.vscode-theme}"
    }
  '';

  # Dispatch: pick the right generator for a file name.
  contentFor =
    file: p: theme: themeName:
    if file == "alacritty.toml" then
      mkAlacritty p
    else if file == "btop.theme" then
      mkBtop p
    else if file == "chromium.theme" then
      mkChromium p
    else if file == "ghostty.conf" then
      mkGhostty p
    else if file == "hyprland.conf" then
      mkHyprland p
    else if file == "hyprlock.conf" then
      mkHyprlock p
    else if file == "icons.theme" then
      mkIcons p
    else if file == "kitty.conf" then
      mkKitty p
    else if file == "mako.ini" then
      mkMako p
    else if file == "swayosd.css" then
      mkSwayosd p
    else if file == "vscode.json" then
      mkVscode theme
    else if file == "walker.css" then
      mkWalker p
    else if file == "waybar.css" then
      mkWaybar p
    else if file == "zellij.kdl" then
      mkZellij p themeName
    else
      throw "theme-generator.nix: unknown generated file ${file}";

  # Build the 14 generated files for a given theme as
  # `{ "<file>" = { text = "..."; }; }`.
  mkGeneratedFiles =
    themeName:
    let
      p = paletteFor themeName;
      t = themes.${themeName};
    in
    lib.genAttrs generatedFileNames (file: {
      text = contentFor file p t themeName;
    });

  # Backgrounds: copy from `config/themes/<source>/backgrounds/` if it exists.
  mkBackgrounds =
    themeName:
    let
      sourceName = getThemeSource themeName;
      sourceDir = ../../config/themes/${sourceName}/backgrounds;
    in
    if builtins.pathExists sourceDir then
      {
        "backgrounds" = {
          source = sourceDir;
          recursive = true;
        };
      }
    else
      { };

  # Static extras (previews, neovim.lua, hyprland-preview-share-picker.css):
  # copy each from `config/themes/<source>/` if it exists.
  mkExtras =
    themeName:
    let
      sourceName = getThemeSource themeName;
      sourceDir = ../../config/themes/${sourceName};
      existingFiles = lib.filter
        (
          name: builtins.pathExists (sourceDir + "/${name}")
        )
        additionalStaticFiles;
    in
    lib.genAttrs existingFiles (name: {
      source = sourceDir + "/${name}";
    });

  # Build the final `home.file` entries for a theme: an attrset of
  # `.config/omarchy/themes/<theme>/<filename>` → `{ text = ... }` or
  # `{ source = ...; recursive = true; }`. We map to a list of pairs
  # (with the keys prefixed) and `listToAttrs` back into an attrset so
  # the result merges cleanly with `//` below.
  mkThemeFileEntries =
    themeName:
    let
      entries = (mkGeneratedFiles themeName) // (mkBackgrounds themeName) // (mkExtras themeName);
    in
    lib.listToAttrs (
      lib.mapAttrsToList
        (name: value: {
          name = ".config/omarchy/themes/${themeName}/${name}";
          inherit value;
        })
        entries
    );

  allThemeFiles = lib.foldl' (acc: themeName: acc // (mkThemeFileEntries themeName)) { } themeNames;
in
{
  home.file = allThemeFiles;

  # Create initial symlink to current theme
  home.activation.omarchy-theme-symlink = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    THEME_SYMLINK="$HOME/.config/omarchy/current/theme"
    THEME_NAME_FILE="$HOME/.config/omarchy/current/theme.name"
    CURRENT_THEME="${config.omarchy.theme}"

    mkdir -p "$(dirname "$THEME_SYMLINK")"

    # Only create symlink if it doesn't exist (don't override user's selection)
    if [[ ! -L "$THEME_SYMLINK" ]]; then
      $DRY_RUN_CMD ln -sf "$HOME/.config/omarchy/themes/$CURRENT_THEME" "$THEME_SYMLINK"
    fi

    # Write theme.name so the lua selector can find user custom backgrounds
    if [[ ! -f "$THEME_NAME_FILE" ]]; then
      printf '%s\n' "$CURRENT_THEME" > "$THEME_NAME_FILE"
    fi
  '';
}
