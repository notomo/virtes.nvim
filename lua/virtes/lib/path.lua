local M = {}

local Path = {}
Path.__index = Path
M.Path = Path

function Path.new(path)
  local tbl = { path = vim.fn.fnamemodify(path, ":p") }
  return setmetatable(tbl, Path)
end

function Path.__tostring(self)
  return self.path
end

function Path.get(self)
  return self.path
end

function Path.join(self, ...)
  local items = {}
  local slash = false
  for _, item in ipairs({ self.path, ... }) do
    if vim.endswith(item, "/") then
      item = item:sub(1, #item - 1)
      slash = true
    else
      slash = false
    end
    table.insert(items, item)
  end

  local path = table.concat(items, "/")
  if slash then
    path = path .. "/"
  end

  return self.new(path)
end

function Path.parent(self)
  if vim.endswith(self.path, "/") then
    return self.new(vim.fn.fnamemodify(self.path, ":h:h"))
  end
  return self.new(vim.fn.fnamemodify(self.path, ":h"))
end

function Path.head(self)
  if not vim.endswith(self.path, "/") or self.path == "/" then
    return vim.fn.fnamemodify(self.path, ":t")
  end
  return vim.fn.fnamemodify(self.path, ":h:t") .. "/"
end

function Path.delete(self)
  return vim.fn.delete(self.path, "rf")
end

function Path.mkdir(self)
  vim.fn.mkdir(self.path, "p")
end

return M
