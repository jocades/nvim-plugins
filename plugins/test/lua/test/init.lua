return {
  setup = function()
    vim.api.nvim_create_user_command('MyPlug', function()
      local ok, what = pcall(print, JVim)
      vim.notify(vim.print(what))
      print('MyPlug')
    end, {})
  end,
}
