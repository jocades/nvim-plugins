local builtin_marks = {
  ['.'] = true,
  ['^'] = true,
  ['`'] = true,
  ["'"] = true,
  ['"'] = true,
  ['<'] = true,
  ['>'] = true,
  ['['] = true,
  [']'] = true,
}

vim.print(vim.fn.getmarklist('%'))

-- trying to create a plugin that displays the current marks in the buffer (but only for non built-in marks)

-- how to add a sign to the buffer?

vim.fn.sign_define('bmark', { text = '🔖', texthl = 'ErrorMsg' })
vim.fn.sign_place(1, 'bmark', 'bmarks', 0, { lnum = 1 })
