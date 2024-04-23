local Diffs = require("virtes.diff").Diffs
local Diff = require("virtes.diff").Diff
local replay = require("virtes.replay")

local M = {}

local TestResult = {}
TestResult.__index = TestResult
M.TestResult = TestResult

function TestResult.new(paths, dir_path, replay_path)
  vim.validate({ paths = { paths, "table" }, replay_path = { replay_path, "string" } })
  local tbl = { paths = paths, dir_path = dir_path, _replay_script_path = replay_path }
  return setmetatable(tbl, TestResult)
end

function TestResult.diff(self, after_result)
  vim.validate({ after_result = { after_result, "table" } })

  local diffs = vim
    .iter(self.paths)
    :enumerate()
    :map(function(i, path)
      local before = { path = path, dir = self.dir_path }

      local name = before.path:head()
      local after_path = after_result.paths[i]
      if after_path == nil then
        return Diff.new(name, before)
      end

      local after = { path = after_path, dir = after_result.dir_path }
      local after_name = after.path:head()
      if name ~= after_name then
        return Diff.new(name, before)
      end

      local diff = vim.trim(vim.fn.system({ "diff", "-u", before.path:get(), after.path:get() }))
      if #diff ~= 0 then
        return Diff.new(name, before, after)
      end
    end)
    :totable()

  return Diffs.new(diffs, self._replay_script_path)
end

function TestResult.write_replay_script(self)
  local strs = vim
    .iter(self.paths)
    :map(function(path)
      return replay.script(path)
    end)
    :totable()
  local path = self.dir_path:join("replay.vim"):get()
  replay.write(path, strs)
  return path
end

return M
