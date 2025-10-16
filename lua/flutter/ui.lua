-- UI: Telescope pickers and UI helpers for Flutter
local M = {}

local device_manager = require("flutter.device-manager")

-- Show device picker
function M.show_device_picker(opts)
	opts = opts or {}
	local callback = opts.callback or function() end
	local prompt_title = opts.prompt_title or "Flutter Devices"

	-- Get devices
	local devices = device_manager.get_devices(true) -- Force refresh

	if not devices or #devices == 0 then
		vim.notify("No Flutter devices found. Connect a device or start an emulator.", vim.log.levels.WARN)
		return
	end

	-- Build picker items
	local items = {}
	for _, device in ipairs(devices) do
		table.insert(items, {
			device = device,
			display = device_manager.format_device(device),
		})
	end

	-- Create Telescope picker
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	pickers
		.new({}, {
			prompt_title = prompt_title,
			finder = finders.new_table({
				results = items,
				entry_maker = function(entry)
					return {
						value = entry,
						display = entry.display,
						ordinal = entry.device.name .. " " .. entry.device.id,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					if selection then
						callback(selection.value.device)
					end
				end)
				return true
			end,
		})
		:find()
end

-- Show emulator picker
function M.show_emulator_picker(opts)
	opts = opts or {}
	local callback = opts.callback or function() end
	local prompt_title = opts.prompt_title or "Flutter Emulators"

	-- Get emulators
	local emulators = device_manager.get_emulators(true) -- Force refresh

	if not emulators or #emulators == 0 then
		vim.notify("No Flutter emulators found. Install an emulator via Android Studio or Xcode.", vim.log.levels.WARN)
		return
	end

	-- Build picker items
	local items = {}
	for _, emulator in ipairs(emulators) do
		table.insert(items, {
			emulator = emulator,
			display = device_manager.format_emulator(emulator),
		})
	end

	-- Create Telescope picker
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	pickers
		.new({}, {
			prompt_title = prompt_title,
			finder = finders.new_table({
				results = items,
				entry_maker = function(entry)
					return {
						value = entry,
						display = entry.display,
						ordinal = entry.emulator.name .. " " .. entry.emulator.id,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					if selection then
						callback(selection.value.emulator)
					end
				end)
				return true
			end,
		})
		:find()
end

-- Show running apps picker
function M.show_running_apps_picker(opts)
	opts = opts or {}
	local callback = opts.callback or function() end
	local prompt_title = opts.prompt_title or "Running Flutter Apps"

	local runner = require("flutter.runner")
	local apps = runner.get_running_apps()

	if not apps or #apps == 0 then
		vim.notify("No running Flutter apps found", vim.log.levels.WARN)
		return
	end

	-- Build picker items
	local items = {}
	for _, app in ipairs(apps) do
		local display = string.format("[%d] %s on %s", app.id, app.name or "Flutter App", app.device_id or "unknown")
		table.insert(items, {
			app = app,
			display = display,
		})
	end

	-- Create Telescope picker
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	pickers
		.new({}, {
			prompt_title = prompt_title,
			finder = finders.new_table({
				results = items,
				entry_maker = function(entry)
					return {
						value = entry,
						display = entry.display,
						ordinal = entry.app.name or "Flutter App",
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					if selection then
						callback(selection.value.app)
					end
				end)
				return true
			end,
		})
		:find()
end

-- Simple prompt using vim.ui.select
function M.simple_select(items, prompt, callback)
	vim.ui.select(items, {
		prompt = prompt,
	}, function(choice)
		if choice then
			callback(choice)
		end
	end)
end

return M
