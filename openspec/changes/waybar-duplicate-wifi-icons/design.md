# Design: Waybar Duplicate WiFi Icons

## Technical Approach

Visual disambiguation: replace the `network` widget's disconnected glyph (`nf-md-wifi-off`, U+F092E) with `nf-md-lan_disconnect` (U+F0319) so the NM-backed disconnected state is visually distinct from the iwd-backed wifi widget. Add `#custom-iwd-wifi` to the existing CSS sizing group for consistent spacing. No Nix code changes — static files deployed via `home.file` recursive copy.

This is a simpler alternative to the proposal's conditional module removal. The user explicitly wants both widgets visible.

## Architecture Decisions

### Decision: Glyph substitution over conditional module removal

| Option | Tradeoff | Decision |
|--------|----------|----------|
| Conditional `modules-right` via `replaceStrings` in `waybar.nix` | Removes duplicate entirely; complex Nix plumbing, risks U+E900 regression | **Rejected** |
| Change `format-disconnected` glyph to `nf-md-lan_disconnect` | Both widgets remain visible; disconnected states look different | **Chosen** |

**Rationale**: User wants both widgets visible at all times. The "duplicate" problem is perceptual — two identical wifi-off icons side by side. Making them visually distinct solves the UX issue without structural changes.

### Decision: Extend existing CSS selector group vs new rule

| Option | Tradeoff | Decision |
|--------|----------|----------|
| New `#custom-iwd-wifi { ... }` rule | Explicit but duplicates properties; maintenance burden | **Rejected** |
| Add `#custom-iwd-wifi` to existing `#cpu, #battery, ...` group | Single source of truth for icon sizing; follows existing pattern | **Chosen** |

**Rationale**: The existing group at lines 32–39 already defines `min-width: 12px; margin: 0 7.5px;` for icon-sized widgets. Adding `#custom-iwd-wifi` to this group gives it identical spacing with zero new CSS. CSS cascade: all selectors in a comma-group have equal specificity; later rules in the file override earlier ones for the same property. Since `#custom-iwd-wifi` has no other `min-width`/`margin` rules, the group rule applies cleanly.

### Decision: Nerd Font glyph availability

**Glyph**: `󰌙` — U+F0319, `nf-md-lan_disconnect` from Material Design Icons range.
**Font**: `Caskaydia Mono Nerd Font` (system monospace, set in `fonts.nix`). This is a Nerd Font-patched family with full MDI coverage (U+F0000–U+F0FFF). The glyph is guaranteed available.
**Risk**: None. If the waybar font were changed to a non-Nerd-Font, ALL existing glyphs (battery, cpu, bluetooth, wifi icons) would break — this change introduces no new dependency.

## Data Flow

No data flow changes. Both widgets continue to read their respective backends:

```
 ┌─────────────┐       ┌──────────────────┐
 │ NM (network) │       │ iwd (iwd-wifi.sh) │
 │  widget      │       │  custom widget     │
 └──────┬──────┘       └────────┬─────────┘
        │                       │
   format-disconnected     exec: iwctl
   "󰌙" (was "󰤮")          → JSON output
        │                       │
        └────── waybar ─────────┘
```

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `config/waybar/config` | Modify | Line 86: change `format-disconnected` from `"󰤮"` to `"󰌙"` |
| `config/waybar/style.css` | Modify | Line 32: add `#custom-iwd-wifi,` to the selector group |
| `nixos-hosts: flake.lock` | Modify | Bump omarchy-nix input after merge |

### Exact Diff: `config/waybar/config`

```diff
@@ -83,7 +83,7 @@
     "format": "{icon}",
     "format-wifi": "{icon}",
     "format-ethernet": "󰀂",
-    "format-disconnected": "󰤮",
+    "format-disconnected": "󰌙",
     "tooltip-format-wifi": "{essid} ({frequency} GHz)",
     "tooltip-format-ethernet": "Connected",
     "tooltip-format-disconnected": "Disconnected",
```

### Exact Diff: `config/waybar/style.css`

```diff
@@ -29,6 +29,7 @@
 #cpu,
 #battery,
 #pulseaudio,
 #custom-omarchy,
+#custom-iwd-wifi,
 #custom-update {
   min-width: 12px;
   margin: 0 7.5px;
```

## Interfaces / Contracts

None. No new modules, scripts, or Nix options.

## Testing Strategy

| Layer | What to Test | Approach |
|-------|-------------|----------|
| Visual | Disconnected state shows `󰌙` (lan_disconnect) not `󰤮` (wifi-off) | Rebuild + look at waybar |
| Visual | `#custom-iwd-wifi` has correct spacing (12px min-width, 7.5px margins) | Compare with `#cpu`/`#battery` spacing |
| Regression | `nm-iwd` hosts: `network` widget still shows wifi icons when NM manages wifi | Check on rog/other nm-iwd hosts |
| Validation | `nix flake check --no-build` passes | CI gate |

## Migration / Rollout

No migration required. Static config files — change takes effect on next `nixos-rebuild switch` (waybar auto-reloads via `reload_style_on_change: true`).

**Cross-repo sequence**:
1. Merge omarchy-nix changes
2. In nixos-hosts: `nix flake lock --update-input omarchy-nix`
3. Rebuild affected hosts

## Open Questions

None.
