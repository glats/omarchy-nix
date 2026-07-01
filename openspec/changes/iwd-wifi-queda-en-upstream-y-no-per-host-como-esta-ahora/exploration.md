# Exploration: iwd-wifi waybar indicator → upstream omarchy-nix

**Change name**: `iwd-wifi-queda-en-upstream-y-no-per-host-como-esta-ahora`
**Project**: omarchy-nix (artifact in this repo) + nixos-hosts (downstream consumer)
**Date**: 2026-06-28
**Investigator**: sdd-explore sub-agent

## 1. Current State

### 1a. The script today (t14 per-host)

The iwd-wifi indicator script lives **inline as a `text` string** inside
`/home/glats/.nixos/hosts/t14/home/default.nix` lines 58–80. Verbatim:

Lines 58–80 of `/home/glats/.nixos/hosts/t14/home/default.nix` (the
header comment + the inline `home.file` block):

```nix
58:   # ------------------------------------------------------------------
59:   # Waybar — iwd WiFi status indicator
60:   # ------------------------------------------------------------------
61:   # omarchy-nix owns the waybar config via home.file (recursive dir
62:   # copy of config/waybar/). We add only the iwd-wifi indicator
63:   # script (iwd-specific, not in upstream). The script deploys but is
64:   # not yet referenced by upstream's waybar modules-right
65:   # (follow-up: patch upstream waybar config to include
66:   # custom/iwd-wifi).
67:   home.file.".config/waybar/indicators/iwd-wifi.sh" = {
68:     text = ''
69:       #!/bin/bash
70:       # waybar custom module: iwd WiFi status
71:       state=$(iwctl station wlan0 show 2>/dev/null | awk '/State/ {print $2}')
72:       ssid=$(iwctl station wlan0 show 2>/dev/null | awk '/Connected network/ {$1=""; $2=""; print}' | xargs)
73:       if [ "$state" = "connected" ] && [ -n "$ssid" ]; then
74:         echo "{\"text\": \" $ssid\", \"class\": \"connected\", \"tooltip\": \"WiFi: $ssid (iwd)\"}"
75:       else
76:         echo "{\"text\": \"󰤮\", \"class\": \"disconnected\", \"tooltip\": \"WiFi disconnected\"}"
77:       fi
78:     '';
79:     executable = true;
80:   };
```

The script is a thin wrapper over `iwctl station wlan0 show` that emits a
waybar JSON blob with `text` (the SSID or a disconnected icon `󰤮`), a
`class` (connected/disconnected), and a `tooltip`. The interface name
`wlan0` is hard-coded.

The file comment on line 65–66 already says the intended follow-up:
"patch upstream waybar config to include `custom/iwd-wifi`". The
**iwd-wifi script is deployed but not wired into the waybar bar** on
the t14 host today — the bar shows no iwd-wifi block, so the file
sits unused at `~/.config/waybar/indicators/iwd-wifi.sh` waiting to be
referenced.

### 1b. omarchy-nix waybar module structure

| File | Role |
|---|---|
| `config/waybar/config` | Static JSON waybar config. `modules-right` lists the tray/network/bt/cpu/battery block. |
| `config/waybar/style.css` | Waybar styling. |
| `config/waybar/indicators/*.sh` | Three indicator scripts already live here: `idle.sh`, `notification-silencing.sh`, `screen-recording.sh`. |
| `modules/home-manager/waybar.nix` | Single `home.file.".config/waybar/" = { source = ../../config/waybar; recursive = true; }` — copies the whole `config/waybar/` dir verbatim. Adds `theme.css` symlink, `font.css`, and `waybar` package. |

The waybar config is **intentionally static** (see `waybar.nix` lines
27–29: "This preserves the U+E900 omarchy icon character which gets
stripped by Nix's JSON encoding"). So the JSON cannot easily be
generated from a Nix attrset; it must stay a hand-edited file.

### 1c. Existing `custom/*` indicator pattern in `config/waybar/config`

The three scripts that already exist in `config/waybar/indicators/`
each have a matching `custom/*` block in the waybar config. They all
follow the same shape:

```json
"custom/screenrecording-indicator": {
  "on-click": "omarchy-cmd-screenrecord",
  "exec": "~/.config/waybar/indicators/screen-recording.sh",
  "signal": 8,
  "return-type": "json"
},
```

Signal numbers already used: **7, 8, 9, 10** (next free: 11). Each
script returns a JSON blob with `text` and optional `tooltip`/`class`.
`on-click` typically launches a related omarchy command (e.g. the
screen-recording one runs `omarchy-cmd-screenrecord`).

### 1d. WiFi backend story in omarchy-nix

- `config.nix:375–400` defines `omarchy.wifi.backend` with two values:
  `nm-iwd` (default) and `standalone-iwd`.
- `modules/nixos/system.nix:217` always enables
  `networking.wireless.iwd.enable = true` (required by impala TUI).
- `modules/nixos/system.nix:223–241` switches NM's wifi backend between
  `iwd` (default) and `standalone-iwd`, marking `wlan0` as `unmanaged`
  in the latter case.
- `bin/omarchy-launch-wifi` and `bin/omarchy-restart-wifi` are the
  existing wifi UX entry points; both route through `impala` TUI
  (which talks iwd D-Bus directly).

The t14 host uses `wifi.backend = "standalone-iwd"` (see
`/home/glats/.nixos/hosts/t14/default.nix:134`). In that mode NM does
not see `wlan0` at all, so the built-in waybar `network` module —
which reads from NM via D-Bus — will not show wifi state correctly
for t14. The custom `iwd-wifi` indicator fills that gap by reading
`iwctl` directly.

### 1e. The `network` block already in waybar config

Lines 79–91 of `config/waybar/config` already define a `network`
module with `format-icons`, `tooltip-format-wifi`, `on-click: "omarchy-launch-wifi"`,
etc. This works correctly on `nm-iwd` systems. On `standalone-iwd`
systems it will show the disconnected icon even when wifi is up,
because NM has no knowledge of `wlan0`. The custom `iwd-wifi`
indicator is the fix.

## 2. Affected Areas

### In `omarchy-nix` (this repo)

- `config/waybar/indicators/iwd-wifi.sh` — **NEW**. The script,
  extracted from the t14 nix file and made +x.
- `config/waybar/config` — **MODIFY**. Add a `custom/iwd-wifi` block
  matching the existing indicator pattern, and add `"custom/iwd-wifi"`
  to `modules-right` (next to the existing `network` module).
- (no module changes needed — `modules/home-manager/waybar.nix`
  already does `recursive = true` so any new file under
  `config/waybar/` deploys automatically).

### In `nixos-hosts` (the .nixos repo)

- `hosts/t14/home/default.nix` — **DELETE** lines 58–80 (the entire
  iwd-wifi `home.file` block + its 12-line header comment). Update
  the file's top-level comment (lines 6–9) which currently says
  "iwd-wifi waybar indicator script (iwd-specific, not in omarchy)" —
  that bullet becomes obsolete.
- `flake.lock` — **BUMP** `omarchy-nix` after the upstream change
  merges. The input is pinned as `github:glats/omarchy-nix/main`
  (branch ref) in `flake.nix:20`, so a `nix flake update omarchy-nix`
  will pick up the new commit.
- `flake.nix` — **NO CHANGE** needed (branch ref already in place).

## 3. Approaches

### Approach A: Static add — always show iwd-wifi

Add the script and a `custom/iwd-wifi` block to `config/waybar/config`
unconditionally. The script handles the "iwd not managing wlan0" case
by returning a disconnected-icon JSON blob (same shape it already
uses today).

- **Pros**: Simplest. Matches existing pattern. No Nix-side JSON
  generation needed (preserves the U+E900 omarchy glyph). Works on
  both `nm-iwd` and `standalone-iwd` — on `nm-iwd` it will just
  always show the disconnected icon since NM owns wlan0, but that's
  harmless.
- **Cons**: Two wifi-related icons on screen on `nm-iwd` systems
  (built-in `network` + custom `iwd-wifi`). Users on `nm-iwd` will
  see a redundant disconnected indicator.
- **Effort**: Low.

### Approach B: Conditional via cfg.wifi.backend

Generate the waybar config from a Nix attrset, gated on
`config.omarchy.wifi.backend == "standalone-iwd"`. When true, the
`custom/iwd-wifi` block is included and the built-in `network` block
is removed (or vice versa).

- **Pros**: Clean UX. One wifi indicator on screen at a time,
  matches the actual wifi ownership. The "right" answer.
- **Cons**: Requires converting the waybar config from a static
  `home.file` source to a generated `xdg.configFile` with
  `text = builtins.toJSON {…}`. The U+E900 omarchy icon
  (`\ue900` in the `custom/omarchy` block line 53) gets stripped by
  Nix's JSON encoder — this is the explicit reason the static copy
  exists today. A workaround is to pass the glyph as a `\u0000`-style
  escape and let waybar decode it (waybar does parse `\u` escapes
  inside JSON strings), but this needs verification.
- **Effort**: Medium-high. Touches `waybar.nix` and the entire
  `config/waybar/config` file format.

### Approach C: Hybrid — static config + post-render patch

Keep the static `config/waybar/config` but add a Nix-side sed/replace
step in `waybar.nix` that injects the `custom/iwd-wifi` block into
the JSON when `cfg.wifi.backend == "standalone-iwd"`, and adds the
module name to `modules-right` at the same time.

- **Pros**: Preserves the static-copy pattern for the omarchy glyph.
  Conditional behaviour without rewriting the config generator.
- **Cons**: String surgery on JSON is fragile. Nix doesn't have a
  clean sed story; would need `pkgs.jq` or a hand-rolled awk step
  inside `waybar.nix`. Hard to read for future maintainers.
- **Effort**: Medium. Higher bug surface than A or B.

## 4. Recommendation

**Approach A (static add) for v1, with Approach B as a follow-up.**

Reasoning:

1. The script already returns the right "no info" output when iwd
   isn't managing wlan0 — a disconnected icon. So the UX on
   `nm-iwd` systems is "a redundant disconnected icon next to the
   working `network` module", not a hard failure.
2. The static-copy decision was made on purpose (U+E900 omarchy
   glyph), and Approach B's JSON-encoding workaround needs
   validation that waybar actually decodes the `\u` escape. Adding
   that risk in the same change as the upstream migration creates
   two unrelated failure modes in one PR.
3. The way to land the migration cleanly is: move the script + add
   the config block today, then file a separate "make iwd-wifi
   conditional on `omarchy.wifi.backend`" follow-up that does the
   JSON generation work in isolation.
4. For the change budget this is small: 1 new 11-line script file,
   ~10 lines of JSON in `config/waybar/config`, ~24 lines deleted
   from `hosts/t14/home/default.nix`. **Well under 400 lines
   (estimated: +20/-25 = 45 line PR).** Single PR, no chaining
   needed.

## 5. Migration Plan (concrete steps)

### Step 1 — Upstream change in `omarchy-nix` (PR → `glats/omarchy-nix`)

1. Create branch `feat/iwd-wifi-indicator`.
2. Create `config/waybar/indicators/iwd-wifi.sh` with the same
   script content as in `hosts/t14/home/default.nix` lines 69–77.
   Make it executable (`chmod +x`) before commit.
3. Edit `config/waybar/config`:
   - Add `"custom/iwd-wifi"` to `modules-right` (position: right
     after `"network"`, so they sit adjacent).
   - Add a `custom/iwd-wifi` block, matching the existing pattern
     (use signal `11` — the next free number after 7/8/9/10):
     ```json
     "custom/iwd-wifi": {
       "exec": "~/.config/waybar/indicators/iwd-wifi.sh",
       "signal": 11,
       "return-type": "json",
       "on-click": "omarchy-launch-wifi"
     }
     ```
4. Run `nix flake check` and `nix fmt -- .` (alejandra).
5. Open PR to `glats/omarchy-nix:main`. Merge.

### Step 2 — Downstream cleanup in `nixos-hosts`

1. After the omarchy PR merges, run `nix flake update omarchy-nix`
   in `~/.nixos`. This bumps `flake.lock` to the new commit.
2. Edit `~/.nixos/hosts/t14/home/default.nix`:
   - Delete lines 58–80 (the entire iwd-wifi `home.file` block + its
     header comment).
   - Update the top-level comment lines 1–9 — remove the "iwd-wifi
     waybar indicator script (iwd-specific, not in omarchy)" bullet
     from the delta list.
3. Run `nix flake check --no-build` and `format-nix` (full repo).
4. Rebuild t14: `nixos-build safe` (then ask before `switch` per
   the AGENTS.md boundary).

### Step 3 (optional) — Conditional follow-up

File a separate `omarchy.wifi.backend` change that converts the
waybar config to Nix-generated JSON and gates the iwd-wifi block on
`cfg.wifi.backend == "standalone-iwd"`. This requires validating
that the `\u0000` JSON escape round-trips through waybar (vs. the
current raw U+E900 character). Coordinate with omarchy maintainers
before starting.

## 6. Other per-host scripts — audit result

| File | Should move upstream? | Why / why not |
|---|---|---|
| `hosts/t14/home/scripts/kb-toggle.sh` | No | Hard-codes `LAYOUTS="es,latam"`. t14-specific. Could be generalized to "cycle layouts from a configurable list" but that needs a t14-side change first (a `layouts` option in t14 config, not in omarchy). |
| `hosts/t14/home/scripts/kb-layout.sh` | No | Same as above — hard-codes `es` and `latam` group indices. |
| `hosts/t14/home/mouse-wiggle.nix` | No | Uses `/run/user/$(id -u)/mouse-wiggle.inhibited` and a `hyprctl`-specific cursorpos hack. Tied to t14's display/lock setup. |
| `hosts/t14/home/hypr/*.nix` | No | Already covered by existing `omarchy.hyprland.*` overlays (looknfeel, monitors, input, hyprlock, hyprsunset). t14 adds per-device fragments on top — that's the intended pattern. |
| **iwd-wifi script** | **YES** | Generic, iwd-specific (not distro-specific), complements omarchy's `wifi.backend` option, fits the existing `config/waybar/indicators/` pattern. |

**Conclusion**: only the iwd-wifi script is a candidate for upstream
in this change. The kb-* and mouse-wiggle scripts are correctly
t14-local.

## 7. Risks

- **R1 (Low) — omarchy-nix flake pin**: `flake.nix:20` pins
  `omarchy-nix` as a **branch ref** (`/main`), so any merged PR is
  picked up by `nix flake update omarchy-nix`. The change is not
  retroactive — the previous flake.lock will continue to point at
  the old commit until update. **Mitigation**: document the
  `nix flake update omarchy-nix` step in the downstream change
  commit message and PR description.

- **R2 (Low) — Signal-number collision**: signal `11` is free today,
  but a parallel omarchy-nix PR could grab it before this one
  merges. **Mitigation**: open the upstream PR first, wait for
  merge, then do the downstream cleanup. Coordinate in the PR
  description that 11 is taken.

- **R3 (Low) — `wlan0` hard-coding**: the script hard-codes
  `wlan0`. On hosts with a renamed interface (e.g. a T14 with
  `wlp1s0` from a fresh installer) the indicator will always show
  disconnected. **Mitigation**: out of scope for v1 — this matches
  t14's actual interface name and `omarchy.nixos.system.nix:230`
  also references `wlan0` literally. Document as a known limitation
  in the script's header comment.

- **R4 (Low) — JSON glyph encoding in `config/waybar/config`**:
  the existing `custom/omarchy` block (line 53) uses a literal
  `\ue900` character that the static file preserves. Adding new
  text/icon fields to the JSON should use the same approach
  (paste the literal glyph, do not use `\u` escapes). No issue with
  the proposed iwd-wifi config — its `text`/`tooltip` only use
  ASCII + the standard Nerd Font disconnected icon `󰤮` (already
  in use on line 84 of the same file).

- **R5 (Low) — `home.file` clobber on downstream**: when the
  downstream t14 file's `home.file.".config/waybar/indicators/iwd-wifi.sh"`
  is deleted, the upstream recursive `home.file.".config/waybar/"`
  copy in `waybar.nix:10–13` will own that path. The order in
  `omarchy.nix:34–57` of `hosts/t14/home/omarchy.nix` puts the
  omarchy HM module FIRST and `./default.nix` (where the iwd-wifi
  block lives today) SECOND. Removing the iwd-wifi block from
  `./default.nix` means there is no second writer — omarchy's
  copy wins by default. **No clobber risk.**

- **R6 (Informational) — Test coverage**: omarchy-nix has no test
  harness (per `openspec/config.yaml` `testing.test_runner: null`).
  Validation is `nix flake check` + `nixos-rebuild dry-build` +
  visual confirmation after a real switch. **No new tests
  required** for this change; visual confirmation of the iwd-wifi
  indicator appearing on the bar is the acceptance check.

## 8. Ready for Proposal

**Yes.** The exploration is complete and concrete:

- Script content identified (lines 67–80 of
  `~/.nixos/hosts/t14/home/default.nix`).
- Target location in omarchy-nix identified
  (`config/waybar/indicators/iwd-wifi.sh` +
  `config/waybar/config` `custom/iwd-wifi` block + `modules-right`
  entry).
- Deployment mechanism confirmed (the `recursive = true` copy in
  `waybar.nix:10–13` picks up new files automatically).
- Downstream cleanup path identified (delete 23 lines from
  `hosts/t14/home/default.nix`, bump flake.lock).
- Other per-host scripts audited and ruled out.
- Risks documented with mitigations.
- PR size estimated at ~45 lines (well within the 400-line budget;
  no chaining required).

**Next phase**: `sdd-propose` to write the formal proposal with
intent, scope, and approach.

**What the orchestrator should tell the user before proposal**:

1. The script currently sits on disk but is **invisible** on the
   t14 bar — moving it upstream also wires the `custom/iwd-wifi`
   block, which is the actual UX improvement (not just code
   tidying).
2. Approach A is recommended: simple unconditional add. The UX
   trade-off is "extra disconnected icon on `nm-iwd` systems" —
   acceptable for v1, with a follow-up to make it conditional.
3. The change touches **two repos**: an upstream PR to
   `glats/omarchy-nix` and a downstream cleanup in `nixos-hosts`.
   Order matters — upstream first, then `nix flake update
   omarchy-nix`, then delete the per-host block.
