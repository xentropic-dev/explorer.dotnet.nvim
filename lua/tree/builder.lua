local node_module = require("tree.node")
local PROJECT_TYPES = require("solution").PROJECT_TYPES
local NodeType = node_module.NodeType
local TreeNode = node_module.TreeNode

local M = {}

---@param solution dotnet_explorer.Solution
---@return dotnet_explorer.TreeNode
function M.build_tree(solution)
  -- Create root solution node
  local path = vim.fn.fnamemodify(solution.path, ":p")
  local root = TreeNode:new(NodeType.SOLUTION, path, solution.path)

  -- First pass: Create all project nodes
  local project_nodes = {}
  for guid, project in pairs(solution.projects_by_guid) do
    local node_type = NodeType.PROJECT
    if project.type_guid == PROJECT_TYPES.SOLUTION_FOLDER then
      node_type = NodeType.SOLUTION_FOLDER
    end
    local project_node = TreeNode:new(node_type, project.name, project.path, guid)
    project_nodes[guid] = project_node
  end

  -- Second pass: Build hierarchy using nested_projects
  for child_guid, parent_guid in pairs(solution.nested_projects) do
    local child_node = project_nodes[child_guid]
    local parent_node = project_nodes[parent_guid]

    if child_node and parent_node then
      parent_node:add_child(child_node)
    end
  end

  -- Third pass: Add root-level projects
  for guid, project_node in pairs(project_nodes) do
    if not project_node.parent then
      root:add_child(project_node)
    end
  end

  -- Fourth pass: Populate file structure for each project
  for _, project_node in pairs(project_nodes) do
    M.populate_project_files(project_node)
  end

  return root
end

---@param project_node dotnet_explorer.TreeNode
function M.populate_project_files(project_node)
  if not project_node.path then
    return
  end

  --local project_dir = require("path").dirname(project_node.path)
  --M.add_directory_contents(project_node, project_dir)
end

---@param parent_node dotnet_explorer.TreeNode
---@param dir_path string
function M.add_directory_contents(parent_node, dir_path)
  -- Implementation here...
end

return M
