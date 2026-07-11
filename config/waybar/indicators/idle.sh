#!/bin/bash

if [[ -f "$HOME/.local/state/omarchy/toggles/idle-off" ]]; then
  echo '{"text": "󱫖", "tooltip": "Idle lock disabled", "class": "active"}'
else
  echo '{"text": ""}'
fi
