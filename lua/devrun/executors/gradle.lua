-- Gradle Executor: Handles Gradle task execution
local M = {}

local variables = require("devrun.variables")

-- Build command with VM arguments
local function build_command(config)
	local cmd = config.command

	-- Add VM arguments if present
	if config.vmArgs and #config.vmArgs > 0 then
		local vm_args = table.concat(config.vmArgs, " ")
		-- Insert VM args after gradlew but before task name
		cmd = cmd:gsub("(%.?/gradlew%s+)", "%1" .. vm_args .. " ")
	end

	return cmd
end

-- Validate Gradle configuration
function M.validate(config)
	local errors = {}

	if not config.command or config.command == "" then
		table.insert(errors, "command is required for Gradle type")
	end

	return errors
end

-- Execute Gradle task
function M.execute(config, callbacks)
	-- Resolve CWD
	local cwd = variables.resolve(config.cwd, config) or vim.fn.getcwd()

	-- Build command with VM args
	local cmd = build_command(config)

	-- Create environment (merge with current env)
	local env = vim.tbl_extend("force", vim.fn.environ(), config.env or {})

	-- Execute via vim.system
	local process = vim.system({ "sh", "-c", cmd }, {
		cwd = cwd,
		env = env,
		stdout = function(err, data)
			if data and callbacks.on_stdout then
				callbacks.on_stdout(data)
			end
		end,
		stderr = function(err, data)
			if data and callbacks.on_stderr then
				callbacks.on_stderr(data)
			end
		end,
	}, function(result)
		if callbacks.on_exit then
			callbacks.on_exit(result.code)
		end
	end)

	return {
		process = process,
		command = cmd,
		cwd = cwd,
	}
end

-- Stop Gradle task
function M.stop(task_info)
	if task_info.process then
		task_info.process:kill(15) -- SIGTERM
		return true
	end
	return false
end

-- Get executor metadata
function M.get_metadata()
	return {
		type = "gradle",
		description = "Gradle task runner with VM arguments support",
		supports_debug = false,
	}
end

return M
