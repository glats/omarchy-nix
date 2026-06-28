# AGENTS.md — Omarchy-Nix

Personal NixOS port of DHH's Omarchy (Hyprland desktop), maintained as a fork of [`mrosseel/omarchy-nix`](https://github.com/mrosseel/omarchy-nix). Aims to grow into a community project by staying current with upstream Omarchy and adding Nix-specific enhancements.

## Porting Philosophy

The original Omarchy (Arch Linux, [`basecamp/omarchy`](https://github.com/basecamp/omarchy)) is the **design reference**. When implementing or modifying features, check how Omarchy Arch does it first:

```bash
# Check what Omarchy Arch has today
gh api repos/basecamp/omarchy/commits --jq '.[0].sha'  # latest commit
gh api repos/basecamp/omarchy/contents/config/hypr       # Hyprland configs
gh api repos/basecamp/omarchy/contents/bin               # utility scripts
```

Default approach: **"How does Omarchy do it today? I want that in omarchy-nix."** Deviate only when Nix requires it (paths, package management, systemd units). Document deviations with a comment explaining why.

## Quick Reference

| What | Where |
|------|-------|
| Omarchy version tracked | `default/omarchy-version` |
| All user-facing options | `config.nix` |
| Home Manager modules | `modules/home-manager/` |
| NixOS modules | `modules/nixos/` |
| Utility scripts (164 total) | `bin/` |
| Hyprland config (split) | `modules/home-manager/hyprland/*.nix` |
| Themes & color schemes | `modules/themes.nix` + `modules/custom-base16-schemes.nix` |
| Default assets (bg, bash, chromium, etc.) | `default/` |
| Theme-specific assets | `config/` |
| Custom packages | `packages/` |
| SDD artifacts | `openspec/` |
| Keybinding reference | `hyprland-shortcuts.md` |

## Architecture

Two flake outputs consumed by hosts:

- **`nixosModules.default`** — system-level (Hyprland, gaming, hardware, etc.)
- **`homeManagerModules.default`** — user-level (apps, theming, scripts, Hyprland HM config)
- **`homeManagerModules.btop`** — standalone btop config (glats theme). Consumer must import `nix-colors` separately.

Both modules source options from `config.nix`. The HM module copies NixOS-level `omarchy.*` into HM scope via `lib.mkIf (osConfig ? omarchy) { omarchy = osConfig.omarchy or {}; }`.

### Dependencies (flake inputs)

| Input | Pinned |
|-------|--------|
| `nixpkgs` | nixos-unstable (follows consumer) |
| `hyprland` | v0.54.3 |
| `walker` | v2.15.2 |
| `home-manager` | master (follows consumer) |
| `nix-colors` | latest |
| `elephant` | latest |

## Configuration Options

All defined in `config.nix`. Required: `username`, `full_name`, `email_address`, `theme`.

### Themes (23 total)

tokyo-night, kanagawa, everforest, catppuccin, catppuccin-latte, rose-pine, rose-pine-dawn, rose-pine-moon, nord, gruvbox, gruvbox-light, flexoki-light, matte-black, ethereal, hackerman, osaka-jade, ristretto, miasma, vantablack, white, retro-82, lumon, **glats**

`glats` is fork-specific (`custom-scheme = true` in `modules/themes.nix`).

### Feature flags

| Option | Default | Purpose |
|--------|---------|---------|
| `gaming.enable` | `false` | Steam, Proton, GameMode, controllers |
| `nvidia.enable` | `false` | NVIDIA GPU + Wayland optimizations |
| `office_suite.enable` | `false` | LibreOffice, etc. |
| `seamless_boot.*` | disabled | Plymouth + auto-login + silent boot |
| `fido2_auth.enable` | `false` | FIDO2/U2F hardware key setup |
| `firewall.enable` | `false` | Firewall rules |
| `wayvnc.enable` | `false` | VNC server on `wayvnc.port` (default 5900) |
| `voxtype.enable` | `false` | Voice dictation service |
| `rotate_on_start` | `true` | Random wallpaper on login |
| `wifi.backend` | `"nm-iwd"` | `"nm-iwd"` or `"standalone-iwd"` |
| `greeter.type` | `"regreet"` | Greeter backend |
| `greeter.keyboard` | `{}` | `layouts`, `options` for greeter keyboard |
| `hardware.{asus_b9406,asus_z13,intel_ptl_fred}.enable` | `false` | Hardware-specific kernel params + udev |
| `xdg.portal` | `{}` | `enable` + `usein` for GTK portal compatibility |

### Fonts (`omarchy.fonts.*`)

Per-component overrides: `alacritty`, `ghostty`, `hyprlock`, `kitty`, `mako`, `rofi`, `swayosd`, `walker`, `waybar`. Default: `"Liberation Sans 11"`.

### Monitors, scale, browser, terminal

`monitors`, `scale`, `browser`, `terminal`, `primary_font` — string or list options, consumed by HM modules.

## Module Inventory

### NixOS (`modules/nixos/`)

`browser-policies`, `containers`, `fido2`, `firewall`, `gaming`, `hardware`, `hyprland`, `nvidia`, `system`, `theme-switcher-sudo`, `voxtype`, `wayvnc`, `1password`, `default` (orchestrator)

### Home Manager (`modules/home-manager/`)

`alacritty`, `battery-monitor`, `brave`, `btop`, `chromium`, `desktop-entries`, `direnv`, `evince`, `fonts`, `ghostty`, `git`, `hypridle`, `hyprland` (split into `bindings`, `configuration`, `envs`, `input`, `looknfeel`, `windows`, `autostart`), `hyprland-preview-share-picker`, `hyprlock`, `hyprpaper`, `hyprsunset`, `kitty`, `light-theme-monitor`, `mako`, `omarchy-post-boot`, `starship`, `swaybg`, `swayosd`, `theme-generator`, `theme-switcher`, `tmux`, `voxtype`, `vscode`, `walker`, `waybar`, `wayvnc`, `xdph`, `zellij`, `zoxide`, `zsh`, `default` (orchestrator)

## Hyprland Configuration

Split across `modules/home-manager/hyprland/`:

| File | Content |
|------|---------|
| `bindings.nix` | Keybindings (full list in `hyprland-shortcuts.md`) |
| `configuration.nix` | Core Hyprland settings |
| `input.nix` | Keyboard, touchpad, misc (`lib.mkDefault` per-key) |
| `looknfeel.nix` | Visual appearance, theming |
| `windows.nix` | Window rules |
| `autostart.nix` | Autostart entries |
| `envs.nix` | Environment variables (`$browser`, `$terminal`, etc.) |

### Key behavior notes
- Touchpad: `clickfinger_behavior = true` (two-finger right-click)
- Keybindings: exact Omarchy set + fork additions (see shortcuts doc)
- Universal clipboard: `SUPER+C/V/X` (Hyprland 0.54+ built-in)
- Workspace cycling: `SUPER+TAB`

## Utility Scripts

164 scripts in `bin/`, deployed to `~/.local/share/omarchy/bin/` and added to PATH. Categories:

- **CLI**: `omarchy` dispatcher, `omarchy-debug`, `omarchy-version`
- **Theme**: `omarchy-theme-*`, `omarchy-toggle-light-mode`, `omarchy-bg-next`
- **Fonts**: `omarchy-font-*`
- **Hardware**: `omarchy-hw-*`, `omarchy-restart-*`
- **Capture**: `omarchy-capture-*`, `omarchy-screensaver`
- **Launch**: `omarchy-launch-*`, `omarchy-webapp-*`
- **Dev**: `omarchy-dev-*`, `omarchy-docker-dbs`
- **Power**: `omarchy-battery-*`, `omarchy-powerprofiles-*`, `omarchy-ac-present`
- **Audio**: `omarchy-audio-*`, `omarchy-restart-pipewire`
- **Setup**: `omarchy-tz-select`, `omarchy-install-tailscale`, `omarchy-setup-fingerprint`
- **Plymouth**: `omarchy-plymouth-*` (Arch-only, kept for name parity)
- **Bash defaults**: `default/bash/{aliases,envs,fns,functions,init,inputrc,rc,shell,completions}`
- **Hook system**: `omarchy-hook` + `.d/` directory

Use `bin/` as source of truth. The `hyprland-shortcuts.md` doc covers what keybindings invoke which scripts.

## Commit Conventions

- **Format**: Conventional Commits — `feat(scope):`, `fix(scope):`, `chore(flake):`, `refactor(scope):`
- **Branch**: direct commits to `main`. No PR workflow on this fork (PRs go to upstream `mrosseel/omarchy-nix` when appropriate).
- **Co-Authored-By**: `Claude Opus <noreply@anthropic.com>` trailer on every commit.
- **Phase 1/Phase 2**: a change here (Phase 1) is followed by a `chore(flake): bump omarchy-nix <short-sha>` in the consumer repo (e.g., `glats/nixos-hosts`).

## SDD Workflow

This repo uses Spec-Driven Development. Artifacts live in `openspec/`. When making changes:

1. Use `sdd-explore` / `sdd-propose` / `sdd-spec` / `sdd-design` / `sdd-tasks` / `sdd-apply` / `sdd-verify` / `sdd-archive` sub-agents.
2. Artifact store: hybrid (Engram + `openspec/` on disk).
3. Closes with a direct commit to `main`.

See `openspec/config.yaml` for project-specific SDD configuration.

## NixOS-Hosts Integration Pattern

Hosts consume omarchy-nix like this (from `glats/nixos-hosts`):

```nix
# flake.nix — NixOS level
extraModules = [ inputs.omarchy-nix.nixosModules.default ];

# Host config — set options
omarchy = {
  theme = "glats";
  username = "glats";
  full_name = "glats";
  email_address = "...";
  wifi.backend = "standalone-iwd";
  wayvnc.enable = true;
  # etc.
};

# Home Manager — standalone mode
homeManagerModules.default  # with omarchy.* injected explicitly
```

Per-host overrides (fonts, hypridle timings, gtk theme) use `lib.mkForce` in `hosts/<host>/home/omarchy.nix`.

## Tooling

- **Validate**: `nix flake check`
- **Version compare**: `.claude/commands/version-compare.md` — diffs this file against actual repo state
- **Formatter**: `nixfmt` (RFC style) via consumer's `format-nix` script. This repo's `flake.nix` does not declare a formatter.

## Design Decisions

- **No blueman GUI**: bluetui TUI only.
- **No waybar drawer**: tray shows directly.
- **Fork vs upstream**: `glats/omarchy-nix` tracks `mrosseel/omarchy-nix`. Fork-specific additions include: `glats` theme, `omarchy.fonts.*`, `wayvnc`, `voxtype`, `greeter` refactor, `wifi.backend`, `hardware.*`, `xdg.portal`, `rotate_on_start`.
