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
    local callback = lazy("command", v.func, vim.tbl_get(v, "meta", "retry_on_setup"))
    vim.api.nvim_create_user_command(v.cmd, callback, v.defn)
  end
end

M.setup = function(opts)
  create_commands()
end

M.display = function(opts)
  print("Displaying an image")
end

return M
