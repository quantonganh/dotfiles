#!/bin/sh

source wezterm-split-pane.sh

program=$(wezterm cli list | awk -v pane_id="$pane_id" '$3==pane_id { print $6 }')
if [ "$program" = "lazygit" ]; then
  echo "q" | wezterm cli send-text --pane-id $pane_id --no-paste
fi

filename="$1"
basedir=$(dirname "$filename")
basename=$(basename "$filename")
basename_without_extension="${basename%.*}"
extension="${filename##*.}"

case "$extension" in
  "c")
    run_command="clang -lcmocka -lmpfr -Wall -O3 $filename -o $basedir/$basename_without_extension && $basedir/$basename_without_extension"
    ;;
  "go")
    run_command="go run $basedir/*.go"
    ;;
  "rkt"|"scm")
    run_command="racket $filename"
    ;;
  "rs")
    run_command="cd $basedir; cargo run"
    ;;
  "sh")
    run_command="sh $filename"
    ;;
esac

echo "${run_command}" | wezterm cli send-text --pane-id $pane_id --no-paste
# wezterm cli activate-pane-direction up