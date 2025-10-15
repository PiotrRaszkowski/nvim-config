return({
	"nvim-pack/nvim-spectre",
	config = function()
		require("spectre").setup({ is_block_ui_break = true })
		vim.keymap.set("n", "<leader>S", '<cmd>lua require("spectre").toggle()<CR>', {
			desc = "Toggle Spectre",
		})
	end,
})
