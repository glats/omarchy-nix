{ pkgs }:
let
  guiutils = pkgs.hyprland-guiutils;
  toolkit = pkgs.hyprtoolkit;
in
assert pkgs.lib.assertMsg (
  guiutils.stdenv.cc == toolkit.stdenv.cc
) "Quattro GUIutils and hyprtoolkit must use the same C++ toolchain";
assert pkgs.lib.assertMsg (builtins.hasAttr (builtins.unsafeDiscardStringContext guiutils.drvPath) (
  builtins.getContext pkgs.hyprland.postInstall
)) "Quattro Hyprland must wrap the compiler-aligned GUIutils";
assert pkgs.lib.assertMsg (
  pkgs.lib.versionAtLeast pkgs.glaze-hyprland.version "7"
  && pkgs.lib.versionOlder pkgs.glaze-hyprland.version "8"
  && builtins.any (
    dependency: dependency.drvPath == pkgs.glaze-hyprland.drvPath
  ) pkgs.hyprland.buildInputs
) "Quattro Hyprland requires its pinned glaze 7.x dependency";
pkgs.runCommand "quattro-toolchain" { } ''
  touch "$out"
''
