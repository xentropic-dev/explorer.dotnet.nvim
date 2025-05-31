local node_module = require("tree.node")
local M = {}

-- Check if nvim-web-devicons is available
local has_devicons, devicons = pcall(require, "nvim-web-devicons")

--- Gets the appropriate icon for a node based on its type and name
---@param node dotnet_explorer.TreeNode The tree node
---@return string|nil  icon The icon to display
---@return string|nil highlight The highlight group name
local function get_icon(node)
  if not has_devicons then
    -- Fallback icons based on node type
    if node.type == node_module.NodeType.SOLUTION then
      return "🎯", "Special"
    elseif node.type == node_module.NodeType.PROJECT then
      return "📦", "Title"
    elseif node.type == node_module.NodeType.SOLUTION_FOLDER then
      return "📁", "Directory"
    elseif node.type == node_module.NodeType.FOLDER then
      return "📂", "Directory"
    elseif node.type == node_module.NodeType.FILE then
      return "📄", "File"
    else
      return "❓", "Comment"
    end
  end

  -- Use nvim-web-devicons for better file type detection
  if node.type == node_module.NodeType.SOLUTION then
    return devicons.get_icon("solution.sln", "sln")
  elseif node.type == node_module.NodeType.PROJECT then
    return devicons.get_icon("project.csproj", "csproj")
  elseif node.type == node_module.NodeType.SOLUTION_FOLDER then
    return "󱋣", "Directory" -- Fallback for solution folders
  elseif node.type == node_module.NodeType.FOLDER then
    return "", "Directory" -- Fallback for solution folders
  elseif node.type == node_module.NodeType.FILE then
    local ext = node.name:match("^.+%.(.+)$") -- Get file extension
    return devicons.get_icon(node.name, ext)
  else
    return "❓", "Comment" -- Fallback for unknown types
  end
end

-- Renders a tree directly to a buffer with colored icons
---@param buf_id number The buffer ID to render to
---@param tree dotnet_explorer.TreeNode The tree to render
---@param opts? table Optional configuration { namespace_id?: number, clear_buffer?: boolean }
---@return number namespace_id The namespace ID used for highlights
function M.render_tree(buf_id, tree, opts)
  opts = opts or {}
  local namespace_id = opts.namespace_id or vim.api.nvim_create_namespace("dotnet_explorer_tree")
  local clear_buffer = opts.clear_buffer ~= false -- default to true

  local lines = {}
  local highlights = {}

  --- Recursive function to build lines and highlight data
  ---@param node dotnet_explorer.TreeNode
  local function build_node(node, indent)
    local icon, hl_group = get_icon(node)
    if not icon then
      icon = "❓"
      hl_group = "Comment"
    end

    local indent_str = string.rep("  ", indent)

    local is_open = true

    local expand_icon = " "

    if
      node.type == node_module.NodeType.FOLDER
      or node.type == node_module.NodeType.SOLUTION_FOLDER
      or node.type == node_module.NodeType.SOLUTION
      or node.type == node_module.NodeType.PROJECT
    then
      if not is_open then
        expand_icon = ""
      else
        expand_icon = ""
      end
    end

    local line_text = indent_str .. expand_icon .. " " .. icon .. " " .. node.name
    local line_num = #lines

    table.insert(lines, line_text)

    -- Calculate highlight positions (byte-based for multibyte icons)
    if hl_group then
      local icon_start = vim.str_byteindex(line_text, #indent_str + 2)
      local icon_end = vim.str_byteindex(line_text, #indent_str + 2 + vim.fn.strchars(icon))

      table.insert(highlights, {
        line = line_num,
        group = hl_group,
        start_col = icon_start,
        end_col = icon_end,
      })
    end

    -- highlight the chevron
    local chevron_start = vim.str_byteindex(line_text, #indent_str)
    local chevron_end = vim.str_byteindex(line_text, #indent_str + 2)
    table.insert(highlights, {
      line = line_num,
      group = "DotNetExplorerChevron",
      start_col = chevron_start,
      end_col = chevron_end,
    })

    -- Sort children by name
    local sorted_children = {}
    for _, child in ipairs(node.children) do
      table.insert(sorted_children, child)
    end
    table.sort(sorted_children, function(a, b)
      return a.name < b.name
    end)

    for _, child in ipairs(sorted_children) do
      build_node(child, indent + 1)
    end
  end

  -- Build the content
  build_node(tree, 0)

  -- Apply to buffer
  if clear_buffer then
    vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
  else
    vim.api.nvim_buf_set_lines(buf_id, -1, -1, false, lines)
  end

  -- Clear existing highlights and apply new ones
  vim.api.nvim_buf_clear_namespace(buf_id, namespace_id, 0, -1)
  for _, highlight in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(
      buf_id,
      namespace_id,
      highlight.group,
      highlight.line,
      highlight.start_col,
      highlight.end_col
    )
  end

  return namespace_id
end

return M
