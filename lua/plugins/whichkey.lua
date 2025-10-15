return {
    "folke/which-key.nvim",
    event = "VimEnter",
    config = function()
        -- gain access to the which key plugin
        local which_key = require("which-key")

        -- call the setup function with default properties
        which_key.setup()

        -- Register prefixes for the different key mappings we have setup previously
        -- which_key.register({
        --     ["<leader>/"] = { name = "Comments", _ = "which_key_ignore" },
        --     ["<leader>c"] = { name = "[C]ode", _ = "which_key_ignore" },
        --     ["<leader>d"] = { name = "[D]ebug", _ = "which_key_ignore" },
        --     ["<leader>e"] = { name = "[E]xplorer", _ = "which_key_ignore" },
        --     ["<leader>f"] = { name = "[F]ind", _ = "which_key_ignore" },
        --     ["<leader>g"] = { name = "[G]it", _ = "which_key_ignore" },
        --     ["<leader>J"] = { name = "[J]ava", _ = "which_key_ignore" },
        --     ["<leader>w"] = { name = "[W]indow", _ = "which_key_ignore" },
        -- })

        which_key.add({
            { "<leader>a",  group = "[A]dd to Harpoon" },
            { "<leader>a_", hidden = true },
            { "<leader>A",  group = "[A]I/Claude Code" },
            { "<leader>A_", hidden = true },
            { "<leader>/",  group = "Comments" },
            { "<leader>/_", hidden = true },
            { "<leader>J",  group = "[J]ava" },
            { "<leader>J_", hidden = true },
            { "<leader>Js",  group = "[S]ource" },
            { "<leader>Js_", hidden = true },
            { "<leader>Jr",  group = "[R]efactor" },
            { "<leader>Jr_", hidden = true },
            { "<leader>F",  group = "[F]lutter" },
            { "<leader>F_", hidden = true },
            { "<leader>t",  group = "[T]ests" },
            { "<leader>t_", hidden = true },
            { "<leader>c",  group = "[C]ode" },
            { "<leader>c_", hidden = true },
            { "<leader>d",  group = "[D]ebug" },
            { "<leader>d_", hidden = true },
            { "<leader>ds",  group = "[S]tep" },
            { "<leader>ds_", hidden = true },
            { "<leader>D",  group = "[D]atabase" },
            { "<leader>D_", hidden = true },
            { "<leader>L",  group = "[L]sp Log Lens" },
            { "<leader>L_", hidden = true },
            { "<leader>R",  group = "[R]un Configurations" },
            { "<leader>R_", hidden = true },
            { "<leader>e",  group = "[E]xplorer" },
            { "<leader>e_", hidden = true },
            { "<leader>f",  group = "[F]ind" },
            { "<leader>f_", hidden = true },
            { "<leader>g",  group = "[G]it" },
            { "<leader>g_", hidden = true },
            { "<leader>N",  group = "[N]eoTest" },
            { "<leader>N_", hidden = true },
            { "<leader>w",  group = "[W]indow" },
            { "<leader>w_", hidden = true },
            { "<leader>u",  group = "[U]ndo" },
            { "<leader>u_", hidden = true },
            { "<leader>W",  group = "[W]orkspace" },
            { "<leader>W_", hidden = true },
        })
    end
}
