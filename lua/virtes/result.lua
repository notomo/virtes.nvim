local Diffs = require("virtes/diff").Diffs
local Diff = require("virtes/diff").Diff

local M = {}

local TestResult = {}
TestResult.__index = TestResult
M.TestResult = TestResult

function TestResult.new(paths, dir_path, replay_path)
  local tbl = {paths = paths, dir_path = dir_path, _replay_script_path = replay_path}
  return setmetatable(tbl, TestResult)
end

function TestResult.diff(self, after_result)
  local diffs = {}
  for i, path in ipairs(self.paths) do
    local before = {path = path, dir = self.dir_path}

    local name = before.path:head()
    local after_path = after_result.paths[i]
    if after_path == nil then
      table.insert(diffs, Diff.new(name, before))
      goto continue
    end

    local after = {path = after_path, dir = after_result.dir_path}
    local after_name = after.path:head()
    if name ~= after_name then
      table.insert(diffs, Diff.new(name, before))
      goto continue
    end

    local diff = vim.trim(vim.fn.system({"diff", "-u", before.path:get(), after.path:get()}))
    if #diff ~= 0 then
      table.insert(diffs, Diff.new(name, before, after))
      goto continue
    end

    ::continue::
  end

  return Diffs.new(diffs, self._replay_script_path)
end

return M
