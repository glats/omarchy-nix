{
  lib,
  makeWrapper,
  stdenvNoCC,
  source,
  runtimeDependencies ? [ ],
}:
stdenvNoCC.mkDerivation {
  pname = "omarchy-runtime";
  version = lib.strings.fileContents "${source}/version";

  # Quattro's source layout is the portable boundary. Arch's installer,
  # migration, test, and packaging machinery is deliberately not copied.
  dontUnpack = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    mkdir -p "$out/share/omarchy"
    cp -r "${source}/default" "$out/share/omarchy/default"
    cp -r "${source}/shell" "$out/share/omarchy/shell"
    cp -r "${source}/themes" "$out/share/omarchy/themes"
    cp -r "${source}/config" "$out/share/omarchy/config"
    cp -r "${source}/bin" "$out/share/omarchy/bin"
    cp "${source}/icon.png" "$out/share/omarchy/icon.png"
    cp "${source}/version" "$out/share/omarchy/version"
    chmod -R u+w "$out/share/omarchy/bin"

    chmod u+w "$out/share/omarchy/shell/services" "$out/share/omarchy/shell/services/PluginRegistry.qml"
    substituteInPlace "$out/share/omarchy/shell/services/PluginRegistry.qml" \
      --replace-fail 'find \"$dir\" -mindepth 2' 'find -L \"$dir\" -mindepth 2'

    # Nix wraps gpu-screen-recorder, so its command line starts with a store
    # path and never matches upstream's anchored "^gpu-screen-recorder".
    chmod u+w "$out/share/omarchy/default/omarchy" "$out/share/omarchy/default/omarchy/omarchy-menu.jsonc" \
      "$out/share/omarchy/shell/plugins/bar/indicators" "$out/share/omarchy/shell/plugins/bar/indicators/ScreenRecording.qml"
    substituteInPlace \
      "$out/share/omarchy/bin/omarchy-capture-screenrecording" \
      "$out/share/omarchy/default/omarchy/omarchy-menu.jsonc" \
      "$out/share/omarchy/shell/plugins/bar/indicators/ScreenRecording.qml" \
      --replace-fail '^gpu-screen-recorder' '(^|/)gpu-screen-recorder( |$)'

    # Upstream intentionally relies on Arch's ambient PATH. Keep the source
    # scripts unchanged, but make the shell entrypoint, IPC client, and restart
    # helper resolve their Nix-provided executables deterministically. The
    # runtime tree remains immutable; writable state stays under ~/.config and
    # ~/.local as it does upstream.
    for script in omarchy-launch-shell omarchy-shell omarchy-restart-shell; do
      mv "$out/share/omarchy/bin/$script" "$out/share/omarchy/bin/$script.upstream"
      makeWrapper "$out/share/omarchy/bin/$script.upstream" "$out/share/omarchy/bin/$script" \
        --prefix PATH : "$out/share/omarchy/bin" \
        --prefix PATH : "${lib.makeBinPath runtimeDependencies}"
    done
  '';
}
