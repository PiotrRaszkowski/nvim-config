-- Log UI: Manages log console window and output display
local M = {}

-- Strip ANSI escape codes from text (colors, styles, etc.)
-- Matches patterns like: \x1b[0m, \x1b[38;5;145m, \x1b[1;32m
local function strip_ansi_codes(text)
	-- Pattern matches ANSI escape sequences: ESC[...m
	-- \27 is ESC character, [%d;]* matches digits and semicolons, m is terminator
	return text:gsub("\27%[[%d;]*m", "")
end

-- State
M.log_bufnr = nil
M.log_winnr = nil
M.current_task_id = nil
M.task_logs = {} -- { task_id = { lines = {...}, last_line = N } }
M.auto_scroll = true

-- Create or get log buffer
local function get_or_create_log_buffer()
	-- Check if buffer still exists
	if M.log_bufnr and vim.api.nvim_buf_is_valid(M.log_bufnr) then
		return M.log_bufnr
	end

	-- Create new buffer
	M.log_bufnr = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(M.log_bufnr, "buftype", "nofile")
	vim.api.nvim_buf_set_option(M.log_bufnr, "bufhidden", "hide")
	vim.api.nvim_buf_set_option(M.log_bufnr, "swapfile", false)
	vim.api.nvim_buf_set_option(M.log_bufnr, "filetype", "log")
	vim.api.nvim_buf_set_name(M.log_bufnr, "Run Configurations - Console")

	-- Set buffer keymaps
	vim.keymap.set("n", "q", function()
		M.close()
	end, { buffer = M.log_bufnr, desc = "Close log console" })

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
function M.open(task_id)
	local bufnr = get_or_create_log_buffer()

	-- Check if window already open
	if M.log_winnr and vim.api.nvim_win_is_valid(M.log_winnr) then
		vim.api.nvim_set_current_win(M.log_winnr)
		if task_id then
			M.switch_to_task(task_id)
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

	if task_id then
		M.switch_to_task(task_id)
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
function M.toggle(task_id)
	if M.log_winnr and vim.api.nvim_win_is_valid(M.log_winnr) then
		M.close()
	else
		M.open(task_id)
	end
end

-- Check if log console is open
function M.is_open()
	return M.log_winnr and vim.api.nvim_win_is_valid(M.log_winnr)
end

-- Initialize log storage for a task
function M.init_task_log(task_id, task_name)
	M.task_logs[task_id] = {
		lines = { string.format("=== Task: %s (ID: %d) ===", task_name, task_id), "" },
		task_name = task_name,
	}
end

-- Append output to task log
function M.append_output(task_id, data, stream_type)
	-- Use vim.schedule to avoid fast event context issues
	vim.schedule(function()
		if not M.task_logs[task_id] then
			M.init_task_log(task_id, "Unknown Task")
		end

		-- Split data into lines
		local lines = vim.split(data, "\n", { plain = true })

		-- Strip ANSI codes and add prefix for stderr
		for i, line in ipairs(lines) do
			line = strip_ansi_codes(line)
			if stream_type == "stderr" then
				lines[i] = "[ERROR] " .. line
			else
				lines[i] = line
			end
		end

		-- Append to task logs
		vim.list_extend(M.task_logs[task_id].lines, lines)

		-- Update display if this is the current task
		if M.current_task_id == task_id and M.is_open() then
			M.refresh_display()
		end
	end)
end

-- Switch to a different task's logs
function M.switch_to_task(task_id)
	M.current_task_id = task_id

	if not M.task_logs[task_id] then
		M.task_logs[task_id] = {
			lines = { string.format("=== Task ID: %d (no output yet) ===", task_id), "" },
		}
	end

	M.refresh_display()
end

-- Refresh display with current task's logs
function M.refresh_display()
	if not M.is_open() then
		return
	end

	local bufnr = get_or_create_log_buffer()
	local task_log = M.task_logs[M.current_task_id]

	if not task_log then
		return
	end

	-- Make buffer modifiable
	vim.api.nvim_buf_set_option(bufnr, "modifiable", true)

	-- Set lines
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, task_log.lines)

	-- Make buffer read-only
	vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

	-- Auto-scroll to bottom
	if M.auto_scroll and M.log_winnr and vim.api.nvim_win_is_valid(M.log_winnr) then
		local line_count = vim.api.nvim_buf_line_count(bufnr)
		vim.api.nvim_win_set_cursor(M.log_winnr, { line_count, 0 })
	end
end

-- Clear current task's log
function M.clear_current_log()
	if not M.current_task_id then
		return
	end

	local task_log = M.task_logs[M.current_task_id]
	if task_log then
		local header = task_log.lines[1]
		M.task_logs[M.current_task_id].lines = { header, "" }
		M.refresh_display()
		vim.notify("Cleared log for task ID: " .. M.current_task_id, vim.log.levels.INFO)
	end
end

-- Clear all logs
function M.clear_all_logs()
	M.task_logs = {}
	M.current_task_id = nil

	if M.is_open() then
		local bufnr = get_or_create_log_buffer()
		vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "=== No active task ===" })
		vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
	end

	vim.notify("Cleared all logs", vim.log.levels.INFO)
end

-- Get log callback for task manager
function M.get_log_callback()
	return function(task_id, data, stream_type)
		M.append_output(task_id, data, stream_type)
	end
end

-- Show help in log window
function M.show_help()
	if not M.is_open() then
		M.open()
	end

	local bufnr = get_or_create_log_buffer()
	vim.api.nvim_buf_set_option(bufnr, "modifiable", true)

	local help_text = {
		"=== Run Configurations - Log Console Help ===",
		"",
		"Keybindings:",
		"  q - Close this window",
		"  c - Clear current task's log",
		"  a - Toggle auto-scroll",
		"",
		"Commands:",
		"  :ShowLogsConsole [task_name] - Show logs for specific task",
		"  :ToggleLogsConsole - Toggle log window",
		"  :RunConfiguration <name> - Run a configuration",
		"  :RunConfigurations - Open configuration picker",
		"  :ShowActiveBackgroundTasks - List running tasks",
		"",
		"Press 'q' to close this help",
	}

	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, help_text)
	vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
end

return M
