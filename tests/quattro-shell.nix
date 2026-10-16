{
  pkgs,
  homeManagerLib,
  inputs,
}:
let
  palette = {
    base00 = "000000";
    base03 = "333333";
    base05 = "ffffff";
    base08 = "ff0000";
    base0D = "0000ff";
  };
  eval =
    {
      shell,
      quattro ? true,
      version ? 1,
    }:
    (homeManagerLib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        (
          { lib, ... }:
          {
            options.omarchy = (import ../config.nix lib).omarchyOptions;
            options.colorScheme.palette = lib.mkOption {
              type = lib.types.attrs;
              default = palette;
            };
            config = {
              home.username = "shell-test";
              home.homeDirectory = "/home/shell-test";
              home.stateVersion = "26.05";
              omarchy.quattro.enable = quattro;
              omarchy.quattro.shell.enable = shell;
              omarchy.quattro.shell.settings = {
                inherit version;
                plugins = [ "omarchy.audio" ];
              };
              omarchy.quattro.shell.style = {
                font.base-size = 12;
              };
            };
          }
        )
        (import ../modules/home-manager/quattro-shell.nix inputs)
      ];
    }).config;
  enabled = eval { shell = true; };
  disabled = eval { shell = false; };
in
assert builtins.hasAttr "omarchy-shell" enabled.systemd.user.services;
assert
  (builtins.fromJSON enabled.xdg.configFile."omarchy/shell.json".text).plugins == [ "omarchy.audio" ];
assert
  enabled.systemd.user.services.omarchy-shell.Install.WantedBy == [ "graphical-session.target" ];
assert enabled.systemd.user.services.omarchy-shell.Unit.PartOf == [ "graphical-session.target" ];
assert enabled.systemd.user.services.omarchy-shell.Service.Restart == "on-failure";
assert
  enabled.home.file.".local/state/omarchy/current/theme/colors.toml".text == ''
    foreground = "#ffffff"
    background = "#000000"
    accent = "#0000ff"
    muted = "#333333"
    red = "#ff0000"
  '';
assert !(builtins.hasAttr "omarchy-shell" disabled.systemd.user.services);
assert !(builtins.hasAttr "omarchy/shell.json" disabled.xdg.configFile);
assert
  !(builtins.tryEval
    (eval {
      shell = true;
      version = 0;
    }).home.activationPackage.drvPath
  ).success;
pkgs.runCommand "quattro-shell" { } ''
  touch "$out"
''
