# Hyprsunset — blue-light filter.
# Migrated from raw xdg.configFile + manual systemd unit to the Home Manager
# services.hyprsunset module, which owns BOTH the config file (rendered via
# lib.hm.generators.toHyprconf) and the systemd user service.  Hosts override
# services.hyprsunset.settings.profile (lib.mkForce) for custom schedules.
{ lib, ... }:

{
  services.hyprsunset = {
    enable = lib.mkDefault true;
    settings.profile = lib.mkDefault [
      {
        time = "07:00";
        identity = true;
      }
    ];
  };
}
