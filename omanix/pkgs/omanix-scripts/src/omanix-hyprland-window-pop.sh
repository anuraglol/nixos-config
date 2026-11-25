#!/usr/bin/env bash
# Toggle to pop-out a tile to stay fixed on a display basis.
# Usage:
#   omanix-hyprland-window-pop [width height [x y]]
#
# Arguments:
#   width   Optional. Width of the floating window. Default: 1300
#   height  Optional. Height of the floating window. Default: 900
#   x       Optional. X position. Must provide both X and Y to take effect.
#   y       Optional. Y position. Must provide both X and Y to take effect.
#
# Behavior:
#   - If the window is already pinned, it will be unpinned and removed from the pop layer.
#   - If the window is not pinned, it will be floated, resized, moved/centered, pinned,
#     brought to top, and tagged as popped.

width=${1:-1300}
height=${2:-900}
x=${3:-}
y=${4:-}

active=$(hyprctl activewindow -j)
pinned=$(echo "$active" | jq ".pinned")
addr=$(echo "$active" | jq -r ".address")

if [[ $pinned == "true" ]]; then
  hyprctl dispatch "hl.dsp.window.pin({window = \"address:$addr\"})"
  hyprctl dispatch "hl.dsp.window.float({action = \"toggle\", window = \"address:$addr\"})"
  hyprctl dispatch "hl.dsp.window.tag({tag = \"-pop\", window = \"address:$addr\"})"
elif [[ -n $addr ]]; then
  hyprctl dispatch "hl.dsp.window.float({action = \"toggle\", window = \"address:$addr\"})"
  hyprctl dispatch "hl.dsp.window.resize({x = $width, y = $height, exact = true, window = \"address:$addr\"})"

  if [[ -n $x && -n $y ]]; then
    hyprctl dispatch "hl.dsp.window.move({x = $x, y = $y, window = \"address:$addr\"})"
  else
    hyprctl dispatch "hl.dsp.window.center({window = \"address:$addr\"})"
  fi

  hyprctl dispatch "hl.dsp.window.pin({window = \"address:$addr\"})"
  hyprctl dispatch "hl.dsp.window.alter_zorder({action = \"top\", window = \"address:$addr\"})"
  hyprctl dispatch "hl.dsp.window.tag({tag = \"+pop\", window = \"address:$addr\"})"
fi
