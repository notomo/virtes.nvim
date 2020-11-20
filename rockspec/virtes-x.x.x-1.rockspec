package = "virtes"
version = "x.x.x-1"
source = {url = "git+https://github.com/notomo/virtes.nvim.git", tag = "vx.x.x"}
description = {
  summary = "neovim visual regression test library",
  detailed = "",
  homepage = "https://github.com/notomo/virtes.nvim",
  license = "MIT <http://opensource.org/licenses/MIT>",
}
dependencies = {}
build = {type = "builtin", modules = {["virtes.screenshot"] = "lua/virtes/screenshot.lua"}}
