local solution_parser = require("solution").Parser
local tree_builder = require("tree").TreeBuilder
local renderer = require("presentation.renderer")

local M = {}

-- set highlight groups
vim.api.nvim_set_hl(0, "DotNetExplorerChevron", { fg = "#6c757d" })
local function open_solution_explorer()
  -- Load solution
  local solution_file = "tests/fixtures/test_solution.sln"
  local solution = solution_parser.parse_solution(solution_file)
  if not solution then
    vim.notify("Failed to parse solution file: " .. solution_file, vim.log.levels.ERROR)
    return
  end

  local root = tree_builder.build_tree(solution)
  -- Create a vertical split on the left with 20 character width
  vim.cmd("topleft 45vnew")

  -- Get the current buffer number
  local buf = vim.api.nvim_get_current_buf()

  -- Set the buffer content
  local namespace_id = renderer.render_tree(buf, root)

  -- Make the buffer read-only and set some nice options
  vim.api.nvim_buf_set_option(buf, "readonly", true)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "swapfile", false)

  -- Set a nice buffer name
  vim.api.nvim_buf_set_name(buf, "Solution Explorer")

  -- Optional: Set some window options for better display
  vim.wo.wrap = true
  vim.wo.linebreak = true
  vim.wo.number = false
  vim.wo.relativenumber = false
end

-- Create a command to call the function
vim.api.nvim_create_user_command("SolutionExplorer", open_solution_explorer, {})

-- Return the function for use in other parts of your plugin
M.open_solution_explorer = open_solution_explorer
M.setup = function() end

return M
