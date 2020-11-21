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
  if #strs > 0 then
    table.insert(strs, ([[" source %s " ex command to show screenshots on failed]]):format(self._replay_script_path) .. "\n")
  end

  local f = io.open(self._replay_script_path, "w")
  f:write(table.concat(strs, "\n"))
  f:close()

  return self._replay_script_path
end

local Diff = {}
Diff.__index = Diff
M.Diff = Diff

function Diff.new(name, before, after)
  local tbl = {name = name, before = before, after = after}
  return setmetatable(tbl, Diff)
end

function Diff.to_replay_script(self)
  if self.after == nil then
    return table.concat({
      ([[" %s not found on after]]):format(self.name),

      [[tabedit | terminal]],
      [[setlocal bufhidden=wipe]],
      ([[call chansend(&channel, "cat %s\n")]]):format(self.before.path),
      ([[file virtes://%s_%s]]):format(self.before.dir, self.name),
    }, "\n")
  end

  return table.concat({
    ([[" diff found: %s %s]]):format(self.before.path, self.after.path),

    [[tabedit | terminal]],
    [[setlocal bufhidden=wipe]],
    ([[call chansend(&channel, "cat %s\n")]]):format(self.before.path),
    ([[file virtes://%s_%s]]):format(self.before.dir, self.name),

    [[tabedit | terminal]],
    [[setlocal bufhidden=wipe]],
    ([[call chansend(&channel, "cat %s\n")]]):format(self.after.path),
    ([[file virtes://%s_%s]]):format(self.after.dir, self.name),
  }, "\n")
end

return M
