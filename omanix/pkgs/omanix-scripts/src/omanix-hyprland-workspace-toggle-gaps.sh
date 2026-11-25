#!/usr/bin/env bash
# Toggles window gaps on the active workspace between no gaps and defaults.

workspace_id=$(hyprctl activeworkspace -j | jq -r .id)
gaps=$(hyprctl workspacerules -j | jq -r ".[] | select(.workspaceString==\"$workspace_id\") | .gapsOut[0] // 0")

outer=${OMANIX_GAPS_OUTER:-10}
inner=${OMANIX_GAPS_INNER:-5}
border=${OMANIX_BORDER_SIZE:-2}

if [[ $gaps == "0" ]]; then
  hyprctl keyword "hl.workspace_rule({workspace = \"$workspace_id\", gaps_out = $outer, gaps_in = $inner, border_size = $border})"
else
  hyprctl keyword "hl.workspace_rule({workspace = \"$workspace_id\", gaps_out = 0, gaps_in = 0, border_size = 0})"
fi
