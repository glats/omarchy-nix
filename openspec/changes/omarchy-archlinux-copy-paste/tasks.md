# Tasks: omarchy-archlinux-copy-paste

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~15-20 (4 files) |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Single PR |
| Delivery strategy | single-pr |
| Chain strategy | size-exception (single PR, migration, well under budget) |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: size-exception
400-line budget risk: Low

### Suggested Work Units

| Unit | Goal | Likely PR | Notes |
|------|------|-----------|-------|
| 1 | Finish 3.1+ clipboard migration + sync docs | PR 1 (single) | 4 files, ~15-20 lines; config + 2 docs + 1 comment |

## Phase 1: Configuration Migration (`config.nix`)

- [x] 1.1 Edit `config.nix` line 216: `SUPER, C, Calendar, ...` → `SUPER SHIFT, C, Calendar, ...`
- [x] 1.2 Edit `config.nix` line 220: `SUPER, X, X (Twitter), ...` → `SUPER SHIFT, X, X (Twitter), ...`
- [x] 1.3 Verify: `nix flake check --no-build` passes after Phase 1

## Phase 2: Render-Order Contract (`bindings.nix`)

- [x] 2.1 Edit `modules/home-manager/hyprland/bindings.nix` lines 307-311: add comment explaining `mkBindd cfg.quick_app_bindings` renders first, `mkBindd mainBindings` second, last-wins in Hyprland, intentional
- [x] 2.2 Verify: `nix flake check --no-build` still passes (no syntax error from comment)

## Phase 3: README Sync

- [x] 3.1 Edit `README.md` line 239: `SUPER + C` → `SUPER SHIFT + C` for Calendar
- [x] 3.2 Edit `README.md` line 242: `SUPER + X` → `SUPER SHIFT + X` for X/Twitter
- [x] 3.3 Verify: README Webapps section matches `config.nix` `quick_app_bindings` default (visual diff)

## Phase 4: `hyprland-shortcuts.md` Rewrite

- [x] 4.1 Rewrite Quick App Launchers table: Super+Shift+C for Calendar, Super+Shift+X for X, Super+Shift+F/B/M/N/T/D/I/O for core apps
- [x] 4.2 Update Super+V entry: "Toggle floating mode" → "Universal paste"
- [x] 4.3 Add Copy/Paste/Cut section: Super+C copy, Super+V paste, Super+X cut, Super+Ctrl+V clipboard manager (Walker)
- [x] 4.4 Fix service names: launcher = Walker (not wofi), clipboard = Walker (not clipse), Super+S = scratchpad (not "magic")
- [x] 4.5 Verify: full file matches `bindings.nix` lines 29-248 and `config.nix` lines 212-239 (visual diff)

## Phase 5: Final Verification

- [x] 5.1 Run `nix flake check --no-build` — zero errors
- [x] 5.2 Run `alejandra` (via `nix fmt`) on all edited .nix files
- [x] 5.3 Cross-check: `SUPER, C`/`SUPER, V`/`SUPER, X` appear only in `mainBindings` (clipboard); `SUPER SHIFT, C`/`SUPER SHIFT, X` only in `quick_app_bindings`
- [x] 5.4 Confirm: README Webapps + hyprland-shortcuts.md Quick App table + `config.nix` default are all consistent
