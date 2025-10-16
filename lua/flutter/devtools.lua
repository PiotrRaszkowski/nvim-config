-- DevTools: Flutter DevTools integration
local M = {}

M.devtools_url = nil
M.devtools_job = nil

-- Launch DevTools
function M.launch()
	if M.devtools_job then
		vim.notify("DevTools already running", vim.log.levels.INFO)
		if M.devtools_url then
			vim.notify("DevTools URL: " .. M.devtools_url, vim.log.levels.INFO)
		end
		return
	end

	vim.notify("Launching Flutter DevTools...", vim.log.levels.INFO)

	M.devtools_job = vim.fn.jobstart("flutter pub global run devtools", {
		on_stdout = function(_, data)
			if data and #data > 0 then
				vim.schedule(function()
					for _, line in ipairs(data) do
						-- Look for DevTools URL
						local url = line:match("(http://[^%s]+)")
						if url then
							M.devtools_url = url
							vim.notify("DevTools available at: " .. url, vim.log.levels.INFO)
							-- Auto-open in browser
							vim.fn.jobstart(string.format("open '%s'", url), { detach = true })
						end
					end
				end)
			end
		end,
		on_exit = function()
			vim.schedule(function()
				M.devtools_job = nil
				M.devtools_url = nil
				vim.notify("DevTools stopped", vim.log.levels.INFO)
			end)
		end,
	})
end

-- Stop DevTools
function M.stop()
	if M.devtools_job then
		vim.fn.jobstop(M.devtools_job)
		M.devtools_job = nil
		M.devtools_url = nil
		vim.notify("DevTools stopped", vim.log.levels.INFO)
	end
end

return M
