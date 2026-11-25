#!/usr/bin/env bash

# Close all windows first to save state
hyprctl clients -j | jq -r ".[].address" | xargs -r -I{} hyprctl dispatch "hl.dsp.window.close({window = \"address:{}\"})"
sleep 1
systemctl poweroff
