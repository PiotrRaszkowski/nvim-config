-- LspLogLens Utilities
-- Shared helper functions for LSP log operations
local M = {}

-- Get LSP log file path
function M.get_log_path()
	return vim.lsp.get_log_path()
end

-- Format timestamp from log line
function M.format_timestamp(line)
	-- Extract timestamp pattern like [ERROR][2025-10-14 15:47:50]
	local level, date, time = line:match("%[([A-Z]+)%]%[(%d+-%d+-%d+) (%d+:%d+:%d+)%]")
	if level and date and time then
		return string.format("[%s] %s %s", level, date, time)
	end
	return nil
end

-- Try to format JSON
function M.try_format_json(text)
	local ok, parsed = pcall(vim.json.decode, text)
	if ok then
		return vim.inspect(parsed)
	end
	return text
end

-- Create a read-only buffer with content
function M.create_read_only_buffer(name, lines, filetype)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(buf, "swapfile", false)
	vim.api.nvim_buf_set_option(buf, "filetype", filetype or "log")
	vim.api.nvim_buf_set_name(buf, name)

	-- Set lines
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	-- Make read-only
	vim.api.nvim_buf_set_option(buf, "modifiable", false)

	return buf
end

-- Open buffer in split
function M.open_in_split(buf, position, size)
	position = position or "botright"
	size = size or 15

	vim.cmd(string.format("%s %dsplit", position, size))
	vim.api.nvim_win_set_buf(0, buf)

	return vim.api.nvim_get_current_win()
end

-- Add common keymaps to buffer
function M.add_buffer_keymaps(buf, extra_maps)
	-- Close with 'q'
	vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, desc = "Close window" })

	-- Add extra keymaps if provided
	if extra_maps then
		for key, action in pairs(extra_maps) do
			vim.keymap.set("n", key, action.callback, { buffer = buf, desc = action.desc })
		end
	end
end

-- Get log file size
function M.get_log_size()
	local log_path = M.get_log_path()
	local size = vim.fn.getfsize(log_path)
	return size, size / (1024 * 1024) -- bytes, MB
end

-- Get log line count
function M.get_log_line_count()
	local log_path = M.get_log_path()
	local cmd = string.format("wc -l < %s", vim.fn.shellescape(log_path))
	local lines = vim.fn.system(cmd)
	return vim.trim(lines)
end

-- Extract last N errors from log
function M.get_recent_errors(count)
	local log_path = M.get_log_path()
	local cmd = string.format('grep -a "ERROR\\|WARN" %s | tail -%d', vim.fn.shellescape(log_path), count)

	local result = vim.fn.system(cmd)
	if vim.v.shell_error ~= 0 then
		return nil, "Failed to read LSP log"
	end

	if result == "" or result == nil then
		return nil, "No errors or warnings found in LSP log"
	end

	return result, nil
end

return M
