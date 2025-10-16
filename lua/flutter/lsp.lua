-- LSP: Standalone Dart LSP configuration (no flutter-tools dependency)
local M = {}

-- Setup Dart LSP
function M.setup()
	local device_manager = require("flutter.device-manager")

	-- Get Flutter SDK path
	local flutter_sdk = device_manager.get_flutter_sdk()
	if not flutter_sdk then
		vim.notify("Flutter SDK not found. Dart LSP may not work correctly.", vim.log.levels.WARN)
		return
	end

	-- Configure Dart LSP using modern vim.lsp.config API
	vim.lsp.config("dartls", {
		cmd = { "dart", "language-server", "--protocol=lsp" },
		filetypes = { "dart" },
		root_markers = { "pubspec.yaml", ".git" },
		settings = {
			dart = {
				enableSdkFormatter = true,
				lineLength = 80,
				completeFunctionCalls = true,
				showTodos = true,
			},
		},
	})

	-- Enable Dart LSP on Dart files
	vim.api.nvim_create_autocmd("FileType", {
		pattern = "dart",
		callback = function(args)
			vim.lsp.enable("dartls", args.buf)

			-- Set Dart-specific options
			vim.opt_local.tabstop = 2
			vim.opt_local.shiftwidth = 2
			vim.opt_local.expandtab = true
			vim.opt_local.colorcolumn = "80"
		end,
	})
end

return M
