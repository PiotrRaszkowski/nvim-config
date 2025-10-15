-- LspLogLens: Advanced LSP log viewing and analysis
local M = {}

local viewer = require("lsploglens.viewer")
local analyzer = require("lsploglens.analyzer")

-- Setup function
function M.setup()
	M.create_commands()
	vim.notify("LspLogLens loaded", vim.log.levels.INFO)
end

-- Create all user commands
function M.create_commands()
	-- Basic log viewing commands
	vim.api.nvim_create_user_command("LspLogLensOpen", function()
		viewer.open_log()
	end, { desc = "LspLogLens: Open LSP log file" })

	vim.api.nvim_create_user_command("LspLogLensTail", function()
		viewer.tail_log()
	end, { desc = "LspLogLens: Tail LSP log in real-time" })

	vim.api.nvim_create_user_command("LspLogLensErrors", function(opts)
		local count = opts.args ~= "" and tonumber(opts.args) or 50
		viewer.show_errors(count)
	end, {
		nargs = "?",
		desc = "LspLogLens: Show last N errors/warnings (default 50)",
	})

	-- Formatted viewing commands
	vim.api.nvim_create_user_command("LspLogLensFormatted", function()
		viewer.show_formatted()
	end, { desc = "LspLogLens: Open formatted LSP log" })

	vim.api.nvim_create_user_command("LspLogLensJdtls", function()
		viewer.show_jdtls_logs()
	end, { desc = "LspLogLens: Show last 100 JDTLS log entries" })

	-- Log management commands
	vim.api.nvim_create_user_command("LspLogLensClear", function()
		viewer.clear_log()
	end, { desc = "LspLogLens: Clear LSP log file" })

	vim.api.nvim_create_user_command("LspLogLensInfo", function()
		viewer.show_info()
	end, { desc = "LspLogLens: Show LSP log info (size, location)" })

	-- AI analysis commands
	vim.api.nvim_create_user_command("LspLogLensExplain", function(opts)
		local count = opts.args ~= "" and tonumber(opts.args) or 10
		analyzer.explain_errors(count)
	end, {
		nargs = "?",
		desc = "LspLogLens: Explain last N LSP errors with AI (default 10)",
	})

	vim.api.nvim_create_user_command("LspLogLensAnalyze", function()
		analyzer.analyze_buffer()
	end, { desc = "LspLogLens: Analyze current buffer's diagnostics with AI" })
end

-- Export submodules for direct access if needed
M.viewer = viewer
M.analyzer = analyzer

return M
