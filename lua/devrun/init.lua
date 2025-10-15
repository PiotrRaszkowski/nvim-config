-- DevRun: Development task runner for Spring Boot/Gradle projects
local M = {}

local parser = require("devrun.parser")
local task_manager = require("devrun.task-manager")
local log_ui = require("devrun.log-ui")

-- Setup function (called by plugin)
function M.setup()
	-- Register log callback with task manager
	task_manager.register_log_callback(log_ui.get_log_callback())

	-- Create commands
	M.create_commands()

	-- Setup keymaps
	vim.keymap.set("n", "<leader>Rr", "<cmd>DevRun<cr>", { desc = "[R]un [D]evRun picker" })
	vim.keymap.set("n", "<leader>Rt", "<cmd>DevRunTasks<cr>", { desc = "[R]un Show [T]asks" })
	vim.keymap.set("n", "<leader>Rl", "<cmd>DevRunToggleLogs<cr>", { desc = "[R]un Toggle [L]ogs" })
	vim.keymap.set("n", "<leader>Rs", "<cmd>DevRunStop<cr>", { desc = "[R]un [S]top task" })
	vim.keymap.set("n", "<leader>RR", "<cmd>DevRunReload<cr>", { desc = "[R]un [R]eload configs" })
	vim.keymap.set("n", "<leader>RI", "<cmd>DevRunInit<cr>", { desc = "[R]un [I]nit example config" })
	vim.keymap.set("n", "<leader>RA", "<cmd>DevRunAddRunConfiguration<cr>", { desc = "[R]un [A]dd configuration" })
end

-- Run a configuration by name (handles beforeRun tasks)
function M.run_configuration(name)
	local config, err = parser.get_config_by_name(name)
	if not config then
		vim.notify(err, vim.log.levels.ERROR)
		return nil
	end

	-- Handle beforeRun task
	if config.beforeRun then
		vim.notify(
			string.format("Running before-run task: %s", config.beforeRun),
			vim.log.levels.INFO
		)

		local before_config, before_err = parser.get_config_by_name(config.beforeRun)
		if not before_config then
			vim.notify(
				string.format("Before-run task '%s' not found: %s", config.beforeRun, before_err),
				vim.log.levels.ERROR
			)
			return nil
		end

		-- Run before task synchronously and wait for completion
		local before_task_id = M.execute_task(before_config)

		-- After before task completes, run main task
		-- For now, run immediately (could be enhanced to wait for completion)
		vim.defer_fn(function()
			M.execute_task(config)
		end, 1000) -- 1 second delay to allow before task to start

		return before_task_id
	else
		-- No before task, run directly
		return M.execute_task(config)
	end
end

-- Execute a single task (internal helper)
function M.execute_task(config)
	-- Initialize log for this task
	local task_id = task_manager.run_task(config, function(tid, data, stream_type)
		-- This callback is handled by the registered log callback
	end, function(tid, exit_code)
		-- On exit callback
		if exit_code ~= 0 then
			log_ui.append_output(tid, string.format("\n[Task exited with code: %d]", exit_code), "stderr")
		else
			log_ui.append_output(tid, string.format("\n[Task completed successfully]", exit_code), "stdout")
		end
	end)

	-- Initialize log UI for this task
	log_ui.init_task_log(task_id, config.name)

	-- Open log console and switch to this task
	log_ui.open(task_id)

	return task_id
end

-- Show configuration picker using Telescope
function M.show_configuration_picker()
	local configs, err = parser.load_configurations()
	if not configs then
		vim.notify(err, vim.log.levels.ERROR)
		return
	end

	-- Build picker items
	local items = {}
	for _, config in ipairs(configs) do
		local type_str = config.type or "gradle"
		local display = string.format("[%s] %s", type_str, config.name)
		if config.beforeRun then
			display = display .. string.format(" (before: %s)", config.beforeRun)
		end
		table.insert(items, {
			name = config.name,
			display = display,
			type = type_str,
			config = config,
		})
	end

	-- Use Telescope picker
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	pickers
		.new({}, {
			prompt_title = "Run Configurations",
			finder = finders.new_table({
				results = items,
				entry_maker = function(entry)
					return {
						value = entry,
						display = entry.display,
						ordinal = entry.name,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					if selection then
						M.run_configuration(selection.value.name)
					end
				end)
				return true
			end,
		})
		:find()
end

-- Show active background tasks
function M.show_active_tasks()
	local tasks = task_manager.get_active_tasks()

	if #tasks == 0 then
		vim.notify("No active tasks", vim.log.levels.INFO)
		return
	end

	-- Format tasks for display
	local lines = { "=== Active Background Tasks ===", "" }
	for _, task in ipairs(tasks) do
		local duration = string.format("%ds", task.duration)
		local type_str = task.type or "gradle"
		table.insert(
			lines,
			string.format("[%d] [%s] %s - %s (%s)", task.id, type_str, task.status:upper(), task.name, duration)
		)
		table.insert(lines, string.format("    Command: %s", task.command))
		table.insert(lines, string.format("    CWD: %s", task.cwd))
		table.insert(lines, "")
	end

	-- Create buffer to display tasks
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")

	-- Open in split
	vim.cmd("botright 15split")
	vim.api.nvim_win_set_buf(0, buf)

	-- Add keymap to close
	vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, desc = "Close task list" })
	vim.keymap.set("n", "s", function()
		-- Stop selected task (simple implementation - stop first running task)
		local running = task_manager.get_running_tasks()
		if #running > 0 then
			task_manager.stop_task(running[1].id)
			vim.cmd("close")
			M.show_active_tasks() -- Refresh
		end
	end, { buffer = buf, desc = "Stop task" })
end

-- Show logs console for specific task or default (latest)
function M.show_logs_console(task_name)
	if task_name then
		-- Find task by name
		local tasks = task_manager.get_active_tasks()
		local found_task = nil

		for _, task in ipairs(tasks) do
			if task.name == task_name then
				found_task = task
				break
			end
		end

		if not found_task then
			vim.notify("Task '" .. task_name .. "' not found", vim.log.levels.WARN)
			return
		end

		log_ui.open(found_task.id)
	else
		-- Show latest task
		local latest = task_manager.get_latest_task()
		if latest then
			log_ui.open(latest.id)
		else
			vim.notify("No tasks have been run yet", vim.log.levels.INFO)
		end
	end
end

-- Stop task by name
function M.stop_task(task_name)
	if not task_name or task_name == "" then
		-- Show picker to select task to stop
		local running = task_manager.get_running_tasks()
		if #running == 0 then
			vim.notify("No running tasks", vim.log.levels.INFO)
			return
		end

		vim.ui.select(running, {
			prompt = "Select task to stop:",
			format_item = function(task)
				return string.format("[%d] %s", task.id, task.name)
			end,
		}, function(choice)
			if choice then
				task_manager.stop_task(choice.id)
			end
		end)
	else
		task_manager.stop_task_by_name(task_name)
	end
end

-- Create user commands
function M.create_commands()
	-- Main commands with DevRun prefix
	vim.api.nvim_create_user_command("DevRun", function()
		M.show_configuration_picker()
	end, { desc = "DevRun: Show configurations picker" })

	vim.api.nvim_create_user_command("DevRunConfig", function(opts)
		if opts.args == "" then
			vim.notify("Usage: :DevRunConfig <name>", vim.log.levels.WARN)
			return
		end
		M.run_configuration(opts.args)
	end, {
		nargs = 1,
		complete = function()
			local names, _ = parser.get_config_names()
			return names or {}
		end,
		desc = "DevRun: Run a specific configuration by name",
	})

	vim.api.nvim_create_user_command("DevRunTasks", function()
		M.show_active_tasks()
	end, { desc = "DevRun: Show all active background tasks" })

	vim.api.nvim_create_user_command("DevRunLogs", function(opts)
		M.show_logs_console(opts.args ~= "" and opts.args or nil)
	end, {
		nargs = "?",
		complete = function()
			local tasks = task_manager.get_active_tasks()
			local names = {}
			for _, task in ipairs(tasks) do
				table.insert(names, task.name)
			end
			return names
		end,
		desc = "DevRun: Show logs console for a task (default: latest)",
	})

	vim.api.nvim_create_user_command("DevRunToggleLogs", function()
		log_ui.toggle()
	end, { desc = "DevRun: Toggle logs console window" })

	vim.api.nvim_create_user_command("DevRunStop", function(opts)
		M.stop_task(opts.args)
	end, {
		nargs = "?",
		complete = function()
			local running = task_manager.get_running_tasks()
			local names = {}
			for _, task in ipairs(running) do
				table.insert(names, task.name)
			end
			return names
		end,
		desc = "DevRun: Stop a running task",
	})

	vim.api.nvim_create_user_command("DevRunStopAll", function()
		task_manager.stop_all_tasks()
	end, { desc = "DevRun: Stop all running tasks" })

	vim.api.nvim_create_user_command("DevRunReload", function()
		local configs, err = parser.reload()
		if configs then
			vim.notify("Reloaded " .. #configs .. " configurations", vim.log.levels.INFO)
		else
			vim.notify("Error reloading: " .. err, vim.log.levels.ERROR)
		end
	end, { desc = "DevRun: Reload run configurations from file" })

	vim.api.nvim_create_user_command("DevRunInit", function()
		local path, err = parser.create_example_config()
		if path then
			vim.notify("Created example config at: " .. path, vim.log.levels.INFO)
			vim.cmd("edit " .. path)
		else
			vim.notify("Error: " .. err, vim.log.levels.ERROR)
		end
	end, { desc = "DevRun: Create example run-configurations.json file" })

	vim.api.nvim_create_user_command("DevRunAddRunConfiguration", function(opts)
		local config_builder = require("devrun.config-builder")

		local config_type = opts.args ~= "" and opts.args or nil

		-- Build config interactively
		local config = config_builder.build_configuration(config_type)

		if not config then
			vim.notify("Configuration creation cancelled", vim.log.levels.INFO)
			return
		end

		-- Save to file
		local file_path, err = parser.add_configuration(config)

		if not file_path then
			vim.notify("Error: " .. err, vim.log.levels.ERROR)
			return
		end

		vim.notify(
			string.format("✓ Configuration '%s' added to %s", config.name, file_path),
			vim.log.levels.INFO
		)
	end, {
		nargs = "?",
		complete = function()
			return { "gradle", "tomcat", "command" }
		end,
		desc = "DevRun: Add new run configuration interactively",
	})

	vim.api.nvim_create_user_command("DevRunVariables", function()
		local variables = require("devrun.variables")

		-- Create buffer to display variables
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_option(buf, "modifiable", false)
		vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
		vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
		vim.api.nvim_buf_set_name(buf, "DevRun Variables")

		-- Get documentation and current values
		local doc_lines = variables.format_documentation()
		table.insert(doc_lines, "")
		table.insert(doc_lines, "Current Values:")
		table.insert(doc_lines, "---------------")

		local current_values = variables.get_current_values()
		for category, vars in pairs(current_values) do
			table.insert(doc_lines, "")
			table.insert(doc_lines, category .. ":")
			for var, value in pairs(vars) do
				table.insert(doc_lines, string.format("  %-35s = %s", var, value))
			end
		end

		-- Set buffer content
		vim.api.nvim_buf_set_option(buf, "modifiable", true)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, doc_lines)
		vim.api.nvim_buf_set_option(buf, "modifiable", false)

		-- Open in split
		vim.cmd("botright vsplit")
		vim.api.nvim_win_set_buf(0, buf)

		-- Add keymap to close
		vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, desc = "Close variables window" })
	end, { desc = "DevRun: Show available variables and their current values" })
end

return M
