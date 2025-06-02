-- explorer_view.lua
-- Handles the buffer and rendering of the solution explorer

local renderer = require("presentation.renderer")
local viewmodel = require("explorer_viewmodel")

---@class ExplorerView
---@field buffer_id number|nil The buffer ID of the explorer
---@field window_id number|nil The window ID of the explorer
---@field namespace_id number|nil The namespace ID used for highlights
---@field config table Configuration options
local ExplorerView = {}
ExplorerView.__index = ExplorerView

---Creates a new ExplorerView
---@param config table Configuration options
---@return ExplorerView
function ExplorerView.new(config)
  local self = setmetatable({}, ExplorerView)
  self.buffer_id = nil
  self.window_id = nil
  self.namespace_id = nil
  self.config = config or {}
  return self
end

---Checks if the explorer buffer is currently open and valid
---@return boolean is_open Whether the explorer is open
function ExplorerView:is_open()
  return self.buffer_id ~= nil and vim.api.nvim_buf_is_valid(self.buffer_id)
end

---Closes the explorer buffer if it's open
function ExplorerView:close()
  if self:is_open() then
    vim.api.nvim_buf_delete(self.buffer_id, { force = true })
    self.buffer_id = nil
    self.window_id = nil
  end
end

---Opens the explorer buffer and renders the tree
---@return boolean success Whether the explorer was opened successfully
function ExplorerView:open()
  -- If the buffer is already open, just focus it
  if self:is_open() then
    local windows = vim.api.nvim_list_wins()
    for _, win in ipairs(windows) do
      if vim.api.nvim_win_get_buf(win) == self.buffer_id then
        vim.api.nvim_set_current_win(win)
        return true
      end
    end

    -- If the buffer exists but has no window, create a new window
    local cmd = "vnew"
    if self.config.side == "left" then
      cmd = "topleft " .. self.config.width .. "vnew"
    else
      cmd = "botright " .. self.config.width .. "vnew"
    end

    vim.cmd(cmd)
    vim.api.nvim_win_set_buf(0, self.buffer_id)
    self.window_id = vim.api.nvim_get_current_win()
    return true
  end

  -- Check if we have a tree to display
  if not viewmodel:get_tree() then
    -- The solution loading should be handled by dotnet_explorer.lua
    -- This is just a safety check
    return false
  end

  -- Create a new buffer and window
  vim.notify("Making Solution Explorer buffer...")
  local cmd = "vnew"
  if self.config.side == "left" then
    cmd = "topleft " .. self.config.width .. "vnew"
  else
    cmd = "botright " .. self.config.width .. "vnew"
  end

  vim.cmd(cmd)

  -- Get the current buffer and window
  self.buffer_id = vim.api.nvim_get_current_buf()
  self.window_id = vim.api.nvim_get_current_win()

  -- Set buffer options
  vim.api.nvim_buf_set_option(self.buffer_id, "buftype", "nofile")
  vim.api.nvim_buf_set_option(self.buffer_id, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(self.buffer_id, "swapfile", false)
  vim.api.nvim_buf_set_option(self.buffer_id, "modifiable", false)
  vim.api.nvim_buf_set_option(self.buffer_id, "readonly", true)

  -- Set window options
  vim.api.nvim_win_set_option(self.window_id, "number", false)
  vim.api.nvim_win_set_option(self.window_id, "relativenumber", false)
  vim.api.nvim_win_set_option(self.window_id, "wrap", false)
  vim.api.nvim_win_set_option(self.window_id, "signcolumn", "no")

  -- Set buffer name
  vim.api.nvim_buf_set_name(self.buffer_id, "Solution Explorer")

  -- Render the tree
  self:render()

  return true
end

---Renders the tree in the explorer buffer
function ExplorerView:render()
  if not self:is_open() or not viewmodel.tree then
    return
  end

  -- Make the buffer modifiable temporarily
  vim.api.nvim_buf_set_option(self.buffer_id, "modifiable", true)
  vim.api.nvim_buf_set_option(self.buffer_id, "readonly", false)

  -- Render the tree
  local window_width = vim.api.nvim_win_get_width(self.window_id)
  self.namespace_id = renderer.render_tree(self.buffer_id, viewmodel.tree, {
    clear_buffer = true,
    window_width = window_width,
    namespace_id = self.namespace_id,
  })

  -- Make the buffer read-only again
  vim.api.nvim_buf_set_option(self.buffer_id, "modifiable", false)
  vim.api.nvim_buf_set_option(self.buffer_id, "readonly", true)
end

---Toggles the explorer (opens if closed, closes if open)
function ExplorerView:toggle()
  if self:is_open() then
    vim.notify("Closing Solution Explorer...", vim.log.levels.INFO)
    self:close()
  else
    vim.notify("Opening Solution Explorer...", vim.log.levels.INFO)
    self:open()
  end
end

---Sets up keymaps for the explorer buffer
function ExplorerView:setup_keymaps()
  if not self:is_open() then
    return
  end

  local keymap = require("keymap")
  keymap.on_attach(self.buffer_id)
end

-- Create a singleton instance
local instance = nil

---Gets the singleton instance of ExplorerView
---@param config table|nil Configuration options
---@return ExplorerView
local function get_instance(config)
  if not instance then
    instance = ExplorerView.new(config)
  end
  return instance
end

return {
  get_instance = get_instance,
}
