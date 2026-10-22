inputs:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.omarchy.quattro;
  system = pkgs.stdenv.hostPlatform.system;
  quickshell = inputs.quickshell.packages.${system}.default;
  runtime = inputs.self.packages.${system}.omarchy-runtime;
  runtimePath = "${config.home.homeDirectory}/.local/share/omarchy/quattro";
  legacyBin = "${config.home.homeDirectory}/.local/share/omarchy/bin";
  toml = pkgs.formats.toml { };
  style = toml.generate "quattro-shell-style.toml" cfg.shell.style;
  # Only these panel APIs differ from the retained personal commands.
  panelCommands = pkgs.runCommand "quattro-panel-commands" { } ''
    mkdir -p "$out/bin"
    for command in omarchy-powerprofiles-set omarchy-powerprofiles-list omarchy-battery-status omarchy-voxtype-status omarchy-theme-bg-set omarchy-theme-bg-next omarchy-system-lock omarchy-hyprland-session-locked omarchy-toggle-idle omarchy-menu-keybindings omarchy-capture-screenshot omarchy-capture-screenrecording; do
      ln -s ${runtime}/share/omarchy/bin/$command "$out/bin/$command"
    done
  '';
  screenshotEditor = import ./lib/screenshot-editor.nix { inherit pkgs; };
  launchShell = pkgs.writeShellScript "omarchy-quickshell" ''
    export PATH=${
      lib.makeBinPath [
        panelCommands
        pkgs.pulseaudio
        pkgs.libxkbcommon
        pkgs.wtype
        pkgs.vips
        pkgs.v4l-utils
      ]
    }:${lib.escapeShellArg legacyBin}:${lib.escapeShellArg "${runtime}/share/omarchy/bin"}:$PATH
    export OMARCHY_SCREENSHOT_EDITOR=${screenshotEditor}
    exec ${quickshell}/bin/quickshell -n -p ${lib.escapeShellArg "${runtimePath}/shell"}
  '';
in
{
  config = lib.mkIf cfg.shell.enable {
    assertions = [
      {
        assertion = cfg.enable;
        message = "omarchy.quattro.shell.enable requires omarchy.quattro.enable";
      }
      {
        assertion = (cfg.shell.settings.version or null) == 1;
        message = "omarchy.quattro.shell.settings.version must be 1; otherwise upstream ignores the plugin policy";
      }
    ];

    xdg.configFile."omarchy/shell.json".text = builtins.toJSON cfg.shell.settings;
    home.file.".local/state/omarchy/current/theme/shell.toml".source = style;
    home.file.".local/state/omarchy/current/theme/colors.toml".text = ''
      foreground = "#${config.colorScheme.palette.base05}"
      background = "#${config.colorScheme.palette.base00}"
      accent = "#${config.colorScheme.palette.base0D}"
      muted = "#${config.colorScheme.palette.base03}"
      red = "#${config.colorScheme.palette.base08}"
    '';

    # The shell background reads the state link while hyprlock reads the
    # config link, so adopt the current background once and keep the config
    # link pointing at the state link.
    # Stay Awake moves from the legacy idle-off toggle to the shell's marker.
    home.activation.migrateStayAwake = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      legacy="${config.home.homeDirectory}/.local/state/omarchy/toggles/idle-off"
      marker="${config.home.homeDirectory}/.local/state/omarchy/indicators/stay-awake"
      if [[ -e "$legacy" ]]; then
        run mkdir -p "$(dirname "$marker")"
        run touch "$marker"
        run rm -f "$legacy"
      fi
    '';

    home.activation.seedQuattroBackground = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      state="${config.home.homeDirectory}/.local/state/omarchy/current"
      legacy="${config.xdg.configHome}/omarchy/current"
      run mkdir -p "$state"
      if [[ ! -e "$state/background" && -e "$legacy/background" ]]; then
        run ln -nsf "$(readlink -f "$legacy/background")" "$state/background"
      fi
      if [[ ! -e "$state/theme.name" && -f "$legacy/theme.name" ]]; then
        run cp "$legacy/theme.name" "$state/theme.name"
      fi
      if [[ -e "$state/background" && "$(readlink "$legacy/background")" != "$state/background" ]]; then
        run mkdir -p "$legacy"
        run ln -nsf "$state/background" "$legacy/background"
      fi
    '';

    systemd.user.services.omarchy-shell = {
      Unit = {
        Description = "Omarchy Quattro native shell";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        Environment = [
          "OMARCHY_PATH=${runtimePath}"
          "QS_DISABLE_FILE_WATCHER=1"
          "QS_NO_RELOAD_POPUP=1"
        ];
        ExecStart = "${launchShell}";
        Restart = "on-failure";
        RestartSec = "2s";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
