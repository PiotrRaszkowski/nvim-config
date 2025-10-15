-- Task Manager: Handles task execution, tracking, and process management
local M = {}

local executors = require("devrun.executors")

-- Active tasks registry
-- Structure: { task_id = { name, executor_info, start_time, status, config, type } }
M.active_tasks = {}
M.task_counter = 0
M.log_callbacks = {}

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

return M
