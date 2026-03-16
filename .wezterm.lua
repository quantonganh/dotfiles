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

config.unix_domains = {
  {
    name = 'unix',
  },
}

-- This causes `wezterm` to act as though it was started as
-- `wezterm connect unix` by default, connecting to the unix
-- domain on startup.
-- If you prefer to connect manually, leave out this line.
config.default_gui_startup_args = { 'connect', 'unix' }

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- This is where you actually apply your config choices
config.native_macos_fullscreen_mode = true

-- For example, changing the color scheme:
config.color_scheme = 'Darcula (base16)'
config.font = wezterm.font_with_fallback { 'JetBrains Mono', 'Iosevka Nerd Font' }
config.font_size = 14.0
config.unzoom_on_switch_pane = true
-- How many lines of scrollback you want to retain per tab
config.scrollback_lines = 3500

config.colors = {
  cursor_bg = 'white',
  cursor_fg = 'black',
}

config.keys = {
  {
    key = ',',
    mods = 'CMD',
    action = act.SpawnCommandInNewTab {
      cwd = os.getenv('WEZTERM_CONFIG_DIR'),
      set_environment_variables = {
        TERM = 'screen-256color',
      },
      args = {
        'hx',
        os.getenv('WEZTERM_CONFIG_FILE'),
      },
    },
  },
  {
    key = ';',
    mods = 'CMD',
    action = act.SpawnCommandInNewTab {
      args = {
        'hx',
        '~/.local/bin/helix-wezterm.sh',
      },
    },
  },
  {
    key = 'd',
    mods = 'CMD',
    action = act.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  {
    key = 'd',
    mods = 'CMD|SHIFT',
    action = act.SplitVertical { domain = 'CurrentPaneDomain' },
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
    action = act.ActivatePaneDirection 'Next',
  },
  {
    key = 'h',
    mods = 'ALT',
    action = act.ActivatePaneDirection 'Left',
  },
  {
    key = 'l',
    mods = 'ALT',
    action = act.ActivatePaneDirection 'Right',
  },
  {
    key = 'k',
    mods = 'CTRL|SHIFT',
    action = act.ScrollByLine(-1),
  },
  {
    key = 'j',
    mods = 'CTRL|SHIFT',
    action = act.ScrollByLine(1),
  },
  {
    key = 'Enter',
    mods = 'CMD|CTRL',
    action = act.TogglePaneZoomState,
  },
    {
    key = 'h',
    mods = 'CMD|CTRL',
    action = act.AdjustPaneSize { 'Left', 5 },
  },
  {
    key = 'j',
    mods = 'CMD|CTRL',
    action = act.AdjustPaneSize { 'Down', 5 },
  },
  {
    key = 'k',
    mods = 'CMD|CTRL',
    action = act.AdjustPaneSize { 'Up', 5 } },
  {
    key = 'l',
    mods = 'CMD|CTRL',
    action = act.AdjustPaneSize { 'Right', 5 },
  },
  {
    key = 's',
    mods = 'CMD|SHIFT',
    action = act.QuickSelectArgs {
      label = 'open url',
      patterns = {
        'https?://\\S+',
        '^/[^/\r\n]+(?:/[^/\r\n]+)*:\\d+:\\d+',
        '[^\\s]+\\.rs:\\d+:\\d+',
        '[^\\s]+\\.go:\\d+:\\d+',
        'rustc --explain E\\d+',
        '[^{]*{.*}',
      },
      action = wezterm.action_callback(function(window, pane)
        local selection = window:get_selection_text_for_pane(pane)
        wezterm.log_info('opening: ' .. selection)
        if Startswith(selection, "http") then
          wezterm.open_with(selection)
        elseif Startswith(selection, "rustc --explain") then
          local action = act{
            SplitPane={
              direction = 'Right',
              command = {
                args = {
                  '/bin/sh',
                  '-c',
                  'rustc --explain ' .. selection:match("(%S+)$") .. ' | mdcat -p',
                },
              },
            };
          };
          window:perform_action(action, pane);
        elseif selection:match('[^{]*{.*}') then
          wezterm.log_info('processing json: ' .. selection)
          local command = 'echo \'' .. selection:match("{.*}") .. '\' | jq -C . | less -R'
          wezterm.log_info('command: ' .. command)
          local action = act{
            SplitPane={
              direction = 'Right',
              command = {
                args = {
                  '/bin/sh',
                  '-c',
                  command,
                },
              },
            };
          };
          window:perform_action(action, pane);
        else
          selection = "$EDITOR:" .. selection
          return open_with_hx(window, pane, selection)
        end
      end),
    },
  },
  {
		key = "I",
		mods = "CTRL|SHIFT",
		action = act.PaneSelect { show_pane_ids = true },
	},
  {
    key = 'O',
    mods = 'CMD|SHIFT',
    action = wezterm.action_callback(function(window, pane)
      -- Here you can dynamically construct a longer list if needed

      local project_dir = wezterm.home_dir .. '/Code/GHTK/atao-cloud'
      local projects = {}
      for _, dir in ipairs(wezterm.glob(project_dir .. '/*')) do
        wezterm.log_info('dir: ', dir)
        table.insert(projects, dir)
      end

      local choices = {}
      for _, project in ipairs(projects) do
        table.insert(choices, { id = project, label = basename(project) })
      end

      window:perform_action(
        act.InputSelector {
          action = wezterm.action_callback(
            function(inner_window, inner_pane, id, label)
              if not id and not label then
                wezterm.log_info 'cancelled'
              else
                wezterm.log_info('id = ' .. id)
                wezterm.log_info('label = ' .. label)
                inner_window:perform_action(
                  act.SpawnCommandInNewTab {
                    args = {
                      'hx',
                      id,
                    },
                  },
                  inner_pane
                )
                wezterm.sleep_ms(100)
                inner_window:perform_action(
                  -- Enter -> Space e -> Esc
                  act.SendString('README.md\r\x20e\x1b'),
                  inner_window:active_pane()
                )
              end
            end
          ),
          title = 'Choose Project',
          choices = choices,
          fuzzy = true,
          fuzzy_description = 'Fuzzy matching: ',
        },
        pane
      )
    end),
  },
}

function Startswith(str, prefix)
  return string.sub(str, 1, string.len(prefix)) == prefix
end

wezterm.on('reload-helix', function(window, pane)
  local top_process = basename(pane:get_foreground_process_name())
  if top_process == 'hx' then
    local bottom_pane = pane:tab():get_pane_direction('Down')
    if bottom_pane ~= nil then
      local bottom_process = basename(bottom_pane:get_foreground_process_name())
      wezterm.log_info('bottom process: ' .. bottom_process)
      if bottom_process == 'lazygit' or bottom_process == 'fish' then
        window:perform_action(act.SendString('\x1b'), pane); -- ESC the file explorer
        wezterm.sleep_ms(100)
        window:perform_action(act.SendString('\x1b'), pane); -- ESC the insert mode
        wezterm.sleep_ms(100)
        window:perform_action(act.SendString(':reload-all\r'), pane);
      end
    end
  end
end)

-- Keep the pane open after the program exits
-- config.exit_behavior = "Hold"

-- Honor kitty keyboard protocol: https://sw.kovidgoyal.net/kitty/keyboard-protocol/
-- config.enable_kitty_keyboard = true

for i = 1, 8 do
  -- CTRL+ALT+number to move to that position
  table.insert(config.keys, {
    key = tostring(i),
    mods = 'CTRL|ALT',
    action = act.MoveTab(i - 1),
  })
end

config.set_environment_variables = {
  PATH = '/Users/quantong/.local/bin:'
      .. '/Users/quantong/.cargo/bin:'
      .. '/opt/homebrew/bin:'
      .. '/Users/quantong/Code/contrib/go/bin:'
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
      rs = true,
    }
    if text_extensions[extension] then
      return true
    end
  end

  return false
end

function extension(filename)
  return filename:match("%.([^.:/\\]+):%d+:%d+$")
end

function basename(s)
  return string.gsub(s, '(.*[/\\])(.*)', '%2')
end

function open_with_hx(window, pane, url)
  local name = extract_filename(url)
  wezterm.log_info('name: ' .. url)
  if name and editable(name) then
    if extension(name) == "rs" then
      local pwd = string.gsub(pane:get_current_working_dir(), "file://.-(/.+)", "%1")
      name = pwd .. "/" .. name
    end

    local direction = 'Up'
    local hx_pane = pane:tab():get_pane_direction(direction)
    wezterm.log_info("fg process: " .. hx_pane:get_foreground_process_name())
    if hx_pane == nil then
      local action = act{
        SplitPane={
          direction = direction,
          command = { args = { 'hx', name } }
        };
      };
      window:perform_action(action, pane);
      pane:tab():get_pane_direction(direction).activate()
    elseif basename(hx_pane:get_foreground_process_name()) == "hx" then
      wezterm.log_info('process = hx')
      local action = act.SendString(':open ' .. name .. '\r')
      window:perform_action(action, hx_pane);
      -- local zoom_action = wezterm.action.SendString(':sh wezterm cli zoom-pane\r\n')
      -- window:perform_action(zoom_action, hx_pane);
      hx_pane:activate()
    else
      local action = act.SendString('hx ' .. name .. '\r')
      window:perform_action(action, hx_pane);
      hx_pane:activate()
    end
    -- prevent the default action from opening in a browser
    return false
  end
  -- otherwise, by not specifying a return value, we allow later
  -- handlers and ultimately the default action to caused the
  -- URI to be opened in the browser
end

wezterm.on('open-uri', function(window, pane, uri)
  return open_with_hx(window, pane, uri)
end)

config.hyperlink_rules = wezterm.default_hyperlink_rules()

table.insert(config.hyperlink_rules, {
  regex = '^/[^/\r\n]+(?:/[^/\r\n]+)*:\\d+:\\d+',
  format = '$EDITOR:$0',
})

table.insert(config.hyperlink_rules, {
  regex = '[^\\s]+\\.rs:\\d+:\\d+',
  format = '$EDITOR:$0',
})

-- https://wezfurlong.org/wezterm/faq.html#multiple-characters-being-renderedcombined-as-one-character
config.harfbuzz_features = { 'calt=0' }

config.float_pane_padding = {
  left = '5%',
  right = '5%',
  top = '5%',
  bottom = '5%',
}

config.float_pane_border = {
  left_width = '0.25cell',
  right_width = '0.25cell',
  bottom_height = '0.125cell',
  top_height = '0.125cell',
  left_color = '#665c54',
  right_color = '#665c54',
  bottom_color = '#665c54',
  top_color = '#665c54',
}

-- and finally, return the configuration to wezterm
return config
