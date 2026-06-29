{
  description = "Omarchy - Base configuration flake";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Use v0.53.0+ for start-hyprland script support
    hyprland.url = "github:hyprwm/Hyprland/v0.54.3";
    nix-colors.url = "github:misterio77/nix-colors";
    elephant.url = "github:abenz1267/elephant";
    walker.url = "github:abenz1267/walker/v2.15.2";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    inputs@{
      self,
      nixpkgs,
      hyprland,
      nix-colors,
      elephant,
      walker,
      home-manager,
    }:
    {
      nixosModules = {
        default =
          {
            config,
            lib,
            pkgs,
            ...
          }:
          {
            imports = [
              (import ./modules/nixos/default.nix inputs)
            ];

            options.omarchy = (import ./config.nix lib).omarchyOptions;
            config = {
              nixpkgs.config.allowUnfree = true;
            };
          };
      };

      homeManagerModules = {
        default =
          {
            config,
            lib,
            pkgs,
            osConfig ? { },
            ...
          }:
          {
            imports = [
              nix-colors.homeManagerModules.default
              (import ./modules/home-manager/default.nix inputs)
            ];
            options.omarchy = (import ./config.nix lib).omarchyOptions;
            config = lib.mkIf (osConfig ? omarchy) {
              omarchy = osConfig.omarchy or { };
            };
          };

        # Standalone btop module — glats theme + settings without the full
        # omarchy desktop (Hyprland, waybar, walker, etc.).
        #
        # Consumers must import nix-colors themselves before this module
        # (btop.nix reads config.colorScheme.palette at eval time).
        btop =
          {
            config,
            lib,
            pkgs,
            ...
          }:
          {
            imports = [
              (import ./modules/home-manager/btop.nix)
            ];
          };

        # Standalone fcitx5 module — IME packages + env + config + autostart
        # without the full omarchy desktop (Hyprland, waybar, walker, etc.).
        #
        # The module reads `config.omarchy.fcitx5.enable`, so we declare
        # the omarchy options here (mirroring what homeManagerModules.default
        # does). Consumers set `omarchy.fcitx5.enable = true` to opt in.
        fcitx5 =
          {
            config,
            lib,
            pkgs,
            ...
          }:
          {
            imports = [
              (import ./modules/home-manager/fcitx5.nix)
            ];
            options.omarchy = (import ./config.nix lib).omarchyOptions;
          };
      };

      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt;
      formatter.aarch64-linux = nixpkgs.legacyPackages.aarch64-linux.nixfmt;
    };
}
