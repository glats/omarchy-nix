# Tasks: t14-monitor-layout-perfection

> Phase 1 of 2 (omarchy-nix generic foundation). Phase 2 will be applied to
> nixos-hosts to wire the new `hyprland.lidSwitch.enable` option from t14.

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~25 (3 files) |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Single PR (direct-to-main) |
| Delivery strategy | single-pr |
| Chain strategy | stacked-to-main |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: stacked-to-main
400-line budget risk: Low

### Suggested Work Units

| Unit | Goal | Likely PR | Notes |
|------|------|-----------|-------|
| 1 | Add `hyprland.lidSwitch.enable` option + wrap `switchBindings` + add `monitoradded` reload handler | PR 1 (omarchy-nix) | 3 files, ~25 lines; generic foundation usable by any consumer |
| 2 | t14 host config: opt in to `lidSwitch.enable = false` and add custom lid-switch bindings | PR 2 (nixos-hosts) | out of scope for this batch |

## Phase 1: omarchy-nix Generic Foundation

- [x] 1.1 Add `monitoradded` handler to `bin/omarchy-hyprland-monitor-watch` — calls `hyprctl reload` so on-monitor-add events refresh layout before the lid-toggle bindings inspect monitor state
- [x] 1.2 Add `hyprland.lidSwitch.enable` option to `config.nix` (alphabetical, between `firewall` and `voxtype`) — default `true`, allows consumers to opt out of omarchy's lid-switch bindings
- [x] 1.3 Wrap `switchBindings` in `lib.optionals cfg.hyprland.lidSwitch.enable` in `modules/home-manager/hyprland/bindings.nix` — preserves existing behavior by default, lets consumers disable the lid-switch bindl lines
- [x] 1.4 Verify: `bash -n bin/omarchy-hyprland-monitor-watch` → OK
- [x] 1.5 Verify: `nix flake check --no-build` in `~/repos/omarchy-nix` → all checks passed
- [x] 1.6 Verify: `nixfmt --check config.nix modules/home-manager/hyprland/bindings.nix` → OK
- [x] 1.7 Config validation: `lib.optionals false [a b]` → `[]`, `mkBindl []` → `""` — confirmed lid-switch bindl lines are absent from generated extraConfig when `enable = false`
- [x] 1.8 Commit on `main` in omarchy-nix with conventional commit message
