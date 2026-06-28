#!/bin/bash
# waybar custom module: iwd WiFi status
state=$(iwctl station wlan0 show 2>/dev/null | awk '/State/ {print $2}')
ssid=$(iwctl station wlan0 show 2>/dev/null | awk '/Connected network/ {$1=""; $2=""; print}' | xargs)
if [ "$state" = "connected" ] && [ -n "$ssid" ]; then
  echo "{\"text\": \" $ssid\", \"class\": \"connected\", \"tooltip\": \"WiFi: $ssid (iwd)\"}"
else
  echo "{\"text\": \"󰤮\", \"class\": \"disconnected\", \"tooltip\": \"WiFi disconnected\"}"
fi
