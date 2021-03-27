local replay = require("virtes.replay")

local M = {}

local Diffs = {}
Diffs.__index = Diffs
M.Diffs = Diffs

function Diffs.new(diffs, replay_path)
  local tbl = {_diffs = diffs, _replay_script_path = replay_path}
  return setmetatable(tbl, Diffs)
end

function Diffs.write_replay_script(self)
  local strs = {}
  for _, diff in ipairs(self._diffs) do
    table.insert(strs, diff:to_replay_script())
  end
  replay.write(self._replay_script_path, strs)
  return self._replay_script_path
end

local Diff = {}
Diff.__index = Diff
M.Diff = Diff

function Diff.new(name, before, after)
  vim.validate({name = {name, "string"}})
  local tbl = {name = name, before = before, after = after}
  return setmetatable(tbl, Diff)
end

function Diff.to_replay_script(self)
  if self.after == nil then
    return table.concat({
      ([[" %s not found on after]]):format(self.name),
      replay.script(self.before.path),
    }, "\n")
  end

  return table.concat({
    ([[" diff found: %s %s]]):format(self.before.path, self.after.path),
    replay.script(self.before.path),
    replay.script(self.after.path),
  }, "\n")
end

return M
