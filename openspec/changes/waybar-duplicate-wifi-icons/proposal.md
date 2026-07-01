# Proposal: Waybar Duplicate WiFi Icons

## Intent

Waybar shows two wifi icons on hosts with `omarchy.wifi.backend = "standalone-iwd"`: a disconnected `network` widget (NM-backed) and a connected `custom/iwd-wifi` widget (iwd-backed). The waybar config must branch on the wifi backend so only the correct widget appears.

## Scope

### In Scope
- omarchy-nix `waybar.nix`: conditionally emit `network` or `custom/iwd-wifi` in `modules-right` based on `cfg.wifi.backend`
- Preserve U+E900 omarchy icon character (stripped by Nix JSON round-trip)
- nixos-hosts: bump omarchy-nix flake input

### Out of Scope
- Changing `iwd-wifi.sh` behavior
- Hosts without waybar (rog, thinkcentre, mact2)
- `nm-iwd` backend changes (already works)

## Capabilities

### New Capabilities
None

### Modified Capabilities
- `iwd-wifi-indicator`: Module Placement changes from "always after `network`" to "sole wifi widget when `standalone-iwd`; coexists with `network` when `nm-iwd`"

## Approach

**Problem**: `config/waybar/config` is static JSON deployed via `home.file` recursive copy. Cannot be Nix-generated — `builtins.toJSON` strips U+E900 (documented in `waybar.nix:29`).

**Solution**: Text-level replacement of `modules-right` at Nix evaluation time.

1. Split deployment: keep recursive `home.file` for indicators/style/theme; deploy `config` separately via `xdg.configFile."waybar/config"` with `text =`
2. Use `builtins.replaceStrings` on the static file to swap `modules-right` based on `cfg.wifi.backend`:
   - `nm-iwd` → `["network", "custom/iwd-wifi"]` (current behavior)
   - `standalone-iwd` → `["custom/iwd-wifi"]` only
3. Only `modules-right` is touched — U+E900 in `custom/omarchy` passes through untouched

**nixos-hosts**: Single `flake.lock` bump. No code changes.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `modules/home-manager/waybar.nix` | Modified | Split deployment: recursive copy for assets + `xdg.configFile` for config with conditional `modules-right` |
| `config/waybar/config` | Unchanged | Static source of truth; patched at deploy time |
| `nixos-hosts: flake.lock` | Modified | Bump omarchy-nix rev |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| `replaceStrings` breaks on format change | Low | Our repo, stable format. `nix flake check` catches eval errors |
| `home.file` + `xdg.configFile` conflict | Low | Config excluded from recursive copy |
| U+E900 regression | Very Low | `replaceStrings` only touches `modules-right` |

## Rollback Plan

Revert `waybar.nix` to restore static recursive copy. Both widgets reappear. In nixos-hosts, revert flake.lock.

## Dependencies

Cross-repo: omarchy-nix commit lands first, then `nix flake update omarchy-nix` in nixos-hosts.

## Verification Plan

1. `nix flake check --no-build` passes in both repos
2. Visual: single wifi icon on t14 after rebuild
3. `nm-iwd` hosts retain both widgets (no regression)

## Success Criteria

- [ ] `nix flake check --no-build` passes in both repos
- [ ] t14 shows exactly ONE wifi icon (iwd widget)
- [ ] No `network` (NM-disconnected) icon on t14
- [ ] `nm-iwd` hosts unchanged
- [ ] U+E900 omarchy icon renders correctly