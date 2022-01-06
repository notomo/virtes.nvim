local Path = require("virtes.lib.path").Path
local TestResult = require("virtes.result").TestResult
local TestContext = require("virtes.context").TestContext

local M = {}

local Test = {}
Test.__index = Test
M.Test = Test

local default_dir_path = vim.fn.getcwd() .. "/spec/screenshot"

function Test.setup(opts)
  vim.validate({ opts = { opts, "table", true } })
  opts = opts or {}
  local result_dir = Path.new(opts.result_dir or default_dir_path)
  local replay_script_path = result_dir:join("replay.vim"):get()

  result_dir:delete()
  result_dir:mkdir()

  local tbl = {
    _dir = result_dir,
    _replay_script_path = replay_script_path,
    _scenario = opts.scenario or function() end,
    _cleanup = opts.cleanup or function()
      vim.cmd("silent! %bwipeout!")
    end,
    _screenshot = opts.screenshot or function(file_path)
      vim.api.nvim_command("redraw!")
      return vim.api.nvim__screenshot(file_path)
    end,
  }
  return setmetatable(tbl, Test)
end

function Test.run(self, opts)
  vim.validate({ opts = { opts, "table", true } })
  opts = opts or {}
  local name = opts.name or opts.hash or "HEAD"
  local dir_path = self._dir:join(name)
  local ctx = TestContext.create(dir_path, opts.hash, self._screenshot)

  self._cleanup()

  local ok, err = ctx:_run(self._scenario)
  if not ok then
    print(err)
    vim.api.nvim_command("cquit")
  end

  return TestResult.new(ctx._paths, ctx._dir, self._replay_script_path)
end

return M
