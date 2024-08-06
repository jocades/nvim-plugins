local NuiTree = require('nui.tree')
local Popup = require('nui.popup')
local event = require('nui.utils.autocmd').event

local popup = Popup({
  enter = true,
  focusable = true,
  border = {
    style = 'rounded',
  },
  position = '50%',
  size = {
    width = '80%',
    height = '60%',
  },
})

-- mount/open the component
popup:mount()

-- unmount component when cursor leaves buffer
popup:on(event.BufLeave, function() popup:unmount() end)

popup:map('n', 'q', function() popup:unmount() end)

-- set content
-- vim.api.nvim_buf_set_lines(popup.bufnr, 0, 1, false, { 'Hello World' })

local tree = NuiTree({
  bufnr = popup.bufnr,
  nodes = {
    NuiTree.Node({ text = 'a' }),
    NuiTree.Node({ text = 'b' }, {
      NuiTree.Node({ text = 'b-1' }),
      NuiTree.Node({ text = { 'b-2', 'b-3' } }),
    }),
  },
})

tree:render()
