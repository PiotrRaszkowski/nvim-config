return {
	"numToStr/Comment.nvim",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		-- Set a vim motion to <Space> + / to comment the line under the cursor in normal mode
		vim.keymap.set("n", "<leader>/", "<Plug>(comment_toggle_linewise_current)", { desc = "Comment Line" })
		-- Set a vim motion to <Space> + / to comment all the lines selected in visual mode
		vim.keymap.set("v", "<leader>/", "<Plug>(comment_toggle_linewise_visual)", { desc = "Comment Selected" })

		-- Setup Comment.nvim with Treesitter integration
		-- Neovim 0.10+ has built-in commentstring support via Treesitter
		-- No need for nvim-ts-context-commentstring plugin anymore
		require("Comment").setup({
			-- Comment.nvim automatically uses Treesitter's built-in commentstring
			-- Just use default configuration
		})
	end,
}
