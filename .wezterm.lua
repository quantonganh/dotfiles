-- Pull in the wezterm API
local wezterm = require("wezterm")
local mux = wezterm.mux
local act = wezterm.action

local quickselect_plugin = wezterm.plugin.require("https://github.com/quantonganh/quickselect.wezterm")

-- This table will hold the configuration.
local config = {
	front_end = "WebGpu",
	max_fps = 120,
	webgpu_power_preference = "HighPerformance",
}

wezterm.on("gui-startup", function(cmd)
	local tab, pane, window = mux.spawn_window(cmd or {})
	window:gui_window():maximize()
end)

-- config.unix_domains = {
--   {
--     name = 'unix',
--   },
-- }

-- -- This causes `wezterm` to act as though it was started as
-- -- `wezterm connect unix` by default, connecting to the unix
-- -- domain on startup.
-- -- If you prefer to connect manually, leave out this line.
-- config.default_gui_startup_args = { 'connect', 'unix' }

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
	local cb = wezterm.config_builder()
	for k, v in pairs(config) do
		cb[k] = v
	end
	config = cb
end

quickselect_plugin.apply_to_config(config)

-- This is where you actually apply your config choices
config.native_macos_fullscreen_mode = true

-- For example, changing the color scheme:
config.color_scheme = "Darcula (base16)"
-- config.color_scheme = 'JetBrains Darcula'
-- config.color_scheme = 'Ayu Mirage'
config.font = wezterm.font_with_fallback({ "JetBrains Mono", "Iosevka Nerd Font" })
config.font_size = 14.0
config.unzoom_on_switch_pane = true
-- How many lines of scrollback you want to retain per tab
config.scrollback_lines = 3500

config.colors = {
	cursor_bg = "white",
	cursor_fg = "black",
}

-- local last_active_pane = nil
-- local last_was_hx = false
-- local last_project_mtime = {} -- key: pane_id, value: newest mtime

-- local function get_project_mtime(pane)
-- 	local cwd_uri = pane:get_current_working_dir()
-- 	wezterm.log_info("cwd_uri: " .. tostring(cwd_uri))
-- 	if not cwd_uri then
-- 		return 0
-- 	end

-- 	local path = cwd_uri.path
-- 	wezterm.log_info("path: " .. path)
-- 	if not path then
-- 		return 0
-- 	end

-- 	local newest = 0
-- 	local ok, entries = pcall(wezterm.read_dir, path)
-- 	if not ok or not entries then
-- 		wezterm.log_info("not ok or not entries")
-- 		return 0
-- 	end

-- 	for _, e in ipairs(entries) do
-- 		wezterm.log_info("e: " .. tostring(e))
-- 		if e.mtime and e.mtime > newest then
-- 			newest = e.mtime
-- 		end
-- 	end

-- 	return newest
-- end

-- wezterm.on("update-status", function(window, pane)
-- 	local pane_id = pane:pane_id()

-- 	if pane_id ~= last_active_pane then
-- 		last_active_pane = pane_id

-- 		local proc = pane:get_foreground_process_name()
-- 		proc = proc and proc:match("([^/\\]+)$")
-- 		local is_hx = (proc == "hx")

-- 		if (not last_was_hx) and is_hx then
-- 			local current_mtime = get_project_mtime(pane)
-- 			wezterm.log_info("current: " .. current_mtime)
-- 			local previous_mtime = last_project_mtime[pane_id] or 0
-- 			wezterm.log_info("previous: " .. previous_mtime)

-- 			if current_mtime > previous_mtime then
-- 				-- Leave INSERT mode safely
-- 				window:perform_action(wezterm.action.SendKey({ key = "Escape" }), pane)
-- 				wezterm.sleep_ms(80)
-- 				pane:send_text(":reload-all\r")
-- 			end

-- 			last_project_mtime[pane_id] = current_mtime
-- 		end

-- 		last_was_hx = is_hx
-- 	end
-- end)

wezterm.on("toggle-padding", function(window, _)
	local overrides = window:get_config_overrides() or {}
	if overrides.window_padding then
		overrides.window_padding = nil
	else
		overrides.window_padding = {
			left = "41cell",
			right = 0,
			top = 0,
			bottom = 0,
		}
	end
	window:set_config_overrides(overrides)
end)

local my_keys = {
	{
		key = "p",
		mods = "CMD|CTRL",
		action = wezterm.action.EmitEvent("toggle-padding"),
	},
	{
		key = ",",
		mods = "CMD",
		action = act.SpawnCommandInNewTab({
			cwd = os.getenv("WEZTERM_CONFIG_DIR"),
			set_environment_variables = {
				TERM = "screen-256color",
			},
			args = {
				"hx",
				os.getenv("WEZTERM_CONFIG_FILE"),
			},
		}),
	},
	{
		key = ";",
		mods = "CMD",
		action = act.SpawnCommandInNewTab({
			args = {
				"hx",
				"~/.local/bin/helix-wezterm.sh",
			},
		}),
	},
	{
		key = "o",
		mods = "CMD",
		action = act.SpawnCommandInNewTab({
			args = {
				"fish",
				"-c",
				"fo ~/Code",
			},
		}),
	},
	{
		key = "d",
		mods = "CMD",
		action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "d",
		mods = "CMD|SHIFT",
		action = act.SplitVertical({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "[",
		mods = "CMD",
		-- action = act.Multiple {
		--   act.ActivatePaneDirection 'Up',
		--   act.EmitEvent 'reload-helix',
		-- }
		action = act.ActivatePaneDirection("Up"),
	},
	{
		key = "]",
		mods = "CMD",
		action = act.ActivatePaneDirection("Next"),
	},
	{
		key = "h",
		mods = "ALT",
		action = act.ActivatePaneDirection("Left"),
	},
	{
		key = "l",
		mods = "ALT",
		action = act.ActivatePaneDirection("Right"),
	},
	{
		key = ";",
		mods = "CTRL",
		action = wezterm.action_callback(function(_, pane)
			local tab = pane:tab()
			local panes = tab:panes_with_info()
			if #panes == 1 then
				pane:split({
					direction = "Bottom",
				})
			elseif panes[1].is_zoomed then
				tab:set_zoomed(false)
				panes[2].pane:activate()
				-- for _, p in ipairs(panes) do
				--     if p.pane:pane_id() == last_active_pane_id then
				--         p.pane:activate()
				--         return
				--     end
				-- end
			else
				-- last_active_pane_id = pane:pane_id()
				panes[1].pane:activate()
				tab:set_zoomed(true)
			end
		end),
	},
	{
		key = "f",
		mods = "CTRL",
		-- action = act.ToggleFloatingPane,
		action = wezterm.action_callback(function(_, pane)
			local tab = pane:tab()
			local panes = tab:panes_with_info()
			if tab:has_floating_pane() then
				if panes[1].is_zoomed then
					tab:set_zoomed(false)
				end
				tab:toggle_floating_pane()
			else
				tab:set_zoomed(false)
				tab:add_floating_pane()
			end
		end),
	},
	{
		key = "k",
		mods = "CTRL|SHIFT",
		action = act.ScrollByLine(-10),
	},
	{
		key = "j",
		mods = "CTRL|SHIFT",
		action = act.ScrollByLine(10),
	},
	{
		key = "Enter",
		mods = "CMD|CTRL",
		action = act.TogglePaneZoomState,
	},
	{
		key = "h",
		mods = "CMD|CTRL",
		action = act.AdjustPaneSize({ "Left", 5 }),
	},
	{
		key = "j",
		mods = "CMD|CTRL",
		action = act.AdjustPaneSize({ "Down", 5 }),
	},
	{
		key = "k",
		mods = "CMD|CTRL",
		action = act.AdjustPaneSize({ "Up", 5 }),
	},
	{
		key = "l",
		mods = "CMD|CTRL",
		action = act.AdjustPaneSize({ "Right", 5 }),
	},
	{
		key = "I",
		mods = "CTRL|SHIFT",
		action = act.PaneSelect({ show_pane_ids = true }),
	},
	{
		key = "b",
		mods = "CTRL",
		action = act.RotatePanes("CounterClockwise"),
	},
}

for _, keymap in ipairs(my_keys) do
	table.insert(config.keys, keymap)
end

-- Keep the pane open after the program exits
-- config.exit_behavior = "Hold"

-- Honor kitty keyboard protocol: https://sw.kovidgoyal.net/kitty/keyboard-protocol/
-- config.enable_kitty_keyboard = true

for i = 1, 8 do
	-- CTRL+ALT+number to move to that position
	table.insert(config.keys, {
		key = tostring(i),
		mods = "CTRL|ALT",
		action = act.MoveTab(i - 1),
	})
end

config.set_environment_variables = {
	-- PATH = '/Users/quantong/.local/bin:'
	--     .. '/Users/quantong/.cargo/bin:'
	--     .. '/opt/homebrew/bin:'
	--     .. '/Users/quantong/Code/contrib/go/bin:'
	--     .. os.getenv('PATH')
	PATH = "/Users/quantong/.cargo/bin:"
		.. "/opt/homebrew/bin:"
		.. "/Users/quantong/Code/contrib/go/bin:"
		.. os.getenv("PATH"),
}

wezterm.on("open-uri", function(window, pane, uri)
	return quickselect_plugin.Open_with_hx(window, pane, uri)
end)

config.hyperlink_rules = wezterm.default_hyperlink_rules()

table.insert(config.hyperlink_rules, {
	regex = "^/[^/\r\n]+(?:/[^/\r\n]+)*:\\d+:\\d+",
	format = "$EDITOR:$0",
})

table.insert(config.hyperlink_rules, {
	regex = "[^\\s]+\\.rs:\\d+:\\d+",
	format = "$EDITOR:$0",
})

-- https://wezfurlong.org/wezterm/faq.html#multiple-characters-being-renderedcombined-as-one-character
config.harfbuzz_features = { "calt=0" }

config.floating_pane_padding = {
	left = "5%",
	right = "5%",
	top = "4%",
	bottom = "5%",
}

-- config.floating_pane_border = {
--     left_width = '0.25cell',
--     right_width = '0.25cell',
--     bottom_height = '0.125cell',
--     top_height = '0.125cell',
--     left_color = '#665c54',
--     right_color = '#665c54',
--     bottom_color = '#665c54',
--     top_color = '#665c54',
-- }

config.inactive_pane_hsb = {
	saturation = 0.75,
	brightness = 0.8,
}

-- and finally, return the configuration to wezterm
return config
