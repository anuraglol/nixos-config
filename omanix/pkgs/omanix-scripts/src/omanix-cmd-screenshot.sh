#!/usr/bin/env bash

# Cleanup any stuck instances
pkill slurp && exit 0
pkill wayfreeze

# Arguments: Mode [smart|region|windows|fullscreen]
# Destination is always clipboard: no Satty/edit window is ever opened.
MODE="${1:-smart}"

# Helper to get window rectangles from Hyprland
get_rectangles() {
  local active_workspace
  active_workspace=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .activeWorkspace.id')
  
  hyprctl monitors -j | jq -r --arg ws "$active_workspace" '.[] | select(.activeWorkspace.id == ($ws | tonumber)) | "\(.x),\(.y) \((.width / .scale) | floor)x\((.height / .scale) | floor)"'
  hyprctl clients -j | jq -r --arg ws "$active_workspace" '.[] | select(.workspace.id == ($ws | tonumber)) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"'
}

# Start Wayfreeze in background to freeze all monitors
wayfreeze & PID=$!
sleep 0.1

# Selection Logic
case "$MODE" in
  region)
    SELECTION=$(slurp 2>/dev/null)
    ;;
  windows)
    SELECTION=$(get_rectangles | slurp -r 2>/dev/null)
    ;;
  fullscreen)
    SELECTION=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | "\(.x),\(.y) \((.width / .scale) | floor)x\((.height / .scale) | floor)"')
    ;;
  smart|*)
    RECTS=$(get_rectangles)
    SELECTION=$(echo "$RECTS" | slurp 2>/dev/null)

    # Smart Logic for tiny clicks
    if [[ "$SELECTION" =~ ^([0-9]+),([0-9]+)[[:space:]]([0-9]+)x([0-9]+)$ ]]; then
      W="${BASH_REMATCH[3]}"
      H="${BASH_REMATCH[4]}"
      AREA=$(( W * H ))
      
      if (( AREA < 20 )); then
        CLICK_X="${BASH_REMATCH[1]}"
        CLICK_Y="${BASH_REMATCH[2]}"

        while IFS= read -r rect; do
          if [[ "$rect" =~ ^([0-9]+),([0-9]+)[[:space:]]([0-9]+)x([0-9]+) ]]; then
            RX="${BASH_REMATCH[1]}"
            RY="${BASH_REMATCH[2]}"
            RW="${BASH_REMATCH[3]}"
            RH="${BASH_REMATCH[4]}"

            if (( CLICK_X >= RX && CLICK_X < RX+RW && CLICK_Y >= RY && CLICK_Y < RY+RH )); then
              SELECTION="$RX,$RY ${RW}x${RH}"
              break
            fi
          fi
        done <<< "$RECTS"
      fi
    fi
    ;;
esac

# CRITICAL: Kill wayfreeze and wait for it to fully exit.
# If grim captures while wayfreeze is still active, it can result in a blurry/dim buffer.
kill $PID 2>/dev/null
wait $PID 2>/dev/null
pkill wayfreeze

# If no selection made, exit
[ -z "$SELECTION" ] && exit 0

# Focus the monitor under the cursor before capturing
hyprctl dispatch 'hl.dsp.focus({monitor = "+0"})' >/dev/null 2>&1

# Always copy directly to clipboard. No Satty/edit window.
grim -g "$SELECTION" - | wl-copy
notify-send "Screenshot copied to clipboard"
