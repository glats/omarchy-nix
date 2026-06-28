# Design: omarchy-archlinux-copy-paste

## Technical Approach

Finish the Omarchy v3.1.0+ clipboard migration by moving two conflicting webapp bindings (`Calendar`, `X`) from `SUPER` to `SUPER SHIFT`, documenting the `mkBindd` render-order contract in `bindings.nix`, and syncing both doc files to the current keymap. No behavioral change to the clipboard `bindd` lines — they already work.

## Architecture Decisions

### Decision: mkBindd ordering — comment only, no `unbind` block

| Option | Tradeoff | Decision |
|--------|----------|----------|
| Comment only documenting "last wins" | Zero runtime impact; relies on convention | **Chosen** |
| Add `unbind = SUPER, C` etc. before clipboard block | Defensive but unnecessary after migration removes all conflicts; adds Hyprland-specific noise | Rejected |
| Reorder `mainBindings` before `quick_app_bindings` | Breaks the existing render order that users may depend on for other overrides | Rejected |

**Rationale**: After migration, `SUPER+C` is bound ONLY in `mainBindings` (clipboard copy). `SUPER SHIFT+C` is bound ONLY in `quick_app_bindings` (Calendar). No key collision exists. A comment at lines 307-311 of `bindings.nix` is sufficient to prevent future regressions. An `unbind` block would be solving a problem that no longer exists.

### Decision: hyprland-shortcuts.md — full rewrite, not patch

| Option | Tradeoff | Decision |
|--------|----------|----------|
| Patch individual stale lines | Risk of missing more stale entries; same drift problem later | Rejected |
| Full rewrite from bindings.nix source of truth | Larger diff but guarantees accuracy; matches README structure | **Chosen** |

**Rationale**: The file has 10+ stale entries (Super+F/B/M/N/T/D/G/O for apps are all missing Shift; Super+V is paste not toggle-floating; Super+S is "scratchpad" not "magic"; launcher is Walker not wofi; clipboard is Walker not clipse). Patching line-by-line is error-prone. A full rewrite from `bindings.nix` as source of truth is cleaner.

## Data Flow

No data flow changes. This is a configuration + documentation change.

    config.nix (quick_app_bindings default)
         │  SUPER SHIFT, C, Calendar    ← was SUPER, C
         │  SUPER SHIFT, X, X (Twitter) ← was SUPER, X
         ▼
    bindings.nix (extraConfig render)
         │  mkBindd cfg.quick_app_bindings  ← renders first (line 308)
         │  mkBindd mainBindings            ← renders second (line 311), includes clipboard
         │  [COMMENT: ordering is intentional, last-wins]
         ▼
    Hyprland extraConfig (no conflicts after migration)
         │
         ▼
    README.md + hyprland-shortcuts.md (docs synced to match)

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `config.nix` line 216 | Modify | `SUPER, C, Calendar` → `SUPER SHIFT, C, Calendar` |
| `config.nix` line 220 | Modify | `SUPER, X, X (Twitter)` → `SUPER SHIFT, X, X (Twitter)` |
| `modules/home-manager/hyprland/bindings.nix` ~line 307 | Modify | Add comment block explaining mkBindd render order: quick_app_bindings first, mainBindings second, last-wins in Hyprland. This is intentional and ensures clipboard bindings win if a user re-introduces a conflicting `quick_app_bindings` entry. |
| `README.md` line 239 | Modify | `SUPER + C` → `SUPER SHIFT + C` for Calendar |
| `README.md` line 242 | Modify | `SUPER + X` → `SUPER SHIFT + X` for X/Twitter |
| `hyprland-shortcuts.md` (whole file) | Rewrite | Full refresh from `bindings.nix` source of truth. Fix: Quick App Launchers table (add Shift to F/B/M/N/T/D/G/O/I/O), fix Super+V (paste, not toggle-floating), fix Super+S (scratchpad, not magic), fix launcher name (Walker, not wofi), fix clipboard manager (Walker, not clipse), add Copy/Paste/Cut section, add Super+T (toggle floating). |

## Interfaces / Contracts

No new interfaces. The `quick_app_bindings` option type (`listOf str`) is unchanged. Users who override this option with `SUPER, C` for a custom webapp will need to update to `SUPER SHIFT, C` — same migration path as upstream Omarchy.

## Testing Strategy

| Layer | What to Test | Approach |
|-------|-------------|----------|
| Evaluation | `nix flake check` passes | Run `nix flake check --no-build` — confirms no eval errors from the config.nix changes |
| Manual | Keybinding correctness | After `nixos-rebuild switch`: verify Super+C = copy, Super+Shift+C = Calendar, Super+X = cut, Super+Shift+X = X/Twitter |
| Doc review | README + hyprland-shortcuts.md match bindings.nix | Visual diff against `bindings.nix` lines 29-248 and config.nix lines 212-239 |

## Migration / Rollout

No migration required. The change is a `git revert` away from rollback. Users who have overridden `quick_app_bindings` in their own `configuration.nix` with `SUPER, C` will silently lose Calendar on that key — but this matches the upstream Omarchy migration path exactly (documented in PR body).

## Open Questions

- None. All decisions are resolved by the exploration and proposal.
