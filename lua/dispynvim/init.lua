local M = {}

local commands = {
  {
    cmd = "DispynvimShowImage",
    args = "index",
    func = "display",
    defn = {
      desc = "Display a single image in a floating window",
    },
  },
}

local function create_commands()
  for _, v in pairs(commands) do
    local command = require(string.format("dispynvim.commands.%s", mod))[v.func](...)
    vim.api.nvim_create_user_command(v.cmd, command, v.defn)
  end
end

M.setup = function(opts)
  create_commands()
end

return M
