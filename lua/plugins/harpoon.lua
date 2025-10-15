return {
	"ThePrimeagen/harpoon",
	branch = "harpoon2",
	event = "VeryLazy",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	config = function()
		local harpoon = require("harpoon")

		harpoon.setup({})
		local conf = require("telescope.config").values
		local function toggle_telescope(harpoon_files)
			local file_paths = {}
			for _, item in ipairs(harpoon_files.items) do
				table.insert(file_paths, item.value)
			end

			require("telescope.pickers")
				.new({}, {
					prompt_title = "Harpoon",
					finder = require("telescope.finders").new_table({
						results = file_paths,
					}),
					previewer = conf.file_previewer({}),
					sorter = conf.generic_sorter({}),
				})
				:find()
		end

		vim.keymap.set("n", "<leader>a", function()
			harpoon:list():add()
		end)

		vim.keymap.set("n", "<S-TAB>", function()
			toggle_telescope(harpoon:list())
		end)

		-- Toggle previous & next buffers stored within Harpoon list
		-- vim.keymap.set("n", "<C-S-P>", function()
		-- 	harpoon:list():prev()
		-- end)
		-- vim.keymap.set("n", "<C-S-N>", function()
		-- 	harpoon:list():next()
		-- end)
		-- Set a vim motion to <Shift>m to mark a file with harpoon
		--vim.keymap.set("n", "<s-m>", "<cmd>lua require('harpoon.mark').add_file()<cr>", {desc = "Harpoon Mark File"})
		-- Set a vim motion to the tab key to open the harpoon menu to easily navigate frequented files
		--vim.keymap.set("n", "<TAB>", "<cmd>lua require('harpoon.ui').toggle_quick_menu()<cr>", {desc = "Harpoon Toggle Menu"})
	end,
}
