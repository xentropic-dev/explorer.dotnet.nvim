---@diagnostic disable: undefined-field
---
describe("TreeBuilder", function()
  local solution_parser = require("solution.parser")
  local tree_builder = require("tree.builder")

  it("can be required", function()
    assert.is_not_nil(tree_builder)
    assert.is_function(tree_builder.build_tree)
  end)

  describe("build_tree", function()
    it("builds a tree from a solution", function()
      local solution = solution_parser.parse_solution("tests/fixtures/test_solution.sln")
      local root_node = tree_builder.build_tree(solution)
      local expected = {
        name = "test_solution.sln",
        type = "solution",
        children = {
          {
            name = "Solution Items",
            type = "solution folder",
            children = {},
          },
          {
            name = "src",
            type = "solution folder",
            children = {
              { name = "Infrastructure", type = "project", children = {} },
              { name = "Application", type = "project", children = {} },
              { name = "Web", type = "project", children = {} },
              { name = "Domain", type = "project", children = {} },
            },
          },
          {
            name = "tests",
            type = "solution folder",
            children = {
              { name = "Infrastructure.IntegrationTests", type = "project", children = {} },
              { name = "Web.AcceptanceTests", type = "project", children = {} },
              { name = "Domain.UnitTests", type = "project", children = {} },
              { name = "Application.UnitTests", type = "project", children = {} },
              { name = "Application.FunctionalTests", type = "project", children = {} },
            },
          },
        },
      }

      assert.is_not_nil(root_node)
      assert.is_table(root_node)

      local function compare_trees(a, b)
        if a.name ~= b.name or a.type ~= b.type then
          return false
        end
        -- Handle cases where children might be nil
        local a_children = a.children or {}
        local b_children = b.children or {}

        if #a_children ~= #b_children then
          return false
        end
        for i = 1, #a_children do
          if not compare_trees(a_children[i], b_children[i]) then
            return false
          end
        end
        return true
      end

      assert.is_true(compare_trees(root_node, expected))
    end)
  end)
end)
