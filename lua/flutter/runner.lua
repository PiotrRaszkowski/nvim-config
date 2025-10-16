-- Runner: Manages Flutter app execution (run/attach/reload/restart/detach)
local M = {}

-- Active Flutter apps registry
-- Structure: { app_id = { id, name, device_id, job_id, stdin_chan, status, start_time } }
M.running_apps = {}
M.app_counter = 0

-- Current active app (for commands without app selection)
M.current_app_id = nil

-- Generate unique app ID
local function generate_app_id()
	M.app_counter = M.app_counter + 1
	return M.app_counter
end

-- Get logger (lazy load to avoid circular dependency)
local function get_logger()
	return require("flutter.logger")
end

-- Run Flutter app on device
function M.run_on_device(device_id, opts)
	opts = opts or {}
	local app_name = opts.app_name or "Flutter App"

	if not device_id then
		vim.notify("No device selected", vim.log.levels.ERROR)
		return nil
	end

	local app_id = generate_app_id()

	vim.notify(string.format("Starting Flutter app on device: %s", device_id), vim.log.levels.INFO)

	-- Build flutter run command
	local cmd = string.format("flutter run -d %s", device_id)

	-- Add additional flags if provided
	if opts.flavor then
		cmd = cmd .. string.format(" --flavor %s", opts.flavor)
	end
	if opts.debug == false then
		cmd = cmd .. " --release"
	end

	-- Initialize app entry
	M.running_apps[app_id] = {
		id = app_id,
		name = app_name,
		device_id = device_id,
		job_id = nil,
		stdin_chan = nil,
		status = "starting",
		start_time = os.time(),
	}

	-- Initialize logger for this app
	local logger = get_logger()
	logger.init_app_log(app_id, app_name)

	-- Start Flutter run job
	local job_id = vim.fn.jobstart(cmd, {
		pty = true, -- Use PTY for interactive mode
		on_stdout = function(_, data)
			if data and #data > 0 then
				vim.schedule(function()
					logger.append_output(app_id, data, "stdout")
				end)
			end
		end,
		on_stderr = function(_, data)
			if data and #data > 0 then
				vim.schedule(function()
					logger.append_output(app_id, data, "stderr")
				end)
			end
		end,
		on_exit = function(_, exit_code)
			vim.schedule(function()
				local app = M.running_apps[app_id]
				if app then
					app.status = exit_code == 0 and "stopped" or "failed"
					vim.notify(
						string.format("Flutter app '%s' exited (code: %d)", app.name, exit_code),
						exit_code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR
					)

					-- If this was the current app, clear it
					if M.current_app_id == app_id then
						M.current_app_id = nil
					end
				end
			end)
		end,
	})

	if job_id <= 0 then
		vim.notify("Failed to start Flutter app", vim.log.levels.ERROR)
		M.running_apps[app_id] = nil
		return nil
	end

	-- Update app with job info
	M.running_apps[app_id].job_id = job_id
	M.running_apps[app_id].stdin_chan = job_id -- For pty mode, job_id is stdin channel
	M.running_apps[app_id].status = "running"

	-- Set as current app
	M.current_app_id = app_id

	-- Open log window
	logger.open(app_id)

	vim.notify(string.format("Flutter app started (ID: %d)", app_id), vim.log.levels.INFO)

	return app_id
end

-- Attach to running Flutter app
function M.attach_to_device(device_id, opts)
	opts = opts or {}
	local app_name = opts.app_name or "Flutter App (attached)"

	if not device_id then
		vim.notify("No device selected", vim.log.levels.ERROR)
		return nil
	end

	local app_id = generate_app_id()

	vim.notify(string.format("Attaching to Flutter app on device: %s", device_id), vim.log.levels.INFO)

	-- Build flutter attach command
	local cmd = string.format("flutter attach -d %s", device_id)

	-- Initialize app entry
	M.running_apps[app_id] = {
		id = app_id,
		name = app_name,
		device_id = device_id,
		job_id = nil,
		stdin_chan = nil,
		status = "attaching",
		start_time = os.time(),
		attached = true,
	}

	-- Initialize logger for this app
	local logger = get_logger()
	logger.init_app_log(app_id, app_name)

	-- Start Flutter attach job
	local job_id = vim.fn.jobstart(cmd, {
		pty = true,
		on_stdout = function(_, data)
			if data and #data > 0 then
				vim.schedule(function()
					logger.append_output(app_id, data, "stdout")
				end)
			end
		end,
		on_stderr = function(_, data)
			if data and #data > 0 then
				vim.schedule(function()
					logger.append_output(app_id, data, "stderr")
				end)
			end
		end,
		on_exit = function(_, exit_code)
			vim.schedule(function()
				local app = M.running_apps[app_id]
				if app then
					app.status = "detached"
					vim.notify(
						string.format("Detached from Flutter app '%s'", app.name),
						vim.log.levels.INFO
					)

					if M.current_app_id == app_id then
						M.current_app_id = nil
					end
				end
			end)
		end,
	})

	if job_id <= 0 then
		vim.notify("Failed to attach to Flutter app", vim.log.levels.ERROR)
		M.running_apps[app_id] = nil
		return nil
	end

	-- Update app with job info
	M.running_apps[app_id].job_id = job_id
	M.running_apps[app_id].stdin_chan = job_id
	M.running_apps[app_id].status = "running"

	-- Set as current app
	M.current_app_id = app_id

	-- Open log window
	logger.open(app_id)

	vim.notify(string.format("Attached to Flutter app (ID: %d)", app_id), vim.log.levels.INFO)

	return app_id
end

-- Send command to Flutter app stdin
local function send_stdin(app_id, command)
	local app = M.running_apps[app_id]
	if not app then
		vim.notify("App not found", vim.log.levels.ERROR)
		return false
	end

	if app.status ~= "running" then
		vim.notify("App is not running", vim.log.levels.WARN)
		return false
	end

	if not app.stdin_chan then
		vim.notify("No stdin channel available", vim.log.levels.ERROR)
		return false
	end

	-- Send command to stdin
	vim.fn.chansend(app.stdin_chan, command .. "\n")
	return true
end

-- Hot reload (preserves app state)
function M.hot_reload(app_id)
	app_id = app_id or M.current_app_id
	if not app_id then
		vim.notify("No active Flutter app", vim.log.levels.WARN)
		return false
	end

	vim.notify("Triggering hot reload...", vim.log.levels.INFO)
	return send_stdin(app_id, "r")
end

-- Hot restart (resets app state)
function M.hot_restart(app_id)
	app_id = app_id or M.current_app_id
	if not app_id then
		vim.notify("No active Flutter app", vim.log.levels.WARN)
		return false
	end

	vim.notify("Triggering hot restart...", vim.log.levels.INFO)
	return send_stdin(app_id, "R")
end

-- Detach from app (without stopping it)
function M.detach(app_id)
	app_id = app_id or M.current_app_id
	if not app_id then
		vim.notify("No active Flutter app", vim.log.levels.WARN)
		return false
	end

	local app = M.running_apps[app_id]
	if not app then
		vim.notify("App not found", vim.log.levels.ERROR)
		return false
	end

	if app.attached then
		vim.notify("Detaching from Flutter app...", vim.log.levels.INFO)
		return send_stdin(app_id, "d")
	else
		vim.notify("Cannot detach from app that wasn't attached", vim.log.levels.WARN)
		return false
	end
end

-- Quit app (stops the app)
function M.quit(app_id)
	app_id = app_id or M.current_app_id
	if not app_id then
		vim.notify("No active Flutter app", vim.log.levels.WARN)
		return false
	end

	local app = M.running_apps[app_id]
	if not app then
		vim.notify("App not found", vim.log.levels.ERROR)
		return false
	end

	vim.notify("Stopping Flutter app...", vim.log.levels.INFO)

	-- Send quit command
	send_stdin(app_id, "q")

	-- Wait briefly, then force kill if needed
	vim.defer_fn(function()
		if app.job_id and app.status == "running" then
			vim.fn.jobstop(app.job_id)
		end
	end, 2000)

	return true
end

-- Get all running apps
function M.get_running_apps()
	local apps = {}
	for _, app in pairs(M.running_apps) do
		if app.status == "running" then
			table.insert(apps, app)
		end
	end
	return apps
end

-- Get current app
function M.get_current_app()
	return M.running_apps[M.current_app_id]
end

-- Set current app
function M.set_current_app(app_id)
	if M.running_apps[app_id] then
		M.current_app_id = app_id
		return true
	end
	return false
end

-- Other Flutter commands via stdin
function M.send_command(command, app_id)
	app_id = app_id or M.current_app_id
	if not app_id then
		vim.notify("No active Flutter app", vim.log.levels.WARN)
		return false
	end

	return send_stdin(app_id, command)
end

return M
