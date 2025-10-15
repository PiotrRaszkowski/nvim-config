return {
    {
        -- Shortened Github Url
        "Mofiqul/dracula.nvim",
        lazy = false,
        priority = 1000,
        enabled = false,
        config = function()
            -- Make sure to set the color scheme when neovim loads and configures the dracula plugin
            vim.cmd.colorscheme("dracula")
        end,
    },
    {
        "baliestri/aura-theme",
        lazy = false,
        priority = 1000,
        enabled = false,
        config = function(plugin)
            vim.opt.rtp:append(plugin.dir .. "/packages/neovim")
            vim.cmd([[colorscheme aura-dark]])
        end,
    },
    {
        "navarasu/onedark.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            require("onedark").setup({
                style = "darker",
            })
            require("onedark").load()
        end,
    },
}
