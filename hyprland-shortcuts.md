# Hyprland Keyboard Shortcuts

This document mirrors the `bindd`/`binddr`/`bindeld`/`bindld`/`bindmd`/`bindl`
entries rendered by `modules/home-manager/hyprland/bindings.nix` together with
the `omarchy.quick_app_bindings` default in `config.nix`. If the live keymap
ever drifts from this file, treat `bindings.nix` and `config.nix` as the
source of truth and refresh this file from there.

> Render-order note: Hyprland resolves duplicate `bindd` entries with a
> "last wins" rule. `bindings.nix` emits `quick_app_bindings` first and
> `mainBindings` (which contains the universal clipboard block) second, so
> `Super+C` / `Super+V` / `Super+X` always resolve to copy/paste/cut even
> if a user re-introduces a colliding entry in `quick_app_bindings`.

---

## Menus & Launchers

| Shortcut | Action |
|----------|--------|
| `Super + Space` | Launch apps (Walker) |
| `Super + Escape` | System menu |
| `Super Alt + Space` | Omarchy menu |
| `Super Shift + Space` | Omarchy menu (alt) |
| `Super Ctrl + E` | Emoji picker (Walker, symbols mode) |
| `Super Ctrl + C` | Capture menu |
| `Super Ctrl + O` | Toggle menu |
| `Super + K` | Show keybindings |

## Aesthetics

| Shortcut | Action |
|----------|--------|
| `Super Shift + Space` | Toggle top bar (waybar) |
| `Super Ctrl + Space` | Theme background menu |
| `Super Shift Ctrl + Space` | Theme menu |
| `Super + Backspace` | Toggle window transparency |
| `Super Shift + Backspace` | Toggle window gaps |
| `Super Ctrl + Backspace` | Toggle single-window square aspect |

## Notifications

| Shortcut | Action |
|----------|--------|
| `Super + ,` | Dismiss last notification |
| `Super Shift + ,` | Dismiss all notifications |
| `Super Ctrl + ,` | Toggle notification silencing |
| `Super Alt + ,` | Invoke last notification |
| `Super Shift Alt + ,` | Restore last notification |

## Toggles

| Shortcut | Action |
|----------|--------|
| `Super Ctrl + I` | Toggle locking on idle |
| `Super Ctrl + N` | Toggle nightlight |
| `Super Ctrl + Delete` | Toggle laptop display |
| `Super Ctrl Alt + Delete` | Toggle laptop display mirroring |
| `Super Ctrl + H` | Hardware menu |
| `Super + /` | Cycle monitor scaling |

## Copy / Paste / Cut

| Shortcut | Action |
|----------|--------|
| `Super + C` | Universal copy (`Ctrl+Insert`) |
| `Super + V` | Universal paste (`Shift+Insert`) |
| `Super + X` | Universal cut (`Ctrl+X`) |
| `Super Ctrl + V` | Clipboard manager (Walker, clipboard mode) |

These four `bindd` entries are emitted from `mainBindings`. They shadow any
`quick_app_bindings` entry that uses the same keys (render-order contract,
see top of file).

## Quick App Launchers (Webapps)

Defaults from `omarchy.quick_app_bindings`. Override per-host in
`configuration.nix` if needed.

| Shortcut | Action |
|----------|--------|
| `Super + A` | Open ChatGPT |
| `Super Shift + A` | Open Grok |
| `Super Shift + C` | Open Hey Calendar |
| `Super + E` | Open Hey Email |
| `Super + Y` | Open YouTube |
| `Super Shift + G` | Open WhatsApp Web |
| `Super Shift + X` | Open X (Twitter) |

## Core Apps

| Shortcut | Action |
|----------|--------|
| `Super + Return` | Terminal |
| `Super Alt + Return` | Tmux |
| `Super Shift + Return` | Browser |
| `Super Shift + F` | File manager |
| `Super Shift + B` | Web browser (alias) |
| `Super Shift + M` | Music player |
| `Super Shift + N` | Neovim |
| `Super Shift + T` | btop |
| `Super Shift + D` | Lazy Docker |
| `Super Shift + I` | Messenger |
| `Super Shift + O` | Obsidian |
| `Super + /` | Password manager |
| `Super + R` | Calculator |
| `Super Shift + S` | Steam (only if `gaming.enable = true`) |

## Window Management

| Shortcut | Action |
|----------|--------|
| `Super + W` | Close window |
| `Ctrl Alt + Delete` | Close all windows |
| `Super + J` | Toggle window split |
| `Super + P` | Pseudo window (dwindle) |
| `Super + T` | Toggle window floating/tiling |
| `Super + F` | Full screen |
| `Super Ctrl + F` | Tiled full screen |
| `Super Alt + F` | Full width |
| `Super + O` | Pop window out (float & pin) |
| `Super + L` | Toggle workspace layout |
| `Super + ←/→/↑/↓` | Move focus between windows |
| `Super Shift + ←/→/↑/↓` | Swap windows |
| `Super + -` | Expand window left |
| `Super + =` | Shrink window left |
| `Super Shift + -` | Shrink window up |
| `Super Shift + =` | Expand window down |

## Workspaces

| Shortcut | Action |
|----------|--------|
| `Super + 1-0` | Switch to workspace 1-10 |
| `Super Shift + 1-0` | Move window to workspace 1-10 |
| `Super Shift Alt + 1-0` | Move window silently to workspace 1-10 |
| `Super + F1-F10` | Switch to workspace 11-20 |
| `Super Shift + F1-F10` | Move window to workspace 11-20 |
| `Super + Tab` | Next workspace |
| `Super Shift + Tab` | Previous workspace |
| `Super Ctrl + Tab` | Former workspace |
| `Super + mouse_up` | Scroll active workspace forward |
| `Super + mouse_down` | Scroll active workspace backward |

## Scratchpad

| Shortcut | Action |
|----------|--------|
| `Super + S` | Toggle scratchpad (special workspace) |
| `Super Alt + S` | Move window to scratchpad |

## Move Workspace Between Monitors

| Shortcut | Action |
|----------|--------|
| `Super Shift Alt + ←/→/↑/↓` | Move workspace to monitor |

## Window Groups

| Shortcut | Action |
|----------|--------|
| `Super + G` | Toggle window grouping |
| `Super Alt + G` | Move active window out of group |
| `Super Alt + ←/→/↑/↓` | Move window into group (direction) |
| `Super Ctrl + ←/→` | Move grouped window focus |
| `Super Alt + Tab` | Next window in group |
| `Super Alt Shift + Tab` | Previous window in group |
| `Super Alt + mouse_down` | Next window in group (scroll) |
| `Super Alt + mouse_up` | Previous window in group (scroll) |
| `Super Alt + 1-5` | Switch to group window 1-5 |

## Capture & Recording

| Shortcut | Action |
|----------|--------|
| `Print` | Screenshot with editing (satty) |
| `Alt + Print` | Screen recording menu |
| `Super + Print` | Color picker (hyprpicker) |
| `Shift + Print` | Screenshot to clipboard (handled by capture menu) |

## File Sharing & Status

| Shortcut | Action |
|----------|--------|
| `Super Ctrl + S` | Share menu |
| `Super Ctrl Alt + T` | Show time notification |
| `Super Ctrl Alt + B` | Show battery status notification |

## Control Panels

| Shortcut | Action |
|----------|--------|
| `Super Ctrl + A` | Audio controls |
| `Super Ctrl + B` | Bluetooth controls |
| `Super Ctrl + W` | Wi-Fi controls |
| `Super Ctrl + T` | Activity (btop) |

## Zoom

| Shortcut | Action |
|----------|--------|
| `Super Ctrl + Z` | Zoom in |
| `Super Ctrl Alt + Z` | Reset zoom |

## Lock & Close

| Shortcut | Action |
|----------|--------|
| `Super Ctrl + L` | Lock system (hyprlock) |

## Apple Display

| Shortcut | Action |
|----------|--------|
| `Ctrl + F1` | Apple Display brightness down |
| `Ctrl + F2` | Apple Display brightness up |
| `Shift Ctrl + F2` | Apple Display full brightness |

## Mouse Controls

| Shortcut | Action |
|----------|--------|
| `Super + Left Click + Drag` | Move window |
| `Super + Right Click + Drag` | Resize window |

## Multimedia (repeat-enabled, works when locked)

| Shortcut | Action |
|----------|--------|
| `XF86AudioRaiseVolume` | Volume up 5% |
| `XF86AudioLowerVolume` | Volume down 5% |
| `XF86AudioMute` | Mute |
| `XF86AudioMicMute` | Mute microphone |
| `XF86MonBrightnessUp` | Brightness up 5% |
| `XF86MonBrightnessDown` | Brightness down 5% |
| `XF86KbdBrightnessUp` | Keyboard brightness up |
| `XF86KbdBrightnessDown` | Keyboard brightness down |
| `Alt + XF86AudioRaiseVolume` | Volume up 1% |
| `Alt + XF86AudioLowerVolume` | Volume down 1% |
| `Alt + XF86MonBrightnessUp` | Brightness up 1% |
| `Alt + XF86MonBrightnessDown` | Brightness down 1% |

## Keyboard Backlight & Touchpad (works when locked)

| Shortcut | Action |
|----------|--------|
| `XF86KbdLightOnOff` | Cycle keyboard backlight |
| `XF86TouchpadToggle` | Toggle touchpad |
| `XF86TouchpadOn` | Enable touchpad |
| `XF86TouchpadOff` | Disable touchpad |

## Media Player (works when locked)

| Shortcut | Action |
|----------|--------|
| `XF86AudioNext` | Next track |
| `XF86AudioPause` | Pause / play-pause |
| `XF86AudioPlay` | Play / play-pause |
| `XF86AudioPrev` | Previous track |
| `Super + XF86AudioMute` | Switch audio output |
| `XF86PowerOff` | Power menu |
| `XF86Calculator` | Calculator |

## Lid Switch (works when locked)

| Trigger | Action |
|---------|--------|
| `Lid Switch on` | External-monitor hookup + laptop display off |
| `Lid Switch off` | Laptop display on |

## Dictation (only when `omarchy.voxtype.enable = true`)

| Shortcut | Action |
|----------|--------|
| `Super Ctrl + X` | Toggle dictation (voxtype) |

## Application Cycling (system-wide, not Super-prefixed)

| Shortcut | Action |
|----------|--------|
| `Alt + Tab` | Cycle to next window |
| `Alt Shift + Tab` | Cycle to previous window |

## Special Features

- **Scratchpad**: `Super + S` toggles a special workspace where windows can
  be hidden/shown quickly; `Super Alt + S` sends the focused window to it
  silently.
- **App launcher**: `Super + Space` opens Walker for launching applications,
  switching windows, running calculator, and more.
- **Clipboard manager**: `Super Ctrl + V` opens Walker in clipboard-history
  mode (replaces the older `clipse`-based manager).
- **Window grouping**: `Super + G` toggles group mode; subsequent focus moves
  with `Super + arrows` cycle within the group. `Super Alt + arrows` joins
  another window into the group.
