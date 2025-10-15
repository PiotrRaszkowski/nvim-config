-- nvim-jdtls plugin configuration
-- JDTLS is configured via ftplugin/java.lua which automatically runs when opening .java files
-- This file just ensures nvim-jdtls plugin is loaded for Java files

return {
	{
		"mfussenegger/nvim-jdtls",
		ft = "java", -- Only load for Java files
		dependencies = {
			"mfussenegger/nvim-dap", -- Debug Adapter Protocol support
		},
		-- Configuration is handled by ftplugin/java.lua
		-- ftplugin/java.lua calls require('jdtls').start_or_attach(config)
	},
}
