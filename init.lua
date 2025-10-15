-- Load the options from the config/options.lua file
require("config.options")
-- Load the keymaps from the config/keymaps.lua file
require("config.keymaps")
-- Load clean build files command to clean the build files like .project, .settings, bin, build, etc.
require("commands.clean-build-files")
-- Load the lazy plugin
require("config.lazy")
-- Load DevRun task runner
require("devrun").setup()
-- Load LSP server configurations (Lua, TypeScript, JSON, Docker, Java, etc.)
require("config.lsp-servers")
-- Load the auto commands from the config/autocmds.lua file (after lazy.nvim loads plugins)
require("config.autocmds")
