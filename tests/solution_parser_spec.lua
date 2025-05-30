---@diagnostic disable: undefined-field
---
describe("solution_parser", function()
  local solution_parser
  before_each(function()
    solution_parser = require("solution_parser")
  end)
  it("can be required", function()
    assert.is_not_nil(solution_parser)
  end)

  it("can parse version number", function()
    local given_sln = [[
Microsoft Visual Studio Solution File, Format Version 12.00
# Visual Studio Version 17
VisualStudioVersion = 17.0.31903.59
MinimumVisualStudioVersion = 10.0.40219.1
]]
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

  it("can discriminate project types", function()
    local given_sln = [[
Project("{9A19103F-16F7-4668-BE54-9A1E7A4F7556}") = "Domain", "src\Domain\Domain.csproj", "{C7E89A3E-A631-4760-8D61-BD1EAB1C4E69}"
EndProject
Project("{9A19103F-16F7-4668-BE54-9A1E7A4F7556}") = "Application", "src\Application\Application.csproj", "{34C0FACD-F3D9-400C-8945-554DD6B0819A}"
EndProject
Project("{9A19103F-16F7-4668-BE54-9A1E7A4F7556}") = "Infrastructure", "src\Infrastructure\Infrastructure.csproj", "{117DA02F-5274-4565-ACC6-DA9B6E568B09}"
EndProject
Project("{2150E333-8FDC-42A3-9474-1A3956D46DE8}") = "src", "src", "{6ED356A7-8B47-4613-AD01-C85CF28491BD}"
EndProject
Project("{2150E333-8FDC-42A3-9474-1A3956D46DE8}") = "tests", "tests", "{664D406C-2F83-48F0-BFC3-408D5CB53C65}"
EndProject
Project("{9A19103F-16F7-4668-BE54-9A1E7A4F7556}") = "Application.UnitTests", "tests\Application.UnitTests\Application.UnitTests.csproj", "{DEFF4009-1FAB-4392-80B6-707E2DC5C00B}"
EndProject
]]
    local project_types = require("project_types")
    local projects = solution_parser._parse_projects(vim.split(given_sln, "\n"))

    assert.is_not_nil(projects)
    assert.are.equal(6, #projects)

    local project_types_by_name = {}
    for _, project in ipairs(projects) do
      project_types_by_name[project.name] = project.type_name
    end

    assert.are.equal(project_types.TYPES.CSHARP_SDK, project_types_by_name["Domain"])
    assert.are.equal(project_types.TYPES.CSHARP_SDK, project_types_by_name["Application"])
    assert.are.equal(project_types.TYPES.CSHARP_SDK, project_types_by_name["Infrastructure"])
    assert.are.equal(project_types.TYPES.SOLUTION_FOLDER, project_types_by_name["src"])
    assert.are.equal(project_types.TYPES.SOLUTION_FOLDER, project_types_by_name["tests"])
    assert.are.equal(project_types.TYPES.CSHARP_SDK, project_types_by_name["Application.UnitTests"])
  end)

  it("can parse a complete solution file", function()
    local solution = solution_parser.parse_solution("tests/fixtures/test_solution.sln")

    -- Verify solution object is created
    assert.is_not_nil(solution)
    assert.is_not_nil(solution.path)
    assert.equals("tests/fixtures/test_solution.sln", solution.path)

    -- Verify header was parsed
    assert.is_not_nil(solution.header)
    assert.is_not_nil(solution.header.file_version)

    -- Verify projects were parsed and added
    assert.is_not_nil(solution.projects_by_guid)
    assert.is_true(next(solution.projects_by_guid) ~= nil) -- Table is not empty

    -- Verify at least one project has expected properties
    local first_project = next(solution.projects_by_guid)
    local project = solution.projects_by_guid[first_project]
    assert.is_not_nil(project.name)
    assert.is_not_nil(project.path)
    assert.is_not_nil(project.guid)
    assert.is_not_nil(project.type_guid)
    assert.is_boolean(project.is_solution_folder)
  end)

  it("throws error for non-existent solution file", function()
    assert.has_error(function()
      solution_parser.parse_solution("non_existent.sln")
    end, "Could not open solution file: non_existent.sln")
  end)

  it("should correctly parse nested projects", function()
    local given_sln = [[
{C7E89A3E-A631-4760-8D61-BD1EAB1C4E69} = {6ED356A7-8B47-4613-AD01-C85CF28491BD}
		{DEFF4009-1FAB-4392-80B6-707E2DC5C00B} = {664D406C-2F83-48F0-BFC3-408D5CB53C65}
]]
    local parent_projects_by_child_guid = solution_parser._parse_nested_projects(vim.split(given_sln, "\n"))
    assert.is_not_nil(parent_projects_by_child_guid)

    assert.is_not_nil(parent_projects_by_child_guid["C7E89A3E-A631-4760-8D61-BD1EAB1C4E69"])
    assert.is_not_nil(parent_projects_by_child_guid["DEFF4009-1FAB-4392-80B6-707E2DC5C00B"])

    assert.is_equal(
      parent_projects_by_child_guid["C7E89A3E-A631-4760-8D61-BD1EAB1C4E69"],
      "6ED356A7-8B47-4613-AD01-C85CF28491BD"
    )

    assert.is_equal(
      parent_projects_by_child_guid["DEFF4009-1FAB-4392-80B6-707E2DC5C00B"],
      "664D406C-2F83-48F0-BFC3-408D5CB53C65"
    )
  end)
end)
