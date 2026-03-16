#!/bin/sh

# Get the action from the first argument
action=$1
export buffer_name=$2
export cursor_line=$3
export selection_line_start=$4
export selection_line_end=$5

pwd=$(PWD)
export basedir=$(dirname "$buffer_name")
export binary_output=$(basename $basedir)
file_name=$(basename "$buffer_name")
export file_stem="${file_name%.*}"
extension="${buffer_name##*.}"

# Load the configuration file
config_file="${XDG_CONFIG_HOME:-$HOME}/.helix-wezterm.yaml"

usage() {
    echo "Usage: $0 <action> [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help      Display this help message and exit"
    echo ""
    echo "Available actions:"
    yq eval '.actions | to_entries | .[] | "- \(.key): \(.value.description)"' $config_file
    exit 0
}

for arg in "$@"; do
  case $arg in
    -h|--help)
      usage
      ;;
  esac
done

# Extract the position, percent and command from the YAML configuration
position=$(yq e ".actions.$action.position" "$config_file")
if [ "$position" == "null" ]; then
  position="bottom"
fi

percent=$(yq e ".actions.$action.percent" "$config_file")
if [ "$percent" == "null" ]; then
  percent=50
fi
command=$(yq e ".actions.$action.command" "$config_file")

case "$action" in
  "ai")
    export selection=$(cat)
    export session=$(basename "$pwd")_$(echo "$buffer_name" | tr "/" "_")
    ;;
  "mock")
    case "$extension" in
      "go")
        current_line=$(head -$cursor_line $buffer_name | tail -1)
        export interface_name=$(echo $current_line | sed -n 's/^type \([A-Za-z0-9_]*\) interface {$/\1/p')
        ;;
    esac
    ;;
  "open")
    remote_url=$(git config remote.origin.url)
    current_branch=$(git rev-parse --abbrev-ref HEAD)
    tracking_branch=$(git for-each-ref --format='%(upstream:short)' refs/heads/$current_branch)
    if [[ $remote_url == *"github.com"* ]]; then
      tracking_remote=$(cut -d'/' -f1 <<< "$tracking_branch")
      tracking_branch_name=$(cut -d'/' -f2- <<< "$tracking_branch")
      gh browse "$buffer_name:$cursor_line" --repo "$(git config remote.$tracking_remote.url)" --branch "$tracking_branch_name"
    else
      if [[ $remote_url == "git@"* ]]; then
        open $(echo $remote_url | sed -e 's|:|/|' -e 's|\.git||' -e 's|git@|https://|')/-/blob/${current_branch}/${buffer_name}#L${cursor_line}
      else
        open $(echo $remote_url | sed -e 's|\.git||')/-/blob/${current_branch}/${buffer_name}#L${cursor_line}
      fi
    fi
    ;;
  "test")
    case "$extension" in
      "go")
        export test_name=$(head -$cursor_line $buffer_name | tail -1 | sed -n 's/func \([^(]*\).*/\1/p')
        ;;
      "hurl")
        current_line=$(head -$cursor_line $buffer_name | tail -1)
        export entry=$(awk -v cur_line=$cursor_line '
          /^(GET|POST|PUT|DELETE|PATCH|HEAD|OPTIONS)/ { entry_line = NR; entry_num++ }
          NR == cur_line { print entry_num }
        ' "$buffer_name")
        ;;
      "rs")
        export test_name=$(head -$cursor_line $buffer_name | tail -1 | sed -n 's/^.*fn \([^ ]*\)().*$/\1/p')
        ;;
    esac
    ;;
  "run")
    case "$file_name" in
      "justfile")
        export recipe=$(head -$cursor_line $buffer_name | tail -1 | sed -n 's/:$//')
        ;;
    esac
    ;;
esac
  
case "$position" in
  "left")
    get_direction="left"
    ;;
  "right")
    get_direction="right"
    ;;
  "top")
    get_direction="up"
    ;;
  "bottom")
    get_direction="down"
    ;;
esac

# Create a new pane in a specified direction or as a floating pane
create_pane() {
  panes_json=$(wezterm cli list --format json)
  tab_id=$(echo "$panes_json" | yq -r ".[] | select(.pane_id == $WEZTERM_PANE) | .tab_id")
  reuse_pattern=$(yq e ".actions.$action.reuse_pattern" "$config_file")

  case "$position" in
    "floating")
      is_zoomed=$(echo "$panes_json" | yq -r ".[] | select(.pane_id == $WEZTERM_PANE) | .is_zoomed")
      if [ "$is_zoomed" == "true" ]; then
        wezterm cli zoom-pane --unzoom
      fi
    
      if [ "$reuse_pattern" == "null" ]; then
        # Check if there is a floating pane containing a shell in the current tab
        pane_id=$(echo "$panes_json" | yq -p=json -o=json ".[] | select(.tab_id == $tab_id and .is_floating == true and (.title | match(\"^~/\"))) | .pane_id" | head -n1)
      else
        pane_id=$(echo "$panes_json" | yq -r ".[] | select(.tab_id == $tab_id and (.title | test(\"$reuse_pattern\"))) | .pane_id" | head -n1)
      fi

      if [ -z "$pane_id" ]; then
        pane_id=$(wezterm cli spawn --floating-pane)
      else
        reuse_pane="true"
      fi
      ;;
    "window")
      pane_id=$(wezterm cli spawn --cwd "$pwd" --new-window)
      ;;
    "tab")
      pane_id=$(wezterm cli spawn --cwd "$pwd")
      ;;
    *)
      if [ "$reuse_pattern" == "null" ]; then
        pane_id=$(wezterm cli get-pane-direction $get_direction)
      else
        pane_id=$(echo "$panes_json" | yq -r ".[] | select(.tab_id == $tab_id and (.title | test(\"$reuse_pattern\"))) | .pane_id" | head -n1)
      fi

      if [ -z "$pane_id" ]; then
        pane_id=$(wezterm cli split-pane --$position --percent $percent)
      else
        reuse_pane="true"
      fi
      ;;
  esac

  wezterm cli activate-pane --pane-id $pane_id
  send_to_pane="wezterm cli send-text --pane-id $pane_id --no-paste"
}

act=$(yq e ".actions.$action" "$config_file")
if [ "$act" != "null" ]; then
  create_pane

  # Send command to the target pane
  ext=$(yq e ".actions.$action.extensions" "$config_file")
  if [ "$ext" != "null" ]; then
    extension="${buffer_name##*.}"
    command=$(yq e ".actions.$action.extensions.$extension" "$config_file")
  fi

  if [ "$reuse_pane" = "true" ]; then
    reuse_command=$(yq e ".actions.$action.reuse_command" "$config_file")
    if [ "$reuse_command" != "null" ]; then
      expanded_command=$(echo "$reuse_command" | envsubst '$buffer_name,$selection_line_start,$selection_line_end')
    fi
  fi

  if [ -z "$expanded_command" ]; then
    expanded_command=$(echo "$command" | envsubst '$WEZTERM_PANE,$basedir,$binary_output,$buffer_name,$file_stem,$cursor_line,$selection,$selection_line_start,$selection_line_end,$interface_name,$test_name,$session,$entry')
  fi

  echo "$expanded_command" | $send_to_pane
fi
