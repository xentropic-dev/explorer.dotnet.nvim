---@meta

---@class Solution
---@field path string The absolute path to the solution file
---@field header SolutionHeader The parsed solution header information
---@field projects_by_guid table<string, dotnet_explorer.Project> A map of project GUIDs to Project objects
---@field nested_projects table<string, string> A map of child project GUIDs to their parent project GUIDs
local Solution = {}
Solution.__index = Solution

---@class SolutionHeader
---@fields visual_studio_version string|nil The Visual Studio version.
---@fields file_version string|nil The solution file format version.
---@fields minimum_visual_studio_version string|nil The minimum Visual Studio version required.

--- Creates a new Solution instance
---@param path string The relative path to the solution file
---@param header SolutionHeader|nil The parsed solution header information
---@return Solution
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

local M = {}
M.Solution = Solution

return M
