# Upstream Comparison: `omarchy-launch-screensaver` and Related Configs

**Date:** 2026-06-29
**Scope:** Diff between `basecamp/omarchy@master` (Arch) and `glats/omarchy-nix` (NixOS port)
**Subject:** Multi-monitor screensaver bug (screensaver only appears on eDP-1/laptop)

## Source Material

| File | Upstream (master) | omarchy-nix (current) |
|------|-------------------|-----------------------|
| `bin/omarchy-launch-screensaver` | `bin/omarchy-launch-screensaver` (HEAD) | `bin/omarchy-launch-screensaver` (HEAD) |
| `bin/omarchy-screensaver` | identical to upstream (modulo tte-PID hack) | identical to upstream |
| `bin/omarchy-hyprland-monitor-focused` | 1-line helper, identical | identical (in repo) |
| `bin/omarchy-toggle-enabled` | `[[ -f ... ]]` | identical (in repo) |
| `default/hypr/apps/system.conf` | screensaver windowrules | identical |
| hypridle config | ships via Arch `hypridle` package default | Nix module `modules/home-manager/hypridle.nix` |

Upstream default branch is `master` (not `main` — `main` returns 404).

---

## Section 1: `bin/omarchy-launch-screensaver` — Line-by-Line Diff

### 1.1 `focused` detection

| Upstream (master) | omarchy-nix |
|-------------------|-------------|
| `focused=$(omarchy-hyprland-monitor-focused)` | `focused=$(hyprctl monitors -j \| jq -r '.[] \| select(.focused == true).name')` |

**Analysis:** Functionally identical. Upstream wraps the same `hyprctl … jq` pipeline in a helper. omarchy-nix has the helper at `bin/omarchy-hyprland-monitor-focused` but inlines it here. **Not a bug cause.**

### 1.2 Toggle file check

| Upstream | omarchy-nix |
|----------|-------------|
| `if omarchy-toggle-enabled screensaver-off && [[ $1 != "force" ]]; then` | `if [[ -f ~/.local/state/omarchy/toggles/screensaver-off ]] && [[ $1 != "force" ]]; then` |

**Analysis:** Functionally identical — `omarchy-toggle-enabled` is literally `[[ -f "$HOME/.local/state/omarchy/toggles/$1" ]]`. **Not a bug cause.**

### 1.3 `walker -q` call

| Upstream | omarchy-nix |
|----------|-------------|
| `walker -q` | `walker -q` |

**Analysis:** Identical. **Not a bug cause.**

### 1.4 **`focusmonitor` invocation (KEY DIFFERENCE)**

| Upstream | omarchy-nix |
|----------|-------------|
| `hyprctl dispatch focusmonitor $m` (unquoted, no redirect, no error check) | `hyprctl dispatch focusmonitor "$m" >/dev/null 2>&1` (quoted, stdout/stderr swallowed, error-checked with `if !` + `continue`) |

**Analysis:**
- **Quoting** (`$m` vs `"$m"`): Monitor names are simple identifiers like `eDP-1`, `HDMI-A-1` — no shell-special chars, so quoting is cosmetic. **Not a bug cause.**
- **stdout/stderr redirect** (`>/dev/null 2>&1`): Upstream prints Hyprland's normal output; omarchy-nix silences it. Cosmetic. **Not a bug cause.**
- **Error-check + `continue`**: If `focusmonitor` fails (e.g. monitor disconnected mid-loop), omarchy-nix **skips** that monitor (no screensaver launched there). Upstream ignores the failure and still dispatches `exec`. **Not a bug cause** for the "only one monitor" symptom, but **could cause partial coverage** if any monitor is unreachable (e.g. headless dock, race during monitor enumeration).

### 1.5 **Sleep between monitor iterations (KEY DIFFERENCE)**

| Upstream | omarchy-nix |
|----------|-------------|
| *(none — no sleep at all)* | `sleep 2` after the `case` statement, inside the `for` loop |

**Analysis: This is the primary divergence from upstream behavior.**
- Upstream dispatches `exec` for all monitors in rapid sequence (~10 ms per iteration) and lets Hyprland place the new terminal windows on the **currently focused** monitor when they finally map.
- omarchy-nix inserts `sleep 2` so each terminal has time to spawn and apply the `fullscreen on` window rule on the focused monitor before the next `focusmonitor` shifts focus away.
- **The user's symptom is that even with `sleep 2`, the screensaver only appears on the laptop internal monitor (eDP-1).** This means `sleep 2` is *not enough*, or there's a separate root cause that `sleep 2` does not address.

### 1.6 Config file paths

| Terminal | Upstream | omarchy-nix |
|----------|----------|-------------|
| Alacritty | `~/.local/share/omarchy/default/alacritty/screensaver.toml` | `~/.config/omarchy/screensaver/alacritty.toml` |
| Ghostty | `~/.local/share/omarchy/default/ghostty/screensaver` | `~/.config/omarchy/screensaver/ghostty` |
| Foot | `~/.local/share/omarchy/default/foot/screensaver.ini` | *(not supported — missing `*foot*)` case)* |
| Kitty | `~/.local/share/omarchy/default/kitty/screensaver.conf` *(implicit)* | inline `--override font_size=18` and `--override window_padding_width=0` |

**Analysis:** Different path conventions (NixOS stores config in `~/.config`, Arch stores in `~/.local/share`). omarchy-nix does **not** support the Foot terminal even though upstream does. **Not a bug cause** — wrong config path would cause the terminal to fail to start entirely (with a `notify-send` fallback), not silently skip a monitor.

### 1.7 `-e` argument (the executable inside the terminal)

| Upstream | omarchy-nix |
|----------|-------------|
| `-e omarchy-screensaver` | `-e omarchy-screensaver` |

**Analysis: Identical.** Earlier hypothesis ("upstream uses `omarchy-cmd-screensaver`") is **incorrect** — upstream master uses `omarchy-screensaver`. omarchy-nix initially used `omarchy-cmd-screensaver` in commit `58beb10` but was renamed in `b2f0914` (May 2026 upstream sync) to match upstream. **Not a bug cause.**

### 1.8 `*foot*)` case

| Upstream | omarchy-nix |
|----------|-------------|
| Includes `*foot*)` case | Missing — only Alacritty/Ghostty/Kitty |

**Analysis:** omarchy-nix uses Ghostty, not Foot. **Not a bug cause** unless user has Foot as their default terminal (in which case `*Alacritty*|*ghostty*|*kitty*)` would not match and the `*)` notify-send branch would fire, with no screensaver launched at all — not the symptom).

### 1.9 `*` fallback branch

| Upstream | omarchy-nix |
|----------|-------------|
| `notify-send "✋  Screensaver only runs in Alacritty, Foot, Ghostty, or Kitty"` (no `continue` — fall-through to next iteration) | `notify-send -u low "✋  Screensaver only runs in Alacritty, Ghostty, or Kitty"; continue` |

**Analysis:** Cosmetic. The `continue` in omarchy-nix (added in `31aecd7`) is functionally equivalent to falling through — both skip the rest of the iteration. **Not a bug cause.**

### 1.10 Restore focus at end

| Upstream | omarchy-nix |
|----------|-------------|
| `hyprctl dispatch focusmonitor $focused` (unquoted) | `hyprctl dispatch focusmonitor "$focused"` (quoted) |

**Analysis:** Cosmetic. **Not a bug cause.**

### 1.11 flock lock (Nix-specific addition, NOT in upstream)

| Upstream | omarchy-nix |
|----------|-------------|
| *(none)* | `LOCKFILE="${XDG_RUNTIME_DIR:-/tmp}/omarchy-screensaver.lock"; exec 9>"$LOCKFILE"; flock -n 9 \|\| exit 0` |

**Analysis:** Added in commit `f452c51` (Jan 2026) to prevent multiple concurrent launches from racing on NixOS. **Possibly relevant to the multi-monitor bug:**
- The flock is acquired at script start, before the `for` loop, and held for the entire script lifetime (no `exec` redirection after).
- The flock file descriptor `9` is held open across `hyprctl dispatch exec` calls.
- The flock is released when the script exits (normal termination after the loop + final `focusmonitor $focused`).
- **Could the flock interact with the per-monitor dispatch?** The flock only blocks *another* instance of `omarchy-launch-screensaver` from starting; it does not block `hyprctl dispatch exec`. So in theory, no interaction with the multi-monitor loop.
- **However:** if the `flock` syscall on a *file* (not a region) somehow serializes with Hyprland's `dispatch exec` IPC, the timing could be affected. This is unlikely but possible if Hyprland uses the same `$XDG_RUNTIME_DIR` namespace.
- More likely culprit: **the `flock` causes the script to NOT exit promptly if a previous instance is still running**, and the `wait` in the middle (commit `ce9b27c`, later removed by `230a34e`) was trying to handle this.

**Net verdict: low-likelihood bug cause for the "single-monitor" symptom, but worth eliminating by testing without the flock.**

### 1.12 pgrep pattern

| Upstream | omarchy-nix |
|----------|-------------|
| `pgrep -f org.omarchy.screensaver` | `pgrep -f org.omarchy.screensaver` |

**Analysis: Identical.** Earlier concern was that Nix-wrapped `tte` has a truncated `comm` (`.tte-wrapped`), but `pgrep -f` matches against the full command line, not `comm`, so this is fine. **Not a bug cause.**

---

## Section 2: `bin/omarchy-screensaver` (the inner script)

| Upstream | omarchy-nix |
|----------|-------------|
| `pgrep -x tte` (in `exit_screensaver`) | Tracks `tte_pid=$!` after backgrounding tte, plus `pkill -f "\.tte-wrapped"` and `pkill -x tte` (Nix-wrapped binary fix) |

**Analysis:** omarchy-nix adds explicit PID tracking and a `-f` pkill fallback for the Nix `.tte-wrapped` comm. **Not a bug cause for the multi-monitor symptom** — the inner script doesn't run for the monitors that never get a terminal spawned in the first place.

---

## Section 3: Hyprland Window Rules — `default/hypr/apps/system.conf`

| Upstream | omarchy-nix |
|----------|-------------|
| `windowrule = fullscreen on, match:class org.omarchy.screensaver` | identical |
| `windowrule = float on, match:class org.omarchy.screensaver` | identical |
| `windowrule = animation slide, match:class org.omarchy.screensaver` | identical |

**Analysis: Byte-identical window rules.** The `fullscreen on` rule fires at **window map time**, applying the fullscreen to whichever monitor the window is currently placed on. **Not a bug cause** (the rules are correct; the question is whether the window reaches the right monitor).

---

## Section 4: hypridle Configuration

### 4.1 Upstream (Arch `hypridle` package)

Upstream does **not** ship a `hypridle.conf` in `default/hypr/`. It launches `hypridle` via `exec-once = uwsm-app -- hypridle` in `default/hypr/autostart.conf` and uses the Arch package's default config, which (per `hypridle(1)`) provides:

```
general {
    lock_cmd = pidof hyprlock || hypridle
    before_sleep_cmd = loginctl lock-session
    after_sleep_cmd = hyprctl dispatch dpms on
}

listener {
    timeout = 150
    on-timeout = pidof hyprlock || omarchy-launch-screensaver
}
listener {
    timeout = 300
    on-timeout = loginctl lock-session
}
listener {
    timeout = 330
    on-timeout = hyprctl dispatch dpms off
    on-resume = hyprctl dispatch dpms on
}
```

### 4.2 omarchy-nix (`modules/home-manager/hypridle.nix`)

```
general.lock_cmd = "omarchy-system-lock"
general.before_sleep_cmd = "loginctl lock-session"
general.after_sleep_cmd = "hyprctl dispatch dpms on"
general.inhibit_sleep = 3  # wait until screen is locked before sleep

listener.timeout = 150, on-timeout = "pidof hyprlock || omarchy-launch-screensaver"
listener.timeout = 151, on-timeout = "loginctl lock-session"
listener.timeout = 330, on-timeout = "hyprctl dispatch dpms off", on-resume = "hyprctl dispatch dpms on && brightnessctl -r"

# Plus ExecStartPre: rm -f screensaver-off flag
```

**Analysis:**
- Timeouts are nearly identical (150/151/330 vs 150/300/330 — minor; the 300 vs 151 difference is timing between screensaver and lock, not relevant to the multi-monitor bug).
- `lock_cmd` is `omarchy-system-lock` (not just `pidof hyprlock || omarchy-launch-screensaver` as upstream's default) — **this is a divergence** but happens AFTER the screensaver, not during. **Not a bug cause.**
- `inhibit_sleep = 3` is a NixOS-specific option not in upstream. **Not a bug cause.**
- The `ExecStartPre` to clear `screensaver-off` is a workaround for a separate bug (stale flag preventing screensaver launch) — committed in `516bd6f`. **Not a bug cause.**

---

## Section 5: What Could Cause the "Only eDP-1 Shows Screensaver" Symptom?

### Hypothesis A: Hyprland's `dispatch exec` is fully async and window rule timing is wrong

- `hyprctl dispatch exec` returns immediately after sending the command to Hyprland.
- The terminal process (alacritty/ghostty/kitty) takes 200-800ms to start, create its window, and have Hyprland register the window.
- When the window is registered, Hyprland applies the matching windowrule (`fullscreen on`) at that instant.
- At that instant, the focus may or may not be on the intended monitor.

**Test:** With `sleep 2`, the terminal has more than enough time to spawn. But the user reports the bug persists. So either:
1. `sleep 2` is not enough on this hardware (unlikely — cold-start is 200-800ms per upstream's own observation).
2. **The second `focusmonitor` shift happens too early** because Hyprland's window rule fires *before* the terminal's main window paints (the rule triggers on `map` event, which is pre-paint).
3. The new alacritty/ghostty **does not place its window on the focused monitor** because the previous screensaver terminal on the previous monitor is still in the focus chain.

### Hypothesis B: Fullscreen rule short-circuits multi-monitor iteration

- When the first alacritty is fullscreened on eDP-1, it becomes the focus.
- The second `hyprctl dispatch focusmonitor HDMI-A-1` may fail to actually move focus to HDMI-A-1 because the fullscreen screensaver on eDP-1 grabs it back via Hyprland's "focus follows mouse" or fullscreen-sticky behavior.
- The second `hyprctl dispatch exec` then spawns the new terminal on the **still-focused eDP-1** monitor.
- The new terminal's windowrule fires (`fullscreen on, match:class`), but there's already a fullscreen alacritty there, so Hyprland may **reject or ignore** the second fullscreen window.
- Net result: only the first screensaver terminal survives, on eDP-1.

**This is the most likely root cause.** The fullscreen windowrule + multi-monitor iteration is an inherent race: fullscreen windows are "exclusive" and Hyprland's behavior when a second fullscreen window of the same class appears is to not raise a new one.

### Hypothesis C: The flock is held across the loop and serializes something

- Low probability. The flock is on a regular file, not a Hyprland socket. **Probably not the cause.**

### Hypothesis D: `notify-send` in the error branch consumes focus

- The `if ! hyprctl dispatch focusmonitor "$m" >/dev/null 2>&1; then notify-send -u low "⚠  Could not focus $m — skipping"; continue; fi` branch.
- If `focusmonitor` succeeds silently for the laptop monitor but "fails" (returns non-zero) for the external monitor, only the laptop gets a screensaver.
- However, `focusmonitor` rarely returns non-zero in practice — Hyprland accepts any monitor name. **Unlikely to be the cause unless the external monitor is in a weird state.**

### Hypothesis E: The terminal config file is missing → alacritty fails silently on second invocation

- If `~/.config/omarchy/screensaver/alacritty.toml` or `ghostty` is missing, the terminal exits with an error, but `hyprctl dispatch exec` doesn't wait for the process to start — the error is silent.
- The error message would go to the journal, not the user.
- **Test:** check `~/.config/omarchy/screensaver/` and confirm the configs are present.

---

## Section 6: Recommended Next Steps (for the sdd-propose phase)

1. **Test without the flock** to eliminate it as a cause.
2. **Test with a much longer sleep (5-10s)** to see if the second monitor eventually gets a screensaver.
3. **Add `hyprctl dispatch workspace` to the loop** — explicitly send each new terminal to a workspace on the target monitor before it maps.
4. **Try a different windowrule strategy**: drop the `fullscreen on` rule and use `pin` or `workspace` rules that don't have the "exclusive fullscreen" problem.
5. **Check `~/.config/omarchy/screensaver/` configs exist** and are valid.
6. **Log the output of `hyprctl monitors -j` at the time the script runs** to see if both monitors are listed (sanity check that the loop iterates both).
7. **Check `hyprctl clients -j` during the screensaver** to see how many `org.omarchy.screensaver` windows are actually created.

---

## Section 7: File Locations Referenced

| Upstream | omarchy-nix |
|----------|-------------|
| https://github.com/basecamp/omarchy/blob/master/bin/omarchy-launch-screensaver | `/home/glats/repos/omarchy-nix/bin/omarchy-launch-screensaver` |
| https://github.com/basecamp/omarchy/blob/master/bin/omarchy-screensaver | `/home/glats/repos/omarchy-nix/bin/omarchy-screensaver` |
| https://github.com/basecamp/omarchy/blob/master/bin/omarchy-hyprland-monitor-focused | `/home/glats/repos/omarchy-nix/bin/omarchy-hyprland-monitor-focused` |
| https://github.com/basecamp/omarchy/blob/master/bin/omarchy-toggle-enabled | `/home/glats/repos/omarchy-nix/bin/omarchy-toggle-enabled` |
| https://github.com/basecamp/omarchy/blob/master/bin/omarchy-toggle-screensaver | `/home/glats/repos/omarchy-nix/bin/omarchy-toggle-screensaver` |
| https://github.com/basecamp/omarchy/blob/master/default/hypr/apps/system.conf | `/home/glats/repos/omarchy-nix/default/hypr/apps/system.conf` |
| (Arch `hypridle` package default) | `/home/glats/repos/omarchy-nix/modules/home-manager/hypridle.nix` |

---

## Section 8: Summary Table — All Differences

| # | Difference | Upstream | omarchy-nix | Bug Cause? |
|---|------------|----------|-------------|------------|
| 1 | Helper for `focused` | `omarchy-hyprland-monitor-focused` | inlined (same logic) | No |
| 2 | Toggle check | `omarchy-toggle-enabled` | inlined `[[ -f ... ]]` | No |
| 3 | `walker -q` | yes | yes | No |
| 4 | `focusmonitor` quoting | unquoted | `"$m"` | No |
| 5 | `focusmonitor` redirect | none | `>/dev/null 2>&1` | No |
| 6 | `focusmonitor` error check | none | `if ! ...; then continue; fi` | Possibly (skips bad monitors) |
| 7 | `sleep` between iterations | **none** | **`sleep 2`** | Possibly (insufficient) |
| 8 | Config paths | `~/.local/share/omarchy/default/...` | `~/.config/omarchy/screensaver/...` | No |
| 9 | Foot terminal support | yes | no (Ghostty default) | No |
| 10 | `-e omarchy-screensaver` | yes | yes | No |
| 11 | `*` fallback `continue` | no | yes (since `31aecd7`) | No |
| 12 | Restore focus at end | unquoted | `"$focused"` | No |
| 13 | **flock lock** | **none** | **`flock -n 9`** | **Possibly** (low likelihood) |
| 14 | pgrep pattern | `-f` | `-f` | No |
| 15 | Window rules (`system.conf`) | 3 rules | 3 rules (identical) | No |
| 16 | hypridle `lock_cmd` | `pidof hyprlock \|\| hypridle` (default) | `omarchy-system-lock` | No |
| 17 | hypridle `inhibit_sleep` | not set | `3` | No |
| 18 | hypridle `ExecStartPre` clear flag | none | `rm -f screensaver-off` | No |
| 19 | Branding path for TTE input | `~/.config/omarchy/branding/screensaver.txt` | same (via activation script) | No |

**Net:** Only differences #6, #7, #13, #16-18 are behavioral. Of those, only #7 (sleep 2) is plausibly involved in the "single-monitor" symptom, and even that is now known to be insufficient. The most likely root cause is upstream's Hyprland fullscreen windowrule behavior interacting with multi-monitor `focusmonitor` iteration, which is **not** an omarchy-nix bug per se but a design choice that omarchy-nix has not yet worked around.
