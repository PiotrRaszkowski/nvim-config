-- Task Manager: Handles task execution, tracking, and process management
local M = {}

local executors = require("devrun.executors")

-- Active tasks registry
-- Structure: { task_id = { name, executor_info, pid, start_time, status, config, type } }
M.active_tasks = {}
M.task_counter = 0
M.log_callbacks = {}

-- Session file path
local function get_session_file_path()
	local cache_dir = vim.fn.stdpath("cache") .. "/devrun"
	vim.fn.mkdir(cache_dir, "p")
	return cache_dir .. "/session.json"
end

-- Generate unique task ID
local function generate_task_id()
	M.task_counter = M.task_counter + 1
	return M.task_counter
end

-- Execute a task
function M.run_task(config, on_output, on_exit)
	local task_id = generate_task_id()

	vim.notify("Starting task: " .. config.name, vim.log.levels.INFO)

	-- Get executor for this config type
	local executor = executors.get_executor(config.type)

	-- Register task early (before execution) so it exists if executor fails early
	M.active_tasks[task_id] = {
		id = task_id,
		name = config.name,
		executor_info = nil, -- Will be set after execution
		pid = nil, -- Will be set after execution
		start_time = os.time(),
		status = "starting",
		config = config,
		type = config.type or "gradle",
		command = "N/A", -- Will be set after execution
		cwd = config.cwd or vim.fn.getcwd(),
	}

	-- Setup callbacks
	-- Note: We don't need vim.schedule for stdout/stderr because:
	-- 1. append_output() already wraps in vim.schedule()
	-- 2. These callbacks don't call vim.notify() or other restricted APIs directly
	local callbacks = {
		on_stdout = function(data)
			if on_output then
				on_output(task_id, data, "stdout")
			end
			-- Call registered log callbacks
			for _, callback in ipairs(M.log_callbacks) do
				callback(task_id, data, "stdout")
			end
		end,
		on_stderr = function(data)
			if on_output then
				on_output(task_id, data, "stderr")
			end
			-- Call registered log callbacks
			for _, callback in ipairs(M.log_callbacks) do
				callback(task_id, data, "stderr")
			end
		end,
		on_exit = function(exit_code)
			-- Use vim.schedule to avoid fast event context issues
			vim.schedule(function()
				-- Update task status (task should always exist now)
				local task = M.active_tasks[task_id]
				if task then
					task.status = exit_code == 0 and "completed" or "failed"
					task.exit_code = exit_code

					local level = exit_code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR
					vim.notify(
						string.format("Task '%s' %s (exit code: %d)", config.name, task.status, exit_code),
						level
					)
				end

				if on_exit then
					on_exit(task_id, exit_code)
				end
			end)
		end,
	}

	-- Execute via executor
	local executor_info = executor.execute(config, callbacks)

	if not executor_info then
		-- Update task status to failed
		M.active_tasks[task_id].status = "failed"
		vim.notify(string.format("Failed to start task: %s", config.name), vim.log.levels.ERROR)
		return nil
	end

	-- Update task with executor info
	M.active_tasks[task_id].executor_info = executor_info
	M.active_tasks[task_id].status = "running"
	M.active_tasks[task_id].command = executor_info.command or config.command or "N/A"
	M.active_tasks[task_id].cwd = executor_info.cwd or config.cwd or vim.fn.getcwd()
	M.active_tasks[task_id].pid = executor_info.pid

	return task_id
end

-- Stop a task by ID
function M.stop_task(task_id)
	local task = M.active_tasks[task_id]
	if not task then
		vim.notify("Task ID " .. task_id .. " not found", vim.log.levels.WARN)
		return false
	end

	-- Get executor and use its stop method
	local executor = executors.get_executor(task.type)
	local stopped = executor.stop(task.executor_info)

	if stopped then
		task.status = "stopped"
		vim.notify("Stopped task: " .. task.name, vim.log.levels.INFO)
		return true
	end

	return false
end

-- Stop task by name
function M.stop_task_by_name(name)
	for task_id, task in pairs(M.active_tasks) do
		if task.name == name and task.status == "running" then
			return M.stop_task(task_id)
		end
	end
	vim.notify("No running task named: " .. name, vim.log.levels.WARN)
	return false
end

-- Stop all running tasks
function M.stop_all_tasks()
	local count = 0
	for task_id, task in pairs(M.active_tasks) do
		if task.status == "running" then
			M.stop_task(task_id)
			count = count + 1
		end
	end
	vim.notify(string.format("Stopped %d task(s)", count), vim.log.levels.INFO)
	return count
end

-- Get all active tasks
function M.get_active_tasks()
	local tasks = {}
	for task_id, task in pairs(M.active_tasks) do
		table.insert(tasks, {
			id = task_id,
			name = task.name,
			type = task.type,
			status = task.status,
			command = task.command,
			cwd = task.cwd,
			pid = task.pid,
			start_time = task.start_time,
			duration = os.time() - task.start_time,
		})
	end
	return tasks
end

-- Get running tasks only
function M.get_running_tasks()
	local tasks = {}
	for _, task in pairs(M.active_tasks) do
		if task.status == "running" then
			table.insert(tasks, task)
		end
	end
	return tasks
end

-- Get task by ID
function M.get_task(task_id)
	return M.active_tasks[task_id]
end

-- Get latest task
function M.get_latest_task()
	local latest_id = nil
	local latest_time = 0

	for task_id, task in pairs(M.active_tasks) do
		if task.start_time > latest_time then
			latest_time = task.start_time
			latest_id = task_id
		end
	end

	return latest_id and M.active_tasks[latest_id] or nil
end

-- Register callback for log output
function M.register_log_callback(callback)
	table.insert(M.log_callbacks, callback)
end

-- Clean up completed tasks (keep last N)
function M.cleanup_tasks(keep_count)
	keep_count = keep_count or 10

	-- Sort tasks by start time
	local sorted_tasks = {}
	for task_id, task in pairs(M.active_tasks) do
		table.insert(sorted_tasks, { id = task_id, time = task.start_time, status = task.status })
	end

	table.sort(sorted_tasks, function(a, b)
		return a.time > b.time
	end)

	-- Remove old completed/failed tasks
	for i = keep_count + 1, #sorted_tasks do
		local task = sorted_tasks[i]
		if task.status ~= "running" then
			M.active_tasks[task.id] = nil
		end
	end
end

-- Check if process is alive
local function is_process_alive(pid)
	if not pid then
		return false
	end
	local result = vim.fn.system(string.format("kill -0 %d 2>/dev/null", pid))
	return vim.v.shell_error == 0
end

-- Save current session to file
function M.save_session()
	local session_file = get_session_file_path()

	-- Build session data (only save running tasks)
	local session_tasks = {}
	for task_id, task in pairs(M.active_tasks) do
		if task.status == "running" and task.pid then
			table.insert(session_tasks, {
				id = task_id,
				name = task.name,
				pid = task.pid,
				type = task.type,
				command = task.command,
				cwd = task.cwd,
				start_time = task.start_time,
				config = task.config, -- Save full config for reconnection
			})
		end
	end

	local session_data = {
		version = 1,
		timestamp = os.time(),
		task_counter = M.task_counter,
		tasks = session_tasks,
	}

	-- Write to file
	local file = io.open(session_file, "w")
	if not file then
		vim.notify("Failed to save DevRun session", vim.log.levels.WARN)
		return false
	end

	file:write(vim.fn.json_encode(session_data))
	file:close()
	return true
end

-- Load session from file
function M.load_session()
	local session_file = get_session_file_path()

	-- Check if session file exists
	if vim.fn.filereadable(session_file) == 0 then
		return nil
	end

	-- Read session file
	local file = io.open(session_file, "r")
	if not file then
		return nil
	end

	local content = file:read("*all")
	file:close()

	-- Parse JSON
	local ok, session_data = pcall(vim.fn.json_decode, content)
	if not ok then
		vim.notify("Failed to parse DevRun session file", vim.log.levels.WARN)
		return nil
	end

	return session_data
end

-- Reconnect to orphaned tasks from previous session
function M.reconnect_session()
	local session_data = M.load_session()
	if not session_data or not session_data.tasks then
		vim.notify("No previous DevRun session found", vim.log.levels.INFO)
		return 0
	end

	local reconnected = 0
	local orphaned = {}

	for _, task_data in ipairs(session_data.tasks) do
		-- Check if process still exists
		if is_process_alive(task_data.pid) then
			-- Restore task to registry (but we can't restore SystemObj)
			M.active_tasks[task_data.id] = {
				id = task_data.id,
				name = task_data.name,
				pid = task_data.pid,
				type = task_data.type,
				command = task_data.command,
				cwd = task_data.cwd,
				start_time = task_data.start_time,
				status = "running",
				config = task_data.config,
				executor_info = {
					pid = task_data.pid,
					command = task_data.command,
					cwd = task_data.cwd,
					process = nil, -- Cannot restore SystemObj
				},
			}

			-- Update task counter if needed
			if task_data.id >= M.task_counter then
				M.task_counter = task_data.id
			end

			reconnected = reconnected + 1
			table.insert(orphaned, task_data.name)
		end
	end

	if reconnected > 0 then
		vim.notify(
			string.format(
				"Reconnected to %d orphaned task(s): %s",
				reconnected,
				table.concat(orphaned, ", ")
			),
			vim.log.levels.INFO
		)
	else
		vim.notify("No orphaned tasks found from previous session", vim.log.levels.INFO)
	end

	return reconnected
end

-- Cleanup orphaned tasks (processes that are no longer running)
function M.cleanup_orphans()
	local removed = 0
	local to_remove = {}

	for task_id, task in pairs(M.active_tasks) do
		if task.status == "running" and task.pid and not is_process_alive(task.pid) then
			table.insert(to_remove, task_id)
		end
	end

	for _, task_id in ipairs(to_remove) do
		local task = M.active_tasks[task_id]
		vim.notify(
			string.format("Removing stale task: %s (PID: %d no longer exists)", task.name, task.pid),
			vim.log.levels.INFO
		)
		task.status = "stopped"
		removed = removed + 1
	end

	if removed > 0 then
		vim.notify(string.format("Cleaned up %d stale task(s)", removed), vim.log.levels.INFO)
	else
		vim.notify("No stale tasks found", vim.log.levels.INFO)
	end

	return removed
end

-- Auto-save session after task state changes
local function auto_save_session()
	vim.schedule(function()
		M.save_session()
	end)
end

-- Wrap run_task to auto-save after starting
local original_run_task = M.run_task
function M.run_task(...)
	local task_id = original_run_task(...)
	if task_id then
		auto_save_session()
	end
	return task_id
end

-- Wrap stop_task to auto-save after stopping
local original_stop_task = M.stop_task
function M.stop_task(...)
	local result = original_stop_task(...)
	if result then
		auto_save_session()
	end
	return result
end

return M
