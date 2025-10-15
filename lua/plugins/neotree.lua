return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
		"MunifTanjim/nui.nvim",
		-- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
	},
	config = function()
		-- Configure diagnostic signs using modern API
		vim.diagnostic.config({
			signs = {
				text = {
					[vim.diagnostic.severity.ERROR] = " ",
					[vim.diagnostic.severity.WARN] = " ",
					[vim.diagnostic.severity.INFO] = " ",
					[vim.diagnostic.severity.HINT] = "󰌵",
				},
			},
		})

		require("neo-tree").setup({
			close_if_last_window = true, -- Close Neo-tree if it's the last window
			popup_border_style = "rounded",
			enable_git_status = true,
			enable_diagnostics = true,

			-- Prevent files from opening in neo-tree window
			open_files_do_not_replace_types = { "terminal", "trouble", "qf", "edgy" },

			-- Move focus to opened file instead of closing neo-tree
			event_handlers = {
				{
					event = "file_opened",
					handler = function(file_path)
						-- Move focus to the opened file window
						vim.schedule(function()
							vim.cmd("wincmd p") -- Go to previous window (the opened file)
						end)
					end,
				},
			},

			filesystem = {
				-- Control directory opening behavior
				hijack_netrw_behavior = "open_default", -- "open_default", "open_current", "disabled"

				filtered_items = {
					visible = true, -- Show hidden files by default
					hide_dotfiles = false,
					hide_gitignored = false,
					hide_by_name = {
						".DS_Store",
						"thumbs.db",
						".git",
					},
				},
				follow_current_file = {
					enabled = true, -- Find and focus current file
					leave_dirs_open = false, -- Close dirs when moving to another file
				},
				use_libuv_file_watcher = true, -- Auto-refresh on external file changes
			},

			window = {
				position = "left", -- Explicit left positioning
				width = 40,
				mappings = {
					["<space>"] = "none", -- Disable space to avoid conflict with leader key
				},
			},

			default_component_configs = {
				git_status = {
					symbols = {
						added = "✚",
						modified = "",
						deleted = "✖",
						renamed = "󰁕",
						untracked = "",
						ignored = "",
						unstaged = "󰄱",
						staged = "",
						conflict = "",
					},
				},
			},
		})

		-- Neo-tree keymaps
		vim.keymap.set("n", "<leader>ee", "<cmd>Neotree toggle reveal<CR>", { desc = "[E]xplorer Toggle" })
		vim.keymap.set("n", "<leader>ef", "<cmd>Neotree focus<CR>", { desc = "[E]xplorer [F]ocus" })
		vim.keymap.set("n", "<leader>ec", "<cmd>Neotree close<CR>", { desc = "[E]xplorer [C]lose" })
	end,
}
