local M = {}

local project_types = require("project_types")

---@class dotnet_explorer.Solution
---@field path string The absolute path to the solution file
---@field header dotnet_explorer.SolutionHeader The parsed solution header information
---@field projects_by_guid table<string, dotnet_explorer.Project> A map of project GUIDs to Project objects
---@field nested_projects table<string, string> A map of child project GUIDs to their parent project GUIDs
local Solution = {}
Solution.__index = Solution

--- Creates a new Solution instance
---@param path string The absolute path to the solution file
---@param header dotnet_explorer.SolutionHeader|nil The parsed solution header information
---@return dotnet_explorer.Solution
function Solution.new(path, header)
  local self = setmetatable({}, Solution)
  self.path = path
  self.header = header
    or {
      visual_studio_version = nil,
      file_version = nil,
      minimum_visual_studio_version = nil,
    }
  self.projects_by_guid = {}
  self.nested_projects = {}
  return self
end

--- Adds a project to the solution
---@param project dotnet_explorer.Project The project to add
function Solution:add_project(project)
  if not project or not project.guid then
    error("Invalid project: must have a valid GUID")
  end
  self.projects_by_guid[project.guid] = project
end

--- Parses a solution file and returns a Solution object
---@param filepath string The absolute path to the solution file
---@return dotnet_explorer.Solution
function M.parse_solution(filepath)
  local file = io.open(filepath, "r")
  if not file then
    error("Could not open solution file: " .. filepath)
  end

  local lines = {}
  for line in file:lines() do
    table.insert(lines, line)
  end

  file:close()

  local header = M._parse_solution_header(lines)
  local solution = Solution.new(filepath, header)
  local projects = M._parse_projects(lines)
  for _, project in ipairs(projects) do
    solution:add_project(project)
  end

  local global_section = M._parse_global(lines)
  local nested_project_section = M._parse_global_section(global_section, "NestedProjects")
  local nested_projects = M._parse_nested_projects(nested_project_section)

  solution.nested_projects = nested_projects

  return solution
end

---@class dotnet_explorer.Project
---@field type_guid string The project type GUID
---@field name string The project name
---@field path string The relative path to the project file
---@field guid string The unique project GUID
---@field type_name string|nil The human-readable project type name
---@field is_solution_folder boolean Whether this is a solution folder
local Project = {}
Project.__index = Project

--- Creates a new Project instance
---@param type_guid string The project type GUID
---@param name string The project name
---@param path string The relative path to the project file
---@param guid string The unique project GUID
---@return dotnet_explorer.Project
function Project.new(type_guid, name, path, guid)
  local self = setmetatable({}, Project)
  self.type_guid = type_guid
  self.name = name
  self.path = path
  self.guid = guid
  self.type_name = project_types.guid_to_type(type_guid)
  self.is_solution_folder = type_guid == project_types.TYPES.SOLUTION_FOLDER
  return self
end

---@class dotnet_explorer.SolutionHeader
---@fields visual_studio_version string|nil The Visual Studio version.
---@fields file_version string|nil The solution file format version.
---@fields minimum_visual_studio_version string|nil The minimum Visual Studio version required.

--- Parses the solution header from the given lines.
---@param lines string[] The lines of the solution file.
---@return dotnet_explorer.SolutionHeader
function M._parse_solution_header(lines)
  local header = {
    visual_studio_version = nil,
    file_version = nil,
    minimum_visual_studio_version = nil,
  }
  for _, line in ipairs(lines) do
    local min_vs_version = line:match("MinimumVisualStudioVersion = (.+)")
    if min_vs_version and not header.minimum_visual_studio_version then
      -- Check MinimumVisualStudioVersion first because it can match ambiguously with VisualStudioVersion
      header.minimum_visual_studio_version = min_vs_version
    end

    local vs_version = line:match("VisualStudioVersion = (.+)")
    if vs_version and not header.visual_studio_version then
      header.visual_studio_version = vs_version
    end

    local format_version = line:match("Microsoft Visual Studio Solution File, Format Version (.+)")
    if format_version and not header.file_version then
      header.file_version = format_version
    end

    if header.visual_studio_version and header.file_version and header.minimum_visual_studio_version then
      break
    end
  end

  return header
end

--- Parses project information from solution file lines
---@param lines string[] The lines of the solution file
---@return dotnet_explorer.Project[] Array of parsed projects
function M._parse_projects(lines)
  local projects = {}

  for _, line in ipairs(lines) do
    -- Match the Project line pattern:
    -- Project("{GUID}") = "Name", "Path", "{GUID}"
    if string.match(line, "^Project%(") then
      local type_guid, name, path, project_guid =
        string.match(line, 'Project%("({[^}]+})"%)%s*=%s*"([^"]+)",%s*"([^"]+)",%s*"({[^}]+})"')

      if type_guid then
        type_guid = type_guid:sub(2, -2) -- Remove first and last character (the braces)
        project_guid = project_guid:sub(2, -2)
      end
      local project = Project.new(type_guid, name, path, project_guid)
      table.insert(projects, project)
    end
  end

  return projects
end

--- Parses the NestedProjects section of a solution file
---@param lines string[] The lines of the solution file
---@return table<string, string> A map of project GUIDs to their parent GUIDs
function M._parse_nested_projects(lines)
  local nested_projects = {}

  for _, line in ipairs(lines) do
    -- Match the NestedProjects line pattern:
    -- {ChildGUID} = {ParentGUID}
    local child_guid, parent_guid = string.match(line, "^[ \t]*(%b{})%s*=%s*(%b{})$")
    if parent_guid and child_guid then
      parent_guid = parent_guid:sub(2, -2) -- Remove first and last character (the braces)
      child_guid = child_guid:sub(2, -2)
      nested_projects[child_guid] = parent_guid
    end
  end

  return nested_projects
end

--- Parses a specific GlobalSection from the solution file
---@param lines string[] The lines of the solution file
---@param section_name string The name of the section to parse (e.g., "NestedProjects")
---@return string[] The lines of the specified section, trimmed of leading/trailing whitespace
function M._parse_global_section(lines, section_name)
  local section = {}
  local in_section = false
  local section_start_pattern = "^[ \t]*GlobalSection%(" .. section_name .. "%)"
  local section_end_pattern = "^[ \t]*EndGlobalSection"

  -- Find the section start
  for _, line in ipairs(lines) do
    if not in_section then
      if string.match(line, section_start_pattern) then
        in_section = true
      end
    else
      if string.match(line, section_end_pattern) then
        break -- End of the section
      else
        section[#section + 1] = line
      end
    end
  end
  return section
end

--- Parses Global..EndGlobal contents from the solution file
---@param lines string[] The lines of the solution file
---@return string[] The contents of the Global section, excluding the header and footer
function M._parse_global(lines)
  local global_section = {}
  local in_global = false

  for _, line in ipairs(lines) do
    if not in_global then
      if string.match(line, "^[ \t]*Global%s*$") then
        in_global = true
      end
    else
      if string.match(line, "^[ \t]*EndGlobal%s*$") then
        break -- End of the Global section
      else
        global_section[#global_section + 1] = line:match("^%s*(.-)%s*$") -- Trim whitespace
      end
    end
  end

  return global_section
end

return M
