return {
	"nvim-treesitter/nvim-treesitter",
	dependencies = {
		-- ts-autotag utilizes treesitter to understand the code structure to automatically close tsx tags
		"windwp/nvim-ts-autotag",
	},
	-- when the plugin builds run the TSUpdate command to ensure all our servers are installed and updated
	build = ":TSUpdate",
	config = function()
		-- gain access to the treesitter config functions
		local ts_config = require("nvim-treesitter.configs")

		-- call the treesitter setup function with properties to configure our experience
		ts_config.setup({
			-- make sure we have vim, vimdoc, lua, java, javascript, typescript, html, css, json, tsx, markdown, markdown, inline markdown, gitignore, and dart highlighting servers
			ensure_installed = {
				"vim",
				"vimdoc",
				"lua",
				"java",
				"javascript",
				"typescript",
				"html",
				"css",
				"json",
				"tsx",
				"markdown",
				"markdown_inline",
				"gitignore",
				"dart", -- Flutter/Dart support
			},
			-- make sure highlighting is enabled
			highlight = { enable = true },
			-- NOTE: autotag config moved to nvim-ts-autotag plugin directly
			-- See the plugin configuration below
		})

		-- Setup nvim-ts-autotag separately (breaking change in recent versions)
		require("nvim-ts-autotag").setup({
			opts = {
				-- Defaults
				enable_close = true, -- Auto close tags
				enable_rename = true, -- Auto rename pairs of tags
				enable_close_on_slash = false, -- Auto close on trailing </
			},
			-- Also override individual filetype configs, these take priority.
			-- Empty by default, useful if one of the "opts" global settings
			-- doesn't work well in a specific filetype
			per_filetype = {
				["html"] = {
					enable_close = true,
				},
			},
		})
	end,
}
