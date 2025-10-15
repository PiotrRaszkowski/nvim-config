-- Command Executor: Handles generic shell commands
local M = {}

local variables = require("devrun.variables")

-- Validate Command configuration
function M.validate(config)
	local errors = {}

	if not config.command or config.command == "" then
		table.insert(errors, "command is required for Command type")
	end

	return errors
end

-- Execute generic command
function M.execute(config, callbacks)
	-- Resolve CWD
	local cwd = variables.resolve(config.cwd, config) or vim.fn.getcwd()

	-- Get command
	local cmd = config.command

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

-- Stop command task
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
		type = "command",
		description = "Generic shell command executor",
		supports_debug = false,
	}
end

return M
