---@diagnostic disable: undefined-field
---
describe("solution_parser", function()
  local solution_parser = require("solution.parser")
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
    local project_types = require("solution.project_types")
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

    -- Verify nested projects were parsed
    local expected_nested_projects = {
      ["117DA02F-5274-4565-ACC6-DA9B6E568B09"] = "6ED356A7-8B47-4613-AD01-C85CF28491BD",
      ["DEFF4009-1FAB-4392-80B6-707E2DC5C00B"] = "664D406C-2F83-48F0-BFC3-408D5CB53C65",
    }

    assert.is_not_nil(solution.nested_projects)
    for child_guid, parent_guid in pairs(expected_nested_projects) do
      assert.is_not_nil(solution.nested_projects[child_guid])
      assert.equals(parent_guid, solution.nested_projects[child_guid])
    end
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

  it("should parse Global contents", function()
    local given_sln = [[
ThisShouldBeIgnored
Global
  GlobalSection(SolutionConfigurationPlatforms) = preSolution
		Debug|Any CPU = Debug|Any CPU
		Release|Any CPU = Release|Any CPU
	EndGlobalSection
  GlobalSection(NestedProjects) = preSolution
		{A1B2C3D4-E5F6-7890-ABCD-EF1234567890} = {B934082E-15DF-4F7E-B203-A883EE5E72B1}
		{B2C3D4E5-F6A7-8901-BCDE-F23456789012} = {E0D01927-9C83-4247-B019-333A13EF266D}
		{C3D4E5F6-A7B8-9012-CDEF-345678901234} = {B934082E-15DF-4F7E-B203-A883EE5E72B1}
		{D4E5F6A7-B8C9-0123-DEF4-56789012345A} = {B934082E-15DF-4F7E-B203-A883EE5E72B1}
		{272DA9DC-3198-4216-8F1E-AB5A336EC9F2} = {B934082E-15DF-4F7E-B203-A883EE5E72B1}
		{E762B07D-EB6D-4BF3-8569-2CB18D6850AC} = {B934082E-15DF-4F7E-B203-A883EE5E72B1}
		{0D2AF229-C82F-45E5-949B-5C06D651DCE4} = {B934082E-15DF-4F7E-B203-A883EE5E72B1}
		{533BBF5D-5755-4078-B83C-B48AC9EB8AF5} = {B934082E-15DF-4F7E-B203-A883EE5E72B1}
	EndGlobalSection
EndGlobal
ThisShouldBeIgnoredAlso
]]
    local global_lines = solution_parser._parse_global(vim.split(given_sln, "\n"))
    assert.is_not_nil(global_lines)

    local expected_length = 14
    assert.is_equal(expected_length, #global_lines)

    local solution_config_section =
      solution_parser._parse_global_section(global_lines, "SolutionConfigurationPlatforms")

    assert.is_not_nil(solution_config_section)

    assert.is_equal(2, #solution_config_section)
    assert.is_equal("Debug|Any CPU = Debug|Any CPU", solution_config_section[1]:gsub("^%s*(.-)%s*$", "%1"))

    local nested_projects_section = solution_parser._parse_global_section(global_lines, "NestedProjects")
    assert.is_not_nil(nested_projects_section)
    assert.is_equal(8, #nested_projects_section)

    local nested_projects = solution_parser._parse_nested_projects(nested_projects_section)
    assert.is_not_nil(nested_projects)
    assert.is_not_nil(nested_projects["A1B2C3D4-E5F6-7890-ABCD-EF1234567890"])

    local expected_nested_parent_guid = "B934082E-15DF-4F7E-B203-A883EE5E72B1"
    assert.is_equal(expected_nested_parent_guid, nested_projects["A1B2C3D4-E5F6-7890-ABCD-EF1234567890"])
  end)
end)
