inputs: {
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.omarchy;

  # Custom desktop file that uses start-hyprland wrapper
  hyprland-uwsm-fixed = pkgs.makeDesktopItem {
    name = "hyprland-uwsm";
    desktopName = "Hyprland (UWSM)";
    comment = "Hyprland compositor managed by UWSM";
    exec = "${pkgs.uwsm}/bin/uwsm start -F -- start-hyprland";
    type = "Application";
    categories = [ ];
    # Identifies this entry as the Hyprland session for greeters like
    # greetd/tuigreet (XDG Desktop Entry Spec: DesktopNames key).
    desktopNames = [ "Hyprland" ];
  };
in {
  programs.hyprland = {
    enable = true;
    # Use nixpkgs-provided Hyprland and portal packages as the canonical
    # default. The omarchy-nix NixOS module is the SOLE owner of
    # `programs.hyprland.package` and `programs.hyprland.portalPackage`.
    # Local consumer hosts (e.g. nixos-hosts/hosts/t14) MUST NOT override
    # these options; the Home Manager layer defers via `lib.mkDefault null`
    # (see modules/home-manager/hyprland.nix).
    package = pkgs.hyprland;
    portalPackage = pkgs.xdg-desktop-portal-hyprland;
    withUWSM = cfg.seamless_boot.enable;
  };

  # Override the auto-generated desktop file with our fixed version
  environment.systemPackages = lib.mkIf cfg.seamless_boot.enable [
    (pkgs.runCommand "hyprland-uwsm-override" {} ''
      mkdir -p $out/share/wayland-sessions
      cat > $out/share/wayland-sessions/hyprland-uwsm.desktop <<EOF
[Desktop Entry]
Name=Hyprland (UWSM)
Comment=Hyprland compositor managed by UWSM
Exec=${pkgs.uwsm}/bin/uwsm start -F -- start-hyprland
Type=Application
DesktopNames=Hyprland
EOF
    '')
  ];

  services.dbus.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "*";
    config.hyprland.default = [ "hyprland" "gtk" ];
  };

  # Enable InputCapture portal for screen sharing applications like Deskflow
  xdg.portal.config.hyprland."org.freedesktop.impl.portal.InputCapture" = [ "hyprland" ];
}
