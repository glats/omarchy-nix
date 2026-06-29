# fcitx5 input method — reusable Home Manager module.
#
# Provides packages, session env vars, user config (profile + behavior),
# and a systemd user service. Gated by omarchy.fcitx5.enable.
#
# Notes on package availability:
#   - fcitx5 and fcitx5-gtk live at the top level of pkgs.
#   - fcitx5-qt and fcitx5-configtool are KDE-packaged and live under
#     pkgs.kdePackages — `with pkgs; [...]` cannot resolve them.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.omarchy.fcitx5;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.fcitx5
      pkgs.fcitx5-gtk
      pkgs.kdePackages.fcitx5-qt
      pkgs.kdePackages.fcitx5-configtool
    ];

    # The IME environment variables are set at the session level so
    # GTK and Qt apps pick up fcitx5 as the input method backend.
    # Wayland-native apps get fcitx5 automatically once GTK_IM_MODULE
    # and QT_IM_MODULE are set.
    home.sessionVariables = {
      GTK_IM_MODULE = "fcitx";
      QT_IM_MODULE = "fcitx";
      XMODIFIERS = "@im=fcitx";
    };

    # fcitx5 profile — pin es/latam/us layouts.
    # Default Layout=es matches the omarchy upstream default kb_layout.
    # Consumers with different layouts can override via xdg.configFile
    # with lib.mkForce in their own HM config.
    xdg.configFile."fcitx5/profile".text = ''
      [Groups/0]
      Name=Default
      Default Layout=es
      DefaultIM=keyboard-es

      [Groups/0/Items/0]
      Name=keyboard-es
      Layout=es

      [Groups/0/Items/1]
      Name=keyboard-latam
      Layout=latam

      [Groups/0/Items/2]
      Name=keyboard-us
      Layout=us

      [GroupOrder]
      0=Default
    '';

    xdg.configFile."fcitx5/config".text = ''
      [Behavior]
      TriggerWhenFocus=True
      ShowInputMethodInformation=True
    '';

    # Systemd user service — survives Hyprland restarts (vs. exec-once),
    # journalctl-visible, matches the voxtype/wayvnc pattern.
    # PartOf=graphical-session.target ensures the daemon stops when the
    # session ends.
    systemd.user.services.fcitx5 = {
      Unit = {
        Description = "Fcitx5 input method";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.fcitx5}/bin/fcitx5";
        Restart = "on-failure";
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
