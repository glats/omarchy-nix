{ pkgs, hyprland }:
# Quattro scripts try Lua commands first and fall back to the classic syntax
# only when hyprctl fails. With the Hyprlang config manager Hyprland rejects
# those commands but still exits 0, so report them as failures instead.
pkgs.writeTextFile {
  name = "hyprctl-hyprlang-compat";
  destination = "/bin/hyprctl";
  executable = true;
  text = ''
    #!${pkgs.runtimeShell}
    args=("$@")
    i=0
    while ((i < ''${#args[@]})); do
      case ''${args[i]} in
        -i | --instance) i=$((i + 2)) ;;
        -*) i=$((i + 1)) ;;
        *) break ;;
      esac
    done
    command=''${args[i]:-}
    target=''${args[i + 1]:-}
    if [[ $command == eval || ($command == dispatch && $target == hl.*) ]]; then
      echo "hyprctl: Lua command unavailable with the Hyprlang config manager" >&2
      exit 1
    fi
    exec ${hyprland}/bin/hyprctl "$@"
  '';
}
