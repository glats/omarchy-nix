# Exploration: omarchy-archlinux-copy-paste

## Change Name
`omarchy-archlinux-copy-paste`

## Problem Statement
The Omarchy Archlinux flavor (v3.1.0+, current omarchy-nix is on v3.7.1 per
`default/omarchy-version`) ships with a universal clipboard feature bound to
`Super + C` / `Super + V` / `Super + X` plus a clipboard manager on
`Super + Ctrl + V`. The `omarchy-nix` Hyprland binding file
(`modules/home-manager/hyprland/bindings.nix` lines 243–247) already defines the
four `bindd` lines verbatim from
`basecamp/omarchy/default/hypr/bindings/clipboard.conf` — but the
`config.nix` `quick_app_bindings` default (line 216) still binds
`SUPER, C, Calendar, ...` and other webapps to the pre-3.1.0 keys, creating
real duplication. The README documents both behaviors side by side and the
`hyprland-shortcuts.md` file still documents the pre-3.1.0 layout.

Goal: reconcile the configuration so that the four universal-clipboard
`bindd` lines win unambiguously, the webapp quick-launchers that previously
occupied `Super + C` / `Super + V` / `Super + X` are moved to the
`Super + Shift + [letter]` positions used by current Omarchy, and
docs/shortcut files are synced — all without diverging from the Archlinux
upstream.

---

## Current State (omarchy-nix @ v3.7.1)

### The four `bindd` lines that already exist (verbatim from upstream)
File: `modules/home-manager/hyprland/bindings.nix`, lines 243–247:
```
# Copy / Paste
"SUPER, C, Universal copy, sendshortcut, CTRL, Insert,"
"SUPER, V, Universal paste, sendshortcut, SHIFT, Insert,"
"SUPER, X, Universal cut, sendshortcut, CTRL, X,"
"SUPER CTRL, V, Clipboard manager, exec, ${omarchyExec}/omarchy-launch-walker -m clipboard"
```
These are **byte-for-byte** identical to
`basecamp/omarchy/default/hypr/bindings/clipboard.conf` (master, multiple
commits confirmed). The clipboard infrastructure is already wired:
- `wl-clipboard` is a system dep (`modules/nixos/system.nix` line 38)
- `wl-clip-persist --clipboard regular & clipse -listen` in
  `modules/home-manager/hyprland/autostart.nix` line 12
- Walker clipboard provider in `config/walker/config.toml` lines 39–45
  (`$` prefix and `-m clipboard` flag)
- Terminals already map `Ctrl+Insert`/`Shift+Insert` to
  copy/paste — `kitty.nix` lines 35–36, `ghostty.nix` lines 40–41,
  `alacritty.nix` lines 48–56

So the "does it work" half of the change is effectively already shipped in
omarchy-nix.

### The actual conflict (unmigrated webapp bindings)
File: `config.nix` `quick_app_bindings` default, lines 212–239:
- `SUPER, C, Calendar, ...` (line 216) — collides with `SUPER, C, Universal copy`
- `SUPER, X, X (Twitter), ...` (line 220) — collides with `SUPER, X, Universal cut`
- `SUPER, V, ...` is NOT bound here, but `mainBindings` line 245 binds
  `SUPER, V, Universal paste`. `hyprland-shortcuts.md` line 44 still
  documents `Super + V` as "Toggle floating mode" — the actual binding is
  now Universal paste (line 245 of bindings.nix), and Toggle floating is on
  `Super + T` (line 101).

In Hyprland, when two `bindd` entries share the same key combo, **the last one
in the rendered `extraConfig` wins**. `bindings.nix` renders
`cfg.quick_app_bindings` (Calendar, X) first, then `mainBindings`
(Universal copy, Universal cut) second. So **the user currently gets the
Universal copy/cut behavior, not Calendar/X launch** — but only because of
file ordering, not because of an explicit `unbind =`. This is fragile: a
future refactor that reorders the `mkBindd` calls (or that lets the user
override `quick_app_bindings` last) would silently break copy/paste.

### Documentation inconsistencies
- `README.md` lines 239 vs 279 — both list `Super + C` once as "Calendar
  (Hey)" and once as "Universal copy". No note about the ordering quirk.
- `hyprland-shortcuts.md` is even more stale: it documents
  `Super + C` → Calendar (line 9), `Super + V` → Toggle floating (line 44),
  and lacks the entire Copy / Paste / Cut section. It appears to track the
  pre-3.1.0 Omarchy layout.

### Hyprland version compatibility
`flake.nix` pins Hyprland to `v0.54.3`. As of Hyprland `0.55.0` (May 2026),
the `sendshortcut` dispatcher requires either:
- a trailing whitespace after the last comma, or
- an explicit `, active` or `, activewindow` argument

The current omarchy-nix bindings use a bare trailing comma (e.g.
`..., Insert,`). On `0.54.3` this still parses. On `0.55+` it would break
exactly as described in
[basecamp/omarchy#5757](https://github.com/basecamp/omarchy/issues/5757).
The fix is trivial: append `active` (or just a space) — but only when
upgrading. **Not in scope for this change** unless we also bump Hyprland.

---

## Affected Areas

| File | Why it's affected |
|------|-------------------|
| `config.nix` lines 212–239 (`quick_app_bindings` default) | Primary source of the conflict. The five pre-3.1.0 webapp/key shortcuts must be moved to `Super + Shift + ...` (and `Super + Alt + ...` for X Post) to match upstream. |
| `modules/home-manager/hyprland/bindings.nix` lines 243–247 | Source of truth for the four `bindd` clipboard lines — should stay verbatim, but consider making the order of `mkBindd cfg.quick_app_bindings` and `mkBindd mainBindings` deterministic so that `mainBindings` (clipboard) ALWAYS wins. Currently it only wins because of file ordering. |
| `README.md` lines 236–244 (webapps) and 278–282 (copy/paste) | Documents the conflict as if both bindings were valid. Needs a single, accurate table — recommend matching Omarchy's manual layout. |
| `hyprland-shortcuts.md` (whole file) | Significantly out of date; doesn't reflect the Copy / Paste / Cut block at all, and still lists pre-3.1.0 webapp keys. |
| `modules/home-manager/hyprland/looknfeel.nix` / `default.nix` | No change required; just noting they don't override the bindings. |

---

## Research: How Omarchy Archlinux resolves this

### Authoritative source
[`basecamp/omarchy/default/hypr/bindings/clipboard.conf`](https://github.com/basecamp/omarchy/blob/master/default/hypr/bindings/clipboard.conf):
```conf
# Copy / Paste
bindd = SUPER, C, Universal copy, sendshortcut, CTRL, Insert,
bindd = SUPER, V, Universal paste, sendshortcut, SHIFT, Insert,
bindd = SUPER, X, Universal cut, sendshortcut, CTRL, X,
bindd = SUPER CTRL, V, Clipboard manager, exec, omarchy-launch-walker -m clipboard
```
Omarchy introduced this in **v3.1.0** as the new default; older installs
were prompted to opt-in. The PR ([#1222](https://github.com/basecamp/omarchy/pull/1222))
explicitly states the migration map:
- `Calendar` → `Super + Shift + C`
- `Toggle floating` → `Super + Shift + V`  *(NOT to be confused with paste)*
- `X` → `Super + Shift + X`
- `X Post` → `Super + Alt + X`

### Current upstream `config/hypr/bindings.conf` (master, confirmed 2026-06)
The full webapp section is already migrated to `Super + Shift + [letter]`:
```conf
bindd = SUPER SHIFT, A, ChatGPT, exec, omarchy-launch-webapp "https://chatgpt.com"
bindd = SUPER SHIFT ALT, A, Grok, exec, omarchy-launch-webapp "https://grok.com"
bindd = SUPER SHIFT, C, Calendar, exec, omarchy-launch-webapp "https://app.hey.com/calendar/weeks/"
bindd = SUPER SHIFT, E, Email, exec, omarchy-launch-webapp "https://app.hey.com"
bindd = SUPER SHIFT, Y, YouTube, exec, omarchy-launch-webapp "https://youtube.com/"
bindd = SUPER SHIFT ALT, G, WhatsApp, exec, omarchy-launch-or-focus-webapp WhatsApp "https://web.whatsapp.com/"
bindd = SUPER SHIFT CTRL, G, Google Messages, exec, omarchy-launch-or-focus-webapp "Google Messages" "https://messages.google.com/web/conversations"
bindd = SUPER SHIFT, P, Google Photos, exec, omarchy-launch-or-focus-webapp "Google Photos" "https://photos.google.com/"
bindd = SUPER SHIFT, X, X, exec, omarchy-launch-webapp "https://x.com/"
bindd = SUPER SHIFT ALT, X, X Post, exec, omarchy-launch-webapp "https://x.com/compose/post"
```

### Upstream core-app bindings are also migrated to `Super + Shift +`
Confirmed (2026-06) on `master`:
- `Terminal` → `Super + Return` (unchanged)
- `Browser` → `Super + Shift + Return`
- `File manager` → `Super + Shift + F`
- `Music` → `Super + Shift + M`
- `Editor` → `Super + Shift + N`
- `Docker` → `Super + Shift + D`
- `Signal` → `Super + Shift + G`
- `Obsidian` → `Super + Shift + O`
- `Typora` → `Super + Shift + W`
- `Passwords` → `Super + Shift + SLASH`

**omarchy-nix already has most of these `Super + Shift +` keys** (see
`config.nix` lines 224–235). The missing pieces are:
- `Super + Shift + C` (Calendar) — currently `Super + C`
- `Super + Shift + X` (X) — currently `Super + X`
- `Super + Alt + X` (X Post) — already correct (line 221)

The other webapp keys (`Super + A` ChatGPT, `Super + Shift + A` Grok,
`Super + E` Email, `Super + Y` YouTube, `Super + Shift + G` WhatsApp) are
ALREADY in `Super + Shift + [letter]` form in the current omarchy-nix —
they were migrated at some earlier point, but Calendar and X were missed.

### `sendshortcut` mechanics
- `sendshortcut` synthesizes a keypress and sends it to the focused window
  via Hyprland's input subsystem.
- `CTRL, Insert` is the historical X11 "copy" sequence (and is the sequence
  that `kitty`/`ghostty`/`alacritty` already map to copy). It works in
  every terminal that doesn't intercept the `Insert` key.
- `SHIFT, Insert` is the historical X11 "paste" sequence. Same.
- `CTRL, X` is the standard "cut" — same as every GUI app, works in
  terminals (sends a literal `^X` to the shell which is the canonical
  cut/clear shortcut in readline).

### Nautilus exception
Omarchy explicitly notes the only app that doesn't honor these is Nautilus.
[Issue #4511](https://github.com/basecamp/omarchy/issues/4511) shows
class-scoped `bindd` workarounds, but they aren't shipped in upstream. Not
in scope for this change.

---

## Approaches

### Option A — Minimal: just move the two conflicting webapp keys
Update only the two `quick_app_bindings` entries that actually collide with
the clipboard `bindd` lines:
- `SUPER, C, Calendar` → `SUPER SHIFT, C, Calendar` (matches upstream)
- `SUPER, X, X (Twitter)` → `SUPER SHIFT, X, X` (matches upstream)

Leave the `SUPER, A, ChatGPT`, `SUPER, E, Email`, `SUPER, Y, YouTube` etc.
as-is (they're already in non-conflicting positions and don't need
changing for the copy/paste conflict to resolve).
- **Pros**: Smallest diff (~2 line changes in `config.nix`). Resolves the
  copy/paste conflict. Matches upstream's migration exactly for the
  affected keys. Lowest review burden.
- **Cons**: Doesn't fix `hyprland-shortcuts.md` or the README.md
  inconsistency. The order-dependence bug (copy only wins because of file
  ordering, not because of an explicit `unbind =`) remains.
- **Effort**: Low.

### Option B — Full Omarchy 3.1+ migration (recommended)
Apply the upstream migration map to ALL webapp keys (Calendar, X, plus
auditing the rest), update `quick_app_bindings` default in `config.nix`,
update `README.md` shortcut tables, refresh `hyprland-shortcuts.md`,
and make the `mkBindd` ordering deterministic so that `mainBindings`
always wins over `quick_app_bindings` (or add an explicit
`unbind = SUPER, C` / `SUPER, X` before the clipboard block — but that
would be opinionated; the simpler fix is to render `mainBindings` first
and `quick_app_bindings` second with a clear comment, OR add an explicit
user-visible note in the option description).
- **Pros**: Matches upstream verbatim. Resolves the conflict. Fixes the
  stale docs. Closes the order-dependence footgun. Aligns with the
  `CLAUDE.md` porting principle: "Match keybindings exactly: Use Omarchy's
  `config/hypr/hyprland.conf` as the source of truth."
- **Cons**: Larger diff (likely 5–15 line changes across 4 files). The
  order-dependence fix is opinionated and may want a discussion.
- **Effort**: Medium.

### Option C — Submap approach (rejected)
Define a "clipboard" submap toggled by `Super + grave` (per
[omarchy/discussions/2675](https://github.com/basecamp/omarchy/discussions/2675))
and put the four clipboard `bindd` lines inside it. This is the most
flexible and avoids the conflict entirely without moving any webapp
key, but it's NOT what upstream does. Per `CLAUDE.md` porting
principles, this would be a divergence, not a port. **Reject.**

---

## Recommendation

**Option B (Full Omarchy 3.1+ migration).**

Rationale:
1. The `CLAUDE.md` porting principle says: "**Match keybindings exactly**:
   Use Omarchy's `config/hypr/hyprland.conf` as the source of truth." The
   current `config.nix` Calendar/X entries violate this — they're a pre-3.1
   leftover that was missed when the clipboard `bindd` lines were ported.
2. The four clipboard `bindd` lines are already a verbatim port — we're
   just finishing the migration.
3. The README and `hyprland-shortcuts.md` are out of date; an
   exploration-only change that doesn't fix them leaves known-stale docs.
4. The order-dependence bug is real and should be fixed in the same
   change. Recommend rendering `quick_app_bindings` *after* `mainBindings`
   in `bindings.nix` and adding a `mkBindd cfg.quick_app_bindings` AFTER
   `mkBindd mainBindings` — OR adding a comment that explicitly documents
   the "last wins" rule and why `mainBindings` is rendered last. The
   cleanest fix is to add an explicit "if you want to override a
   `mainBindings` shortcut, prefer editing `mainBindings` itself or using
   `extraConfig`" docstring on the `quick_app_bindings` option.
5. Hyprland 0.55+ compat (`active` argument on `sendshortcut`) is a
   separate, larger concern — should be a follow-up change tied to the
   Hyprland bump.

Scope budget estimate: 1 PR, ~15–20 line changes across 4 files. Well
under the 400-line chained-PR threshold.

---

## Risks

- **User-override breakage**: Users who have overridden `quick_app_bindings`
  in their own `configuration.nix` to put a webapp on `Super + C` or
  `Super + X` will silently lose that binding after the migration.
  Mitigation: document the breaking change in `CLAUDE.md` /
  `openspec/changes/.../proposal.md`; consider leaving a commented-out
  escape hatch showing the old position.
- **README/shortcut file drift**: Any change to `bindings.nix` must be
  reflected in `README.md` and `hyprland-shortcuts.md` or we recreate the
  problem. Mitigation: include doc updates in this same change.
- **Hyprland 0.55+ future breakage**: Not in scope, but worth flagging as
  a follow-up. The current `sendshortcut, CTRL, Insert,` (trailing comma
  with no arg) will break when Hyprland is bumped past 0.55.
- **Walker clipboard vs `clipse`**: The `omarchy-launch-walker -m clipboard`
  invocation uses the Walker clipboard provider (`config/walker/config.toml`
  line 45). The upstream Omarchy manual mentions both `clipse` and
  `walker -m clipboard` interchangeably — our setup is consistent with
  upstream (we use Walker because that's what `modules/home-manager/walker.nix`
  ships). No risk.

---

## Ready for Proposal

**Yes.** The orchestrator should:
1. Move to `sdd-propose` with change name `omarchy-archlinux-copy-paste`.
2. Recommend Option B in the proposal.
3. Flag the Hyprland 0.55+ `sendshortcut` follow-up as a separate change
   (deferred, tracked but not in scope).
4. Note the user-override breakage as a migration concern in the proposal's
   rollback / risk section.
