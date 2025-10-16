-- Logger: Comprehensive logging for Flutter apps (IntelliJ-style)
-- Captures Flutter output + device logs (adb logcat for Android, idevicesyslog for iOS)
local M = {}

-- State
M.log_bufnr = nil
M.log_winnr = nil
M.current_app_id = nil
M.app_logs = {} -- { app_id = { lines = {...}, name = "...", device_logs_job = nil } }
M.auto_scroll = true

-- Log level colors (for highlighting)
M.log_levels = {
	ERROR = { pattern = "%[ERROR%]", hl_group = "Error" },
	WARN = { pattern = "%[WARN%]", hl_group = "WarningMsg" },
	INFO = { pattern = "%[INFO%]", hl_group = "Normal" },
	DEBUG = { pattern = "%[DEBUG%]", hl_group = "Comment" },
}

-- Strip ANSI escape codes
local function strip_ansi_codes(text)
	return text:gsub("\27%[[%d;]*m", "")
end

-- Add timestamp to log line
local function add_timestamp(line)
	local timestamp = os.date("%H:%M:%S")
	return string.format("[%s] %s", timestamp, line)
end

-- Detect log level and add prefix
local function format_log_line(line, stream_type)
	line = strip_ansi_codes(line)

	-- Add ERROR prefix for stderr
	if stream_type == "stderr" and not line:match("%[ERROR%]") then
		line = "[ERROR] " .. line
	end

	-- Add timestamp
	line = add_timestamp(line)

	return line
end

-- Create or get log buffer
local function get_or_create_log_buffer()
	if M.log_bufnr and vim.api.nvim_buf_is_valid(M.log_bufnr) then
		return M.log_bufnr
	end

	M.log_bufnr = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(M.log_bufnr, "buftype", "nofile")
	vim.api.nvim_buf_set_option(M.log_bufnr, "bufhidden", "hide")
	vim.api.nvim_buf_set_option(M.log_bufnr, "swapfile", false)
	vim.api.nvim_buf_set_option(M.log_bufnr, "filetype", "flutter-log")
	vim.api.nvim_buf_set_name(M.log_bufnr, "Flutter Console")

	-- Set buffer keymaps
	vim.keymap.set("n", "q", function()
		M.close()
	end, { buffer = M.log_bufnr, desc = "Close Flutter log console" })

	vim.keymap.set("n", "c", function()
		M.clear_current_log()
	end, { buffer = M.log_bufnr, desc = "Clear current log" })

	vim.keymap.set("n", "a", function()
		M.auto_scroll = not M.auto_scroll
		vim.notify("Auto-scroll: " .. (M.auto_scroll and "ON" or "OFF"), vim.log.levels.INFO)
	end, { buffer = M.log_bufnr, desc = "Toggle auto-scroll" })

	return M.log_bufnr
end

-- Open log console window
function M.open(app_id)
	local bufnr = get_or_create_log_buffer()

	-- Check if window already open
	if M.log_winnr and vim.api.nvim_win_is_valid(M.log_winnr) then
		vim.api.nvim_set_current_win(M.log_winnr)
		if app_id then
			M.switch_to_app(app_id)
		end
		return
	end

	-- Create split window at bottom
	vim.cmd("botright 15split")
	M.log_winnr = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(M.log_winnr, bufnr)

	-- Set window options
	vim.api.nvim_win_set_option(M.log_winnr, "number", false)
	vim.api.nvim_win_set_option(M.log_winnr, "relativenumber", false)
	vim.api.nvim_win_set_option(M.log_winnr, "wrap", false)

	if app_id then
		M.switch_to_app(app_id)
	end
end

-- Close log console
function M.close()
	if M.log_winnr and vim.api.nvim_win_is_valid(M.log_winnr) then
		vim.api.nvim_win_close(M.log_winnr, true)
		M.log_winnr = nil
	end
end

-- Toggle log console
function M.toggle(app_id)
	if M.log_winnr and vim.api.nvim_win_is_valid(M.log_winnr) then
		M.close()
	else
		M.open(app_id)
	end
end

-- Check if log console is open
function M.is_open()
	return M.log_winnr and vim.api.nvim_win_is_valid(M.log_winnr)
end

-- Initialize log storage for an app
function M.init_app_log(app_id, app_name)
	M.app_logs[app_id] = {
		lines = { string.format("=== Flutter App: %s (ID: %d) ===", app_name, app_id), "" },
		name = app_name,
		device_logs_job = nil,
	}
end

-- Start device-specific logging (adb logcat for Android)
function M.start_device_logs(app_id, device_id, package_name)
	local app_log = M.app_logs[app_id]
	if not app_log then
		return
	end

	-- Detect device platform (simplified - check if Android)
	-- For Android: use adb logcat
	-- For iOS: would use idevicesyslog (requires libimobiledevice)

	if device_id:match("emulator") or device_id:match("android") then
		-- Android device - use adb logcat
		M.append_output(app_id, { "[INFO] Starting Android device logs (adb logcat)..." }, "stdout")

		local filter = package_name and string.format(" | grep %s", package_name) or ""
		local cmd = string.format("adb -s %s logcat%s", device_id, filter)

		local job_id = vim.fn.jobstart(cmd, {
			on_stdout = function(_, data)
				if data and #data > 0 then
					vim.schedule(function()
						-- Prefix device logs
						local prefixed = vim.tbl_map(function(line)
							return "[DEVICE] " .. line
						end, data)
						M.append_output(app_id, prefixed, "device-log")
					end)
				end
			end,
			on_exit = function()
				vim.schedule(function()
					M.append_output(app_id, { "[INFO] Device logs stopped" }, "stdout")
				end)
			end,
		})

		app_log.device_logs_job = job_id
	end
end

-- Stop device logs for app
function M.stop_device_logs(app_id)
	local app_log = M.app_logs[app_id]
	if app_log and app_log.device_logs_job then
		vim.fn.jobstop(app_log.device_logs_job)
		app_log.device_logs_job = nil
	end
end

-- Append output to app log
function M.append_output(app_id, data, stream_type)
	vim.schedule(function()
		if not M.app_logs[app_id] then
			M.init_app_log(app_id, "Unknown App")
		end

		local lines = {}

		-- Handle both string and table input
		if type(data) == "string" then
			lines = vim.split(data, "\n", { plain = true })
		else
			lines = data
		end

		-- Format and add lines
		for _, line in ipairs(lines) do
			if line ~= "" then
				local formatted_line = format_log_line(line, stream_type)
				table.insert(M.app_logs[app_id].lines, formatted_line)
			end
		end

		-- Update display if this is the current app
		if M.current_app_id == app_id and M.is_open() then
			M.refresh_display()
		end
	end)
end

-- Switch to a different app's logs
function M.switch_to_app(app_id)
	M.current_app_id = app_id

	if not M.app_logs[app_id] then
		M.app_logs[app_id] = {
			lines = { string.format("=== App ID: %d (no output yet) ===", app_id), "" },
		}
	end

	M.refresh_display()
end

-- Refresh display with current app's logs
function M.refresh_display()
	if not M.is_open() then
		return
	end

	local bufnr = get_or_create_log_buffer()
	local app_log = M.app_logs[M.current_app_id]

	if not app_log then
		return
	end

	-- Make buffer modifiable
	vim.api.nvim_buf_set_option(bufnr, "modifiable", true)

	-- Set lines
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, app_log.lines)

	-- Make buffer read-only
	vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

	-- Auto-scroll to bottom
	if M.auto_scroll and M.log_winnr and vim.api.nvim_win_is_valid(M.log_winnr) then
		local line_count = vim.api.nvim_buf_line_count(bufnr)
		vim.api.nvim_win_set_cursor(M.log_winnr, { line_count, 0 })
	end
end

-- Clear current app's log
function M.clear_current_log()
	if not M.current_app_id then
		return
	end

	local app_log = M.app_logs[M.current_app_id]
	if app_log then
		local header = app_log.lines[1]
		M.app_logs[M.current_app_id].lines = { header, "" }
		M.refresh_display()
		vim.notify("Cleared log for app ID: " .. M.current_app_id, vim.log.levels.INFO)
	end
end

-- Clear all logs
function M.clear_all_logs()
	M.app_logs = {}
	M.current_app_id = nil

	if M.is_open() then
		local bufnr = get_or_create_log_buffer()
		vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "=== No active app ===" })
		vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
	end

	vim.notify("Cleared all Flutter logs", vim.log.levels.INFO)
end

return M
