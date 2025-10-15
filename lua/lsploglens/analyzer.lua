-- LspLogLens Analyzer
-- AI-powered LSP log and diagnostic analysis using Ollama
local utils = require("lsploglens.utils")
local M = {}

-- Configuration
M.OLLAMA_MODEL = "qwen2.5-coder:7b-instruct"
M.OLLAMA_BIN = "/opt/homebrew/bin/ollama"

-- Check if Ollama is available
function M.is_ollama_available()
	local result = vim.fn.executable(M.OLLAMA_BIN)
	return result == 1
end

-- Call Ollama with a prompt
local function call_ollama(prompt)
	-- Create temporary file for prompt
	local tmp_file = vim.fn.tempname()
	vim.fn.writefile(vim.split(prompt, "\n"), tmp_file)

	-- Call Ollama
	local cmd = { M.OLLAMA_BIN, "run", M.OLLAMA_MODEL }
	local result = vim.system(cmd, {
		stdin = vim.fn.readfile(tmp_file),
		text = true,
	}):wait()

	-- Clean up
	vim.fn.delete(tmp_file)

	if result.code ~= 0 then
		return nil, "Ollama error: " .. (result.stderr or "Unknown error")
	end

	return result.stdout, nil
end

-- Create explanation buffer
local function create_explanation_buffer(title, content)
	-- Add header
	local header = {
		"# " .. title,
		"",
		"Press 'q' to close this window",
		"",
		string.rep("─", 80),
		"",
	}

	local lines = vim.split(content, "\n")
	vim.list_extend(header, lines)

	-- Create buffer
	local buf = utils.create_read_only_buffer(title, header, "markdown")

	-- Open in split
	utils.open_in_split(buf)

	-- Add keymaps
	utils.add_buffer_keymaps(buf)

	return buf
end

-- Explain last N LSP errors with AI
function M.explain_errors(count)
	-- Check Ollama
	if not M.is_ollama_available() then
		vim.notify("Ollama is not available. Please install Ollama first.", vim.log.levels.ERROR)
		return
	end

	count = count or 10

	vim.notify("Extracting last " .. count .. " errors from LSP log...", vim.log.levels.INFO)

	-- Get recent errors
	local errors, err = utils.get_recent_errors(count)
	if err then
		vim.notify(err, vim.log.levels.ERROR)
		return
	end

	vim.notify("Analyzing errors with AI (this may take a moment)...", vim.log.levels.INFO)

	-- Create prompt
	local prompt = string.format(
		[[You are a helpful assistant analyzing LSP (Language Server Protocol) errors from Eclipse JDTLS (Java Development Tools Language Server) in Neovim.

Below are the last %d error/warning entries from the LSP log. Please:
1. Identify the main issues
2. Explain what each error means in simple terms
3. Suggest specific fixes or next steps
4. Focus on actionable advice

LSP LOG ENTRIES:
```
%s
```

Please provide a clear, structured explanation with specific recommendations.]],
		count,
		errors
	)

	-- Call Ollama
	local response, ollama_err = call_ollama(prompt)
	if ollama_err then
		vim.notify(ollama_err, vim.log.levels.ERROR)
		return
	end

	-- Create explanation buffer
	create_explanation_buffer("LSP Log AI Analysis", response)

	vim.notify("Analysis complete! Press 'q' to close the explanation window.", vim.log.levels.INFO)
end

-- Analyze current buffer's diagnostics with AI
function M.analyze_buffer()
	-- Check Ollama
	if not M.is_ollama_available() then
		vim.notify("Ollama is not available. Please install Ollama first.", vim.log.levels.ERROR)
		return
	end

	-- Get diagnostics
	local diagnostics = vim.diagnostic.get(0)

	if #diagnostics == 0 then
		vim.notify("No diagnostics found in current buffer", vim.log.levels.INFO)
		return
	end

	vim.notify("Analyzing " .. #diagnostics .. " diagnostic(s) with AI...", vim.log.levels.INFO)

	-- Format diagnostics
	local diag_text = {}
	for i, diag in ipairs(diagnostics) do
		local severity = ({
			[vim.diagnostic.severity.ERROR] = "ERROR",
			[vim.diagnostic.severity.WARN] = "WARN",
			[vim.diagnostic.severity.INFO] = "INFO",
			[vim.diagnostic.severity.HINT] = "HINT",
		})[diag.severity] or "UNKNOWN"

		table.insert(
			diag_text,
			string.format(
				"%d. [%s] Line %d: %s\n   Source: %s",
				i,
				severity,
				diag.lnum + 1,
				diag.message,
				diag.source or "unknown"
			)
		)
	end

	-- Create prompt
	local prompt = string.format(
		[[You are a helpful assistant analyzing LSP diagnostics from a Java file in Neovim.

Below are %d diagnostic messages from the current buffer. Please:
1. Explain what each diagnostic means
2. Provide specific fixes or suggestions
3. Prioritize by severity (errors first)
4. Give actionable code examples where helpful

DIAGNOSTICS:
%s

Please provide clear explanations and specific solutions.]],
		#diagnostics,
		table.concat(diag_text, "\n\n")
	)

	-- Call Ollama
	local response, ollama_err = call_ollama(prompt)
	if ollama_err then
		vim.notify(ollama_err, vim.log.levels.ERROR)
		return
	end

	-- Create explanation buffer
	create_explanation_buffer("Buffer Diagnostics AI Analysis", response)

	vim.notify("Analysis complete! Press 'q' to close the explanation window.", vim.log.levels.INFO)
end

return M
