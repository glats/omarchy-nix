{
  lib,
  stdenvNoCC,
  source,
}:
stdenvNoCC.mkDerivation {
  pname = "omarchy-runtime";
  version = lib.strings.fileContents "${source}/version";

  # Quattro's source layout is the portable boundary. Arch's installer,
  # migration, test, and packaging machinery is deliberately not copied.
  dontUnpack = true;

  installPhase = ''
    mkdir -p "$out/share/omarchy"
    cp -r "${source}/default" "$out/share/omarchy/default"
    cp -r "${source}/shell" "$out/share/omarchy/shell"
    cp -r "${source}/themes" "$out/share/omarchy/themes"
    cp -r "${source}/config" "$out/share/omarchy/config"
    cp -r "${source}/bin" "$out/share/omarchy/bin"
    cp "${source}/icon.png" "$out/share/omarchy/icon.png"
    cp "${source}/version" "$out/share/omarchy/version"
  '';
}
