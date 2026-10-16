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
    for command in omarchy-powerprofiles-set omarchy-powerprofiles-list omarchy-battery-status; do
      ln -s ${runtime}/share/omarchy/bin/$command "$out/bin/$command"
    done
  '';
  launchShell = pkgs.writeShellScript "omarchy-quickshell" ''
    export PATH=${
      lib.makeBinPath [
        panelCommands
        pkgs.pulseaudio
        pkgs.libxkbcommon
      ]
    }:${lib.escapeShellArg legacyBin}:${lib.escapeShellArg "${runtime}/share/omarchy/bin"}:$PATH
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
