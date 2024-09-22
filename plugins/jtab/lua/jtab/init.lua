local M = {}
local fn = vim.fn

M.options = {
  show_index = true,
  show_modify = true,
  show_icon = false,
  fnamemodify = ':t',
  brackets = { '[', ']' },
  no_name = 'No Name',
  modify_indicator = ' [+]',
  inactive_tab_max_length = 0,
}

local function nospect(what)
  vim.notify(vim.inspect(what))
end

function jtab(opts)
  -- for i = 1, 5 do
  --   print('hello', i)
  --   -- vim.notify('hello')
  -- end
  -- local len = #vim.api.nvim_list_tabpages()
  -- print(len)

  local tabline = {}
  local tab = {}

  local i = vim.api.nvim_get_current_tabpage()
  local hi = '%#TabLineSel#'

  nospect(vim.api.nvim_list_bufs())

  local wins = vim.api.nvim_tabpage_list_wins(0)
  print('WIN:', wins[#wins])

  local buf = vim.api.nvim_win_get_buf(wins[1])
  print('BUF:', buf)
  if not buf then
    vim.notify('no buf', 'error')
  end

  local bufname = vim.api.nvim_buf_get_name(buf)

  local name = bufname ~= '' and vim.fn.fnamemodify(bufname, ':t')
    or '[No Name]'

  vim.notify(name)

  table.insert(tab, hi)
  table.insert(tab, ' ')
  table.insert(tab, 1)
  table.insert(tab, ': ')
  table.insert(tab, name)
  table.insert(tab, ' ')

  table.insert(tabline, table.concat(tab))

  table.insert(tabline, '%#TabLineFill#')

  local out = table.concat(tabline)
  print(out)
end

-- jtab()
vim.o.tabline = '%!v:lua.jtab()'

local function tabline(options)
  local s = ''
  for index = 1, fn.tabpagenr('$') do
    local winnr = fn.tabpagewinnr(index)
    local buflist = fn.tabpagebuflist(index)
    local bufnr = buflist[winnr]
    local bufname = fn.bufname(bufnr)
    local bufmodified = fn.getbufvar(bufnr, '&mod')

    s = s .. '%' .. index .. 'T'
    if index == fn.tabpagenr() then
      s = s .. '%#TabLineSel#'
    else
      s = s .. '%#TabLine#'
    end
    -- tab index
    s = s .. ' '
    -- index
    if options.show_index then
      s = s .. index .. ':'
    end
    -- icon
    local icon = ''
    if options.show_icon and M.has_devicons then
      local ext = fn.fnamemodify(bufname, ':e')
      icon = M.devicons.get_icon(bufname, ext, { default = true }) .. ' '
    end
    -- buf name
    s = s .. options.brackets[1]
    local pre_title_s_len = string.len(s)
    if bufname ~= '' then
      if type(options.fnamemodify) == 'function' then
        s = s .. icon .. options.fnamemodify(bufname)
      else
        s = s .. icon .. fn.fnamemodify(bufname, options.fnamemodify)
      end
    else
      s = s .. options.no_name
    end
    if
      options.inactive_tab_max_length
      and options.inactive_tab_max_length > 0
      and index ~= fn.tabpagenr()
    then
      s = string.sub(s, 1, pre_title_s_len + options.inactive_tab_max_length)
    end
    s = s .. options.brackets[2]
    -- modify indicator
    if
      bufmodified == 1
      and options.show_modify
      and options.modify_indicator ~= nil
    then
      s = s .. options.modify_indicator
    end
    -- additional space at the end of each tab segment
    s = s .. ' '
  end

  s = s .. '%#TabLineFill#'
  return s
end

function M.setup(user_options)
  M.options = vim.tbl_extend('force', M.options, user_options)
  M.has_devicons, M.devicons = pcall(require, 'nvim-web-devicons')

  function _G.nvim_tabline()
    return tabline(M.options)
  end

  vim.o.tabline = '%!v:lua.nvim_tabline()'

  vim.g.loaded_nvim_tabline = 1
end

return M
