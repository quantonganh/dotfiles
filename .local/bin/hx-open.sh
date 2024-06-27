#!/usr/bin/env sh

fpath="$1"

pane_id=$(wezterm cli get-pane-direction right)
if [ -z "${pane_id}" ]; then
  pane_id=$(wezterm cli split-pane --right --percent 80)
fi

program=$(wezterm cli list --format json | jq --arg pane_id $pane_id -r '.[] | select(.pane_id  == ($pane_id | tonumber)) | .title' | awk '{ print $1 }')
program_name=$(basename $program)
if [ "$program_name" = "hx" ]; then
  echo ":open ${fpath}\r" | wezterm cli send-text --pane-id $pane_id --no-paste
else
  echo "hx ${fpath}" | wezterm cli send-text --pane-id $pane_id --no-paste
fi

wezterm cli activate-pane-direction --pane-id $pane_id right
