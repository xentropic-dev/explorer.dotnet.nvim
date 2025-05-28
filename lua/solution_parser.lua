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
  self.type_name = PROJECT_TYPES[type_guid]
  self.is_solution_folder = type_guid == SOLUTION_FOLDER_GUID
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

return M
