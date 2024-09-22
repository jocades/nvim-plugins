local M = {
  one = 1,
}

setmetatable(M, {
  __index = function(t, k)
    print('--meta--')
    P(t)
    print(k)
  end,
})

-- M.two = 2
print(M.two)
P(M)
