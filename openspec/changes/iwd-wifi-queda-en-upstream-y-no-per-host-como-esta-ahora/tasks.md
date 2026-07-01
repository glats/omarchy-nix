# Tasks: iwd-wifi Waybar Indicator Upstream Migration

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~40 (15 added in omarchy-nix, 25 deleted in nixos-hosts) |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | 3 commits across 2 repos, direct-to-main |
| Delivery strategy | single-commit (direct-to-main, no PR gate) |
| Chain strategy | size-exception (user-approved direct commits) |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: size-exception
400-line budget risk: Low

### Suggested Work Units

| Unit | Goal | Repo | Notes |
|------|------|------|-------|
| 1 | Upstream iwd-wifi into omarchy-nix | omarchy-nix | script + waybar config wiring; one atomic commit |
| 2 | Pull new omarchy-nix revision | nixos-hosts | `nix flake update omarchy-nix` |
| 3 | Remove per-host iwd-wifi block | nixos-hosts | delete lines from `hosts/t14/home/default.nix` |

## Phase 1: omarchy-nix — Add Script and Wire Waybar

- [x] 1.1 Create `config/waybar/indicators/iwd-wifi.sh` with the 9-line script from the design (wlan0 hard-coded, identical to nixos-hosts lines 69-77)
- [x] 1.2 `chmod +x config/waybar/indicators/iwd-wifi.sh`; verify with `ls -la` matches `screen-recording.sh` perms
- [x] 1.3 In `config/waybar/config` insert `"custom/iwd-wifi",` on a new line after `"network",` (line 12) inside `modules-right` (Req 3)
- [x] 1.4 In `config/waybar/config` add the JSON block after the `notification-silencing-indicator` block (line 166): `signal: 11`, `return-type: "json"`, `on-click: "omarchy-launch-wifi"`, `exec: "~/.config/waybar/indicators/iwd-wifi.sh"` (Req 2, 7, 8)
- [x] 1.5 Validate JSON: `python3 -c "import json; json.load(open('config/waybar/config'))"` (catches trailing-comma or unclosed-brace errors)
- [x] 1.6 Run `nix flake check --no-build` in `~/repos/omarchy-nix`
- [x] 1.7 Run `nix fmt` in `~/repos/omarchy-nix` (covers shell scripts)
- [x] 1.8 Commit on `main` in omarchy-nix: `feat(waybar): add iwd-wifi indicator` — files: `config/waybar/indicators/iwd-wifi.sh`, `config/waybar/config`

## Phase 2: nixos-hosts — Bump Flake Lock

- [x] 2.1 In `/home/glats/.nixos` run `nix flake update omarchy-nix`
- [x] 2.2 Verify `flake.lock` `nodes.omarchy-nix.locked.rev` matches the new commit from Phase 1
- [x] 2.3 Run `nix flake check --no-build` in nixos-hosts (lock + omarchy-nix still evaluate)
- [x] 2.4 Commit on `master` in nixos-hosts: `chore(flake): bump omarchy-nix (iwd-wifi indicator)` — file: `flake.lock`

## Phase 3: nixos-hosts — Remove Per-Host iwd-wifi Block

- [x] 3.1 In `hosts/t14/home/default.nix` delete line 8 (the comment bullet `  - iwd-wifi waybar indicator script (iwd-specific, not in omarchy)`)
- [x] 3.2 In `hosts/t14/home/default.nix` delete lines 58-80 (the entire `home.file.".config/waybar/indicators/iwd-wifi.sh"` block including its 3-line header comment)
- [x] 3.3 Run `format-nix` in nixos-hosts
- [x] 3.4 Run `nix flake check --no-build` in nixos-hosts
- [x] 3.5 Run `nixos-build dry` for t14 to confirm t14 still evaluates without the per-host block
- [x] 3.6 Commit on `master` in nixos-hosts: `refactor(t14): drop per-host iwd-wifi block (moved to omarchy-nix)` — file: `hosts/t14/home/default.nix`

## Phase 4: Manual Verification on t14

> Run after `nixos-build switch` on t14 (requires user approval per AGENTS.md rule 6).

- [ ] 4.1 Req 1 (Deployment): `test -x ~/.config/waybar/indicators/iwd-wifi.sh && echo OK`
- [ ] 4.2 Req 2 (Config block): `jq '.["custom/iwd-wifi"]' ~/.config/waybar/config` — verify `signal == 11`, `return-type == "json"`, exec path ends in `indicators/iwd-wifi.sh`
- [ ] 4.3 Req 3 (Placement): `jq '.["modules-right"]' ~/.config/waybar/config` — verify `custom/iwd-wifi` is at index `i+1` where `network` is at index `i`
- [ ] 4.4 Req 4 (Connected): `bash ~/.config/waybar/indicators/iwd-wifi.sh` while connected — expect JSON with `class: "connected"` and SSID in `text`
- [ ] 4.5 Req 5 (Disconnected): after `iwctl station wlan0 disconnect`, re-run script — expect `class: "disconnected"`, text `󰤮`
- [ ] 4.6 Req 6 (Graceful degradation): `PATH=/usr/bin:/bin bash ~/.config/waybar/indicators/iwd-wifi.sh` — expect `class: "disconnected"`, no stderr
- [ ] 4.7 Req 7 (Click): click indicator on waybar — verify `omarchy-launch-wifi` TUI launches
- [ ] 4.8 Req 8 (Signal refresh): `pkill -RTMIN+11 waybar` — verify indicator re-executes script
- [ ] 4.9 Req 9 (No regression): visually confirm other modules (network, bluetooth, pulseaudio, clock) unchanged in position and behavior
