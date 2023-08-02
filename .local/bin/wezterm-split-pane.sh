#!/bin/sh

pane_id=$(wezterm cli get-pane-direction down)
if [ -z "${pane_id}" ]; then
  pane_id=$(wezterm cli split-pane)
fi

wezterm cli activate-pane-direction --pane-id $pane_id down
