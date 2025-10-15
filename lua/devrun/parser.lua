-- Configuration Parser: Loads and validates run configurations from JSON
local M = {}

local executors = require("devrun.executors")

-- Default configuration file paths (searched in order)
M.config_paths = {
	".nvim/run-configurations.json", -- Project-local (highest priority)
	vim.fn.stdpath("config") .. "/run-configurations.json", -- Global config
}

-- Cached configurations
M.cached_configs = nil
M.cached_file_path = nil

-- Validate a single configuration
local function validate_config(config, index)
	local errors = {}

	-- Validate name
	if not config.name or config.name == "" then
		table.insert(errors, string.format("Config #%d: 'name' is required", index))
	end

	-- Set default type if not specified (backward compatibility)
	if not config.type or config.type == "" then
		config.type = "gradle"
	end

	-- Validate with executor-specific validation
	local executor_errors = executors.validate_config(config)
	for _, err in ipairs(executor_errors) do
		table.insert(
			errors,
			string.format("Config #%d (%s): %s", index, config.name or "unnamed", err)
		)
	end

	return errors
end

-- Find configuration file
function M.find_config_file()
	for _, path in ipairs(M.config_paths) do
		local full_path = vim.fn.expand(path)
		if vim.fn.filereadable(full_path) == 1 then
			return full_path
		end
	end
	return nil
end

-- Load configurations from file
function M.load_configurations(force_reload)
	-- Return cached if available and not forcing reload
	if M.cached_configs and not force_reload then
		return M.cached_configs, M.cached_file_path
	end

	-- Find config file
	local config_file = M.find_config_file()
	if not config_file then
		return nil, "No run-configurations.json found. Create one at .nvim/run-configurations.json"
	end

	-- Read file
	local file = io.open(config_file, "r")
	if not file then
		return nil, "Could not open file: " .. config_file
	end

	local content = file:read("*all")
	file:close()

	-- Parse JSON
	local ok, parsed = pcall(vim.json.decode, content)
	if not ok then
		return nil, "Invalid JSON in " .. config_file .. ": " .. tostring(parsed)
	end

	-- Validate structure
	if not parsed.configurations or type(parsed.configurations) ~= "table" then
		return nil, "Config file must have 'configurations' array"
	end

	-- Validate each configuration
	local all_errors = {}
	for i, config in ipairs(parsed.configurations) do
		local errors = validate_config(config, i)
		vim.list_extend(all_errors, errors)
	end

	if #all_errors > 0 then
		return nil, "Validation errors:\n" .. table.concat(all_errors, "\n")
	end

	-- Apply defaults
	for _, config in ipairs(parsed.configurations) do
		-- Set default type if not specified (backward compatibility)
		config.type = config.type or "gradle"

		-- Common defaults
		config.cwd = config.cwd or "${workspaceFolder}"
		config.env = config.env or {}

		-- Type-specific defaults
		if config.type == "gradle" or config.type == "tomcat" then
			config.vmArgs = config.vmArgs or {}
		end

		if config.type == "tomcat" then
			config.httpPort = config.httpPort or 8080
			config.cleanDeploy = config.cleanDeploy or false
		end
	end

	-- Cache results
	M.cached_configs = parsed.configurations
	M.cached_file_path = config_file

	return parsed.configurations, config_file
end

-- Get configuration by name
function M.get_config_by_name(name)
	local configs, err = M.load_configurations()
	if not configs then
		return nil, err
	end

	for _, config in ipairs(configs) do
		if config.name == name then
			return config
		end
	end

	return nil, "Configuration '" .. name .. "' not found"
end

-- Get all configuration names
function M.get_config_names()
	local configs, err = M.load_configurations()
	if not configs then
		return nil, err
	end

	local names = {}
	for _, config in ipairs(configs) do
		table.insert(names, config.name)
	end

	return names
end

-- Reload configurations (clear cache)
function M.reload()
	M.cached_configs = nil
	M.cached_file_path = nil
	return M.load_configurations(true)
end

-- Create example configuration file
function M.create_example_config()
	local example = {
		["$schema"] = "./run-configurations.schema.json",
		configurations = {
			{
				name = "Clean",
				type = "gradle",
				command = "./gradlew clean",
				cwd = "${workspaceFolder}",
			},
			{
				name = "Build WAR",
				type = "gradle",
				command = "./gradlew war",
				beforeRun = "Clean",
				cwd = "${workspaceFolder}",
			},
			{
				name = "Spring Boot Dev",
				type = "gradle",
				command = "./gradlew clean bootRun",
				vmArgs = { "-Dspring.profiles.active=dev", "-Xmx2G" },
				cwd = "${workspaceFolder}",
				env = {
					SPRING_PROFILES_ACTIVE = "dev",
				},
			},
			{
				name = "Tomcat 9 Dev",
				type = "tomcat",
				beforeRun = "Build WAR",
				tomcatHome = "/usr/local/tomcat9",
				artifact = "${workspaceFolder}/build/libs/myapp-1.0.0.war",
				httpPort = 8080,
				debugPort = 5005,
				contextPath = "myapp",
				vmArgs = { "-Xmx1G", "-Dspring.profiles.active=dev" },
				cleanDeploy = true,
				cwd = "${workspaceFolder}",
			},
			{
				name = "Test",
				type = "gradle",
				command = "./gradlew test",
				cwd = "${workspaceFolder}",
			},
			{
				name = "Custom Script",
				type = "command",
				command = "./deploy.sh",
				cwd = "${workspaceFolder}",
			},
		},
	}

	-- Create .nvim directory if it doesn't exist
	local nvim_dir = vim.fn.getcwd() .. "/.nvim"
	if vim.fn.isdirectory(nvim_dir) == 0 then
		vim.fn.mkdir(nvim_dir, "p")
	end

	local config_path = nvim_dir .. "/run-configurations.json"

	-- Check if file already exists
	if vim.fn.filereadable(config_path) == 1 then
		return nil, "Configuration file already exists at: " .. config_path
	end

	-- Write example config
	local file = io.open(config_path, "w")
	if not file then
		return nil, "Could not create file: " .. config_path
	end

	file:write(vim.json.encode(example))
	file:close()

	-- Copy schema file to project
	local schema_source = vim.fn.stdpath("config") .. "/schemas/run-configurations.schema.json"
	local schema_dest = nvim_dir .. "/run-configurations.schema.json"

	if vim.fn.filereadable(schema_source) == 1 and vim.fn.filereadable(schema_dest) == 0 then
		local copy_cmd = string.format("cp '%s' '%s'", schema_source, schema_dest)
		vim.fn.system(copy_cmd)
	end

	return config_path, nil
end

-- Pretty-format JSON with indentation
local function format_json_pretty(config_table)
	-- Use vim.json.encode with custom formatting
	local json = vim.json.encode(config_table)

	-- Add indentation (2 spaces per level)
	local formatted = json:gsub("({)", "{\n  ")
	formatted = formatted:gsub("(,)", ",\n  ")
	formatted = formatted:gsub("(})", "\n}")
	formatted = formatted:gsub("(%[)", "[\n    ")
	formatted = formatted:gsub("(%])", "\n  ]")

	-- Note: This is a simple formatter. For production use, consider a proper JSON formatter.
	-- For now, we'll use vim.fn.json_encode which may have better formatting.

	-- Better approach: Use vim.fn.system with jq if available, otherwise use simple formatting
	local jq_path = vim.fn.executable("jq")
	if jq_path == 1 then
		local input_json = vim.json.encode(config_table)
		local formatted_json = vim.fn.system("jq .", input_json)
		if vim.v.shell_error == 0 then
			return formatted_json
		end
	end

	-- Fallback: Use Lua's own formatting (simple indentation)
	return vim.fn.json_encode(config_table)
end

-- Add new configuration to existing file
function M.add_configuration(new_config)
	-- Ensure config file exists
	local config_file = M.find_config_file()

	if not config_file then
		-- Create new config file if it doesn't exist
		local result, err = M.create_example_config()
		if not result then
			return nil, "Failed to create config file: " .. (err or "unknown error")
		end
		config_file = result
	end

	-- Load existing configurations
	local configs, err = M.load_configurations(true) -- Force reload
	if not configs then
		-- If file exists but can't be loaded, try to create a fresh one
		configs = {}
	end

	-- Validate new configuration
	local errors = validate_config(new_config, #configs + 1)
	if #errors > 0 then
		return nil, "Validation errors:\n" .. table.concat(errors, "\n")
	end

	-- Check name uniqueness
	for _, config in ipairs(configs) do
		if config.name == new_config.name then
			return nil, "Configuration name already exists: " .. new_config.name
		end
	end

	-- Apply defaults if not set
	new_config.type = new_config.type or "gradle"
	new_config.cwd = new_config.cwd or "${workspaceFolder}"
	new_config.env = new_config.env or {}

	-- Type-specific defaults
	if new_config.type == "gradle" or new_config.type == "tomcat" then
		new_config.vmArgs = new_config.vmArgs or {}
	end

	if new_config.type == "tomcat" then
		new_config.httpPort = new_config.httpPort or 8080
		new_config.cleanDeploy = new_config.cleanDeploy or false
	end

	-- Append to configurations array
	table.insert(configs, new_config)

	-- Prepare full config structure
	local full_config = {
		["$schema"] = "./run-configurations.schema.json",
		configurations = configs,
	}

	-- Write to file with pretty formatting
	local formatted_json = format_json_pretty(full_config)

	local file = io.open(config_file, "w")
	if not file then
		return nil, "Could not open file for writing: " .. config_file
	end

	file:write(formatted_json)
	file:close()

	-- Reload cache
	M.reload()

	return config_file, nil
end

return M
