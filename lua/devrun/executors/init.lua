-- Executor Registry: Manages different task executors
local M = {}

-- Lazy-loaded executors
M.executors = nil

-- Initialize executors (lazy loading)
local function init_executors()
	if not M.executors then
		M.executors = {
			gradle = require("devrun.executors.gradle"),
			tomcat = require("devrun.executors.tomcat"),
			command = require("devrun.executors.command"),
		}
	end
	return M.executors
end

-- Get executor by type
function M.get_executor(type)
	local executors = init_executors()

	-- Default to gradle for backward compatibility
	if not type or type == "" then
		return executors.gradle
	end

	local executor = executors[type]
	if not executor then
		vim.notify(
			string.format("Unknown executor type '%s', falling back to 'command' executor", type),
			vim.log.levels.WARN
		)
		return executors.command
	end

	return executor
end

-- Validate configuration with appropriate executor
function M.validate_config(config)
	local executor = M.get_executor(config.type)

	if not executor.validate then
		return {}
	end

	return executor.validate(config)
end

-- Get list of all available executor types
function M.get_available_types()
	local executors = init_executors()
	local types = {}

	for type_name, executor in pairs(executors) do
		local metadata = executor.get_metadata and executor.get_metadata() or { type = type_name }
		table.insert(types, metadata)
	end

	return types
end

-- Check if executor supports a specific feature
function M.supports_feature(type, feature)
	local executor = M.get_executor(type)
	local metadata = executor.get_metadata and executor.get_metadata() or {}

	if feature == "debug" then
		return metadata.supports_debug or false
	end

	return false
end

return M
