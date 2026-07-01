# iwd-wifi-indicator Specification

## Purpose

Waybar custom module displaying WiFi status for hosts using `standalone-iwd` (where NetworkManager does not manage `wlan0`). Reads `iwctl station wlan0 show` and emits JSON with SSID, class, and tooltip. Deployed via omarchy-nix's static waybar config alongside existing indicators (`screen-recording`, `idle`, `notification-silencing`).

## Requirements

### Requirement: Script Deployment

The system SHALL deploy `iwd-wifi.sh` to `~/.config/waybar/indicators/iwd-wifi.sh` as an executable via omarchy-nix's `home.file.".config/waybar/"` recursive copy.

#### Scenario: Script present after rebuild

- GIVEN omarchy-nix home-manager module is enabled
- WHEN the system is rebuilt
- THEN `~/.config/waybar/indicators/iwd-wifi.sh` exists with executable permission

### Requirement: Waybar Config Block

The system SHALL include a `custom/iwd-wifi` block in `config/waybar/config` with `exec` pointing to `~/.config/waybar/indicators/iwd-wifi.sh`, `signal: 11`, and `return-type: "json"`.

#### Scenario: Config block present

- GIVEN omarchy-nix waybar config is deployed
- WHEN `~/.config/waybar/config` is parsed
- THEN `custom/iwd-wifi` exists with `signal: 11`, `return-type: "json"`, and `exec` ending in `indicators/iwd-wifi.sh`

### Requirement: Module Placement

The system SHALL include `"custom/iwd-wifi"` in `modules-right`, immediately after `"network"`.

#### Scenario: Positioned after network

- GIVEN waybar config is deployed
- WHEN `modules-right` is read
- THEN `"custom/iwd-wifi"` appears at index `i+1` where `"network"` is at index `i`

### Requirement: Connected State

When iwd manages `wlan0` with `State: connected` and a non-empty SSID, the script SHALL output JSON with `text` = `" {ssid}"`, `class` = `"connected"`, `tooltip` = `"WiFi: {ssid} (iwd)"`.

#### Scenario: Connected to network

- GIVEN `iwctl station wlan0 show` reports `State: connected` and `Connected network: MyNet`
- WHEN `iwd-wifi.sh` executes
- THEN stdout is JSON with `text: " MyNet"`, `class: "connected"`, `tooltip: "WiFi: MyNet (iwd)"`

### Requirement: Disconnected State

When iwd manages `wlan0` but is not connected (or SSID is empty), the script SHALL output JSON with `text` = `"󰤮"`, `class` = `"disconnected"`, `tooltip` = `"WiFi disconnected"`.

#### Scenario: iwd managing wlan0 but disconnected

- GIVEN `iwctl station wlan0 show` reports `State: disconnected`
- WHEN `iwd-wifi.sh` executes
- THEN stdout is JSON with `text: "󰤮"`, `class: "disconnected"`, `tooltip: "WiFi disconnected"`

### Requirement: Graceful Degradation

When iwd does not manage `wlan0` (`iwctl` fails or interface absent), the script SHALL output the disconnected-icon JSON without erroring or producing non-JSON output.

#### Scenario: iwctl fails

- GIVEN `iwctl station wlan0 show` exits non-zero
- WHEN `iwd-wifi.sh` executes
- THEN stdout is JSON with `text: "󰤮"`, `class: "disconnected"`, `tooltip: "WiFi disconnected"`
- AND stderr is empty or suppressed

### Requirement: Click Interaction

The `custom/iwd-wifi` block SHALL set `on-click: "omarchy-launch-wifi"`.

#### Scenario: Click launches wifi TUI

- GIVEN the indicator is visible on waybar
- WHEN clicked
- THEN `omarchy-launch-wifi` executes

### Requirement: Signal-Based Refresh

The block SHALL use `signal: 11` so external processes can trigger refresh via `pkill -RTMIN+11 waybar`.

#### Scenario: Signal refreshes indicator

- GIVEN waybar is running with the module loaded
- WHEN `pkill -RTMIN+11 waybar` is sent
- THEN waybar re-executes `iwd-wifi.sh` and updates display

### Requirement: No Regression on Existing Modules

Adding `custom/iwd-wifi` SHALL NOT alter behavior, position, or configuration of any existing waybar module.

#### Scenario: Existing modules unchanged

- GIVEN a waybar config before the addition
- WHEN the iwd-wifi block and modules-right entry are added
- THEN all other module blocks remain byte-identical
- AND all other `modules-right/left/center` entries retain original order (except the new insertion after `network`)
