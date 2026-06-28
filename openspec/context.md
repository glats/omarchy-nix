# omarchy-nix — SDD Context

## Project Overview

Omarchy-nix is a NixOS flake that ports DHH's Omarchy Hyprland desktop from Arch
Linux to NixOS. The guiding principle is "stay as close to Omarchy as possible" —
same themes, same keybindings, same script names and logic.

## Repository Structure

```
omarchy-nix/
├── flake.nix                    # Entry point: nixosModules.default, homeManagerModules.default
├── flake.lock                   # Pinned inputs (nixpkgs unstable, hyprland v0.54.3, etc.)
├── config.nix                   # All user-configurable options (lib.mkOption)
├── modules/
│   ├── nixos/                   # System-level NixOS modules
│   │   ├── default.nix          # Module import hub
│   │   ├── hyprland.nix         # Hyprland compositor system config
│   │   ├── system.nix           # Core system packages & services
│   │   ├── gaming.nix           # Steam/Proton/controllers (declarative, replaces bash)
│   │   ├── nvidia.nix           # NVIDIA GPU with Wayland opts
│   │   ├── 1password.nix        # 1Password integration
│   │   ├── hardware.nix         # ASUS workarounds (B9406, Z13, Intel PTL)
│   │   └── ... (fido2, firewall, containers, voxtype, wayvnc, browser-policies)
│   └── home-manager/            # User-level Home Manager modules
│       ├── default.nix          # Import hub, file deployment, activation blocks
│       ├── hyprland/            # Split Hyprland config
│       │   ├── configuration.nix  # $terminal, $browser, monitor settings
│       │   ├── bindings.nix       # ALL keybindings (main, multimedia, mouse, lid)
│       │   ├── input.nix          # Input device config
│       │   ├── looknfeel.nix      # Visual appearance
│       │   ├── windows.nix        # Window rules
│       │   ├── envs.nix           # Environment variables
│       │   └── autostart.nix      # Autostart apps
│       └── ... (40+ app modules: waybar, walker, mako, ghostty, etc.)
├── packages/                   # Custom Nix derivations
│   ├── plymouth-theme-omarchy.nix
│   ├── hyprland-preview-share-picker.nix
│   ├── voxtype.nix
│   └── terminaltexteffects.nix
├── bin/                        # 40+ utility scripts → ~/.local/share/omarchy/bin/
├── config/                     # Default config files (walker, elephant, screensaver)
├── default/                    # Static assets, wallpapers, bash defaults, hypr toggles
├── lib/                        # Helper functions (selected-wallpaper.nix)
├── config.nix                  # Single source of truth for all omarchy.* options
├── modules/themes.nix          # Theme → base16/VSCode mappings
├── modules/custom-base16-schemes.nix  # Custom schemes (vantablack, retro-82, lumon)
└── modules/packages.nix        # systemPackages + homePackages split
```

## Architecture Notes

- **Two module entry points**: `nixosModules.default` (system) and
  `homeManagerModules.default` (user), both defined in `flake.nix`.
- **Config propagation**: User sets `omarchy.*` at the NixOS level; Home Manager
  syncs it via `lib.mkIf (osConfig ? omarchy)` in `homeManagerModules.default`.
- **Theme flow**: Theme name → `modules/themes.nix` → base16 scheme (nix-colors or
  custom) → `config.colorScheme.palette.base00..0F` consumed by all modules.
- **Keybindings**: All defined in `modules/home-manager/hyprland/bindings.nix` via
  `bindd =` / `bindeld =` / `bindmd =` extraConfig strings. Quick launcher bindings
  come from `config.nix` `quick_app_bindings` option.

## Upcoming Change

**Change**: omarchy-archlinux-copy-paste
**Description**: Configure Super+C and Super+V as universal copy/paste shortcuts
in Hyprland, matching the behavior found in Omarchy Archlinux flavor.
**Relevant files**: modules/home-manager/hyprland/bindings.nix (lines 243-247)
**Known issue**: `SUPER, C` is used both for "Universal copy" (mainBindings line
244) AND "Calendar" (quick_app_bindings line 216 in config.nix). The Archlinux
flavor likely resolves this differently.

## Validation Commands

```bash
nix flake check                    # Syntax + eval
nixos-rebuild dry-build --flake .  # Full config eval
alejandra .                        # Format Nix files
```
