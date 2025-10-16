-- Device Manager: Handles Flutter device and emulator detection/management
local M = {}

-- Cache for devices and emulators
M.devices_cache = nil
M.emulators_cache = nil
M.flutter_sdk_path = nil

-- Get Flutter SDK path
function M.get_flutter_sdk()
	if M.flutter_sdk_path then
		return M.flutter_sdk_path
	end

	-- Try to get Flutter SDK path
	local result = vim.fn.system("flutter sdk-path 2>/dev/null")
	if vim.v.shell_error == 0 then
		M.flutter_sdk_path = vim.trim(result)
		return M.flutter_sdk_path
	end

	return nil
end

-- Check if Flutter is available
function M.is_flutter_available()
	local result = vim.fn.system("command -v flutter >/dev/null 2>&1 && echo 'yes' || echo 'no'")
	return vim.trim(result) == "yes"
end

-- Parse JSON output from Flutter commands
local function parse_json(output)
	local ok, decoded = pcall(vim.fn.json_decode, output)
	if not ok then
		vim.notify("Failed to parse Flutter JSON output", vim.log.levels.ERROR)
		return nil
	end
	return decoded
end

-- Get list of devices
function M.get_devices(force_refresh)
	if M.devices_cache and not force_refresh then
		return M.devices_cache
	end

	-- Run flutter devices with machine-readable output
	local result = vim.fn.system("flutter devices --machine 2>/dev/null")
	if vim.v.shell_error ~= 0 then
		vim.notify("Failed to get Flutter devices", vim.log.levels.ERROR)
		return {}
	end

	local devices = parse_json(result)
	if not devices then
		return {}
	end

	-- Cache the results
	M.devices_cache = devices

	return devices
end

-- Get list of emulators
function M.get_emulators(force_refresh)
	if M.emulators_cache and not force_refresh then
		return M.emulators_cache
	end

	-- Run flutter emulators with machine-readable output
	local result = vim.fn.system("flutter emulators --machine 2>/dev/null")
	if vim.v.shell_error ~= 0 then
		vim.notify("Failed to get Flutter emulators", vim.log.levels.ERROR)
		return {}
	end

	local emulators = parse_json(result)
	if not emulators then
		return {}
	end

	-- Cache the results
	M.emulators_cache = emulators

	return emulators
end

-- Launch an emulator
function M.launch_emulator(emulator_id, callback)
	if not emulator_id then
		vim.notify("No emulator ID provided", vim.log.levels.ERROR)
		return false
	end

	vim.notify(string.format("Launching emulator: %s...", emulator_id), vim.log.levels.INFO)

	-- Launch emulator in background
	vim.fn.jobstart(string.format("flutter emulators --launch %s", emulator_id), {
		on_exit = function(_, exit_code)
			vim.schedule(function()
				if exit_code == 0 then
					vim.notify(string.format("Emulator %s launched successfully", emulator_id), vim.log.levels.INFO)
					-- Clear cache to refresh device list
					M.devices_cache = nil
					if callback then
						callback(true)
					end
				else
					vim.notify(string.format("Failed to launch emulator: %s", emulator_id), vim.log.levels.ERROR)
					if callback then
						callback(false)
					end
				end
			end)
		end,
		on_stderr = function(_, data)
			if data and #data > 0 then
				vim.schedule(function()
					for _, line in ipairs(data) do
						if line ~= "" then
							vim.notify(line, vim.log.levels.WARN)
						end
					end
				end)
			end
		end,
	})

	return true
end

-- Get device by ID
function M.get_device_by_id(device_id)
	local devices = M.get_devices()
	for _, device in ipairs(devices) do
		if device.id == device_id then
			return device
		end
	end
	return nil
end

-- Get emulator by ID
function M.get_emulator_by_id(emulator_id)
	local emulators = M.get_emulators()
	for _, emulator in ipairs(emulators) do
		if emulator.id == emulator_id then
			return emulator
		end
	end
	return nil
end

-- Format device for display
function M.format_device(device)
	local platform_icons = {
		android = " ",
		ios = " ",
		web = "󰖟 ",
		macos = " ",
		linux = " ",
		windows = " ",
	}

	local icon = platform_icons[device.platform] or "󰄶 "
	local status = device.emulator and "(emulator)" or "(physical)"

	return string.format("%s %s - %s %s", icon, device.name, device.id, status)
end

-- Format emulator for display
function M.format_emulator(emulator)
	local platform_icons = {
		android = " ",
		ios = " ",
	}

	local platform = emulator.platformIdentifier or "unknown"
	local icon = platform:find("android") and platform_icons.android or platform_icons.ios

	return string.format("%s %s (%s)", icon, emulator.name, emulator.id)
end

-- Clear cache
function M.clear_cache()
	M.devices_cache = nil
	M.emulators_cache = nil
end

return M
