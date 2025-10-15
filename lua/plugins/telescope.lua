return {
	{
		"nvim-telescope/telescope.nvim",
		-- pull a specific version of the plugin
		-- tag = '0.1.6',
		dependencies = {
			-- general purpose plugin used to build user interfaces in neovim plugins
			"nvim-lua/plenary.nvim",
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		},
		config = function()
			-- get access to telescopes built in functions
			local builtin = require("telescope.builtin")

			-- ==================== FILE SYSTEM ====================
			vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "[F]ind [F]iles" })
			vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "[F]ind [G]rep" })
			vim.keymap.set("n", "<leader>fd", builtin.diagnostics, { desc = "[F]ind [D]iagnostics" })
			vim.keymap.set("n", "<leader>fr", builtin.resume, { desc = "[F]inder [R]esume" })
			vim.keymap.set("n", "<leader>f.", builtin.oldfiles, { desc = '[F]ind Recent Files ("." for repeat)' })
			vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "[F]ind [B]uffers" })
			vim.keymap.set("n", "<leader>fs", builtin.current_buffer_fuzzy_find, { desc = "[F]ind [S]tring" })
			vim.keymap.set("n", "<leader>fq", builtin.quickfix, { desc = "[F]ind [Q]uicklist" })
			vim.keymap.set("n", "<leader>fQ", builtin.quickfixhistory, { desc = "[F]ind [Q]uicklist History" })

			-- ==================== GIT ====================
			vim.keymap.set("n", "<leader>gs", builtin.git_status, { desc = "Git [S]tatus" })
			vim.keymap.set("n", "<leader>gb", builtin.git_branches, { desc = "Git [B]ranches" })

			-- ==================== LSP ====================
			vim.keymap.set("n", "<leader>fI", builtin.lsp_implementations, { desc = "[F]ind [I]mplementations" })
			vim.keymap.set("n", "<leader>fR", builtin.lsp_references, { desc = "[F]ind [R]eferences" })
			vim.keymap.set("n", "<leader>fD", builtin.lsp_definitions, { desc = "[F]ind [D]efinitions" })
			vim.keymap.set("n", "<leader>fT", builtin.lsp_type_definitions, { desc = "[F]ind [T]ype Definitions" })

			vim.keymap.set("n", "<leader>fS", builtin.lsp_document_symbols, { desc = "[F]ind Document [S]ymbols" })
		end,
	},
	{
		"nvim-telescope/telescope-ui-select.nvim",
		config = function()
			-- get access to telescopes navigation functions
			local actions = require("telescope.actions")
			local telescope = require("telescope")

			telescope.load_extension("fzf")

			require("telescope").setup({
				-- use ui-select dropdown as our ui
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown({}),
					},
				},
				defaults = {
					path_display = { "smart" },
					-- set keymappings to navigate through items in the telescope io
					mappings = {
						i = {
							-- use <cltr> + n to go to the next option
							["<C-n>"] = actions.cycle_history_next,
							-- use <cltr> + p to go to the previous option
							["<C-p>"] = actions.cycle_history_prev,
							-- use <cltr> + j to go to the next preview
							["<C-j>"] = actions.move_selection_next,
							-- use <cltr> + k to go to the previous preview
							["<C-k>"] = actions.move_selection_previous,

							["<C-a>"] = actions.send_to_qflist + actions.open_qflist,
							["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
						},
					},
				},
				-- load the ui-select extension
				require("telescope").load_extension("ui-select"),
			})
		end,
	},
}
