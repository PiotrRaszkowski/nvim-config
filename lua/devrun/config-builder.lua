-- Configuration Builder: Interactive GUI for creating run configurations using Telescope
local M = {}

local parser = require("devrun.parser")
local executors = require("devrun.executors")

-- Field schema definitions (derived from JSON schema)
local field_schemas = {
	common = {
		{ name = "name", label = "Configuration Name", required = true, type = "string" },
		{ name = "beforeRun", label = "Before Run Task (optional)", required = false, type = "select" },
		{ name = "cwd", label = "Working Directory", required = false, type = "string", default = "${workspaceFolder}" },
		{ name = "env", label = "Environment Variables", required = false, type = "multimap" },
	},
	gradle = {
		{ name = "command", label = "Gradle Command", required = true, type = "string", placeholder = "./gradlew bootRun" },
		{
			name = "vmArgs",
			label = "JVM Arguments",
			required = false,
			type = "multivalue",
			placeholder = "-Xmx2G",
		},
	},
	tomcat = {
		{
			name = "tomcatHome",
			label = "Tomcat Installation Path",
			required = true,
			type = "path",
			placeholder = "/usr/local/tomcat9",
		},
		{
			name = "artifact",
			label = "WAR Artifact (file or directory)",
			required = true,
			type = "path",
			placeholder = "${workspaceFolder}/build/libs/app.war or exploded dir",
		},
		{
			name = "httpPort",
			label = "HTTP Port",
			required = false,
			type = "number",
			default = 8080,
			validate = function(val)
				local num = tonumber(val)
				return num and num >= 1024 and num <= 65535
			end,
		},
		{
			name = "debugPort",
			label = "Debug Port (optional, for JPDA)",
			required = false,
			type = "number",
			validate = function(val)
				if not val or val == "" then
					return true
				end
				local num = tonumber(val)
				return num and num >= 1024 and num <= 65535
			end,
		},
		{
			name = "contextPath",
			label = "Context Path (optional)",
			required = false,
			type = "string",
			placeholder = "myapp",
			validate = function(val)
				if not val or val == "" then
					return true
				end
				return val:match("^[a-zA-Z0-9_-]+$") ~= nil
			end,
		},
		{
			name = "vmArgs",
			label = "JVM Arguments",
			required = false,
			type = "multivalue",
			placeholder = "-Xmx1G",
		},
		{ name = "cleanDeploy", label = "Clean Deploy Before Starting", required = false, type = "boolean", default = false },
	},
	command = {
		{ name = "command", label = "Shell Command", required = true, type = "string", placeholder = "./deploy.sh" },
	},
}

-- Telescope select function (async with callback)
local function telescope_select(options, prompt, callback)
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	pickers
		.new({}, {
			prompt_title = prompt,
			finder = finders.new_table({
				results = options,
				entry_maker = function(entry)
					return {
						value = entry,
						display = entry,
						ordinal = entry,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(prompt_bufnr)
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					if selection then
						callback(selection.value)
					else
						callback(nil)
					end
				end)
				return true
			end,
		})
		:find()
end

-- Prompt for a single string/number field (synchronous)
local function prompt_field(field_def, step_info)
	local prompt = field_def.label
	if field_def.default then
		prompt = string.format("%s [%s]", field_def.label, tostring(field_def.default))
	end

	if step_info then
		prompt = string.format("Step %d/%d - %s: ", step_info.current, step_info.total, prompt)
	else
		prompt = prompt .. ": "
	end

	-- Use synchronous vim.fn.input
	local value
	if field_def.type == "path" then
		-- Path fields with file completion
		value = vim.fn.input(prompt, field_def.default and tostring(field_def.default) or "", "file")
	else
		-- Regular string/number fields without completion
		value = vim.fn.input(prompt, field_def.default and tostring(field_def.default) or "")
	end

	-- Handle cancellation (empty on ESC press, but also check if required)
	if value == "" then
		if field_def.default then
			value = tostring(field_def.default)
		elseif not field_def.required then
			return ""
		else
			-- Required field with no input
			return nil
		end
	end

	-- Validate
	if field_def.validate and not field_def.validate(value) then
		vim.notify(
			string.format("Invalid value for '%s'. Please try again.", field_def.label),
			vim.log.levels.ERROR
		)
		return prompt_field(field_def, step_info) -- Retry
	end

	return value
end

-- Prompt for boolean field using Telescope (async with callback)
local function prompt_boolean(field_def, step_info, callback)
	local prompt = field_def.label
	if step_info then
		prompt = string.format("Step %d/%d - %s", step_info.current, step_info.total, prompt)
	end

	local options = { "Yes", "No" }

	telescope_select(options, prompt, function(result)
		if result == nil then
			callback(nil) -- Cancelled
		else
			callback(result == "Yes")
		end
	end)
end

-- Prompt for selecting existing configuration using Telescope (async with callback)
local function prompt_select_config(step_info, callback)
	local configs, err = parser.load_configurations()
	if not configs or #configs == 0 then
		vim.notify("No existing configurations found", vim.log.levels.WARN)
		callback("")
		return
	end

	local options = { "[Skip]" }
	for _, config in ipairs(configs) do
		table.insert(options, config.name)
	end

	local prompt = "Before Run Task (optional)"
	if step_info then
		prompt = string.format("Step %d/%d - %s", step_info.current, step_info.total, prompt)
	end

	telescope_select(options, prompt, function(result)
		if result == nil or result == "[Skip]" then
			callback("")
		else
			callback(result)
		end
	end)
end

-- Prompt for multi-value field using Telescope for yes/no (async with callback)
local function prompt_multivalue(field_def, step_info, callback)
	local values = {}

	local prompt = string.format("Add %s?", field_def.label)
	if step_info then
		prompt = string.format("Step %d/%d - %s", step_info.current, step_info.total, prompt)
	end

	-- Ask if user wants to add values
	telescope_select({ "Yes", "No" }, prompt, function(add_values)
		if add_values ~= "Yes" then
			callback(values)
			return
		end

		-- Collect values in a loop (synchronous part)
		while true do
			local input_prompt = string.format("Enter %s (ESC to finish): ", field_def.label)
			local value = vim.fn.input(input_prompt, field_def.placeholder or "")

			-- Stop on empty input
			if value == "" then
				break
			end

			table.insert(values, value)
		end

		callback(values)
	end)
end

-- Prompt for multi-map field using Telescope for yes/no (async with callback)
local function prompt_multimap(field_def, step_info, callback)
	local map = {}

	local prompt = string.format("Add %s?", field_def.label)
	if step_info then
		prompt = string.format("Step %d/%d - %s", step_info.current, step_info.total, prompt)
	end

	-- Ask if user wants to add values
	telescope_select({ "Yes", "No" }, prompt, function(add_values)
		if add_values ~= "Yes" then
			callback(map)
			return
		end

		-- Collect key-value pairs (synchronous part)
		while true do
			-- Get key
			local key = vim.fn.input("Enter variable name (ESC to finish): ")

			if key == "" then
				break
			end

			-- Get value
			local value = vim.fn.input(string.format("Enter value for '%s': ", key))

			if value == "" then
				break
			end

			map[key] = value
		end

		callback(map)
	end)
end

-- Show configuration summary in a buffer
local function show_summary(config)
	local lines = {}
	table.insert(lines, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	table.insert(lines, "Configuration Summary")
	table.insert(lines, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	table.insert(lines, "")
	table.insert(lines, string.format("Type:        %s", config.type or "gradle"))
	table.insert(lines, string.format("Name:        %s", config.name))

	if config.beforeRun and config.beforeRun ~= "" then
		table.insert(lines, string.format("Before Run:  %s", config.beforeRun))
	end

	if config.command then
		table.insert(lines, string.format("Command:     %s", config.command))
	end

	if config.tomcatHome then
		table.insert(lines, string.format("Tomcat Home: %s", config.tomcatHome))
	end

	if config.artifact then
		table.insert(lines, string.format("Artifact:    %s", config.artifact))
	end

	if config.httpPort then
		table.insert(lines, string.format("HTTP Port:   %d", config.httpPort))
	end

	if config.debugPort then
		table.insert(lines, string.format("Debug Port:  %d", config.debugPort))
	end

	if config.contextPath and config.contextPath ~= "" then
		table.insert(lines, string.format("Context:     %s", config.contextPath))
	end

	if config.cwd and config.cwd ~= "${workspaceFolder}" then
		table.insert(lines, string.format("Working Dir: %s", config.cwd))
	end

	if config.vmArgs and #config.vmArgs > 0 then
		table.insert(lines, string.format("VM Args:     %s", table.concat(config.vmArgs, ", ")))
	end

	if config.env and next(config.env) ~= nil then
		table.insert(lines, "Environment Variables:")
		for key, value in pairs(config.env) do
			table.insert(lines, string.format("  %s = %s", key, value))
		end
	end

	if config.cleanDeploy ~= nil then
		table.insert(lines, string.format("Clean Deploy: %s", config.cleanDeploy and "yes" or "no"))
	end

	table.insert(lines, "")
	table.insert(lines, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

	-- Create buffer
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")

	-- Open in split
	vim.cmd("botright 20split")
	vim.api.nvim_win_set_buf(0, buf)

	-- Keymap to close
	vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, desc = "Close summary" })
end

-- Calculate total steps for a configuration type
local function calculate_total_steps(config_type)
	local total = #field_schemas.common
	total = total + #field_schemas[config_type]
	return total + 1 -- +1 for confirmation
end

-- Collect a single field value (async with callback for select/boolean types)
local function collect_single_field(config, field, step_info, callback)
	if field.name == "beforeRun" then
		prompt_select_config(step_info, function(value)
			if value == nil then
				callback(nil, nil) -- Cancelled
			else
				callback(field.name, value)
			end
		end)
	elseif field.type == "string" or field.type == "path" then
		local value = prompt_field(field, step_info)
		if value == nil then
			callback(nil, nil) -- Cancelled
		else
			callback(field.name, value)
		end
	elseif field.type == "number" then
		local str_value = prompt_field(field, step_info)
		if str_value == nil then
			callback(nil, nil) -- Cancelled
		elseif str_value == "" then
			callback(field.name, nil) -- Optional field skipped
		else
			callback(field.name, tonumber(str_value))
		end
	elseif field.type == "boolean" then
		prompt_boolean(field, step_info, function(value)
			if value == nil then
				callback(nil, nil) -- Cancelled
			else
				callback(field.name, value)
			end
		end)
	elseif field.type == "multivalue" then
		prompt_multivalue(field, step_info, function(value)
			callback(field.name, value)
		end)
	elseif field.type == "multimap" then
		prompt_multimap(field, step_info, function(value)
			callback(field.name, value)
		end)
	end
end

-- Collect all fields from a field list recursively (async with callback chain)
local function collect_fields(config, fields, index, total_steps, base_step, callback)
	if index > #fields then
		callback(config) -- All fields collected
		return
	end

	local field = fields[index]
	local step_info = { current = base_step + index - 1, total = total_steps }

	collect_single_field(config, field, step_info, function(field_name, value)
		if field_name == nil then
			callback(nil) -- Cancelled
			return
		end

		-- Set value if non-empty
		if value ~= "" and value ~= nil then
			if field.type == "multimap" and next(value) == nil then
				-- Skip empty maps
			elseif field.type == "multivalue" and #value == 0 then
				-- Skip empty arrays
			else
				config[field_name] = value
			end
		end

		-- Continue to next field
		collect_fields(config, fields, index + 1, total_steps, base_step, callback)
	end)
end

-- Show summary and confirm (async with callback)
local function show_summary_and_confirm(config, step_info, callback)
	show_summary(config)

	local prompt = string.format("Step %d/%d - Save configuration?", step_info.current, step_info.total)

	telescope_select({ "Yes", "No" }, prompt, function(confirm)
		-- Close summary window
		vim.cmd("close")

		if confirm == "Yes" then
			callback(config)
		else
			callback(nil)
		end
	end)
end

-- Build configuration interactively (async with callback-based flow)
function M.build_configuration(config_type)
	-- Step 1: Select type if not provided
	if not config_type then
		local types = { "gradle", "tomcat", "command" }
		telescope_select(types, "Select Configuration Type", function(selected_type)
			if selected_type then
				M.start_config_flow(selected_type)
			end
		end)
	else
		M.start_config_flow(config_type)
	end
end

-- Start the configuration flow (internal, called after type selection)
function M.start_config_flow(config_type)
	-- Validate type
	if not field_schemas[config_type] then
		vim.notify("Invalid configuration type: " .. config_type, vim.log.levels.ERROR)
		return
	end

	-- Initialize config
	local config = { type = config_type }
	local total_steps = calculate_total_steps(config_type)

	-- Collect common fields
	collect_fields(config, field_schemas.common, 1, total_steps, 1, function(config_with_common)
		if not config_with_common then
			return -- Cancelled
		end

		-- Collect type-specific fields
		local base_step = #field_schemas.common + 1
		collect_fields(
			config_with_common,
			field_schemas[config_type],
			1,
			total_steps,
			base_step,
			function(final_config)
				if not final_config then
					return -- Cancelled
				end

				-- Show summary and confirm
				local step_info = { current = total_steps, total = total_steps }
				show_summary_and_confirm(final_config, step_info, function(confirmed_config)
					if confirmed_config then
						-- Save configuration
						local file_path, err = parser.add_configuration(confirmed_config)

						if not file_path then
							vim.notify("Error: " .. err, vim.log.levels.ERROR)
							return
						end

						vim.notify(
							string.format("✓ Configuration '%s' added to %s", confirmed_config.name, file_path),
							vim.log.levels.INFO
						)
					end
				end)
			end
		)
	end)
end

return M
