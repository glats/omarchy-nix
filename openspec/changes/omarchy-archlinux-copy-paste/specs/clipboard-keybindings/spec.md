# Clipboard & Quick-App Keybindings Specification

## Purpose

Defines the Omarchy 3.1+ clipboard keybinding layout and its coexistence with quick-app launchers. The four universal clipboard operations occupy `Super+C/V/X` and `Super+Ctrl+V`. Quick-app launchers that previously used those keys MUST relocate to `Super+Shift+<key>`. Documentation MUST reflect the final layout.

---

## Requirements

### REQ-CLIPBOARD-BINDINGS

The system SHALL provide four `bindd` entries in `mainBindings`:

| Key | Action | Dispatcher |
|-----|--------|------------|
| `SUPER, C` | Universal copy | `sendshortcut, CTRL, Insert` |
| `SUPER, V` | Universal paste | `sendshortcut, SHIFT, Insert` |
| `SUPER, X` | Universal cut | `sendshortcut, CTRL, X` |
| `SUPER CTRL, V` | Clipboard manager | `exec, omarchy-launch-walker -m clipboard` |

Entries MUST be byte-identical to upstream `basecamp/omarchy/default/hypr/bindings/clipboard.conf`.

#### Scenario: Copy in focused window
- GIVEN a window is focused
- WHEN `Super+C` is pressed
- THEN `Ctrl+Insert` SHALL be synthesized to the focused window

#### Scenario: Clipboard manager
- GIVEN an active Hyprland session
- WHEN `Super+Ctrl+V` is pressed
- THEN Walker clipboard history SHALL appear

---

### REQ-NO-CONFLICT

No `quick_app_bindings` entry SHALL use `SUPER, C`, `SUPER, V`, or `SUPER, X`.

#### Scenario: Calendar does not shadow copy
- GIVEN default `quick_app_bindings`
- WHEN `Super+C` is pressed
- THEN Universal copy fires AND Calendar does NOT launch

#### Scenario: X/Twitter does not shadow cut
- GIVEN default `quick_app_bindings`
- WHEN `Super+X` is pressed
- THEN Universal cut fires AND X/Twitter does NOT launch

---

### REQ-QUICK-APPS-MIGRATION

`config.nix` `quick_app_bindings` default SHALL bind:

| App | Old | New |
|-----|-----|-----|
| Calendar | `SUPER, C` | `SUPER SHIFT, C` |
| X (Twitter) | `SUPER, X` | `SUPER SHIFT, X` |

All other entries SHALL remain unchanged.

#### Scenario: Calendar on migrated key
- GIVEN default `quick_app_bindings`
- WHEN `Super+Shift+C` is pressed
- THEN Calendar SHALL launch via `omarchy-launch-or-focus-webapp`

#### Scenario: X/Twitter on migrated key
- GIVEN default `quick_app_bindings`
- WHEN `Super+Shift+X` is pressed
- THEN X/Twitter SHALL launch

---

### REQ-MKBINDD-ORDER

In `bindings.nix` `extraConfig`, `mkBindd mainBindings` SHALL render AFTER `mkBindd cfg.quick_app_bindings`. An inline comment SHALL document the "last bindd wins" rule.

#### Scenario: Clipboard wins over stale user override
- GIVEN a user adds `"SUPER, C, SomeApp, ..."` to `quick_app_bindings`
- WHEN config is rendered
- THEN clipboard `bindd` SHALL appear after the user entry AND `Super+C` SHALL perform Universal copy

---

### REQ-DOCS-SYNC

`README.md` and `hyprland-shortcuts.md` SHALL document the 3.1+ layout consistently:
- README Webapps: Calendar → `Super+Shift+C`, X → `Super+Shift+X`
- README Copy/Paste/Cut section present
- hyprland-shortcuts.md Quick App table uses `Super+Shift` for core apps
- `Super+V` documented as Universal paste (not "Toggle floating")
- hyprland-shortcuts.md includes Copy/Paste/Cut section

#### Scenario: README agrees with config
- GIVEN `config.nix` binds Calendar to `SUPER SHIFT, C`
- WHEN reader consults README Webapps
- THEN reader sees `Super+Shift+C` for Calendar

#### Scenario: Shortcuts doc reflects paste
- GIVEN `bindings.nix` binds `SUPER, V` to paste
- WHEN reader consults `hyprland-shortcuts.md`
- THEN `Super+V` is documented as Universal paste, not Toggle floating
