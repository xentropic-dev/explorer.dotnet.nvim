-- Example usage in your Neovim plugin
local solution_parser = require("solution_parser")

-- Parse a solution file
local solution, err = solution_parser.parse_solution("/home/xentropy/src/test_project/test_project.sln")
if not solution then
  print("Error parsing solution: " .. err)
  return
end

print("Parsed solution successfully!")

-- Print basic solution info
print("Solution version: " .. (solution.version or "Unknown"))
print("Visual Studio version: " .. (solution.visual_studio_version or "Unknown"))
print("Projects found: " .. vim.tbl_count(solution.projects))
print("Solution folders: " .. vim.tbl_count(solution.solution_folders))

-- Build and display the tree structure
local tree = solution_parser.build_tree(solution)
print("\nSolution structure:")
solution_parser.print_tree(tree)

-- Get flat list of projects with hierarchy paths
local project_paths = solution_parser.get_project_paths(solution)
print("\nAll projects:")
for _, project in ipairs(project_paths) do
  print(string.format("  %s (%s) -> %s", project.path, project.project_type, project.file_path))
end

-- Access specific project information
for guid, project in pairs(solution.projects) do
  if project.name == "MyProject" then
    print("\nFound MyProject:")
    print("  GUID: " .. project.guid)
    print("  Path: " .. project.path)
    print("  Type: " .. project.type_name)

    -- Check if it has any project dependencies
    if project.sections["ProjectDependencies"] then
      print("  Dependencies:")
      for dep_guid, _ in pairs(project.sections["ProjectDependencies"]) do
        print("    " .. dep_guid)
      end
    end
  end
end
