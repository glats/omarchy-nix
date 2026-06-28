# Proposal: omarchy-archlinux-copy-paste

## Intent

Omarchy v3.1.0+ ships universal clipboard on `Super+C/V/X`, but `omarchy-nix` still binds Calendar to `Super+C` and X/Twitter to `Super+X` in `quick_app_bindings`. The clipboard `bindd` lines happen to win today because `mainBindings` renders after `quick_app_bindings` in `bindings.nix` — but this is an implicit ordering dependency, not an explicit contract. The README documents both behaviors as valid, and `hyprland-shortcuts.md` predates the clipboard feature entirely. This change finishes the 3.1+ migration that was started but not completed when the clipboard lines were first ported.

## Scope

### In Scope
- Migrate `SUPER, C, Calendar` → `SUPER SHIFT, C, Calendar` in `config.nix` `quick_app_bindings` default
- Migrate `SUPER, X, X (Twitter)` → `SUPER SHIFT, X, X (Twitter)` in `config.nix` `quick_app_bindings` default
- Make `mkBindd` ordering explicit in `bindings.nix` — add comment documenting "last wins" rule and why `mainBindings` must render after `quick_app_bindings`
- Update `README.md` webapps table: `Super+C` → `Super+Shift+C` (Calendar), `Super+X` → `Super+Shift+X` (X/Twitter)
- Refresh `hyprland-shortcuts.md` to match current 3.1+ layout: update Quick App Launchers table, fix stale `Super+V` (now paste, not toggle floating), add Copy/Paste/Cut section

### Out of Scope
- Hyprland 0.55+ `sendshortcut` trailing-comma fix (deferred to Hyprland bump change)
- Nautilus clipboard exception (not shipped in upstream either)
- Migrating other `quick_app_bindings` keys that don't conflict (ChatGPT, Email, YouTube stay on plain `Super`)
- Follow-up PR to `/home/glats/.nixos` flake lock update (separate repo)

## Capabilities

### New Capabilities
None

### Modified Capabilities
None

> This is a configuration migration + documentation sync. No spec-level behavior changes — the clipboard `bindd` lines already exist and work. We are removing conflicts and fixing docs.

## Approach

**Option B (Full Omarchy 3.1+ migration)** — match upstream `basecamp/omarchy` `config/hypr/bindings.conf` verbatim for the affected keys.

1. Edit `config.nix` `quick_app_bindings` default (lines 216, 220): change `SUPER, C` → `SUPER SHIFT, C` and `SUPER, X` → `SUPER SHIFT, X`
2. Edit `bindings.nix` (around line 308): add inline comment explaining that `quick_app_bindings` renders first and `mainBindings` (clipboard) renders second — this is intentional, last-wins in Hyprland
3. Edit `README.md` webapps section (lines 239, 242): update to `Super+Shift+C` and `Super+Shift+X`
4. Rewrite `hyprland-shortcuts.md`: update Quick App Launchers table, fix `Super+V` entry (was "Toggle floating", now "Universal paste"), add Copy/Paste/Cut section matching README

Estimated diff: ~15-20 lines across 4 files. Single PR, light review.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `config.nix` lines 216, 220 | Modified | Calendar → `SUPER SHIFT, C`, X → `SUPER SHIFT, X` |
| `modules/home-manager/hyprland/bindings.nix` ~line 308 | Modified | Add comment documenting mkBindd render order |
| `README.md` lines 239, 242 | Modified | Update webapps shortcut table |
| `hyprland-shortcuts.md` (whole file) | Modified | Full refresh to 3.1+ layout |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Users overriding `quick_app_bindings` to `Super+C` lose Calendar silently | Low | Document breaking change in PR body; the upstream migration path is identical |
| Docs drift again after this change | Low | Single source of truth is `bindings.nix`; docs are regenerated manually but now match |
| `Super+Shift+C` conflicts with another binding | None | Verified: no existing `SUPER SHIFT, C` binding in `mainBindings` |

## Rollback Plan

Revert the single PR. Since this only changes `config.nix` defaults and documentation, a `git revert` restores the pre-migration state cleanly. Users who adopted `Super+Shift+C` would need to manually revert their muscle memory, but no data is lost.

## Dependencies

- None. The clipboard `bindd` lines already exist in `bindings.nix` lines 243-247. `wl-clipboard`, `clipse`, and Walker clipboard provider are already wired.

## Success Criteria

- [ ] `nix flake check` passes with no evaluation errors
- [ ] `SUPER SHIFT, C` launches Calendar (no conflict with `SUPER, C` copy)
- [ ] `SUPER SHIFT, X` launches X/Twitter (no conflict with `SUPER, X` cut)
- [ ] `SUPER, C` / `SUPER, V` / `SUPER, X` perform clipboard operations unambiguously
- [ ] `README.md` and `hyprland-shortcuts.md` both document the same keymap, matching `bindings.nix`
- [ ] `bindings.nix` has explicit comment explaining mkBindd render order
