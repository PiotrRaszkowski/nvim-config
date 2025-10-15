-- Mason - Portable package manager for LSP servers, DAP servers, linters, and formatters
return {
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup({
				ui = {
					border = "rounded",
					icons = {
						package_installed = "✓",
						package_pending = "➜",
						package_uninstalled = "✗",
					},
				},
			})
		end,
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "williamboman/mason.nvim" },
		config = function()
			require("mason-tool-installer").setup({
				ensure_installed = {
					-- Formatters
					"stylua", -- Lua formatter
					"prettier", -- JavaScript/TypeScript/JSON/HTML/CSS/Markdown formatter
					-- Linters
					"eslint_d", -- JavaScript/TypeScript linter
				},
				auto_update = false,
				run_on_start = true, -- Install missing tools on startup
			})
		end,
	},
}
