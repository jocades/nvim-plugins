local M = {}

local ns = vim.api.nvim_create_namespace('__twf')
local group = vim.api.nvim_create_augroup('__twf', { clear = true })

---@alias x vim.api.keyset.get_extmark_item

---@param msg string
---@param title? string
local function err(msg, title)
  vim.notify(msg, vim.log.levels.ERROR, { title = title or 'Twf' })
end

---@class TwfOpts
---@field enabled? boolean
---@field char? string
---@field highlight? vim.api.keyset.highlight

local state = {
  ---@type table<number, number[]|nil>
  bufs = {}, -- buf: ids
  ---@type TwfOpts
  opts = {
    enabled = true,
    char = '…', -- 󰇘 󱏿 …
    highlight = {
      fg = '#38BDF8',
    },
  },
}

---@param opts? TwfOpts
local function set_state(opts)
  if not opts then
    return
  end
  for k, v in pairs(opts) do
    state.opts[k] = v
  end
end

local queries = {}

-- queries.jsx = [[
--   ((jsx_attribute
--     (property_identifier) @name (#any-of? @name "class" "className")
--     (string (string_fragment) @value) (#set! @value conceal "%s")))
--   ]]

queries.jsx = [[
  ((jsx_attribute 
    (property_identifier) @name (#any-of? @name "class" "className")
    (string (string_fragment) @value)))
  ]]

queries.html = [[
  ((attribute 
    (attribute_name) @name (#eq? @name "class")
    (quoted_attribute_value (attribute_value) @value) (#set! @value conceal "%s"))) 
]]

local lang_to_query_map = {
  html = queries.html,
  tsx = queries.jsx,
  javascript = queries.jsx,
}

---@param lang string
local function get_query(lang)
  return lang_to_query_map[lang]
end

---@param buf number
local function conceal(buf)
  local ft = vim.bo[buf].ft
  local lang = vim.treesitter.language.get_lang(ft)

  if not lang then
    err('No treesitter parser found for ' .. ft)
    return
  end

  local root = vim.treesitter.get_parser(buf):parse()[1]:root()
  local query = vim.treesitter.query.parse(lang, get_query(lang))

  for i, node in query:iter_captures(root, buf) do
    local capture = query.captures[i]

    if capture == 'value' then
      local srow, scol, erow, ecol = node:range()

      if not state.bufs[buf] then
        state.bufs[buf] = {}
      end

      vim.print({
        srow = srow,
        scol = scol,
        erow = erow,
        ecol = ecol,
      })

      local extmarks = vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, {})
      vim.print('Extmarks', extmarks)

      vim.api.nvim_buf_set_extmark(buf, ns, srow, scol, {
        end_line = erow,
        end_col = ecol,
        hl_group = 'Twf',
        ephemeral = true,
        priority = 0,
        conceal = state.opts.char,
      })

      --[[ table.insert(
        state.bufs[buf],
        vim.api.nvim_buf_set_extmark(buf, ns, srow, scol, {
          end_line = erow,
          end_col = ecol,
          conceal = state.opts.char,

          hl_group = 'Twf',
          priority = 0,
        })
      ) ]]
    end
  end
end

---@param buf number
local function unconceal(buf)
  for _, id in ipairs(state.bufs[buf]) do
    vim.api.nvim_buf_del_extmark(buf, ns, id)
  end
  state.bufs[buf] = nil
end

local fts = {
  'html',
  'typescriptreact',
  'javascriptreact',
  'javascript',
}

local ft_to_ext_map = {
  html = 'html',
  typescriptreact = 'tsx',
  javascriptreact = 'jsx',
  javascript = 'js',
}

local function get_pattern()
  return vim.tbl_map(function(ft)
    return '*.' .. ft_to_ext_map[ft]
  end, fts)
end

local function check(ft)
  return vim.tbl_contains(fts, ft)
end

local function ft_not_supported()
  err(
    'Filetype not supported, make sure it is one of ' .. table.concat(fts, ', ')
  )
end

---@param buf number
---@param opts? { toggle?: boolean, show_msg?: boolean }
function M.execute(buf, opts)
  opts = opts or {}

  if not check(vim.bo[buf].ft) then
    if opts.show_msg then
      ft_not_supported()
    end
    return
  end

  if not opts.toggle then
    conceal(buf)
    return
  end

  if state.bufs[buf] then
    unconceal(buf)
  else
    conceal(buf)
  end
end

function M.enable()
  state.opts.enabled = true
  vim.api.nvim_exec_autocmds('TextChanged', { group = group })
end

function M.disable()
  state.opts.enabled = false
  for buf, _ in pairs(state.bufs) do
    if state.bufs[buf] then
      unconceal(buf)
    end
  end
end

---@param opts? TwfOpts
function M.setup(opts)
  set_state(opts)

  vim.api.nvim_create_user_command('Twf', function()
    M.execute(vim.api.nvim_get_current_buf())
  end, {})

  vim.api.nvim_create_user_command('TwfEnable', function()
    M.enable()
  end, {})

  vim.api.nvim_create_user_command('TwfDisable', function()
    -- M.disable()
    vim.opt_local.conceallevel = 0
  end, {})

  vim.api.nvim_create_user_command('TwfDebug', function()
    vim.print(state)
  end, {})

  --[[ vim.api.nvim_create_autocmd(
    { 'BufEnter', 'BufWritePost', 'TextChanged', 'InsertLeave' },
    {
      group = group,
      pattern = get_pattern(),
      callback = function(e)
        if not state.opts.enabled then
          return
        end

        M.execute(e.buf)
      end,
    }
  ) ]]

  vim.api.nvim_set_decoration_provider(ns, {
    on_line = function(_, win, buf, line)
      -- M.execute(buf)
    end,
  })

  vim.api.nvim_set_hl(0, 'Twf', state.opts.highlight)
end

return M
