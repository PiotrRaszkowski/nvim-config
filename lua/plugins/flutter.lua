-- Flutter Tools Plugin
-- Simple Flutter development support for Neovim
-- Handles Dart LSP, Flutter SDK, hot reload, and DevTools

return {
	"akinsho/flutter-tools.nvim",
	lazy = false,
	dependencies = {
		"nvim-lua/plenary.nvim",
		"stevearc/dressing.nvim", -- optional for better UI
	},
	config = function()
		local flutter_tools = require("flutter-tools")

		flutter_tools.setup({
			-- Development log settings
			dev_log = {
				enabled = true,
				open_cmd = "botright 15split", -- Open in bottom split
			},

			-- Dart LSP configuration
			lsp = {
				-- LSP capabilities (integrates with nvim-cmp)
				capabilities = function(config)
					local cmp_nvim_lsp = require("cmp_nvim_lsp")
					config.capabilities = vim.tbl_deep_extend(
						"force",
						config.capabilities or vim.lsp.protocol.make_client_capabilities(),
						cmp_nvim_lsp.default_capabilities()
					)
					return config.capabilities
				end,
			},

			-- DAP (Debug Adapter Protocol) configuration
			debugger = {
				enabled = false, -- Don't auto-open DAP when running Flutter
			},
		})

		-- ============================================================================
		-- Flutter Keymaps
		-- ============================================================================
		-- All Flutter commands use <leader>F prefix

		local keymap = vim.keymap.set
		local opts = { noremap = true, silent = true }

		-- Flutter run and reload
		keymap("n", "<leader>Fr", "<cmd>FlutterRun<cr>", vim.tbl_extend("force", opts, { desc = "[F]lutter [R]un" }))
		keymap("n", "<leader>Fq", "<cmd>FlutterQuit<cr>", vim.tbl_extend("force", opts, { desc = "[F]lutter [Q]uit" }))
		keymap("n", "<leader>FR", "<cmd>FlutterRestart<cr>", vim.tbl_extend("force", opts, { desc = "[F]lutter [R]estart" }))
		keymap("n", "<leader>Fh", "<cmd>FlutterReload<cr>", vim.tbl_extend("force", opts, { desc = "[F]lutter [H]ot Reload" }))

		-- Flutter devices and emulators
		keymap("n", "<leader>Fd", "<cmd>FlutterDevices<cr>", vim.tbl_extend("force", opts, { desc = "[F]lutter [D]evices" }))
		keymap("n", "<leader>Fe", "<cmd>FlutterEmulators<cr>", vim.tbl_extend("force", opts, { desc = "[F]lutter [E]mulators" }))

		-- Flutter DevTools
		keymap("n", "<leader>FT", "<cmd>FlutterDevTools<cr>", vim.tbl_extend("force", opts, { desc = "[F]lutter Dev[T]ools" }))

		-- Flutter outline and logs
		keymap("n", "<leader>Fo", "<cmd>FlutterOutlineToggle<cr>", vim.tbl_extend("force", opts, { desc = "[F]lutter [O]utline Toggle" }))
		keymap("n", "<leader>FL", "<cmd>FlutterLogToggle<cr>", vim.tbl_extend("force", opts, { desc = "[F]lutter [L]og Toggle" }))
		keymap("n", "<leader>Fl", "<cmd>FlutterLogClear<cr>", vim.tbl_extend("force", opts, { desc = "[F]lutter [L]og Clear" }))

		-- Flutter pub commands
		keymap("n", "<leader>Fp", "<cmd>FlutterPubGet<cr>", vim.tbl_extend("force", opts, { desc = "[F]lutter [P]ub Get" }))
		keymap("n", "<leader>FP", "<cmd>FlutterPubUpgrade<cr>", vim.tbl_extend("force", opts, { desc = "[F]lutter [P]ub Upgrade" }))

		-- Flutter copy profiler URL
		keymap("n", "<leader>Fc", "<cmd>FlutterCopyProfilerUrl<cr>", vim.tbl_extend("force", opts, { desc = "[F]lutter [C]opy Profiler URL" }))

		-- Flutter LSP restart
		keymap("n", "<leader>Fs", "<cmd>FlutterLspRestart<cr>", vim.tbl_extend("force", opts, { desc = "[F]lutter LSP Re[s]tart" }))

		-- Flutter rename (creates both .dart and corresponding test file)
		keymap("n", "<leader>Fn", "<cmd>FlutterRename<cr>", vim.tbl_extend("force", opts, { desc = "[F]lutter Re[n]ame" }))

		-- ============================================================================
		-- Dart-specific settings
		-- ============================================================================
		-- Set up Dart-specific options when opening Dart files
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "dart",
			callback = function()
				-- Set Dart-specific options
				vim.opt_local.tabstop = 2
				vim.opt_local.shiftwidth = 2
				vim.opt_local.expandtab = true
				vim.opt_local.colorcolumn = "80" -- Dart style guide recommends 80 chars
			end,
		})
	end,
}
