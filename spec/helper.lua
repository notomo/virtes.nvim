local helper = require("vusted.helper")

function helper.before_each() end

function helper.after_each()
  helper.cleanup()
  helper.cleanup_loaded_modules("virtes")
end

function helper.new_file(path, ...)
  local f = io.open(path, "w")
  for _, line in ipairs({ ... }) do
    f:write(line .. "\n")
  end
  f:close()
end

local asserts = require("vusted.assert").asserts

asserts.create("endswith"):register(function(self)
  return function(_, args)
    local pattern = args[1]
    local actual = args[2]
    self:set_positive(("should ends with '%s', but actual: '%s'"):format(pattern, actual))
    self:set_negative(("should not end with '%s', but actual: '%s'"):format(pattern, actual))
    return vim.endswith(actual, pattern)
  end
end)

asserts.create("empty_file"):register(function(self)
  return function(_, args)
    local path = args[1]
    local f = io.open(path, "r")
    if f == nil then
      self:set_positive("should file exists, but doesn't exist")
      self:set_negative("should file exists, but doesn't exist")
      return false
    end
    local content = f:read("*all")
    f:close()
    self:set_positive(("'%s' should empty file, but actual: '%s'"):format(path, content))
    self:set_negative(("'%s' should not empty file, but actual: '%s'"):format(path, content))
    return content == ""
  end
end)

asserts.create("tab_count"):register_eq(function()
  return vim.fn.tabpagenr("$")
end)

package.loaded["test.helper"] = helper
