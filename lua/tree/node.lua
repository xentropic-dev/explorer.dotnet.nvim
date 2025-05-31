local M = {}

---@enum dotnet_explorer.NodeType
M.NodeType = {
  SOLUTION = "solution", -- The root node representing the solution
  PROJECT = "project", -- A project node within the solution
  SOLUTION_FOLDER = "solution folder", -- A solution folder node, which can contain projects or other solution folders
  FOLDER = "folder", -- A file system folder node
  FILE = "file", -- A file node, which can be a source file or other file type
}

---@class dotnet_explorer.TreeNode
---@field type dotnet_explorer.NodeType
---@field name string
---@field path string?
---@field guid string?
---@field children dotnet_explorer.TreeNode[]
---@field parent dotnet_explorer.TreeNode?
---@field metadata table?
M.TreeNode = {}
M.TreeNode.__index = M.TreeNode

function M.TreeNode:new(node_type, name, path, guid)
  local node = {
    type = node_type,
    name = name,
    path = path,
    guid = guid,
    children = {},
    parent = nil,
    metadata = {},
  }
  setmetatable(node, self)
  return node
end

function M.TreeNode:add_child(child)
  child.parent = self
  table.insert(self.children, child)
  return child
end

function M.TreeNode:find_child_by_guid(guid)
  for _, child in ipairs(self.children) do
    if child.guid == guid then
      return child
    end
    local found = child:find_child_by_guid(guid)
    if found then
      return found
    end
  end
  return nil
end

function M.TreeNode:filter(predicate)
  local filtered_children = {}
  for _, child in ipairs(self.children) do
    if predicate(child) then
      local filtered_child = child:filter(predicate)
      table.insert(filtered_children, filtered_child)
    end
  end

  local filtered_node = M.TreeNode:new(self.type, self.name, self.path, self.guid)
  filtered_node.children = filtered_children
  return filtered_node
end

return M
