# Verification Report: omarchy-archlinux-copy-paste

> **Date**: 2026-06-28
> **Verdict**: PASS WITH WARNINGS
> **Next**: fixes-required (2 doc-code alignment issues)

## Completeness

| Dimension | Status |
|-----------|--------|
| Tasks (16/16) | ✅ All checked |
| `nix flake check --no-build` | ✅ PASS |
| Keybinding conflict search | ✅ Clean |
| Git diff scope | ✅ 4 intended files only |

## Spec Compliance Matrix

| Requirement | Scenarios | Status |
|-------------|-----------|--------|
| REQ-CLIPBOARD-BINDINGS | Copy in focused window, Clipboard manager | ✅ PASS |
| REQ-NO-CONFLICT | Calendar does not shadow copy, X does not shadow cut | ✅ PASS |
| REQ-QUICK-APPS-MIGRATION | Calendar on migrated key, X/Twitter on migrated key | ⚠️ WARNING |
| REQ-MKBINDD-ORDER | Clipboard wins over stale user override | ✅ PASS |
| REQ-DOCS-SYNC | README agrees with config, Shortcuts doc reflects paste | ⚠️ WARNING |

## Issues

### #1 (WARNING) — config.nix: Compose post on X entry silently removed

**Spec**: REQ-QUICK-APPS-MIGRATION — "All other entries SHALL remain unchanged"
**Reality**: The `SUPER SHIFT, X, Compose post on X` entry was removed when X/Twitter migrated from `SUPER, X` to `SUPER SHIFT, X`
**Impact**: Functionally necessary (would have been a keybinding conflict), but violates spec text
**Fix**: (a) Add compose post back on a distinct key (e.g., `SUPER SHIFT CTRL, X`); or (b) amend spec to acknowledge intentional removal

### #2 (WARNING) — hyprland-shortcuts.md: Stale compose post entry

**Spec**: REQ-DOCS-SYNC — docs SHALL document layout consistently with config.nix
**Reality**: Quick App Launchers table lists `Super Shift + X` → "Open X compose post" as a second entry; note says it's "bound twice" and references stale config.nix lines 220-221. The compose post entry is NOT in config.nix.
**Impact**: Reader expects compose to possibly fire; only X/Twitter opens
**Fix**: Remove compose post row and note, OR re-add compose post to config.nix on a distinct key

## Evidence

- bindings.nix:244-247 — all 4 clipboard bindd entries present
- config.nix:216 — `SUPER SHIFT, C, Calendar` (was `SUPER, C`)
- config.nix:220 — `SUPER SHIFT, X, X (Twitter)` (was `SUPER, X`)
- bindings.nix:307-318 — mkBindd ordering comment and blocks
- README.md:277-281 — Copy/Paste/Cut section present
- hyprland-shortcuts.md:62-73 — Copy/Paste/Cut section
- hyprland-shortcuts.md:84-88 — Quick App Launchers (Calendar/X migrated)
