local M = {}

-- Project type GUIDs for common project types
local PROJECT_TYPES = {
  ["8BC9CEB8-8B4A-11D0-8D11-00A0C91BC942"] = "C++",
  ["FAE04EC0-301F-11D3-BF4B-00C04F79EFBC"] = "C#",
  ["F184B08F-C81C-45F6-A57F-5ABD9991F28F"] = "VB.NET",
  ["A1591282-1198-4647-A2B1-27E5FF5F6F3B"] = "Silverlight",
  ["2150E333-8FDC-42A3-9474-1A3956D46DE8"] = "Solution Folder",
  ["E53F8FEA-EAE0-44A6-8774-FFD645390401"] = "ASP.NET MVC",
  ["349c5851-65df-11da-9384-00065b846f21"] = "Web Application",
  ["E24C65DC-7377-472b-9ABA-BC803B73C61A"] = "Web Site",
  ["F135691A-BF7E-435D-8960-F99683D2D49C"] = "Distributed System",
  ["3D9AD99F-2412-4246-B90B-4EAA41C64699"] = "Windows Communication Foundation",
  ["60dc8134-eba5-43b8-bcc9-bb4bc16c2548"] = "Windows Presentation Foundation",
  ["32f31d43-81cc-4c15-9de6-3fc5453562b6"] = "Workflow Foundation",
  ["3AC096D0-A1C2-E12C-1390-A8335801FDAB"] = "Test",
  ["F088123C-0E9E-452A-89E6-6BA2F21D5CAC"] = "Modeling",
  ["A9ACE9BB-CECE-4E62-9AA4-C7E7C5BD2124"] = "Database",
  ["4F174C21-8C12-11D0-8340-0000F80270F8"] = "Database (other project types)",
  ["3EA9E505-35AC-4774-B492-AD1749C4943A"] = "Deployment Cab",
  ["06A35CCD-C46D-44D5-987B-CF40FF872267"] = "Deployment Merge Module",
  ["978C614F-708E-4E1A-B201-565925725DBA"] = "Deployment Setup",
  ["AB322303-2255-48EF-A496-5904EB18DA55"] = "Deployment Smart Device Cab",
}

-- Solution folder GUID
local SOLUTION_FOLDER_GUID = "2150E333-8FDC-42A3-9474-1A3956D46DE8"

function M.parse_solution(file_path)
  local file = io.open(file_path, "r")
  if not file then
    return nil, "Could not open solution file: " .. file_path
  end

  local content = file:read("*all")
  file:close()

  local solution = {
    path = file_path,
    version = nil,
    visual_studio_version = nil,
    projects = {},
    solution_folders = {},
    nested_projects = {},
    global_sections = {},
  }

  -- Parse header information
  for line in content:gmatch("[^\r\n]+") do
    local vs_version = line:match("VisualStudioVersion = (.+)")
    if vs_version then
      solution.visual_studio_version = vs_version
    end

    local format_version = line:match("Microsoft Visual Studio Solution File, Format Version (.+)")
    if format_version then
      solution.version = format_version
    end
  end

  print("Parsed solution version: " .. (solution.version or "Unknown"))
  -- Parse projects
  for project_block in content:gmatch('Project%("([^"]+)")%s*=%s*"([^"]+)",%s*"([^"]+)",%s*"([^"]+)"(.-?)EndProject') do
    local type_guid, name, path, project_guid, project_content = project_block:match("(.+)")

    local project = {
      name = name,
      path = path,
      guid = project_guid,
      type_guid = type_guid,
      type_name = PROJECT_TYPES[type_guid] or "Unknown",
      is_solution_folder = type_guid == SOLUTION_FOLDER_GUID,
      dependencies = {},
      sections = {},
    }

    -- Parse project sections if they exist
    if project_content then
      for section_name, section_content in
        project_content:gmatch("ProjectSection%(([^)]+)%)%s*=%s*[^\r\n]*\r?\n(.-?)EndProjectSection")
      do
        project.sections[section_name] = {}
        for key, value in section_content:gmatch("([^=\r\n]+)%s*=%s*([^\r\n]+)") do
          project.sections[section_name][key:match("^%s*(.-)%s*$")] = value:match("^%s*(.-)%s*$")
        end
      end
    end

    if project.is_solution_folder then
      solution.solution_folders[project_guid] = project
    else
      solution.projects[project_guid] = project
    end
  end

  -- Parse global sections
  for section_name, section_content in
    content:gmatch("GlobalSection%(([^)]+)%)%s*=%s*[^\r\n]*\r?\n(.-?)EndGlobalSection")
  do
    solution.global_sections[section_name] = {}

    -- Handle NestedProjects section specially
    if section_name == "NestedProjects" then
      for child_guid, parent_guid in section_content:gmatch("([^=\r\n]+)%s*=%s*([^\r\n]+)") do
        local child = child_guid:match("^%s*(.-)%s*$")
        local parent = parent_guid:match("^%s*(.-)%s*$")
        solution.nested_projects[child] = parent
      end
    else
      -- Parse other sections as key-value pairs
      for key, value in section_content:gmatch("([^=\r\n]+)%s*=%s*([^\r\n]+)") do
        solution.global_sections[section_name][key:match("^%s*(.-)%s*$")] = value:match("^%s*(.-)%s*$")
      end
    end
  end

  return solution
end

-- Build a hierarchical tree structure from the flat project list
function M.build_tree(solution)
  local tree = {
    name = vim.fn.fnamemodify(solution.path, ":t:r"), -- Solution name without extension
    type = "solution",
    children = {},
    path = solution.path,
  }

  local nodes = {}

  -- Create nodes for all projects and solution folders
  for guid, project in pairs(solution.projects) do
    nodes[guid] = {
      name = project.name,
      type = "project",
      project_type = project.type_name,
      path = project.path,
      guid = guid,
      children = {},
    }
  end

  for guid, folder in pairs(solution.solution_folders) do
    nodes[guid] = {
      name = folder.name,
      type = "folder",
      guid = guid,
      children = {},
    }
  end

  -- Build the hierarchy
  for child_guid, parent_guid in pairs(solution.nested_projects) do
    local child_node = nodes[child_guid]
    local parent_node = nodes[parent_guid]

    if child_node and parent_node then
      table.insert(parent_node.children, child_node)
    end
  end

  -- Add root-level items (those without parents) to the tree
  for guid, node in pairs(nodes) do
    if not solution.nested_projects[guid] then
      table.insert(tree.children, node)
    end
  end

  return tree
end

-- Helper function to print the tree structure (useful for debugging)
function M.print_tree(node, indent)
  indent = indent or ""
  local icon = ""

  if node.type == "solution" then
    icon = "📁"
  elseif node.type == "folder" then
    icon = "📂"
  elseif node.type == "project" then
    if node.project_type == "C#" then
      icon = "🔷"
    elseif node.project_type == "C++" then
      icon = "⚡"
    elseif node.project_type == "Test" then
      icon = "🧪"
    else
      icon = "📄"
    end
  end

  print(indent .. icon .. " " .. node.name .. (node.project_type and (" (" .. node.project_type .. ")") or ""))

  for _, child in ipairs(node.children or {}) do
    M.print_tree(child, indent .. "  ")
  end
end

-- Get all projects as a flat list with their full paths in the hierarchy
function M.get_project_paths(solution)
  local tree = M.build_tree(solution)
  local paths = {}

  local function traverse(node, path)
    local current_path = path == "" and node.name or (path .. "/" .. node.name)

    if node.type == "project" then
      table.insert(paths, {
        name = node.name,
        path = current_path,
        file_path = node.path,
        project_type = node.project_type,
        guid = node.guid,
      })
    end

    for _, child in ipairs(node.children or {}) do
      traverse(child, current_path)
    end
  end

  traverse(tree, "")
  return paths
end

return M
