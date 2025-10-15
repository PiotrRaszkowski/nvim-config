-- lsp-progress.nvim - LSP progress notifications
return {
	"linrongbin16/lsp-progress.nvim",
	event = "VeryLazy",
	config = function()
		require("lsp-progress").setup({
			-- Spinning icons
			spinner = { "⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷" },
			-- Spinning update interval in milliseconds
			spin_update_time = 200,
			-- Last message cached delay in milliseconds
			decay = 700,
			-- User event name
			event = "LspProgressStatusUpdated",
			-- Maximum progress string length
			max_size = 80,
			-- Format function for messages
			format = function(messages)
				local lsp_clients = vim.lsp.get_clients()
				if #lsp_clients > 0 then
					if #messages > 0 then
						return table.concat(messages, " ")
					end
				end
				return ""
			end,
		})
	end,
}
