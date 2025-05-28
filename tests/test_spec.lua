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
  it("can parse project information", function()
    local given_sln = [[
Project("{9A19103F-16F7-4668-BE54-9A1E7A4F7556}") = "Domain", "src\Domain\Domain.csproj", "{C7E89A3E-A631-4760-8D61-BD1EAB1C4E69}"
EndProject
]]
    local solution_parser = require("solution_parser")
    local projects = solution_parser._parse_projects(vim.split(given_sln, "\n"))

    assert.is_not_nil(projects)
    assert.are.equal(1, #projects)

    local project = projects[1]
    assert.are.equal("9A19103F-16F7-4668-BE54-9A1E7A4F7556", project.type_guid)
    assert.are.equal("Domain", project.name)
    assert.are.equal("src\\Domain\\Domain.csproj", project.path)
    assert.are.equal("C7E89A3E-A631-4760-8D61-BD1EAB1C4E69", project.guid)
    assert.is_false(project.is_solution_folder)
  end)
end)
