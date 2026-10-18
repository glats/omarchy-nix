{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.omarchy;
in
{
  # Enable mako service
  services.mako.enable = !(config.omarchy.quattro.shell.enable or false);

  # Install mako core config
  home.file.".local/share/omarchy/default/mako/core.ini".source = ../../default/mako/core.ini;

  # Mako config reads from symlinked theme directory
  xdg.configFile."mako/config".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/omarchy/current/theme/mako.ini";
}
