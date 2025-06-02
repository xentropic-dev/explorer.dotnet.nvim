-- dotnet_explorer.lua
-- Entry point for the .NET Solution Explorer plugin

local viewmodel = require("explorer_viewmodel")
local view_module = require("explorer_view")

local M = {}

-- Default configuration
M.config = {
  renderer = {
    width = 30, -- Default width of the solution explorer window
    side = "left", -- Default side to open the solution explorer
  },
}

-- Set highlight groups
vim.api.nvim_set_hl(0, "DotNetExplorerChevron", { fg = "#6c757d" })

-- Finds the solution file in the current directory or its parents
local function find_solution_file()
  local current_dir = vim.fn.getcwd()
  local found = false

  while not found and current_dir ~= "/" do
    -- Check for .sln files in the current directory
    local files = vim.fn.globpath(current_dir, "*.sln", false, true)
    for _, file in ipairs(files) do
      if vim.fn.filereadable(file) == 1 then
        return file -- Return the first readable solution file found
      end
    end
    -- Move up to the parent directory
    current_dir = vim.fn.fnamemodify(current_dir, ":h")
    if current_dir == "" then
      break -- Stop if we reach the root directory
    end
  end

  return nil -- Return nil if no solution file is found
end

-- Open the solution explorer
local function open_solution_explorer()
  local view = view_module.get_instance(M.config.renderer)

  vim.notify("Opening Solution Explorer DUDEE", vim.log.levels.INFO)

  -- If the view is already open, just focus it
  if view:is_open() then
    vim.notify("Solution Explorer is already open", vim.log.levels.INFO)
    return view:open()
  end

  -- Find and load the solution file if not already loaded
  if not viewmodel.tree then
    local solution_file = find_solution_file()
    if not solution_file then
      vim.notify("No solution file found in the current directory or its parents.", vim.log.levels.ERROR)
      return false
    end

    local success = viewmodel:load_solution(solution_file)
    if not success then
      vim.notify("Failed to parse solution file: " .. solution_file, vim.log.levels.ERROR)
      return false
    end

    vim.notify("Loaded solution: " .. solution_file, vim.log.levels.INFO)
  end

  vim.notify("View model tree ok", vim.log.levels.INFO)

  -- Open the view and set up keymaps
  local success = view:open()
  if success then
    view:setup_keymaps()
  end

  return success
end

-- Close the solution explorer
local function close_solution_explorer()
  local view = view_module.get_instance()
  view:close()
end

-- Toggle the solution explorer
local function toggle_solution_explorer()
  local view = view_module.get_instance(M.config.renderer)

  -- Find and load the solution file if not already loaded
  if not viewmodel.tree then
    local solution_file = find_solution_file()
    if not solution_file then
      vim.notify("No solution file found in the current directory or its parents.", vim.log.levels.ERROR)
      return false
    end

    local success = viewmodel:load_solution(solution_file)
    if not success then
      vim.notify("Failed to parse solution file: " .. solution_file, vim.log.levels.ERROR)
      return false
    end

    vim.notify("Loaded solution: " .. solution_file, vim.log.levels.INFO)
  end

  view:toggle()

  -- If we just opened the view, set up keymaps
  if view:is_open() then
    view:setup_keymaps()
  end
end

-- Create user commands
vim.api.nvim_create_user_command("OpenSolutionExplorer", open_solution_explorer, {})
vim.api.nvim_create_user_command("ToggleSolutionExplorer", toggle_solution_explorer, {})
vim.api.nvim_create_user_command("CloseSolutionExplorer", close_solution_explorer, {})

-- Export functions
M.open_solution_explorer = open_solution_explorer
M.close_solution_explorer = close_solution_explorer
M.toggle_solution_explorer = toggle_solution_explorer

---@class RendererConfig
---@field width number Width of the solution explorer window (default: 30)
---@field side string Side of the window to open (default: "left", options: "left", "right")

---@class SolutionExplorerConfig
---@field renderer RendererConfig Renderer configuration options

--- Sets up .NET Solution Explorer
---@param opts SolutionExplorerConfig|nil Configuration options
M.setup = function(opts)
  opts = opts or {}
  opts.renderer = opts.renderer or {}
  opts.renderer.width = opts.renderer.width or 30
  opts.renderer.side = opts.renderer.side or "left"

  -- Validation
  if type(opts.renderer.width) ~= "number" or opts.renderer.width <= 0 then
    vim.notify("Invalid width specified, using default width of 30", vim.log.levels.WARN)
    opts.renderer.width = 30
  end

  if opts.renderer.side ~= "left" and opts.renderer.side ~= "right" then
    vim.notify("Invalid side specified, using default side 'left'", vim.log.levels.WARN)
    opts.renderer.side = "left"
  end

  -- Store config
  M.config = opts
end

return M
