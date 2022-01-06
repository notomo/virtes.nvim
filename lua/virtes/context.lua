local M = {}

local TestContext = {}
TestContext.__index = TestContext
M.TestContext = TestContext

function TestContext.create(dir_path, hash, screenshot_impl)
  vim.validate({ hash = { hash, "string", true }, screenshot_impl = { screenshot_impl, "function" } })
  local tbl = { _paths = {}, _dir = dir_path, _hash = hash, _screenshot = screenshot_impl }
  dir_path:mkdir()

  return setmetatable(tbl, TestContext)
end

function TestContext.screenshot(self, name)
  vim.validate({ name = { name, "string", true } })
  local file_path = self._dir:join(name or tostring(#self._paths + 1))

  file_path:delete()
  local path = file_path:get()
  self._screenshot(path)

  table.insert(self._paths, file_path)
  return path
end

function TestContext._run(self, scenario)
  vim.validate({ scenario = { scenario, "function" } })
  local origin_branch
  if self._hash ~= nil then
    origin_branch = vim.fn.systemlist({ "git", "rev-parse", "--abbrev-ref", "HEAD" })[1]
    vim.fn.system({ "git", "checkout", self._hash })
    if vim.v.shell_error ~= 0 then
      return false, "failed to checkout " .. self._hash
    end
  end

  local ok, result = pcall(scenario, self)

  if origin_branch ~= nil then
    vim.fn.system({ "git", "checkout", origin_branch })
  end

  return ok, result
end

return M
