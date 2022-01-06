local virtes = require("virtes")
local helper = require("test.helper")

describe("virtes", function()
  after_each(function()
    helper.after_each()
  end)

  it("can run with empty scenario", function()
    virtes.setup():run()
  end)

  it("can run with scenario", function()
    local created = {}

    virtes.setup({
      scenario = function(ctx)
        ctx:screenshot()
        vim.cmd("tabedit")
        ctx:screenshot()
      end,
      screenshot = function(path)
        helper.new_file(path)
        table.insert(created, path)
      end,
    }):run()

    assert.is_same(2, #created)
    assert.endswith("HEAD/1", created[1])
    assert.endswith("HEAD/2", created[2])
  end)

  it("writes empty replay script if diff does not exist", function()
    local test = virtes.setup({
      scenario = function(ctx)
        ctx:screenshot()
      end,
      screenshot = function(path)
        helper.new_file(path)
      end,
    })
    local before = test:run({ name = "before" })
    local after = test:run({ name = "after" })

    local script_path = before:diff(after):write_replay_script()

    assert.empty_file(script_path)
  end)

  it("can write replay script", function()
    local test = virtes.setup({
      scenario = function(ctx)
        ctx:screenshot()
      end,
      screenshot = function(path)
        helper.new_file(path)
      end,
    })

    local before = test:run({ name = "before" })
    local script_path = before:write_replay_script()
    assert.no.empty_file(script_path)

    vim.cmd("source " .. script_path)
    assert.tab_count(2)
  end)

  it("writes replay script if diff exists", function()
    local test = virtes.setup({
      scenario = function(ctx)
        ctx:screenshot()
      end,
      screenshot = function(path)
        helper.new_file(path)
      end,
    })

    local before = test:run({ name = "before" })

    test._screenshot = function(path)
      helper.new_file(path, [[content]])
    end
    local after = test:run({ name = "after" })

    local script_path = before:diff(after):write_replay_script()

    assert.no.empty_file(script_path)

    vim.cmd("source " .. script_path)
    assert.tab_count(3)
  end)
end)
