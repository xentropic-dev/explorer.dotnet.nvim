local solution_parser = require("solution").Parser
local tree_builder = require("tree").TreeBuilder
local renderer = require("presentation.renderer")

local M = {}

M.config = {
  renderer = {
    width = 30, -- Default width of the solution explorer window
    side = "left", -- Default side to open the solution explorer
  },
}

-- explorer buffer
local explorer_buf = nil

-- set highlight groups
vim.api.nvim_set_hl(0, "DotNetExplorerChevron", { fg = "#6c757d" })

local function close_solution_explorer()
  if explorer_buf and vim.api.nvim_buf_is_valid(explorer_buf) then
    -- Close the buffer if it exists
    vim.api.nvim_buf_delete(explorer_buf, { force = true })
    explorer_buf = nil
  end
end

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

local function open_solution_explorer()
  if explorer_buf and vim.api.nvim_buf_is_valid(explorer_buf) then
    -- If the buffer already exists, just switch to it
    vim.api.nvim_set_current_buf(explorer_buf)
    return
  end
  -- Load solution
  --local solution_file = "tests/fixtures/test_solution.sln"
  local solution_file = find_solution_file()
  if not solution_file then
    vim.notify("No solution file found in the current directory or its parents.", vim.log.levels.ERROR)
    return
  end
  local solution = solution_parser.parse_solution(solution_file)
  if not solution then
    vim.notify("Failed to parse solution file: " .. solution_file, vim.log.levels.ERROR)
    return
  end

  local root = tree_builder.build_tree(solution)

  local cmd = "vnew"
  local renderer_config = M.config.renderer
  if renderer_config.side == "left" then
    cmd = "topleft " .. renderer_config.width .. "vnew"
  else
    cmd = "botright " .. renderer_config.width .. "vnew"
  end

  vim.cmd(cmd) -- Open a new vertical split window

  -- Get the current buffer number
  local buf = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()
  explorer_buf = buf -- Store the buffer number for future reference

  -- Set the buffer content
  local namespace_id = renderer.render_tree(buf, root, { clear_buffer = true, window_width = window_width })

  -- Make the buffer read-only and set some nice options
  vim.api.nvim_buf_set_option(buf, "readonly", true)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "swapfile", false)
  vim.api.nvim_buf_set_option(buf, "laststatus", 0)

  -- Set window options
  vim.api.nvim_win_set_option(win, "number", false)
  vim.api.nvim_win_set_option(win, "relativenumber", false)

  -- Set a nice buffer name
  vim.api.nvim_buf_set_name(buf, "Solution Explorer")

  -- Optional: Set some window options for better display
  vim.wo.wrap = true
  vim.wo.linebreak = true
  vim.wo.number = false
  vim.wo.relativenumber = false
end

local function toggle_solution_explorer()
  if explorer_buf and vim.api.nvim_buf_is_valid(explorer_buf) then
    -- If the buffer exists, close it
    close_solution_explorer()
  else
    -- Otherwise, open the solution explorer
    open_solution_explorer()
  end
end

vim.api.nvim_create_user_command("OpenSolutionExplorer", open_solution_explorer, {})
vim.api.nvim_create_user_command("ToggleSolutionExplorer", toggle_solution_explorer, {})
vim.api.nvim_create_user_command("CloseSolutionExplorer", close_solution_explorer, {})

-- Return the function for use in other parts of your plugin
M.open_solution_explorer = open_solution_explorer

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
