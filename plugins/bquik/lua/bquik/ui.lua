local function test()
  local Popup = require('nui.popup')

  local pop = Popup({
    position = '50%',
    size = {
      width = 80,
      height = 40,
    },
    enter = true,
    focusable = true,
    zindex = 50,
    relative = 'editor',
    border = {
      padding = {
        top = 2,
        bottom = 2,
        left = 3,
        right = 3,
      },
      style = 'rounded',
      text = {
        top = ' bquik ',
        top_align = 'center',
        bottom = 'I am bottom title',
        bottom_align = 'left',
      },
    },
    buf_options = {
      modifiable = true,
      readonly = false,
    },
    win_options = {
      winblend = 10,
      winhighlight = 'Normal:Normal,FloatBorder:FloatBorder',
    },
  })

  ---@param path string
  ---@param mode? 'r' | 'w' | 'a' | 'rb' | 'wb' | 'ab'
  local function open(path, mode)
    local file = assert(io.open(path, mode or 'r'))
    return file
  end

  ---@return string
  local function read(path)
    local file = open(path)
    local content = file:read('*a')
    file:close()
    return content
  end

  ---Write to the file
  ---@param path string
  ---@param data string | string[]
  ---@param mode? 'w' | 'a' | 'wb' | 'ab'
  local function write(data, path, mode)
    local file = open(path, mode or 'w')

    if type(data) == 'table' then
      file:write(vim.json.encode(data))
    else
      file:write(data)
    end

    file:close()
  end

  local M = {}

  function M.restore()
    return vim.json.decode(read('data.json'))
  end

  local state = M.restore()

  function M.add()
    local path = vim.api.nvim_buf_get_name(0)
    state[path] = true
  end

  vim.keymap.set('n', '<leader>a', function()
    M.add()
  end)

  local first = true

  function M.attach(buf)
    vim.bo[buf].filetype = 'bquik'

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.tbl_keys(state))

    vim.keymap.set('n', 'q', function()
      pop:unmount()
    end, { buffer = buf })

    if first then
      first = false
    end
  end

  vim.keymap.set('n', '<leader>]', function()
    pop:mount()
    M.attach(pop.bufnr)
  end)

  vim.keymap.set('n', '<cr>', function()
    local path = vim.trim(vim.api.nvim_get_current_line())
    if state[path] then
      vim.cmd.e(path)
    else
      print('Path not found', path)
    end
  end, { buffer = pop.bufnr })

  pop:on('BufLeave', function()
    local lines = vim.api.nvim_buf_get_lines(pop.bufnr, 0, -1, false)
    vim.print(lines)
    pop:unmount()

    local not_found = {}

    for _, path in ipairs(lines) do
      if not state[path] then
        table.insert(not_found, path)
      end
    end

    vim.print('NOT FOUND', not_found)

    for _, path in pairs(not_found) do
      state[path] = nil
    end

    vim.print(state)

    -- print(popup.bufnr)
  end, { once = true })
end

test()
