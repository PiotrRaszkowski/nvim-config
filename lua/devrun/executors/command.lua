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

	-- Extract PID from process object
	local pid = process.pid

	return {
		process = process,
		pid = pid,
		command = cmd,
		cwd = cwd,
	}
end

-- Check if process is still running
local function is_process_alive(pid)
	if not pid then
		return false
	end
	-- Use kill -0 to check if process exists without sending a signal
	local result = vim.fn.system(string.format("kill -0 %d 2>/dev/null", pid))
	return vim.v.shell_error == 0
end

-- Stop command task
function M.stop(task_info)
	local success = false

	-- Step 1: Try to kill via SystemObj (SIGTERM to process group)
	if task_info.process then
		-- Try to kill the process group first (kills child processes too)
		-- Use negative PID to signal the process group
		if task_info.pid then
			vim.notify(string.format("Stopping command process group (PID: %d)...", task_info.pid), vim.log.levels.INFO)
			local kill_result = vim.fn.system(string.format("kill -TERM -- -%d 2>/dev/null", task_info.pid))

			-- Wait briefly to see if process terminates
			vim.wait(2000, function()
				return not is_process_alive(task_info.pid)
			end, 100)

			if not is_process_alive(task_info.pid) then
				vim.notify("Command process terminated gracefully", vim.log.levels.INFO)
				return true
			end
		end

		-- Fallback: kill via SystemObj
		task_info.process:kill(15) -- SIGTERM
		success = true
	end

	-- Step 2: Fallback - try to kill by PID directly if process object failed
	if task_info.pid and is_process_alive(task_info.pid) then
		vim.notify(string.format("Process still alive, trying direct kill (PID: %d)...", task_info.pid), vim.log.levels.WARN)

		-- Try SIGTERM to process group
		vim.fn.system(string.format("kill -TERM -- -%d 2>/dev/null", task_info.pid))

		-- Wait for graceful shutdown
		vim.wait(2000, function()
			return not is_process_alive(task_info.pid)
		end, 100)

		-- Step 3: Force kill if still alive (SIGKILL)
		if is_process_alive(task_info.pid) then
			vim.notify(string.format("Force killing process (PID: %d)...", task_info.pid), vim.log.levels.WARN)
			vim.fn.system(string.format("kill -KILL -- -%d 2>/dev/null", task_info.pid))

			-- Final verification
			vim.wait(1000, function()
				return not is_process_alive(task_info.pid)
			end, 100)

			if not is_process_alive(task_info.pid) then
				vim.notify("Process force-killed successfully", vim.log.levels.INFO)
				success = true
			else
				vim.notify("Failed to kill process", vim.log.levels.ERROR)
			end
		else
			vim.notify("Process terminated successfully", vim.log.levels.INFO)
			success = true
		end
	end

	return success
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
