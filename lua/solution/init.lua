local M = {}

local project_types_module = require("solution.project_types")
local parser_model = require("solution.parser")

M.PROJECT_TYPES = project_types_module.TYPES
M.Parser = parser_model

return M
