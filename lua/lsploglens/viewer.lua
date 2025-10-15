-- LspLogLens Viewer
-- Formatted LSP log viewing functionality
local utils = require("lsploglens.utils")
local M = {}

-- Open raw LSP log file
function M.open_log()
	local log_path = utils.get_log_path()
	vim.cmd("edit " .. log_path)
end

-- Tail LSP log in real-time
function M.tail_log()
	local log_path = utils.get_log_path()
	vim.cmd("botright 15split | term tail -f " .. vim.fn.shellescape(log_path))
end

-- Show last N errors/warnings
function M.show_errors(count)
	count = count or 50
	local log_path = utils.get_log_path()
	vim.cmd(
		string.format(
			'botright 15split | term grep -a "ERROR\\|WARN" %s | tail -%d',
			vim.fn.shellescape(log_path),
			count
		)
	)
end

-- Show formatted log with timestamps and separators
function M.show_formatted()
	local log_path = utils.get_log_path()

	-- Read log file
	local lines = vim.fn.readfile(log_path)
	local formatted_lines = {}
	local current_entry = {}

	-- Process log entries
	for _, line in ipairs(lines) do
		local timestamp = utils.format_timestamp(line)

		if timestamp then
			-- New log entry, process previous entry
			if #current_entry > 0 then
				table.insert(formatted_lines, "")
				table.insert(formatted_lines, string.rep("─", 80))
				vim.list_extend(formatted_lines, current_entry)
			end

			-- Start new entry
			current_entry = { timestamp }
		else
			-- Continuation of current entry
			table.insert(current_entry, line)
		end
	end

	-- Add last entry
	if #current_entry > 0 then
		table.insert(formatted_lines, "")
		table.insert(formatted_lines, string.rep("─", 80))
		vim.list_extend(formatted_lines, current_entry)
	end

	-- Create buffer
	local buf = utils.create_read_only_buffer("LSP Log (Formatted)", formatted_lines, "log")

	-- Open in split
	utils.open_in_split(buf)

	-- Add keymaps
	utils.add_buffer_keymaps(buf, {
		r = {
			callback = function()
				vim.cmd("close")
				M.show_formatted()
			end,
			desc = "Refresh log",
		},
	})

	vim.notify("LSP log formatted. Press 'q' to close, 'r' to refresh", vim.log.levels.INFO)
end

-- Show only JDTLS-related logs
function M.show_jdtls_logs()
	local log_path = utils.get_log_path()
	vim.cmd(
		string.format(
			'botright 15split | term grep -a "jdtls\\|eclipse.jdt" %s | tail -100',
			vim.fn.shellescape(log_path)
		)
	)
end

-- Clear LSP log file
function M.clear_log()
	local log_path = utils.get_log_path()
	vim.fn.writefile({}, log_path)
	vim.notify("LSP log cleared", vim.log.levels.INFO)
end

-- Show log file information
function M.show_info()
	local log_path = utils.get_log_path()
	local size_bytes, size_mb = utils.get_log_size()
	local line_count = utils.get_log_line_count()

	vim.notify(
		string.format("LSP Log Info:\nPath: %s\nSize: %.2f MB\nLines: %s", log_path, size_mb, line_count),
		vim.log.levels.INFO
	)
end

return M
