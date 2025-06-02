local viewmodel = require("explorer_viewmodel")
local M = {}

----- Key mappings for solution explorer
---@param bufnr number: The buffer number to attach the key mappings to
function M.on_attach(bufnr)
  local view = require("explorer_view").get_instance()
  
  -- Toggle node expansion with Enter
  vim.keymap.set("n", "<CR>", function()
    local line = vim.api.nvim_win_get_cursor(0)[1] - 1 -- Convert to 0-based
    local changed, file_path = viewmodel:activate_node_at_line(line)
    
    if changed then
      -- If a file path was returned, open the file
      if file_path then
        vim.cmd("wincmd p") -- Go to previous window
        vim.cmd("edit " .. vim.fn.fnameescape(file_path))
      else
        -- Otherwise, just refresh the view
        view:render()
      end
    end
  end, { buffer = bufnr, noremap = true, silent = true })
  
  -- Toggle node expansion with space
  vim.keymap.set("n", "<Space>", function()
    local line = vim.api.nvim_win_get_cursor(0)[1] - 1 -- Convert to 0-based
    if viewmodel:toggle_node_at_line(line) then
      view:render()
    end
  end, { buffer = bufnr, noremap = true, silent = true })
  
  -- Close explorer with q
  vim.keymap.set("n", "q", function()
    view:close()
  end, { buffer = bufnr, noremap = true, silent = true })
  
  -- Refresh explorer with r
  vim.keymap.set("n", "r", function()
    if viewmodel.solution_path then
      viewmodel:load_solution(viewmodel.solution_path)
      view:render()
    end
  end, { buffer = bufnr, noremap = true, silent = true })
end

return M
