-- LspLogLens Plugin
-- Advanced LSP log viewing and AI-powered analysis
return {
	dir = vim.fn.stdpath("config"),
	name = "lsploglens",
	dependencies = {},
	config = function()
		local lsploglens = require("lsploglens")
		lsploglens.setup()

		-- Keybindings under <leader>L prefix
		vim.keymap.set("n", "<leader>Ll", "<cmd>LspLogLensOpen<cr>", { desc = "[L]sp [L]og open" })
		vim.keymap.set("n", "<leader>Lt", "<cmd>LspLogLensTail<cr>", { desc = "[L]sp Log [T]ail" })
		vim.keymap.set("n", "<leader>Lf", "<cmd>LspLogLensFormatted<cr>", { desc = "[L]sp Log [F]ormatted" })
		vim.keymap.set("n", "<leader>Le", "<cmd>LspLogLensErrors<cr>", { desc = "[L]sp Log [E]rrors" })
		vim.keymap.set("n", "<leader>Lj", "<cmd>LspLogLensJdtls<cr>", { desc = "[L]sp Log [J]dtls" })
		vim.keymap.set("n", "<leader>Lx", "<cmd>LspLogLensExplain<cr>", { desc = "[L]sp Log E[x]plain AI" })
		vim.keymap.set("n", "<leader>La", "<cmd>LspLogLensAnalyze<cr>", { desc = "[L]sp Log [A]nalyze buffer" })
		vim.keymap.set("n", "<leader>Lc", "<cmd>LspLogLensClear<cr>", { desc = "[L]sp Log [C]lear" })
		vim.keymap.set("n", "<leader>Li", "<cmd>LspLogLensInfo<cr>", { desc = "[L]sp Log [I]nfo" })
	end,
}
