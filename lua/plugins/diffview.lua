return {
    {
        "sindrets/diffview.nvim",
        config = function()
            vim.keymap.set("n", "<leader>gd", "<cmd>DiffviewOpen<CR>", { desc = "[D]iff" })
        end
    }
}
