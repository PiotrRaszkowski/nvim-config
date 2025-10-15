-- nvim-dbee - Interactive database client for Neovim
-- Supports SQLite, MySQL, PostgreSQL, and more
-- Backend written in Go, frontend in Lua
return {
	"kndndrj/nvim-dbee",
	dependencies = {
		"MunifTanjim/nui.nvim",
	},
	build = function()
		-- Install the dbee backend (Go binary)
		require("dbee").install()
	end,
	config = function()
		require("dbee").setup({
			-- Sources for database connections
			-- Can use files, environment variables, or manual configuration
			sources = {
				-- Load connections from a JSON file
				-- Create ~/.local/share/nvim/dbee/connections.json with your connections
				require("dbee.sources").FileSource:new(vim.fn.stdpath("data") .. "/dbee/connections.json"),
				-- Or use environment variables
				require("dbee.sources").EnvSource:new("DBEE_CONNECTIONS"),
			},
			-- Optional: Configure the drawer (connection list panel)
			drawer = {
				-- Drawer width
				width = 30,
				-- Position: left or right
				position = "left",
			},
			-- Optional: Result window configuration
			result = {
				-- Window position: tab, split, vsplit, float
				window_type = "split",
				-- Window position when using split/vsplit
				window_position = "bottom",
				-- Window size (for split/vsplit)
				window_size = 15,
			},
		})

		-- Keymaps for dbee
		vim.keymap.set("n", "<leader>Dt", "<cmd>lua require('dbee').toggle()<cr>", { desc = "[D]atabase [T]oggle UI" })
		vim.keymap.set("n", "<leader>De", "<cmd>lua require('dbee').execute()<cr>", { desc = "[D]atabase [E]xecute Query" })
		vim.keymap.set(
			"n",
			"<leader>Ds",
			"<cmd>lua require('dbee').store()<cr>",
			{ desc = "[D]atabase [S]ave Results" }
		)
		vim.keymap.set("n", "<leader>Dc", "<cmd>lua require('dbee').close()<cr>", { desc = "[D]atabase [C]lose" })
	end,
}
