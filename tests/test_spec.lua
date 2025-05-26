---@diagnostic disable: undefined-field
---
describe("solution_parser", function()
  it("can be required", function()
    local solution_parser = require("solution_parser")
    assert.is_not_nil(solution_parser)
  end)
end)
describe("some basics", function()
  local bello = function(boo)
    return "bello " .. boo
  end

  local bounter

  before_each(function()
    bounter = 0
  end)

  it("some test", function()
    bounter = 100
    assert.equals("bello Brian", bello("Brian"))
  end)

  it("some other test", function()
    assert.equals(0, bounter)
  end)
end)
