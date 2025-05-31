---@diagnostic disable: undefined-field

describe("project_types", function()
  local project_types

  before_each(function()
    project_types = require("solution.project_types")
  end)

  it("can be required", function()
    assert.is_not_nil(project_types)
    assert.is_not_nil(project_types.TYPES)
    assert.is_function(project_types.guid_to_type)
    assert.is_function(project_types.is_type)
  end)

  describe("C# project types", function()
    it("recognizes standard C# project GUID", function()
      local guid = "FAE04EC0-301F-11D3-BF4B-00C04F79EFBC"
      local result = project_types.guid_to_type(guid)
      assert.equals(project_types.TYPES.CSHARP, result)
      assert.equals("C#", result)
    end)

    it("recognizes SDK-style C# project GUID", function()
      local guid = "9A19103F-16F7-4668-BE54-9A1E7A4F7556"
      local result = project_types.guid_to_type(guid)
      assert.equals(project_types.TYPES.CSHARP_SDK, result)
      assert.equals("C# (forces use of SDK project system)", result)
    end)

    it("handles lowercase GUIDs", function()
      local guid = "fae04ec0-301f-11d3-bf4b-00c04f79efbc"
      local result = project_types.guid_to_type(guid)
      assert.equals(project_types.TYPES.CSHARP, result)
    end)

    it("handles mixed case GUIDs", function()
      local guid = "fAe04Ec0-301F-11d3-BF4b-00c04f79efbc"
      local result = project_types.guid_to_type(guid)
      assert.equals(project_types.TYPES.CSHARP, result)
    end)
  end)

  describe("Web project types", function()
    it("recognizes ASP.NET MVC 5 project GUID", function()
      local guid = "349C5851-65DF-11DA-9384-00065B846F21"
      local result = project_types.guid_to_type(guid)
      assert.equals(project_types.TYPES.ASPNET_MVC_5, result)
      assert.equals("ASP.NET MVC 5 / Web Application", result)
    end)

    it("recognizes Web Site project GUID", function()
      local guid = "E24C65DC-7377-472B-9ABA-BC803B73C61A"
      local result = project_types.guid_to_type(guid)
      assert.equals(project_types.TYPES.WEB_SITE, result)
    end)
  end)

  describe("WPF and desktop types", function()
    it("recognizes WPF project GUID", function()
      local guid = "60DC8134-EBA5-43B8-BCC9-BB4BC16C2548"
      local result = project_types.guid_to_type(guid)
      assert.equals(project_types.TYPES.WPF, result)
      assert.equals("Windows Presentation Foundation (WPF)", result)
    end)
  end)

  describe("Test project types", function()
    it("recognizes Test project GUID", function()
      local guid = "3AC096D0-A1C2-E12C-1390-A8335801FDAB"
      local result = project_types.guid_to_type(guid)
      assert.equals(project_types.TYPES.TEST, result)
      assert.equals("Test", result)
    end)
  end)

  describe("Solution folder", function()
    it("recognizes Solution Folder GUID", function()
      local guid = "2150E333-8FDC-42A3-9474-1A3956D46DE8"
      local result = project_types.guid_to_type(guid)
      assert.equals(project_types.TYPES.SOLUTION_FOLDER, result)
      assert.equals("Solution Folder", result)
    end)
  end)

  describe("is_type helper function", function()
    it("correctly identifies C# projects", function()
      local csharp_guid = "FAE04EC0-301F-11D3-BF4B-00C04F79EFBC"
      assert.is_true(project_types.is_type(csharp_guid, project_types.TYPES.CSHARP))
      assert.is_false(project_types.is_type(csharp_guid, project_types.TYPES.VBNET))
    end)

    it("correctly identifies WPF projects", function()
      local wpf_guid = "60DC8134-EBA5-43B8-BCC9-BB4BC16C2548"
      assert.is_true(project_types.is_type(wpf_guid, project_types.TYPES.WPF))
      assert.is_false(project_types.is_type(wpf_guid, project_types.TYPES.CSHARP))
    end)
  end)

  describe("edge cases", function()
    it("returns nil for unknown GUID", function()
      local unknown_guid = "00000000-0000-0000-0000-000000000000"
      local result = project_types.guid_to_type(unknown_guid)
      assert.is_nil(result)
    end)

    it("returns nil for nil input", function()
      local result = project_types.guid_to_type(nil)
      assert.is_nil(result)
    end)

    it("returns nil for empty string", function()
      local result = project_types.guid_to_type("")
      assert.is_nil(result)
    end)

    it("is_type returns false for unknown GUID", function()
      local unknown_guid = "00000000-0000-0000-0000-000000000000"
      assert.is_false(project_types.is_type(unknown_guid, project_types.TYPES.CSHARP))
    end)
  end)
end)
