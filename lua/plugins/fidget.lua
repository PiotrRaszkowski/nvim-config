-- fidget.nvim - LSP progress notifications
-- Shows LSP loading progress and active LSP servers
return {
	"j-hui/fidget.nvim",
	event = "LspAttach",
	opts = {
		-- Notification window configuration
		notification = {
			window = {
				winblend = 0, -- Background opacity (0 = opaque, 100 = transparent)
			},
		},
	},
}
