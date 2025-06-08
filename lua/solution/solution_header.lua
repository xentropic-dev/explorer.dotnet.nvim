---@class SolutionHeader
---@field visual_studio_version string|nil The Visual Studio version.
---@field file_version string|nil The solution file format version.
---@field minimum_visual_studio_version string|nil The minimum Visual Studio version required.
local SolutionHeader = {}
SolutionHeader.__index = SolutionHeader

--- Creates a new SolutionHeader instance
---@param visual_studio_version string|nil The Visual Studio version.
---@param file_version string|nil The solution file format version.
---@param minimum_visual_studio_version string|nil The minimum Visual Studio version required.
---@return SolutionHeader
function SolutionHeader.new(visual_studio_version, file_version, minimum_visual_studio_version)
  local self = setmetatable({}, { SolutionHeader })
  self.visual_studio_version = visual_studio_version
  self.file_version = file_version
  self.minimum_visual_studio_version = minimum_visual_studio_version
  return self
end

local M = {}
M.SolutionHeader = SolutionHeader
return M
