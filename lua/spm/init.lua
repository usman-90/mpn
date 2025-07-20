
local M = {}

local project_path = vim.fn.stdpath("data") .. "/usman_90_spm.json"

local function read_json(path)
  local file = io.open(path, "r")
  if not file then return {} end

  local content = file:read("*a")
  file:close()
  return vim.fn.json_decode(content) or {}
end

local function write_json(path, tbl)
  local file = io.open(path, "w")

  if not file then
    vim.notify("⚠ Could not open file for writing: " .. path, vim.log.levels.ERROR)
    return
  end
  file:write(vim.fn.json_encode(tbl))
  file:close()
end


_G.delete_popup_line = function()
  local buf = vim.api.nvim_get_current_buf()
  local line_num = vim.api.nvim_win_get_cursor(0)[1]
  local line_text = vim.api.nvim_buf_get_lines(buf, line_num - 1, line_num, false)[1]

  local name = line_text:match("^(.-)→")
  if name then
    name = vim.trim(name)
  end

  local project_json = read_json(project_path)
  project_json[name] = nil

  write_json(project_path, project_json)

  vim.api.nvim_buf_set_lines(buf, line_num - 1, line_num, false, {})
end


_G.navigate_to_dir = function()
  local buf = vim.api.nvim_get_current_buf()
  local line_num = vim.api.nvim_win_get_cursor(0)[1]
  local line_text = vim.api.nvim_buf_get_lines(buf, line_num - 1, line_num, false)[1]

  local path = line_text:match("→%s*(.+)")

  if not path then
    vim.notify("⚠ No path found in the selected line.", vim.log.levels.WARN)
    return
  end

  if path then
    path = vim.trim(path)
  end

  vim.api.nvim_set_current_dir(path)

  for _, temp_buf in ipairs(vim.api.nvim_list_bufs()) do
    vim.api.nvim_buf_delete(temp_buf, { force = true })
  end

  if vim.api.nvim_win_get_config(0).relative ~= "" then
    vim.cmd("wincmd p")
  end

  vim.cmd("pwd")
  vim.cmd("edit .")

end


local function show_table_popup(tbl)
  local lines = {}
  for k, v in pairs(tbl) do
    table.insert(lines, string.format(" %s → %s", tostring(k), tostring(v)))
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  vim.api.nvim_buf_set_name(buf, "spm://project-picker")

  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)

  local width = math.min(70, vim.o.columns - 4)
  local height = math.min(math.max(#lines, 1), vim.o.lines - 4)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
    title = " Project Picker ",
    title_pos = "center",
  })

  vim.api.nvim_win_set_option(win, 'number', true)

  vim.api.nvim_buf_set_keymap(buf, 'n', 'dd', [[:lua _G.delete_popup_line()<CR>]], { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, 'n', 'vv', [[:lua _G.navigate_to_dir()<CR>]], { noremap = true, silent = true })
end




local function add_project_to_list()
    
    local cwd = vim.fn.getcwd()
    local project_name = vim.trim(vim.fn.fnamemodify(cwd, ":t"))

    local json = read_json(project_path)

    if not json then
        local tbl = {
            [project_name] = cwd
        }
        write_json(project_path , tbl)
        return
    end

    json[project_name] = cwd

    write_json(project_path, json)
end


M.add_project_to_list = add_project_to_list
M.project_path = project_path
M.show_table_popup = function()
  local projects = read_json(project_path)
  show_table_popup(projects)
end

return M

