-- Flutter Custom Plugin: Main entry point
local M = {}

local device_manager = require("flutter.device-manager")
local ui = require("flutter.ui")
local runner = require("flutter.runner")
local logger = require("flutter.logger")
local devtools = require("flutter.devtools")
local lsp = require("flutter.lsp")

-- Setup function
function M.setup(opts)
	opts = opts or {}

	-- Check if Flutter is available
	if not device_manager.is_flutter_available() then
		vim.notify("Flutter not found in PATH. Please install Flutter SDK.", vim.log.levels.ERROR)
		return
	end

	-- Setup Dart LSP
	lsp.setup()

	-- Create commands
	M.create_commands()

	-- Setup keymaps
	M.setup_keymaps()

	vim.notify("Flutter custom plugin loaded", vim.log.levels.INFO)
end

-- Create user commands
function M.create_commands()
	-- Device/Emulator commands
	vim.api.nvim_create_user_command("FlutterDevices", function()
		ui.show_device_picker({
			prompt_title = "Flutter Devices",
			callback = function(device)
				vim.notify(string.format("Selected device: %s (%s)", device.name, device.id), vim.log.levels.INFO)
			end,
		})
	end, { desc = "Flutter: Show devices" })

	vim.api.nvim_create_user_command("FlutterEmulators", function()
		ui.show_emulator_picker({
			prompt_title = "Launch Emulator",
			callback = function(emulator)
				device_manager.launch_emulator(emulator.id)
			end,
		})
	end, { desc = "Flutter: Show and launch emulators" })

	-- Run/Attach commands
	vim.api.nvim_create_user_command("FlutterRun", function(cmd_opts)
		local device_id = cmd_opts.args ~= "" and cmd_opts.args or nil

		if device_id then
			runner.run_on_device(device_id)
		else
			ui.show_device_picker({
				prompt_title = "Run Flutter App - Select Device",
				callback = function(device)
					runner.run_on_device(device.id)
				end,
			})
		end
	end, {
		nargs = "?",
		desc = "Flutter: Run app on device",
	})

	vim.api.nvim_create_user_command("FlutterAttach", function(cmd_opts)
		local device_id = cmd_opts.args ~= "" and cmd_opts.args or nil

		if device_id then
			runner.attach_to_device(device_id)
		else
			ui.show_device_picker({
				prompt_title = "Attach to Flutter App - Select Device",
				callback = function(device)
					runner.attach_to_device(device.id)
				end,
			})
		end
	end, {
		nargs = "?",
		desc = "Flutter: Attach to running app",
	})

	-- Hot reload/restart
	vim.api.nvim_create_user_command("FlutterReload", function()
		runner.hot_reload()
	end, { desc = "Flutter: Hot reload" })

	vim.api.nvim_create_user_command("FlutterRestart", function()
		runner.hot_restart()
	end, { desc = "Flutter: Hot restart" })

	-- Quit/Detach
	vim.api.nvim_create_user_command("FlutterQuit", function()
		local app = runner.get_current_app()
		if app then
			runner.quit(app.id)
		else
			vim.notify("No active Flutter app", vim.log.levels.WARN)
		end
	end, { desc = "Flutter: Quit app" })

	vim.api.nvim_create_user_command("FlutterDetach", function()
		runner.detach()
	end, { desc = "Flutter: Detach from app" })

	-- Log commands
	vim.api.nvim_create_user_command("FlutterLogs", function()
		local app = runner.get_current_app()
		if app then
			logger.open(app.id)
		else
			vim.notify("No active Flutter app", vim.log.levels.WARN)
		end
	end, { desc = "Flutter: Show logs" })

	vim.api.nvim_create_user_command("FlutterLogToggle", function()
		logger.toggle()
	end, { desc = "Flutter: Toggle logs window" })

	vim.api.nvim_create_user_command("FlutterLogClear", function()
		logger.clear_current_log()
	end, { desc = "Flutter: Clear logs" })

	-- DevTools
	vim.api.nvim_create_user_command("FlutterDevTools", function()
		devtools.launch()
	end, { desc = "Flutter: Launch DevTools" })

	vim.api.nvim_create_user_command("FlutterDevToolsStop", function()
		devtools.stop()
	end, { desc = "Flutter: Stop DevTools" })

	-- Pub commands
	vim.api.nvim_create_user_command("FlutterPubGet", function()
		vim.notify("Running flutter pub get...", vim.log.levels.INFO)
		vim.fn.jobstart("flutter pub get", {
			on_exit = function(_, code)
				vim.schedule(function()
					if code == 0 then
						vim.notify("flutter pub get completed successfully", vim.log.levels.INFO)
					else
						vim.notify("flutter pub get failed", vim.log.levels.ERROR)
					end
				end)
			end,
		})
	end, { desc = "Flutter: Run pub get" })

	vim.api.nvim_create_user_command("FlutterPubUpgrade", function()
		vim.notify("Running flutter pub upgrade...", vim.log.levels.INFO)
		vim.fn.jobstart("flutter pub upgrade", {
			on_exit = function(_, code)
				vim.schedule(function()
					if code == 0 then
						vim.notify("flutter pub upgrade completed successfully", vim.log.levels.INFO)
					else
						vim.notify("flutter pub upgrade failed", vim.log.levels.ERROR)
					end
				end)
			end,
		})
	end, { desc = "Flutter: Run pub upgrade" })
end

-- Setup keymaps
function M.setup_keymaps()
	local keymap = vim.keymap.set
	local opts = { noremap = true, silent = true }

	-- Devices and emulators
	keymap("n", "<leader>Fd", "<cmd>FlutterDevices<cr>", vim.tbl_extend("force", opts, { desc = "[F]lutter [D]evices" }))
	keymap("n", "<leader>Fe", "<cmd>FlutterEmulators<cr>", vim.tbl_extend("force", opts, { desc = "[F]lutter [E]mulators" }))

	-- Run and attach
	keymap("n", "<leader>Fr", "<cmd>FlutterRun<cr>", vim.tbl_extend("force", opts, { desc = "[F]lutter [R]un" }))
	keymap("n", "<leader>Fa", "<cmd>FlutterAttach<cr>", vim.tbl_extend("force", opts, { desc = "[F]lutter [A]ttach" }))

	-- Hot reload/restart
	keymap("n", "<leader>Fh", "<cmd>FlutterReload<cr>", vim.tbl_extend("force", opts, { desc = "[F]lutter [H]ot Reload" }))
	keymap("n", "<leader>FR", "<cmd>FlutterRestart<cr>", vim.tbl_extend("force", opts, { desc = "[F]lutter [R]estart" }))

	-- Quit/Detach
	keymap("n", "<leader>Fq", "<cmd>FlutterQuit<cr>", vim.tbl_extend("force", opts, { desc = "[F]lutter [Q]uit" }))
	keymap("n", "<leader>FD", "<cmd>FlutterDetach<cr>", vim.tbl_extend("force", opts, { desc = "[F]lutter [D]etach" }))

	-- Logs
	keymap("n", "<leader>Fl", "<cmd>FlutterLogs<cr>", vim.tbl_extend("force", opts, { desc = "[F]lutter [L]ogs" }))
	keymap("n", "<leader>FL", "<cmd>FlutterLogToggle<cr>", vim.tbl_extend("force", opts, { desc = "[F]lutter [L]og Toggle" }))
	keymap("n", "<leader>Fc", "<cmd>FlutterLogClear<cr>", vim.tbl_extend("force", opts, { desc = "[F]lutter [C]lear Logs" }))

	-- DevTools
	keymap("n", "<leader>FT", "<cmd>FlutterDevTools<cr>", vim.tbl_extend("force", opts, { desc = "[F]lutter Dev[T]ools" }))

	-- Pub commands
	keymap("n", "<leader>Fp", "<cmd>FlutterPubGet<cr>", vim.tbl_extend("force", opts, { desc = "[F]lutter [P]ub Get" }))
	keymap("n", "<leader>FP", "<cmd>FlutterPubUpgrade<cr>", vim.tbl_extend("force", opts, { desc = "[F]lutter [P]ub Upgrade" }))
end

return M
