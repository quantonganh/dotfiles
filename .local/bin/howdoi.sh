#!/bin/sh

source wezterm-split-pane.sh

program=$(wezterm cli list | awk -v pane_id="$pane_id" '$3==pane_id { print $6 }')
if [ "$program" = "lazygit" ]; then
  echo "q" | wezterm cli send-text --pane-id $pane_id --no-paste
fi

echo "howdoi -c `pbpaste`" | wezterm cli send-text --pane-id $pane_id --no-paste
