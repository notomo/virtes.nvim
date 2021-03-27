local M = {}

function M.script(path)
  local dir_name = path:parent():head():gsub("/", "")
  local file_name = path:head()
  return table.concat({
    [[tabedit | terminal]],
    [[setlocal bufhidden=wipe]],
    ([[call chansend(&channel, "cat %s\n")]]):format(path),
    ([[file virtes://%s_%s]]):format(dir_name, file_name),
  }, "\n")
end

function M.write(path, strs)
  vim.validate({strs = {strs, "table"}})
  if #strs > 0 then
    table.insert(strs, ([[" source %s " ex command to show screenshots]]):format(path) .. "\n")
  end

  local f = io.open(path, "w")
  f:write(table.concat(strs, "\n"))
  f:close()
end

return M
