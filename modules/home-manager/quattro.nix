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
  runtime = inputs.self.packages.${system}.omarchy-runtime;
  quickshell = inputs.quickshell.packages.${system}.default;
  runtimePath = "${config.home.homeDirectory}/.local/share/omarchy/quattro";
in
{
  imports = [
    (import ./hyprland-lua.nix inputs)
    (import ./quattro-theme.nix)
  ];

  config = lib.mkIf cfg.enable {
    # Keep the upstream runtime tree immutable while giving its scripts a
    # stable user-local path. User edits belong under ~/.config/omarchy.
    home.file.".local/share/omarchy/quattro" = {
      source = "${runtime}/share/omarchy";
      recursive = true;
    };

    home.packages = [ quickshell ];
    home.sessionPath = [ "${runtimePath}/bin" ];
    home.sessionVariables.OMARCHY_PATH = runtimePath;

    xdg.configFile."environment.d/90-omarchy-quattro.conf".text = ''
      OMARCHY_PATH=${runtimePath}
      PATH=${runtimePath}/bin:$PATH
    '';
  };
}
