{ config, lib, ... }:
let
  cfg = config.omarchy.quattro;
in
{
  config = lib.mkIf cfg.enable {
    # Themes remain in the immutable runtime. The config directory is created
    # as a writable override boundary instead of linking mutable state into
    # the Nix store.
    home.activation.initializeQuattroOverrides = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "$HOME/.config/omarchy"
      if [ ! -e "$HOME/.config/omarchy/shell.toml" ]; then
        : > "$HOME/.config/omarchy/shell.toml"
      fi
    '';
  };
}
