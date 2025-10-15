return {
	{
		"oclay1st/gradle.nvim",
		cmd = { "Gradle", "GradleExec", "GradleInit" },
		dependencies = {
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
		},
		opts = {}, -- options, see default configuration
		keys = {
			{
				"<Leader>G",
				function()
					require("gradle").toggle_projects_view()
				end,
				desc = "Gradle",
			},
		},
	},
}
