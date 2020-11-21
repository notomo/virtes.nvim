local Path = require("virtes/lib/path").Path

local M = {}

local Test = {}
Test.__index = Test

local TestContext = {}
TestContext.__index = TestContext

function TestContext.create(dir_path, hash)
  local tbl = {_paths = {}, _dir = dir_path, _hash = hash}
  dir_path:mkdir()

  return setmetatable(tbl, TestContext)
end

function TestContext.screenshot(self, name)
  local file_path = self._dir:join(name or tostring(#self._paths + 1))

  file_path:delete()
  local path = file_path:get()
  M._screenshot(path)

  table.insert(self._paths, file_path)
  return path
end

function TestContext._run(self, scenario)
  local origin_branch
  if self._hash ~= nil then
    origin_branch = vim.fn.systemlist({"git", "rev-parse", "--abbrev-ref", "HEAD"})[1]
    vim.fn.system({"git", "checkout", self._hash})
    if vim.v.shell_error ~= 0 then
      return false, "failed to checkout " .. self._hash
    end
  end

  local ok, result = pcall(scenario, self)

  if origin_branch ~= nil then
    vim.fn.system({"git", "checkout", origin_branch})
  end

  return ok, result
end

local Diffs = {}
Diffs.__index = Diffs

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

local TestResult = {}
TestResult.__index = TestResult

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

function Test.run(self, opts)
  opts = opts or {}
  local name = opts.name or opts.hash or "HEAD"
  local dir_path = self._dir:join(name)
  local ctx = TestContext.create(dir_path, opts.hash)

  self._cleanup()

  local ok, err = ctx:_run(self._scenario)
  if not ok then
    print(err)
    vim.api.nvim_command("cquit")
  end

  return TestResult.new(ctx._paths, ctx._dir, self._replay_script_path)
end

local default_dir_path = vim.fn.getcwd() .. "/spec/screenshot"

M._screenshot = function(file_path)
  return vim.api.nvim__screenshot(file_path)
end

M.setup = function(opts)
  opts = opts or {}
  local result_dir = Path.new(opts.result_dir or default_dir_path)
  local replay_script_path = result_dir:join("replay.vim"):get()

  result_dir:delete()
  result_dir:mkdir()

  local tbl = {
    _dir = result_dir,
    _replay_script_path = replay_script_path,
    _scenario = opts.scenario or function()
    end,
    _cleanup = opts.cleanup or function()
      vim.cmd("silent! %bwipeout!")
    end,
  }
  return setmetatable(tbl, Test)
end

return M
