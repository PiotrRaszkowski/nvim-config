return {
    {
        "lewis6991/gitsigns.nvim",
        config = function()
            -- setup gitsigns with default properties
            require("gitsigns").setup({})

            -- Set a vim motion to <Space> + g + h to preview changes to the file under the cursor in normal mode
            vim.keymap.set("n", "<leader>gh", ":Gitsigns preview_hunk<CR>", { desc = "Preview [H]unk" })
            vim.keymap.set("n", "<leader>gB", ":Gitsigns blame<CR>", { desc = "[B]lame" })
        end,
    },
    {
        "NeogitOrg/neogit",
        dependencies = {
            "nvim-lua/plenary.nvim", -- required
            "sindrets/diffview.nvim", -- optional - Diff integration
            "nvim-telescope/telescope.nvim", -- optional
        },
        config = function()
            local neogit = require("neogit")

            vim.keymap.set("n", "<leader>gn", "<cmd>Neogit<CR>", { desc = "[N]eogit" })


            neogit.setup({
                integrations = {
                    telescope = true,
                    diffview = true
                },
            })
        end,
    },
    {
        "kdheepak/lazygit.nvim",
        lazy = true,
        cmd = {
            "LazyGit",
            "LazyGitConfig",
            "LazyGitCurrentFile",
            "LazyGitFilter",
            "LazyGitFilterCurrentFile",
        },
        config = function ()
            vim.g.lazygit_floating_window_use_plenary = 1

            require("telescope").load_extension("lazygit")
        end,
        -- optional for floating window border decoration
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-telescope/telescope.nvim",
        },
        -- setting the keybinding for LazyGit with 'keys' is recommended in
        -- order to load the plugin when the command is run for the first time
        keys = {
            { "<leader>gl", "<cmd>LazyGit<cr>", desc = "[L]azyGit" },
        },
    },
}
