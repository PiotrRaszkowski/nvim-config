-- LSP Server Configurations
-- This file configures LSP servers using the modern vim.lsp.config API (Neovim 0.11+)
-- Servers are auto-enabled when opening files of the corresponding filetype

-- Ensure Mason registry is available for auto-installation
local mason_registry = require("mason-registry")

-- Helper function to ensure Mason packages are installed
local function ensure_installed(packages)
	for _, package in ipairs(packages) do
		local p = mason_registry.get_package(package)
		if not p:is_installed() then
			p:install()
		end
	end
end

-- Install required LSP servers via Mason
ensure_installed({
	"lua-language-server", -- lua_ls
	"typescript-language-server", -- ts_ls
	"json-lsp", -- jsonls
	"docker-compose-language-service", -- docker_compose_language_service
	"dockerfile-language-server", -- dockerls
	"dart-debug-adapter", -- Dart debugging
    "jdtls", -- Jdtls
    "java-debug-adapter",
    "java-test"
})

-- ============================================================================
-- Lua Language Server (lua_ls)
-- ============================================================================
vim.lsp.config("lua_ls", {
	cmd = { "lua-language-server" },
	filetypes = { "lua" },
	root_markers = { ".luarc.json", ".luarc.jsonc", ".luacheckrc", ".stylua.toml", "stylua.toml", "selene.toml", "selene.yml", ".git" },
	settings = {
		Lua = {
			runtime = {
				version = "LuaJIT",
			},
			diagnostics = {
				globals = { "vim" },
			},
			workspace = {
				library = {
					vim.env.VIMRUNTIME,
				},
				checkThirdParty = false,
			},
			telemetry = {
				enable = false,
			},
			completion = {
				callSnippet = "Replace",
			},
		},
	},
})

-- ============================================================================
-- TypeScript/JavaScript Language Server (ts_ls)
-- ============================================================================
vim.lsp.config("ts_ls", {
	cmd = { "typescript-language-server", "--stdio" },
	filetypes = {
		"javascript",
		"javascriptreact",
		"javascript.jsx",
		"typescript",
		"typescriptreact",
		"typescript.tsx",
	},
	root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" },
	settings = {
		typescript = {
			inlayHints = {
				includeInlayParameterNameHints = "all",
				includeInlayParameterNameHintsWhenArgumentMatchesName = false,
				includeInlayFunctionParameterTypeHints = true,
				includeInlayVariableTypeHints = true,
				includeInlayPropertyDeclarationTypeHints = true,
				includeInlayFunctionLikeReturnTypeHints = true,
				includeInlayEnumMemberValueHints = true,
			},
		},
		javascript = {
			inlayHints = {
				includeInlayParameterNameHints = "all",
				includeInlayParameterNameHintsWhenArgumentMatchesName = false,
				includeInlayFunctionParameterTypeHints = true,
				includeInlayVariableTypeHints = true,
				includeInlayPropertyDeclarationTypeHints = true,
				includeInlayFunctionLikeReturnTypeHints = true,
				includeInlayEnumMemberValueHints = true,
			},
		},
	},
})

-- ============================================================================
-- JSON Language Server (jsonls)
-- ============================================================================
vim.lsp.config("jsonls", {
	cmd = { "vscode-json-language-server", "--stdio" },
	filetypes = { "json", "jsonc" },
	root_markers = { ".git" },
	settings = {
		json = {
			-- SchemaStore integration (optional - requires b0o/schemastore.nvim plugin)
			-- If you want JSON schema validation, install the plugin and uncomment below:
			-- schemas = require("schemastore").json.schemas(),
			validate = { enable = true },
		},
	},
})

-- ============================================================================
-- Docker Compose Language Service
-- ============================================================================
vim.lsp.config("docker_compose_language_service", {
	cmd = { "docker-compose-langserver", "--stdio" },
	filetypes = { "yaml.docker-compose" },
	root_markers = { "docker-compose.yaml", "docker-compose.yml", ".git" },
})

-- ============================================================================
-- Dockerfile Language Server
-- ============================================================================
vim.lsp.config("dockerls", {
	cmd = { "docker-langserver", "--stdio" },
	filetypes = { "dockerfile" },
	root_markers = { "Dockerfile", ".git" },
})

-- ============================================================================
-- Java Language Server (jdtls)
-- For Java/Spring Boot development - integrated with nvim-jdtls
-- ============================================================================
-- NOTE: JDTLS is configured via lua/config/jdtls.lua
-- Automatically triggered by FileType autocmd in lua/config/autocmds.lua
-- Mason packages (jdtls, java-debug-adapter, java-test) are ensured above

-- ============================================================================
-- Dart Language Server (dartls)
-- For Flutter development - integrated with flutter-tools.nvim
-- ============================================================================
-- NOTE: Dart LSP is configured via flutter-tools.nvim plugin
-- See lua/plugins/flutter.lua for the complete Flutter/Dart setup
-- flutter-tools handles dartls configuration, Flutter SDK detection,
-- hot reload, debugging, and Flutter-specific features

-- ============================================================================
-- LSP Keymaps (Global)
-- ============================================================================
-- These keymaps are available in all buffers with an active LSP server
-- Buffer-local keymaps are set via LspAttach autocmd

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspConfig", {}),
	callback = function(ev)
		-- Buffer-local options
		vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

		-- Buffer-local keymaps
		local opts = { buffer = ev.buf, noremap = true, silent = true }

		-- Diagnostics
		vim.keymap.set("n", "<leader>ce", vim.diagnostic.open_float, vim.tbl_extend("force", opts, { desc = "[C]ode [E]rror (Line diagnostics)" }))

		-- Hover and signature
		vim.keymap.set("n", "<leader>ch", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "[C]ode [H]over" }))
		vim.keymap.set("n", "<leader>cs", vim.lsp.buf.signature_help, vim.tbl_extend("force", opts, { desc = "[C]ode [S]ignature" }))

		-- Navigation
		vim.keymap.set("n", "<leader>cd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "[C]ode [D]efinition" }))
		vim.keymap.set("n", "<leader>cD", vim.lsp.buf.declaration, vim.tbl_extend("force", opts, { desc = "[C]ode [D]eclaration" }))
		vim.keymap.set("n", "<leader>ci", vim.lsp.buf.implementation, vim.tbl_extend("force", opts, { desc = "[C]ode [I]mplementation" }))
		vim.keymap.set("n", "<leader>cr", vim.lsp.buf.references, vim.tbl_extend("force", opts, { desc = "[C]ode [R]eferences" }))

		-- Code actions
		vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "[C]ode [A]ction" }))
		vim.keymap.set("n", "<leader>cR", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "[C]ode [R]ename" }))

		-- Formatting (async to prevent freezing)
		vim.keymap.set("n", "<leader>cf", function()
			vim.lsp.buf.format({ async = true })
		end, vim.tbl_extend("force", opts, { desc = "[C]ode [F]ormat" }))
	end,
})

-- ============================================================================
-- Auto-enable LSP servers on FileType
-- ============================================================================
-- The vim.lsp.config API with 'filetypes' field auto-enables servers,
-- but we explicitly enable them here for clarity and control

local lsp_filetypes = {
	{ "lua", "lua_ls" },
	{ "javascript,javascriptreact,typescript,typescriptreact", "ts_ls" },
	{ "json,jsonc", "jsonls" },
	{ "yaml.docker-compose", "docker_compose_language_service" },
	{ "dockerfile", "dockerls" },
	-- Note: dartls is handled by flutter-tools.nvim, not here
}

for _, config in ipairs(lsp_filetypes) do
	vim.api.nvim_create_autocmd("FileType", {
		pattern = vim.split(config[1], ","),
		callback = function(args)
			vim.lsp.enable(config[2], args.buf)
		end,
	})
end
