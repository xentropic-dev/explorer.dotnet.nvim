---@diagnostic disable: undefined-field
---
describe("tree", function()
  local solution_parser = require("solution.parser")
  local tree_builder = require("tree.builder")

  it("can be required", function()
    assert.is_not_nil(tree_builder)
    assert.is_function(tree_builder.build_tree)
  end)

  it("builds a tree from a solution", function()
    local solution = solution_parser.parse_solution("tests/fixtures/test_solution.sln")
    local root_node = tree_builder.build_tree(solution)

    print(vim.inspect(root_node))
  end)
end)
