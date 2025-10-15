-- DevRun Plugin
-- Development task runner for Spring Boot/Gradle projects with JSON-based configurations
return {
	dir = vim.fn.stdpath("config"),
	name = "devrun",
	lazy = false,
	dependencies = {
		"nvim-telescope/telescope.nvim", -- For configuration picker
	},
	config = function()
		local devrun = require("devrun")

		-- Initialize the plugin
		devrun.setup()

		-- Keymaps under <leader>R prefix (Run)
		vim.keymap.set("n", "<leader>Rr", "<cmd>DevRun<cr>", { desc = "[R]un [D]evRun picker" })
		vim.keymap.set("n", "<leader>Rt", "<cmd>DevRunTasks<cr>", { desc = "[R]un Show [T]asks" })
		vim.keymap.set("n", "<leader>Rl", "<cmd>DevRunToggleLogs<cr>", { desc = "[R]un Toggle [L]ogs" })
		vim.keymap.set("n", "<leader>Rs", "<cmd>DevRunStop<cr>", { desc = "[R]un [S]top task" })
		vim.keymap.set("n", "<leader>RR", "<cmd>DevRunReload<cr>", { desc = "[R]un [R]eload configs" })
		vim.keymap.set("n", "<leader>RI", "<cmd>DevRunInit<cr>", { desc = "[R]un [I]nit example config" })
		vim.keymap.set("n", "<leader>RA", "<cmd>DevRunAddRunConfiguration<cr>", { desc = "[R]un [A]dd configuration" })
	end,
}
