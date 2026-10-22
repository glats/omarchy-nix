{ pkgs }:
pkgs.writeShellScript "omarchy-screenshot-editor" ''
  exec ${pkgs.satty}/bin/satty --filename "$1" \
    --output-filename "$1" \
    --actions-on-enter save-to-clipboard \
    --save-after-copy \
    --copy-command ${pkgs.wl-clipboard}/bin/wl-copy
''
