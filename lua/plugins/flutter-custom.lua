-- Custom Flutter Plugin
-- Replaces flutter-tools.nvim with Telescope-integrated custom solution
return {
	{
		-- Custom Flutter plugin (local)
		dir = vim.fn.stdpath("config") .. "/lua/flutter",
		name = "flutter-custom",
		lazy = false,
		dependencies = {
			"nvim-telescope/telescope.nvim",
			"nvim-lua/plenary.nvim",
		},
		config = function()
			require("flutter").setup({
				-- Add any custom options here
			})
		end,
	},
}
