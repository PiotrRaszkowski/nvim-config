return {
	"nvimtools/none-ls.nvim",
	dependencies = {
		"nvimtools/none-ls-extras.nvim",
	},
	config = function()
		-- get access to the none-ls functions
		local null_ls = require("null-ls")
		-- run the setup function for none-ls to setup our different formatters
		null_ls.setup({
			sources = {
				-- setup lua formatter
				null_ls.builtins.formatting.stylua,
				-- setup eslint linter for javascript
				require("none-ls.diagnostics.eslint_d"),
				-- setup prettier to format languages that are not lua
				null_ls.builtins.formatting.prettier,
			},
			-- Format on save for specific filetypes
			on_attach = function(client, bufnr)
				if client.supports_method("textDocument/formatting") then
					vim.api.nvim_create_autocmd("BufWritePre", {
						buffer = bufnr,
						callback = function()
							-- Only auto-format for specific file types
							local ft = vim.bo[bufnr].filetype
							if ft == "json" or ft == "jsonc" then
								vim.lsp.buf.format({ bufnr = bufnr, async = false })
							end
						end,
					})
				end
			end,
		})

		-- set up a vim motion for <Space> + c + f to automatically format our code based on which language server is active
		vim.keymap.set({ "n", "v" }, "<leader>cf", function()
			vim.lsp.buf.format({ async = true })
		end, { desc = "[C]ode [F]ormat" })
	end,
}
