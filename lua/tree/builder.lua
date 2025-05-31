local node_module = require("tree.node")
local PROJECT_TYPES = require("solution").PROJECT_TYPES
local NodeType = node_module.NodeType
local TreeNode = node_module.TreeNode

local M = {}

-- Helper function to get sorted keys
local function get_sorted_keys(t, sort_func)
  local keys = {}
  for k in pairs(t) do
    table.insert(keys, k)
  end
  table.sort(keys, sort_func)
  return keys
end

-- Helper function to sort projects by name
local function sort_projects_by_name(guid_a, guid_b, projects_by_guid)
  local project_a = projects_by_guid[guid_a]
  local project_b = projects_by_guid[guid_b]
  return project_a.name < project_b.name
end

---@param solution dotnet_explorer.Solution
---@return dotnet_explorer.TreeNode
function M.build_tree(solution)
  -- Create root solution node
  local path = vim.fn.fnamemodify(solution.path, ":t")
  local root = TreeNode:new(NodeType.SOLUTION, path, solution.path)

  -- First pass: Create all project nodes (sorted by GUID for consistency)
  local project_nodes = {}
  local sorted_guids = get_sorted_keys(solution.projects_by_guid)

  for _, guid in ipairs(sorted_guids) do
    local project = solution.projects_by_guid[guid]
    local node_type = NodeType.PROJECT
    if project.type_name == PROJECT_TYPES.SOLUTION_FOLDER then
      node_type = NodeType.SOLUTION_FOLDER
    end
    local project_node = TreeNode:new(node_type, project.name, project.path, guid)
    project_nodes[guid] = project_node
  end

  -- Second pass: Build hierarchy using nested_projects (sorted for consistency)
  local sorted_nested_keys = get_sorted_keys(solution.nested_projects)

  for _, child_guid in ipairs(sorted_nested_keys) do
    local parent_guid = solution.nested_projects[child_guid]
    local child_node = project_nodes[child_guid]
    local parent_node = project_nodes[parent_guid]

    if child_node and parent_node then
      parent_node:add_child(child_node)
    end
  end

  -- Third pass: Add root-level projects (sorted by project name)
  local root_level_guids = {}
  for guid, project_node in pairs(project_nodes) do
    if not project_node.parent then
      table.insert(root_level_guids, guid)
    end
  end

  -- Sort root-level projects by name
  table.sort(root_level_guids, function(a, b)
    return sort_projects_by_name(a, b, solution.projects_by_guid)
  end)

  for _, guid in ipairs(root_level_guids) do
    local project_node = project_nodes[guid]
    root:add_child(project_node)
  end

  -- Fourth pass: Populate file structure for each project
  for _, guid in ipairs(sorted_guids) do
    local project_node = project_nodes[guid]
    M.populate_project_files(project_node)
  end

  return root
end

-- Alternative: Sort children after tree construction
function M.sort_tree_children(node)
  -- Sort children by name
  table.sort(node.children, function(a, b)
    return a.name < b.name
  end)

  -- Recursively sort all children
  for _, child in ipairs(node.children) do
    M.sort_tree_children(child)
  end
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
