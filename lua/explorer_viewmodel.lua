-- explorer_viewmodel.lua
-- Represents the state of the tree and persists between buffer open/close

local solution_parser = require("solution").Parser
local tree_builder = require("tree.builder")
local node_module = require("tree.node")
local NodeType = node_module.NodeType

---@class ExplorerViewModel
---@field solution dotnet_explorer.Solution The parsed solution
---@field tree dotnet_explorer.TreeNode The tree representation of the solution
---@field selected_node dotnet_explorer.TreeNode|nil The currently selected node
---@field solution_path string|nil Path to the solution file
local ExplorerViewModel = {}
ExplorerViewModel.__index = ExplorerViewModel

---Creates a new ExplorerViewModel
---@return ExplorerViewModel
function ExplorerViewModel.new()
  local self = setmetatable({}, ExplorerViewModel)
  self.solution = nil
  self.tree = nil
  self.selected_node = nil
  self.solution_path = nil
  return self
end

---Loads a solution file and builds the tree
---@param solution_path string Path to the solution file
---@return boolean success Whether the solution was loaded successfully
function ExplorerViewModel:load_solution(solution_path)
  self.solution_path = solution_path

  -- Parse the solution file
  local solution = solution_parser.parse_solution(solution_path)
  if not solution then
    return false
  end

  self.solution = solution

  -- Build the tree
  self.tree = tree_builder.build_tree(solution)

  -- Set the root node as selected by default
  self.selected_node = self.tree

  return true
end

---Finds a node at a specific line in the rendered tree
---@param line_number number The line number (0-based)
---@return dotnet_explorer.TreeNode|nil node The node at the line, or nil if not found
function ExplorerViewModel:get_node_at_line(line_number)
  if not self.tree then
    return nil
  end

  local current_line = 0

  local function traverse(node)
    -- Check if this is the node we're looking for
    if current_line == line_number then
      return node
    end

    -- Move to the next line
    current_line = current_line + 1

    -- If the node is expanded, check its children
    if node.expanded then
      -- Sort children by name to match the renderer's sorting
      local sorted_children = {}
      for _, child in ipairs(node.children) do
        table.insert(sorted_children, child)
      end
      table.sort(sorted_children, function(a, b)
        return a.name < b.name
      end)

      -- Traverse sorted children
      for _, child in ipairs(sorted_children) do
        local result = traverse(child)
        if result then
          return result
        end
      end
    end

    return nil
  end

  return traverse(self.tree)
end

---Toggles the expanded state of a node
---@param node dotnet_explorer.TreeNode The node to toggle
function ExplorerViewModel:toggle_node(node)
  if node then
    node.expanded = not node.expanded
  end
end

---Toggles the expanded state of the node at a specific line
---@param line_number number The line number (0-based)
---@return boolean changed Whether the tree state changed
function ExplorerViewModel:toggle_node_at_line(line_number)
  local node = self:get_node_at_line(line_number)

  -- Debug output to help diagnose issues
  if node then
    vim.notify(
      "Node found at line " .. line_number .. ": " .. node.name .. " (type: " .. node.type .. ")",
      vim.log.levels.INFO
    )
  else
    vim.notify("No node found at line " .. line_number, vim.log.levels.WARN)
    return false
  end

  -- Check if the node is a container type that can be expanded/collapsed
  if
    node
    and (
      node.type == NodeType.FOLDER
      or (node.type == NodeType.FILE and #node.children > 0)
      or node.type == NodeType.SOLUTION_FOLDER
      or node.type == NodeType.SOLUTION
      or node.type == NodeType.PROJECT
    )
  then
    -- Toggle the expanded state
    node.expanded = not node.expanded
    return true
  end

  return false
end

---Selects a node at a specific line
---@param line_number number The line number (0-based)
---@return boolean changed Whether the selection changed
function ExplorerViewModel:select_node_at_line(line_number)
  local node = self:get_node_at_line(line_number)
  if node and node ~= self.selected_node then
    self.selected_node = node
    return true
  end
  return false
end

---Opens a file or toggles a folder
---@param line_number number The line number (0-based)
---@return boolean changed Whether the tree state changed
---@return string|nil file_path Path to the file to open, if applicable
function ExplorerViewModel:activate_node_at_line(line_number)
  local node = self:get_node_at_line(line_number)
  if not node then
    return false, nil
  end

  -- Select the node
  self.selected_node = node

  -- If it's a folder or project, toggle expansion
  if
    node.type == NodeType.FOLDER
    or node.type == NodeType.SOLUTION_FOLDER
    or node.type == NodeType.SOLUTION
    or node.type == NodeType.PROJECT
  then
    self:toggle_node(node)
    return true, nil
  end

  -- if it's a file with children and isn't already expanded, toggle it
  if node.type == NodeType.FILE and #node.children > 0 and not node.expanded then
    self:toggle_node(node)
    return true, nil
  end

  -- If it's a file, return the path to open
  if node.type == NodeType.FILE then
    return true, node.path
  end

  return false, nil
end

-- Create a singleton instance
local instance = ExplorerViewModel.new()

-- Add a getter for the tree property to make it more explicit
function instance:get_tree()
  return self.tree
end

-- Add a setter for the tree property
function instance:set_tree(tree)
  self.tree = tree
end

return instance
