-- Pull in the wezterm API
local wezterm = require 'wezterm'
local mux = wezterm.mux
local act = wezterm.action

-- This table will hold the configuration.
local config = {}

wezterm.on('gui-startup', function(cmd)
  local tab, pane, window = mux.spawn_window(cmd or {})
  window:gui_window():maximize()
end)

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
config.color_scheme = 'Darcula (base16)'
config.font_size = 14.0
config.unzoom_on_switch_pane = true

config.keys = {
  {
    key = 'd',
    mods = 'CMD',
    action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  {
    key = 'd',
    mods = 'CMD|SHIFT',
    action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
  },
  {
    key = '[',
    mods = 'CMD',
    action = act.Multiple {
      act.ActivatePaneDirection 'Up',
      act.EmitEvent 'reload-helix',
    }
  },
  {
    key = ']',
    mods = 'CMD',
    action = act.ActivatePaneDirection 'Down',
  },
  {
    key = 'UpArrow',
    mods = 'SHIFT',
    action = act.ScrollByLine(-1),
  },
  {
    key = 'DownArrow',
    mods = 'SHIFT',
    action = act.ScrollByLine(1),
  },
  {
    key = 'Enter',
    mods = 'CMD|SHIFT',
    action = wezterm.action.TogglePaneZoomState,
  },
}

wezterm.on('reload-helix', function(window, pane)
  local top_process = basename(pane:get_foreground_process_name())
  if top_process == 'hx' then
    local bottom_pane = pane:tab():get_pane_direction('Down')
    if bottom_pane ~= nil then
      local bottom_process = basename(bottom_pane:get_foreground_process_name())
      if bottom_process == 'lazygit' then
        local action = wezterm.action.SendString(':reload-all\r\n')
        window:perform_action(action, pane);
      end
    end
  end
end)

-- Keep the pane open after the program exits
-- config.exit_behavior = "Hold"

-- Honor kitty keyboard protocol: https://sw.kovidgoyal.net/kitty/keyboard-protocol/
config.enable_kitty_keyboard = true

for i = 1, 8 do
  -- CTRL+ALT+number to move to that position
  table.insert(config.keys, {
    key = tostring(i),
    mods = 'CTRL|ALT',
    action = wezterm.action.MoveTab(i - 1),
  })
end

config.set_environment_variables = {
  PATH = '/Users/quantong/.cargo/bin:'
      .. '/opt/homebrew/bin:'
      .. os.getenv('PATH')
}

function extract_filename(uri)
  local start, match_end = uri:find("$EDITOR:");
  if start == 1 then
    return uri:sub(match_end+1)
  end

  return nil
end

function editable(filename)
  local extension = filename:match("%.([^.:/\\]+):%d+:%d+$")
  if extension then
    wezterm.log_info(string.format("extension is [%s]", extension))
    local text_extensions = {
      md = true,
      c = true,
      go = true,
      scm = true,
      rkt = true,
    }
    if text_extensions[extension] then
      return true
    end
  end

  return false
end

function basename(s)
  return string.gsub(s, '(.*[/\\])(.*)', '%2')
end

wezterm.on('open-uri', function(window, pane, uri)
  local name = extract_filename(uri)
  if name and editable(name) then
    local direction = 'Up'
    local hx_pane = pane:tab():get_pane_direction(direction)
    if hx_pane == nil then
      local action = wezterm.action{
        SplitPane={
          direction = direction,
          command = { args = { 'hx', name } }
        };
      };
      window:perform_action(action, pane);
    elseif basename(hx_pane:get_foreground_process_name()) == "hx" then
      local action = wezterm.action.SendString(':open ' .. name .. '\r\n')
      window:perform_action(action, hx_pane);
    else
      local action = wezterm.action.SendString('hx ' .. name .. '\r\n')
      window:perform_action(action, hx_pane);
    end
    -- prevent the default action from opening in a browser
    return false
  end
  -- otherwise, by not specifying a return value, we allow later
  -- handlers and ultimately the default action to caused the
  -- URI to be opened in the browser
end)

config.hyperlink_rules = wezterm.default_hyperlink_rules()

table.insert(config.hyperlink_rules, {
  regex = '^/[^/\r\n]+(?:/[^/\r\n]+)*:\\d+:\\d+',
  format = '$EDITOR:$0',
})

-- and finally, return the configuration to wezterm
return config
