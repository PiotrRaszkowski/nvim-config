-- ============================================================================
-- JDTLS Configuration
-- Java Language Server setup for Neovim with comprehensive Spring Boot support
-- Dependencies: Mason packages (jdtls, java-debug-adapter, java-test) are
-- auto-installed via lua/config/lsp-servers.lua ensure_installed()
-- ============================================================================

local jdtls = require("jdtls")

local function setup_jdtls()
	-- ========================================================================
	-- Java Home Configuration
	-- ========================================================================
	local function get_java_home()
		-- Java 21.0.4-zulu path (update if using different version)
		local java_home = vim.fn.expand("~/.sdkman/candidates/java/21.0.4-zulu")

		-- Verify Java path exists
		if vim.fn.isdirectory(java_home) == 0 then
			vim.notify(
				"Java home not found at: " .. java_home .. "\nPlease update the path in lua/config/jdtls.lua",
				vim.log.levels.ERROR
			)
			return nil
		end

		return java_home
	end

	-- ========================================================================
	-- JDTLS Paths Configuration (Mason-installed)
	-- ========================================================================
	local function get_jdtls()
		local mason_registry = require("mason-registry")
		local jdtls_package = mason_registry.get_package("jdtls")
		local jdtls_path = jdtls_package:get_install_path()

		-- Find the launcher JAR
		local launcher = vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar")
		if launcher == "" then
			vim.notify("JDTLS launcher JAR not found at: " .. jdtls_path, vim.log.levels.ERROR)
			return nil, nil, nil, nil
		end

		-- OS-specific configuration (mac, linux, win)
		local SYSTEM = "mac"
		if vim.fn.has("linux") == 1 then
			SYSTEM = "linux"
		elseif vim.fn.has("win32") == 1 then
			SYSTEM = "win"
		end

		local jdtls_config = jdtls_path .. "/config_" .. SYSTEM
		local lombok = jdtls_path .. "/lombok.jar"
		local jdtls_cache_config = vim.fn.stdpath("cache") .. "/jdtls/config"

		return launcher, jdtls_config, lombok, jdtls_cache_config
	end

	-- ========================================================================
	-- Debug and Test Bundles (Mason-installed)
	-- ========================================================================
	local function get_bundles()
		local mason_registry = require("mason-registry")
		local bundles = {}

		-- Java Debug Adapter
		local java_debug = mason_registry.get_package("java-debug-adapter")
		local java_debug_path = java_debug:get_install_path()
		vim.list_extend(
			bundles,
			vim.split(vim.fn.glob(java_debug_path .. "/extension/server/com.microsoft.java.debug.plugin-*.jar"), "\n")
		)

		-- Java Test
		local java_test = mason_registry.get_package("java-test")
		local java_test_path = java_test:get_install_path()
		vim.list_extend(bundles, vim.split(vim.fn.glob(java_test_path .. "/extension/server/*.jar", 1), "\n"))

		-- Spring Boot extensions (if spring-boot.nvim is available)
		local ok, spring_boot = pcall(require, "spring_boot")
		if ok then
			vim.list_extend(bundles, spring_boot.java_extensions())
		end

		return bundles
	end

	-- ========================================================================
	-- Workspace Directory
	-- ========================================================================
	local function get_workspace()
		local home = os.getenv("HOME")
		local workspace_path = home .. "/.cache/nvim/jdtls/workspaces/"
		local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
		local workspace_dir = workspace_path .. project_name
		return workspace_dir
	end

	-- ========================================================================
	-- Google Java Style Formatter
	-- ========================================================================
	local function get_formatter()
		local formatter_path = vim.fn.stdpath("config") .. "/lua/config/eclipse-java-google-style.xml"
		if vim.fn.filereadable(formatter_path) == 0 then
			vim.notify(
				"Google Java Style formatter not found at: " .. formatter_path,
				vim.log.levels.WARN
			)
			return nil
		end
		return formatter_path
	end

	-- ========================================================================
	-- Java-Specific Keymaps
	-- ========================================================================
	local function java_keymaps()
		local opts = { buffer = true, noremap = true, silent = true }

		-- ========================== SOURCE ==========================
		vim.keymap.set(
			"n",
			"<leader>Jsi",
			"<Cmd>lua require('jdtls').organize_imports()<CR>",
			vim.tbl_extend("force", opts, { desc = "Organize [I]mports" })
		)

		-- ========================== REFACTOR ==========================
		vim.keymap.set(
			"n",
			"<leader>Jrv",
			"<Cmd>lua require('jdtls').extract_variable()<CR>",
			vim.tbl_extend("force", opts, { desc = "Extract [V]ariable" })
		)

		vim.keymap.set(
			"v",
			"<leader>Jrv",
			"<Esc><Cmd>lua require('jdtls').extract_variable(true)<CR>",
			vim.tbl_extend("force", opts, { desc = "Extract [V]ariable" })
		)

		vim.keymap.set(
			"n",
			"<leader>Jrc",
			"<Cmd>lua require('jdtls').extract_constant()<CR>",
			vim.tbl_extend("force", opts, { desc = "Extract [C]onstant" })
		)

		vim.keymap.set(
			"v",
			"<leader>Jrc",
			"<Esc><Cmd>lua require('jdtls').extract_constant(true)<CR>",
			vim.tbl_extend("force", opts, { desc = "Extract [C]onstant" })
		)

		vim.keymap.set(
			"v",
			"<leader>Jrm",
			"<Esc><Cmd>lua require('jdtls').extract_method(true)<CR>",
			vim.tbl_extend("force", opts, { desc = "Extract [M]ethod" })
		)

		-- ========================== TESTS ==========================
		vim.keymap.set(
			"n",
			"<leader>tt",
			"<Cmd>lua require('jdtls').test_nearest_method()<CR>",
			vim.tbl_extend("force", opts, { desc = "Run [T]est Method" })
		)

		vim.keymap.set(
			"v",
			"<leader>tt",
			"<Esc><Cmd>lua require('jdtls').test_nearest_method(true)<CR>",
			vim.tbl_extend("force", opts, { desc = "Run [T]est Method" })
		)

		vim.keymap.set(
			"n",
			"<leader>tc",
			"<Cmd>lua require('jdtls').test_class()<CR>",
			vim.tbl_extend("force", opts, { desc = "Run Test [C]lass" })
		)

		vim.keymap.set(
			"n",
			"<leader>tg",
			"<Cmd>lua require('jdtls.tests').generate()<CR>",
			vim.tbl_extend("force", opts, { desc = "[G]enerate tests for current class" })
		)

		vim.keymap.set(
			"n",
			"<leader>to",
			"<Cmd>lua require('jdtls.tests').goto_subjects()<CR>",
			vim.tbl_extend("force", opts, { desc = "[O]pen test class" })
		)

		-- ============================= BUILD =============================
		vim.keymap.set(
			"n",
			"<leader>JU",
			"<Cmd>lua require('jdtls').update_projects_config({select_mode = 'all'})<CR>",
			vim.tbl_extend("force", opts, { desc = "[U]pdate all projects" })
		)

		vim.keymap.set(
			"n",
			"<leader>JB",
			"<Cmd>lua require('jdtls').build_projects({select_mode = 'all'})<CR>",
			vim.tbl_extend("force", opts, { desc = "[B]uild all projects" })
		)
	end

	-- ========================================================================
	-- Get Required Paths and Validate
	-- ========================================================================
	local java_home = get_java_home()
	if not java_home then
		return
	end

	local launcher, jdtls_config, lombok, jdtls_cache_config = get_jdtls()
	if not launcher then
		return
	end

	local workspace_dir = get_workspace()
	local bundles = get_bundles()
	local formatter_url = get_formatter()

	-- ========================================================================
	-- JDTLS Command
	-- ========================================================================
	local cmd = {
		java_home .. "/bin/java",
		"-Declipse.application=org.eclipse.jdt.ls.core.id1",
		"-Dosgi.bundles.defaultStartLevel=4",
		"-Declipse.product=org.eclipse.jdt.ls.core.product",
		"-Dlog.protocol=true",
		"-Dlog.level=ALL",
		"-Xmx2G", -- Increased memory allocation for better performance
		"-Xms2G",
		"--add-modules=ALL-SYSTEM",
		"--add-opens", "java.base/java.util=ALL-UNNAMED",
		"--add-opens", "java.base/java.lang=ALL-UNNAMED",
		"-javaagent:" .. lombok,
		"-jar", launcher,
		"-configuration", jdtls_config,
		"-data", workspace_dir,
	}

	-- ========================================================================
	-- Root Directory Detection
	-- ========================================================================
	local root_markers = { "gradlew", "mvnw", ".git", "pom.xml", "build.gradle", "settings.gradle" }
	local root_dir = vim.fs.dirname(vim.fs.find(root_markers, { upward = true })[1])

	-- ========================================================================
	-- LSP Capabilities
	-- ========================================================================
	local capabilities = vim.lsp.protocol.make_client_capabilities()

	-- nvim-cmp capabilities
	local cmp_ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
	if cmp_ok then
		capabilities = vim.tbl_deep_extend("force", capabilities, cmp_nvim_lsp.default_capabilities())
	end

	-- JDTLS extended capabilities
	local extendedClientCapabilities = jdtls.extendedClientCapabilities
	extendedClientCapabilities.resolveAdditionalTextEditsSupport = true

	-- ========================================================================
	-- JDTLS Settings
	-- ========================================================================
	local settings = {
		java = {
			format = {
				enabled = true,
				settings = formatter_url and {
					url = formatter_url,
					profile = "GoogleStyle",
				} or nil,
			},
			eclipse = {
				downloadSources = true,
			},
			maven = {
				downloadSources = true,
			},
			signatureHelp = {
				enabled = true,
			},
			contentProvider = {
				preferred = "fernflower", -- Decompiler
			},
			saveActions = {
				organizeImports = true,
			},
			completion = {
				favoriteStaticMembers = {
					"org.hamcrest.Matchers.*",
					"org.hamcrest.CoreMatchers.*",
					"org.junit.jupiter.api.Assertions.*",
					"org.assertj.core.api.Assertions.*",
					"java.util.Objects.requireNonNull",
					"java.util.Objects.requireNonNullElse",
					"org.mockito.Mockito.*",
				},
				filteredTypes = {
					"com.sun.*",
					"io.micrometer.shaded.*",
					"java.awt.*",
					"jdk.*",
					"sun.*",
				},
				importOrder = {
					"java",
					"jakarta",
					"javax",
					"com",
					"org",
				},
			},
			sources = {
				organizeImports = {
					starThreshold = 9999,
					staticStarThreshold = 9999,
				},
			},
			codeGeneration = {
				toString = {
					template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
				},
				hashCodeEquals = {
					useJava7Objects = true,
				},
				useBlocks = true,
			},
			referencesCodeLens = {
				enabled = true,
			},
			references = {
				includeDecompiledSources = true,
			},
			implementationsCodeLens = {
				enabled = true,
			},
			configuration = {
				updateBuildConfiguration = "automatic",
			},
			inlayHints = {
				parameterNames = {
					enabled = "all", -- Show parameter names for all method calls
				},
			},
		},
	}

	-- ========================================================================
	-- JDTLS Configuration Object
	-- ========================================================================
	local config = {
		cmd = cmd,
		root_dir = root_dir,
		settings = settings,
		capabilities = capabilities,
		flags = {
			allow_incremental_sync = true,
		},
		init_options = {
			bundles = bundles,
			extendedClientCapabilities = extendedClientCapabilities,
		},
		on_attach = function(client, bufnr)
			-- Setup Java-specific keymaps
			java_keymaps()

			-- Setup DAP (Debug Adapter Protocol)
			jdtls.setup_dap({ hotcodereplace = "auto" })

			-- Remote attach configuration for debugging
			require("dap").configurations.java = {
				{
					type = "java",
					request = "attach",
					name = "Debug (Attach) - Remote",
					hostName = "127.0.0.1",
					port = 5005,
				},
			}

			-- Setup main class configurations for debugging
			jdtls.setup_dap_main_class_configs()

			-- Add JDTLS commands
			jdtls.setup.add_commands()

			-- Initialize Spring Boot LSP commands if available
			local ok, spring_boot = pcall(require, "spring_boot")
			if ok then
				spring_boot.init_lsp_commands()
			end

			-- Auto-refresh code lens on save
			vim.api.nvim_create_autocmd("BufWritePost", {
				buffer = bufnr,
				callback = function()
					pcall(vim.lsp.codelens.refresh, { bufnr = bufnr })
				end,
				desc = "Refresh code lens on save",
			})

			-- Initial code lens refresh
			vim.schedule(function()
				pcall(vim.lsp.codelens.refresh, { bufnr = bufnr })
			end)
		end,
	}

	-- ========================================================================
	-- Start JDTLS
	-- ========================================================================
	jdtls.start_or_attach(config)
end

return {
	setup_jdtls = setup_jdtls,
}
