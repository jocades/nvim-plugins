return {
  setup = function()
    vim.api.nvim_create_user_command(
      'MyPlug',
      function() print('MyPlug') end,
      {}
    )
  end,
}
