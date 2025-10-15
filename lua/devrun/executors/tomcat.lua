-- Tomcat Executor: Handles Tomcat server deployment and execution
local M = {}

local variables = require("devrun.variables")

-- Extract WAR name from file or directory path
-- For packed WAR: removes .war extension
-- For exploded WAR: uses directory name
local function extract_war_name(war_path)
	local basename = vim.fn.fnamemodify(war_path, ":t")
	-- Remove .war extension if present, otherwise use basename as-is
	return basename:match("(.+)%.war$") or basename
end

-- Validate Tomcat configuration
function M.validate(config)
	local errors = {}

	if not config.tomcatHome or config.tomcatHome == "" then
		table.insert(errors, "tomcatHome is required for Tomcat type")
	else
		local tomcat_home = variables.resolve(config.tomcatHome, config)
		if vim.fn.isdirectory(tomcat_home) == 0 then
			table.insert(errors, "tomcatHome directory not found: " .. tomcat_home)
		elseif vim.fn.filereadable(tomcat_home .. "/bin/catalina.sh") == 0 then
			table.insert(errors, "catalina.sh not found in tomcatHome: " .. tomcat_home)
		end
	end

	if not config.artifact or config.artifact == "" then
		table.insert(errors, "artifact is required for Tomcat type")
	else
		local artifact = variables.resolve(config.artifact, config)
		local is_war_file = artifact:match("%.war$")
		local is_directory = vim.fn.isdirectory(artifact) == 1

		-- Accept either .war file or directory, but validate structure if checking exists
		if not is_war_file and not is_directory then
			-- If it doesn't exist yet, it should at least look like a WAR path or directory path
			if not artifact:match("%.war$") and not artifact:match("/$") then
				vim.notify(
					"Artifact should be either a .war file or a directory path: " .. artifact,
					vim.log.levels.WARN
				)
			end
		end

		-- If directory exists, validate it has web app structure
		if is_directory then
			local web_inf = artifact .. "/WEB-INF"
			if vim.fn.isdirectory(web_inf) == 0 then
				table.insert(errors, "Exploded WAR must contain WEB-INF directory: " .. artifact)
			end
		end
		-- Note: We don't check if artifact exists yet because it might be built by beforeRun
	end

	if config.httpPort and (config.httpPort < 1024 or config.httpPort > 65535) then
		table.insert(errors, "httpPort must be between 1024 and 65535")
	end

	if config.debugPort and (config.debugPort < 1024 or config.debugPort > 65535) then
		table.insert(errors, "debugPort must be between 1024 and 65535")
	end

	if config.contextPath and not config.contextPath:match("^[a-zA-Z0-9_-]+$") then
		table.insert(errors, "contextPath must contain only alphanumeric characters, underscores, and hyphens")
	end

	return errors
end

-- Deploy WAR file or exploded WAR directory to Tomcat webapps directory
local function deploy_artifact(config)
	local artifact = variables.resolve(config.artifact, config)
	local tomcat_home = variables.resolve(config.tomcatHome, config)
	local context = config.contextPath or extract_war_name(artifact)
	local target_dir = tomcat_home .. "/webapps"
	local target_war = target_dir .. "/" .. context .. ".war"
	local target_exploded = target_dir .. "/" .. context

	-- Detect artifact type (packed WAR file or exploded WAR directory)
	local is_file = vim.fn.filereadable(artifact) == 1
	local is_directory = vim.fn.isdirectory(artifact) == 1

	-- Check if artifact exists
	if not is_file and not is_directory then
		return nil, "Artifact not found: " .. artifact .. " (ensure beforeRun task builds it)"
	end

	-- Create webapps directory if it doesn't exist
	if vim.fn.isdirectory(target_dir) == 0 then
		vim.fn.mkdir(target_dir, "p")
	end

	-- Clean deployment if requested
	if config.cleanDeploy then
		vim.notify("Cleaning previous deployment...", vim.log.levels.INFO)
		vim.fn.delete(target_war)
		vim.fn.delete(target_exploded, "rf")
	end

	if is_file then
		-- Deploy packed WAR file
		vim.notify(
			string.format("Deploying packed WAR %s to %s...", vim.fn.fnamemodify(artifact, ":t"), context),
			vim.log.levels.INFO
		)
		local copy_cmd = string.format("cp '%s' '%s'", artifact, target_war)
		local result = vim.fn.system(copy_cmd)

		if vim.v.shell_error ~= 0 then
			return nil, "Failed to copy WAR file: " .. result
		end

		return target_war, nil
	else
		-- Deploy exploded WAR directory
		vim.notify(
			string.format("Deploying exploded WAR from %s to %s...", vim.fn.fnamemodify(artifact, ":t"), context),
			vim.log.levels.INFO
		)

		-- Try rsync first (faster and better for incremental updates)
		local rsync_cmd = string.format("rsync -av --delete '%s/' '%s/'", artifact, target_exploded)
		local result = vim.fn.system("command -v rsync >/dev/null 2>&1 && echo 'yes' || echo 'no'")

		if result:match("yes") then
			-- rsync is available
			result = vim.fn.system(rsync_cmd)
			if vim.v.shell_error ~= 0 then
				return nil, "Failed to sync exploded WAR with rsync: " .. result
			end
		else
			-- Fall back to recursive cp
			vim.notify("rsync not found, using cp -r (slower)", vim.log.levels.WARN)
			local cp_cmd = string.format("cp -r '%s' '%s'", artifact, target_exploded)
			result = vim.fn.system(cp_cmd)
			if vim.v.shell_error ~= 0 then
				return nil, "Failed to copy exploded WAR: " .. result
			end
		end

		return target_exploded, nil
	end
end

-- Build catalina.sh command
local function build_command(config)
	local tomcat_home = variables.resolve(config.tomcatHome, config)
	local script = config.debugPort and "jpda run" or "run"
	return string.format("%s/bin/catalina.sh %s", tomcat_home, script)
end

-- Build environment variables for Tomcat
local function build_env(config)
	local env = vim.tbl_extend("force", vim.fn.environ(), config.env or {})

	-- Add VM args to JAVA_OPTS
	if config.vmArgs and #config.vmArgs > 0 then
		local java_opts = table.concat(config.vmArgs, " ")
		env.JAVA_OPTS = (env.JAVA_OPTS or "") .. " " .. java_opts
	end

	-- Add JPDA settings if debug port specified
	if config.debugPort then
		env.JPDA_ADDRESS = tostring(config.debugPort)
		env.JPDA_TRANSPORT = "dt_socket"
		vim.notify(
			string.format("Remote debugging enabled on port %d", config.debugPort),
			vim.log.levels.INFO
		)
	end

	-- Set CATALINA_HOME and CATALINA_BASE
	local tomcat_home = variables.resolve(config.tomcatHome, config)
	env.CATALINA_HOME = tomcat_home
	env.CATALINA_BASE = tomcat_home

	return env
end

-- Execute Tomcat task
function M.execute(config, callbacks)
	-- Deploy artifact first
	local deployed_war, deploy_err = deploy_artifact(config)
	if not deployed_war then
		vim.notify("Deployment failed: " .. deploy_err, vim.log.levels.ERROR)
		if callbacks.on_exit then
			callbacks.on_exit(1)
		end
		return nil
	end

	vim.notify("Artifact deployed successfully", vim.log.levels.INFO)

	-- Build command and env
	local cmd = build_command(config)
	local env = build_env(config)
	local cwd = variables.resolve(config.cwd, config) or variables.resolve(config.tomcatHome, config)

	-- Notify user about server startup
	local context = config.contextPath or extract_war_name(variables.resolve(config.artifact, config))
	local http_port = config.httpPort or 8080
	vim.notify(
		string.format("Starting Tomcat server on port %d (context: /%s)...", http_port, context),
		vim.log.levels.INFO
	)

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
		tomcat_home = variables.resolve(config.tomcatHome, config),
		context_path = context,
		http_port = http_port,
	}
end

-- Stop Tomcat gracefully using catalina.sh
function M.stop(task_info)
	if not task_info.tomcat_home then
		vim.notify("Cannot stop Tomcat: tomcat_home not found in task info", vim.log.levels.ERROR)
		return false
	end

	vim.notify("Stopping Tomcat server gracefully...", vim.log.levels.INFO)

	-- Use catalina.sh stop for graceful shutdown
	local stop_cmd = string.format("%s/bin/catalina.sh stop", task_info.tomcat_home)
	local result = vim.fn.system(stop_cmd)

	if vim.v.shell_error == 0 then
		vim.notify("Tomcat shutdown initiated", vim.log.levels.INFO)

		-- Also kill the process if it's still running
		if task_info.process then
			vim.defer_fn(function()
				task_info.process:kill(15) -- SIGTERM after graceful stop
			end, 2000) -- Wait 2 seconds for graceful shutdown
		end

		return true
	else
		vim.notify("Failed to stop Tomcat: " .. result, vim.log.levels.ERROR)

		-- Force kill as fallback
		if task_info.process then
			task_info.process:kill(9) -- SIGKILL
			return true
		end

		return false
	end
end

-- Get executor metadata
function M.get_metadata()
	return {
		type = "tomcat",
		description = "Apache Tomcat server deployment and execution",
		supports_debug = true,
	}
end

return M
