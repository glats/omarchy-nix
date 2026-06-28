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
    # package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    withUWSM = lib.mkDefault true;
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

  # Patch xdg-desktop-portal-gtk to include cfg.usein tokens in UseIn.
  # Without this, the portal framework filters out gtk on non-GNOME sessions
  # (XDG_CURRENT_DESKTOP=Hyprland), and libadwaita apps silently lose Settings.
  nixpkgs.overlays = lib.optionals cfg.xdg.portal.enable [
    (final: prev: {
      xdg-desktop-portal-gtk = prev.xdg-desktop-portal-gtk.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          substituteInPlace $out/share/xdg-desktop-portal/portals/gtk.portal \
            --replace-fail "UseIn=gnome" \
            "UseIn=gnome;${lib.concatStringsSep ";" cfg.xdg.portal.usein}"
        '';
      });
    })
  ];

  xdg.portal = lib.mkIf cfg.xdg.portal.enable {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "*";
    config.hyprland = {
      default = lib.mkDefault [ "hyprland" "gtk" ];
      "org.freedesktop.impl.portal.Settings" = lib.mkDefault [ "gtk" ];
      # Enable InputCapture portal for screen sharing applications like Deskflow
      "org.freedesktop.impl.portal.InputCapture" = [ "hyprland" ];
    };
  };
}
