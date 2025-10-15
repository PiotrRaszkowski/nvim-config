-- DevRun Variable Resolution System
-- Provides VSCode-compatible variable substitution for run configurations
local M = {}

-- Get current file info (safely handles no open file)
local function get_file_info()
	local file = vim.fn.expand("%:p")
	if file == "" or file == vim.fn.getcwd() then
		return nil
	end
	return {
		path = file,
		basename = vim.fn.fnamemodify(file, ":t"),
		basename_no_ext = vim.fn.fnamemodify(file, ":t:r"),
		dirname = vim.fn.fnamemodify(file, ":h"),
		extname = vim.fn.fnamemodify(file, ":e"),
		relative = vim.fn.expand("%"),
		relative_dirname = vim.fn.fnamemodify(vim.fn.expand("%"), ":h"),
	}
end

-- Main variable resolution function
-- @param str string: String containing variables to resolve
-- @param config table: Optional config object for ${config:field} references
-- @return string: Resolved string with variables substituted
function M.resolve(str, config)
	if not str or str == "" then
		return str
	end

	local resolved = str
	local workspace = vim.fn.getcwd()

	-- Path variables
	resolved = resolved:gsub("%$%{workspaceFolder%}", workspace)
	resolved = resolved:gsub("%$%{workspaceFolderBasename%}", vim.fn.fnamemodify(workspace, ":t"))
	resolved = resolved:gsub("%$%{userHome%}", vim.fn.expand("~"))

	-- File variables (with safe defaults)
	local file_info = get_file_info()
	if file_info then
		resolved = resolved:gsub("%$%{file%}", file_info.path)
		resolved = resolved:gsub("%$%{fileBasename%}", file_info.basename)
		resolved = resolved:gsub("%$%{fileBasenameNoExtension%}", file_info.basename_no_ext)
		resolved = resolved:gsub("%$%{fileDirname%}", file_info.dirname)
		resolved = resolved:gsub("%$%{fileExtname%}", file_info.extname)
		resolved = resolved:gsub("%$%{relativeFile%}", file_info.relative)
		resolved = resolved:gsub("%$%{relativeFileDirname%}", file_info.relative_dirname)
	end

	-- Project variables
	resolved = resolved:gsub("%$%{projectName%}", vim.fn.fnamemodify(workspace, ":t"))
	resolved = resolved:gsub("%$%{buildDir%}", "build")
	resolved = resolved:gsub("%$%{targetDir%}", "build")

	-- Date/time variables
	resolved = resolved:gsub("%$%{date%}", os.date("%Y-%m-%d"))
	resolved = resolved:gsub("%$%{time%}", os.date("%H:%M:%S"))
	resolved = resolved:gsub("%$%{timestamp%}", tostring(os.time()))

	-- Random number (6 digits)
	resolved = resolved:gsub("%$%{random%}", tostring(math.random(100000, 999999)))

	-- Environment variables: ${env:VAR_NAME}
	resolved = resolved:gsub("%$%{env:([^}]+)%}", function(var_name)
		local value = vim.fn.getenv(var_name)
		if value == vim.NIL or value == nil then
			vim.notify(
				string.format("Warning: Environment variable '%s' not set, using empty string", var_name),
				vim.log.levels.WARN
			)
			return ""
		end
		return value
	end)

	-- Config references: ${config:field}
	if config then
		resolved = resolved:gsub("%$%{config:([^}]+)%}", function(field_name)
			local value = config[field_name]
			if value == nil then
				vim.notify(
					string.format("Warning: Config field '%s' not found, using empty string", field_name),
					vim.log.levels.WARN
				)
				return ""
			end
			return tostring(value)
		end)
	end

	-- Backward compatibility: ${workspacePath} -> ${workspaceFolder}
	if resolved:match("%$%{workspacePath%}") then
		vim.notify("Warning: ${workspacePath} is deprecated, use ${workspaceFolder}", vim.log.levels.WARN)
		resolved = resolved:gsub("%$%{workspacePath%}", workspace)
	end

	return resolved
end

-- Helper: Resolve variables in a config object (recursive)
-- @param config table: Configuration object
-- @return table: Config with all string values resolved
function M.resolve_config(config)
	if type(config) ~= "table" then
		return config
	end

	local resolved = {}
	for key, value in pairs(config) do
		if type(value) == "string" then
			resolved[key] = M.resolve(value, config)
		elseif type(value) == "table" then
			resolved[key] = M.resolve_config(value)
		else
			resolved[key] = value
		end
	end
	return resolved
end

-- Get documentation for all variables
-- @return table: Categorized variable documentation
function M.get_documentation()
	return {
		["Path Variables"] = {
			["${workspaceFolder}"] = "Current workspace directory (cwd)",
			["${workspaceFolderBasename}"] = "Workspace folder name (e.g., 'myproject')",
			["${userHome}"] = "User home directory (e.g., '/Users/username')",
			["${file}"] = "Currently open file (absolute path)",
			["${fileBasename}"] = "File name with extension (e.g., 'Main.java')",
			["${fileBasenameNoExtension}"] = "File name without extension (e.g., 'Main')",
			["${fileDirname}"] = "Directory containing current file",
			["${fileExtname}"] = "File extension (e.g., 'java')",
			["${relativeFile}"] = "File path relative to workspace",
			["${relativeFileDirname}"] = "File directory relative to workspace",
		},
		["Project Variables"] = {
			["${projectName}"] = "Project name (from workspace folder name)",
			["${buildDir}"] = "Build output directory (default: 'build')",
			["${targetDir}"] = "Target directory (default: 'build')",
		},
		["Date/Time Variables"] = {
			["${date}"] = "Current date (YYYY-MM-DD format)",
			["${time}"] = "Current time (HH:MM:SS format)",
			["${timestamp}"] = "Unix timestamp (seconds since epoch)",
		},
		["Special Variables"] = {
			["${env:NAME}"] = "Environment variable value (e.g., ${env:JAVA_HOME})",
			["${config:field}"] = "Reference to config field value (e.g., ${config:httpPort})",
			["${random}"] = "Random 6-digit number (useful for ports)",
		},
	}
end

-- Format documentation as readable text
-- @return table: Lines of formatted documentation
function M.format_documentation()
	local lines = {}
	table.insert(lines, "=== DevRun Variables Documentation ===")
	table.insert(lines, "")

	local docs = M.get_documentation()
	for category, vars in pairs(docs) do
		table.insert(lines, category .. ":")
		table.insert(lines, string.rep("-", #category + 1))
		for var, desc in pairs(vars) do
			table.insert(lines, string.format("  %-35s %s", var, desc))
		end
		table.insert(lines, "")
	end

	table.insert(lines, "Examples:")
	table.insert(lines, "----------")
	table.insert(lines, "  ${workspaceFolder}/build/libs/${projectName}.war")
	table.insert(lines, "  ${userHome}/tomcat9")
	table.insert(lines, "  ${env:JAVA_HOME}/bin/java")
	table.insert(lines, "  ${workspaceFolder}/logs/app-${date}.log")
	table.insert(lines, "  http://localhost:${config:httpPort}")
	table.insert(lines, "")
	table.insert(lines, "Note: VSCode-compatible syntax for easy migration")

	return lines
end

-- Get current values for all variables (for debugging/display)
-- @param config table: Optional config for ${config:field} resolution
-- @return table: Variable names mapped to current values
function M.get_current_values(config)
	local workspace = vim.fn.getcwd()
	local file_info = get_file_info()

	local values = {
		["Path Variables"] = {
			["${workspaceFolder}"] = workspace,
			["${workspaceFolderBasename}"] = vim.fn.fnamemodify(workspace, ":t"),
			["${userHome}"] = vim.fn.expand("~"),
		},
		["Project Variables"] = {
			["${projectName}"] = vim.fn.fnamemodify(workspace, ":t"),
			["${buildDir}"] = "build",
			["${targetDir}"] = "build",
		},
		["Date/Time Variables"] = {
			["${date}"] = os.date("%Y-%m-%d"),
			["${time}"] = os.date("%H:%M:%S"),
			["${timestamp}"] = tostring(os.time()),
		},
		["Special Variables"] = {
			["${random}"] = tostring(math.random(100000, 999999)),
		},
	}

	if file_info then
		values["Path Variables"]["${file}"] = file_info.path
		values["Path Variables"]["${fileBasename}"] = file_info.basename
		values["Path Variables"]["${fileBasenameNoExtension}"] = file_info.basename_no_ext
		values["Path Variables"]["${fileDirname}"] = file_info.dirname
		values["Path Variables"]["${fileExtname}"] = file_info.extname
		values["Path Variables"]["${relativeFile}"] = file_info.relative
		values["Path Variables"]["${relativeFileDirname}"] = file_info.relative_dirname
	else
		values["Path Variables"]["${file}"] = "(no file open)"
		values["Path Variables"]["${fileBasename}"] = "(no file open)"
	end

	return values
end

return M
