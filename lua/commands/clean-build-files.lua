-- lua/plugins/clean_eclipse_files.lua

local uv = vim.loop

-- Default list of targets to delete
local default_targets = { '.project', '.classpath', '.factorypath', '.settings', 'bin', 'build' }

-- Function to check if a name matches one of the targets
local function is_target(name, targets)
  for _, target in ipairs(targets) do
    if name == target then
      return true
    end
  end
  return false
end

-- Function to recursively delete files and directories
local function delete_recursive(path)
  local stat = uv.fs_stat(path)
  if not stat then
    return
  end
  if stat.type == 'file' then
    uv.fs_unlink(path)
  elseif stat.type == 'directory' then
    local req = uv.fs_scandir(path)
    if req then
      while true do
        local name = uv.fs_scandir_next(req)
        if not name then break end
        delete_recursive(path .. '/' .. name)
      end
    end
    uv.fs_rmdir(path)
  end
end

-- Function to traverse directories and delete targets
local function traverse_and_delete(path, targets)
  local req = uv.fs_scandir(path)
  if not req then
    return
  end
  while true do
    local name, type = uv.fs_scandir_next(req)
    if not name then break end
    local full_path = path .. '/' .. name
    if is_target(name, targets) then
      delete_recursive(full_path)
    elseif type == 'directory' then
      traverse_and_delete(full_path, targets)
    end
  end
end

-- Command callback function
local function clean_build_files(opts)
  local targets_to_use = nil
  if #opts.fargs > 0 then
    targets_to_use = opts.fargs
  else
    targets_to_use = default_targets
  end
  local cwd = vim.fn.getcwd()
  traverse_and_delete(cwd, targets_to_use)
  print('Build files cleared.')
end

-- Create the CleanEclipseFiles command with optional arguments
vim.api.nvim_create_user_command('CleanBuildFiles', clean_build_files, { nargs = '*' })

