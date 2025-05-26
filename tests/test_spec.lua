---@diagnostic disable: undefined-field
---
describe("solution_parser", function()
  it("can be required", function()
    local solution_parser = require("solution_parser")
    assert.is_not_nil(solution_parser)
  end)

  it("can parse version number", function()
    local given_sln = [[
Microsoft Visual Studio Solution File, Format Version 12.00
# Visual Studio Version 17
VisualStudioVersion = 17.0.31903.59
MinimumVisualStudioVersion = 10.0.40219.1
]]
    local solution_parser = require("solution_parser")
    local header = solution_parser._parse_solution_header(vim.split(given_sln, "\n"))

    assert.is_not_nil(header)

    local expected = {
      visual_studio_version = "17.0.31903.59",
      file_version = "12.00",
      minimum_visual_studio_version = "10.0.40219.1",
    }

    assert.are.same(expected, header)
  end)
end)
