local M = {}

--- Module setup
---
---@usage `require('select-hxml').setup()`
function M.setup()
  M.create_select_hxml_command()
  M.create_select_hxml_all_command()
end

--- Creates |:SelectHxml| command
function M.create_select_hxml_command()
  vim.api.nvim_create_user_command("SelectHxml", function()
    M.select_hxml()
  end, {
    desc = "Select hxml file",
  })
end

--- Creates |:SelectHxmlAll| command
function M.create_select_hxml_all_command()
  vim.api.nvim_create_user_command("SelectHxmlAll", function()
    M.select_hxml_all()
  end, {
    desc = "Select all hxml file",
  })
end

function M.get_lsp_client()
  ---@type lsp.Client[]
  local clients = vim.lsp.get_active_clients({ bufnr = 0, name = "haxe_language_server" })

  return clients[1]
end

--- Get relative path `from` `to`.
---@param from string
---@param to string
---@return string
local function get_relative_path(from, to)
  return tostring(require("plenary.path"):new(to):make_relative(from))
end

--- Find `*.hxml` files under `root`
---@param root string
---@return string[]
function M.find_hxml(root)
  local query = tostring(require("plenary.path"):new(root):joinpath("**", "*.hxml"))
  local hxml_abs_paths = vim.fn.glob(query, false, true)
  return vim.tbl_map(function(abs_path)
    return get_relative_path(root, abs_path)
  end, hxml_abs_paths)
end

--- Set `displayArguments`
---
---@see https://github.com/vshaxe/haxe-language-server
---@param client lsp.Client
---@param arguments string[]
---@return boolean
function M.set_display_arguments(client, arguments)
  return client.rpc.notify("haxe/didChangeDisplayArguments", { arguments = arguments })
end

--- Prompt user to select a hxml file.
---@param hxml_path_list string[]
---@param on_choice fun(hxml_path: string|nil, index: integer|nil)
---@param format_item? (fun(hxml_path: string): string)|nil
local function select_hxml(hxml_path_list, on_choice, format_item)
  vim.ui.select(hxml_path_list, {
    prompt = "Select hxml:",
    format_item = format_item,
  }, function(choice, index)
    on_choice(choice, index)
  end)
end

--- Select a `*.hxml` and send it to haxe-language-server.
function M.select_hxml()
  local client = M.get_lsp_client()

  if client == nil then
    vim.notify("haxe_language_server is not activated")
    return
  end

  local root = (client.workspace_folders or {})[1]

  if root == nil then
    vim.notify("workspace folder is not detected")
    return
  end

  local hxml_paths = M.find_hxml(root.name)

  select_hxml(hxml_paths, function(hxml_path)
    if hxml_path ~= nil then
      local success = M.set_display_arguments(client, { hxml_path })

      if success then
        vim.notify("Success set " .. hxml_path, vim.log.levels.INFO)
      else
        vim.notify("Failed set " .. hxml_path, vim.log.levels.ERROR)
      end
    end
  end)
end

--- Select all `*.hxml`s and send it to haxe-language-server.
function M.select_hxml_all()
  local client = M.get_lsp_client()

  if client == nil then
    vim.notify("haxe_language_server is not activated")
    return
  end

  local root = (client.workspace_folders or {})[1]

  if root == nil then
    vim.notify("workspace folder is not detected")
    return
  end

  local hxml_paths = M.find_hxml(root.name)

  local success = M.set_display_arguments(client, hxml_paths)

  if success then
    vim.notify("Success set all hxml files", vim.log.levels.INFO)
  else
    vim.notify("Failed set all hxml files ", vim.log.levels.ERROR)
  end
end

return M
