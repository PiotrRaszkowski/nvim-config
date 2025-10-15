return {
	"coder/claudecode.nvim",
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		require("claudecode").setup({
			-- Server configuration
			auto_start = true,
			log_level = "info",

			-- Terminal configuration
			terminal = {
				split_side = "right", -- Open on right side
				split_width_percentage = 0.30, -- 30% of window width
				provider = "auto", -- Auto-detect best terminal provider
				auto_close = false, -- Keep terminal open after commands
			},

			-- Diff integration
			diff_opts = {
				auto_close_on_accept = true, -- Auto-close diff after accepting changes
				vertical_split = true, -- Use vertical split for diffs
				open_in_current_tab = true, -- Open diffs in current tab
				keep_terminal_focus = false, -- Move focus to diff window
			},
		})

		-- Custom keymaps (using <leader>A prefix for AI/Claude to avoid conflicts with LSP <leader>c)
		vim.keymap.set("n", "<C-,>", "<cmd>ClaudeCode<cr>", { desc = "Toggle Claude Code" })
		vim.keymap.set("t", "<C-,>", "<cmd>ClaudeCode<cr>", { desc = "Toggle Claude Code" })

		vim.keymap.set("n", "<leader>Ac", "<cmd>ClaudeCode<cr>", { desc = "[A]I - Toggle [C]laude" })
		vim.keymap.set("n", "<leader>AC", "<cmd>ClaudeCode --continue<cr>", { desc = "[A]I - [C]ontinue conversation" })
		vim.keymap.set("n", "<leader>Af", "<cmd>ClaudeCodeFocus<cr>", { desc = "[A]I - [F]ocus Claude" })
		vim.keymap.set("n", "<leader>Ar", "<cmd>ClaudeCode --resume<cr>", { desc = "[A]I - [R]esume session" })
		vim.keymap.set("n", "<leader>Am", "<cmd>ClaudeCodeSelectModel<cr>", { desc = "[A]I - Select [M]odel" })
		vim.keymap.set("n", "<leader>Ab", "<cmd>ClaudeCodeAdd %<cr>", { desc = "[A]I - Add [B]uffer" })
		vim.keymap.set("v", "<leader>As", "<cmd>ClaudeCodeSend<cr>", { desc = "[A]I - [S]end selection" })
	end,
}
